import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kailibrate/core/database/app_database.dart';
import 'package:kailibrate/core/services/backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertSampleQuestion(AppDatabase target,
      {String text = 'Wird es morgen regnen?'}) async {
    final id = await target.insertQuestion(QuestionsCompanion.insert(
      questionText: text,
      category: 'aleatory',
      tags: const Value('["weather"]'),
      predictionType: const Value('binary'),
    ));
    await target.upsertEstimate(EstimatesCompanion.insert(
      questionId: id,
      probability: 0.7,
      confidenceLevel: const Value(0.7),
      binaryChoice: const Value(true),
    ));
    await target.upsertResolution(ResolutionsCompanion.insert(
      questionId: id,
      outcome: true,
      notes: const Value('Quelle: Wetterbericht'),
    ));
    return id;
  }

  group('BackupService Roundtrip', () {
    test('createBackup → restoreBackup stellt alle Daten wieder her',
        () async {
      await insertSampleQuestion(db);

      final backupJson = await BackupService.createBackup(
        db: db,
        password: 'korrekt-pferd-batterie',
      );

      // In eine frische Datenbank wiederherstellen.
      final restored = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(restored.close);
      await BackupService.restoreBackup(
        db: restored,
        backupJson: backupJson,
        password: 'korrekt-pferd-batterie',
      );

      final views = await restored.getAllPredictionViews();
      expect(views, hasLength(1));
      final v = views.single;
      expect(v.question.questionText, 'Wird es morgen regnen?');
      expect(v.question.category, 'aleatory');
      expect(v.tagList, ['weather']);
      expect(v.estimate, isNotNull);
      expect(v.estimate!.probability, closeTo(0.7, 1e-9));
      expect(v.estimate!.binaryChoice, isTrue);
      expect(v.resolution, isNotNull);
      expect(v.resolution!.outcome, isTrue);
      expect(v.resolution!.notes, 'Quelle: Wetterbericht');
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('falsches Passwort wirft BackupException ohne Datenverlust',
        () async {
      await insertSampleQuestion(db);
      final backupJson = await BackupService.createBackup(
        db: db,
        password: 'richtig',
      );

      await expectLater(
        BackupService.restoreBackup(
          db: db,
          backupJson: backupJson,
          password: 'falsch',
        ),
        throwsA(isA<BackupException>().having(
            (e) => e.message, 'message', contains('Passwort'))),
      );

      // Bestehende Daten bleiben unangetastet.
      expect(await db.getAllQuestions(), hasLength(1));
    }, timeout: const Timeout(Duration(minutes: 2)));
  });

  group('BackupService Fehlerfälle', () {
    test('keine gültige JSON-Datei wirft BackupException', () async {
      await expectLater(
        BackupService.restoreBackup(
          db: db,
          backupJson: 'kein json',
          password: 'egal',
        ),
        throwsA(isA<BackupException>()),
      );
    });

    test('nicht unterstützte Version wirft BackupException', () async {
      final json = jsonEncode({'version': 99});
      await expectLater(
        BackupService.restoreBackup(db: db, backupJson: json, password: 'x'),
        throwsA(isA<BackupException>().having(
            (e) => e.message, 'message', contains('Version'))),
      );
    });

    test('manipulierte KDF-Iterationen werden abgelehnt', () async {
      for (final iterations in [1, 2147483647]) {
        final json = jsonEncode({
          'version': 1,
          'kdf': {
            'algorithm': 'PBKDF2-HMAC-SHA256',
            'iterations': iterations,
            'salt': base64Encode(List.filled(16, 0)),
          },
          'cipher': 'AES-256-GCM',
          'nonce': base64Encode(List.filled(12, 0)),
          'mac': base64Encode(List.filled(16, 0)),
          'ciphertext': base64Encode(List.filled(32, 0)),
        });
        await expectLater(
          BackupService.restoreBackup(
              db: db, backupJson: json, password: 'x'),
          throwsA(isA<BackupException>().having(
              (e) => e.message, 'message', contains('KDF'))),
        );
      }
    });
  });

  group('AppDatabase.restoreFromBackup', () {
    test('defektes Backup lässt bestehende Daten unangetastet (atomar)',
        () async {
      await insertSampleQuestion(db, text: 'Bestehende Frage');

      // Zweiter Eintrag ist defekt (text fehlt) → Transaktion rollt zurück.
      await expectLater(
        db.restoreFromBackup({
          'version': 1,
          'questions': [
            {'text': 'Neue Frage', 'category': 'epistemic'},
            {'category': 'epistemic'},
          ],
        }),
        throwsA(isA<FormatException>()),
      );

      final questions = await db.getAllQuestions();
      expect(questions, hasLength(1));
      expect(questions.single.questionText, 'Bestehende Frage');
    });
  });
}
