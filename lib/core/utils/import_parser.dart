import 'dart:convert';
import 'package:yaml/yaml.dart';

import 'obfuscation.dart';

class ImportResolution {
  final bool outcome;
  final double? numericOutcome;
  final String? notes;

  const ImportResolution({
    required this.outcome,
    this.numericOutcome,
    this.notes,
  });
}

class ImportQuestion {
  final String text;
  final String? category;        // per-Frage, nur in v2-Exporten gesetzt
  final List<String> tags;
  final bool? answer;
  final DateTime? deadline;
  // Schätzfelder (optional)
  final String predictionType;   // 'binary' | 'factual' | 'interval'
  final double? probability;     // kanonischer Wert aus v2-Exporten (read-only)
  final bool? binaryChoice;      // für binary/factual-Typ
  final double? confidenceLevel; // für binary + interval
  final double? lowerBound;      // für interval
  final double? upperBound;      // für interval
  final String? unit;            // für interval (z.B. "km", "°C")
  final ImportResolution? resolution;

  const ImportQuestion({
    required this.text,
    this.category,
    this.tags = const [],
    this.answer,
    this.deadline,
    this.predictionType = 'binary',
    this.probability,
    this.binaryChoice,
    this.confidenceLevel,
    this.lowerBound,
    this.upperBound,
    this.unit,
    this.resolution,
  });

  bool get hasResolution => resolution != null;

  bool get hasEstimateData {
    return ((predictionType == 'binary' || predictionType == 'factual') &&
            binaryChoice != null) ||
        (predictionType == 'interval' &&
            lowerBound != null &&
            upperBound != null);
  }
}

class ImportFile {
  final int version;
  final String category;
  final String? source;
  final List<ImportQuestion> questions;

  const ImportFile({
    required this.version,
    required this.category,
    this.source,
    required this.questions,
  });
}

class ImportParseException implements Exception {
  final String message;
  const ImportParseException(this.message);

  @override
  String toString() => 'ImportParseException: $message';
}

class ImportParser {
  static ImportFile parse(String content, String filename) {
    Map<String, dynamic> data;

    final lowerName = filename.toLowerCase();
    if (lowerName.endsWith('.yaml') || lowerName.endsWith('.yml')) {
      final yaml = loadYaml(content);
      data = _yamlToMap(yaml);
    } else if (lowerName.endsWith('.json')) {
      data = jsonDecode(content) as Map<String, dynamic>;
    } else {
      throw ImportParseException(
          'Unbekanntes Format: $filename. Nur .json und .yaml werden unterstützt.');
    }

    return _parseMap(data);
  }

  /// Erkennt das Format automatisch – zuerst JSON, dann Markdown-Code-Block,
  /// dann YAML.
  static ImportFile parseAutoDetect(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw const ImportParseException('Inhalt ist leer.');
    }

    if (trimmed.startsWith('{')) {
      try {
        final data = jsonDecode(trimmed) as Map<String, dynamic>;
        return _parseMap(data);
      } on FormatException catch (e) {
        throw ImportParseException('Ungültiges JSON: ${e.message}');
      }
    }

    // Markdown-Code-Block (```json / ```yaml / ```yml) extrahieren und parsen.
    final extracted = _extractFromCodeBlock(trimmed);
    if (extracted != null) {
      if (extracted.startsWith('{')) {
        try {
          final data = jsonDecode(extracted) as Map<String, dynamic>;
          return _parseMap(data);
        } on FormatException catch (e) {
          throw ImportParseException(
              'Ungültiges JSON im Code-Block: ${e.message}');
        }
      }
      try {
        final yaml = loadYaml(extracted);
        final data = _yamlToMap(yaml);
        return _parseMap(data);
      } on ImportParseException {
        rethrow;
      } catch (e) {
        throw ImportParseException(
            'Ungültiges YAML im Code-Block: $e');
      }
    }

    try {
      final yaml = loadYaml(trimmed);
      final data = _yamlToMap(yaml);
      return _parseMap(data);
    } on ImportParseException {
      rethrow;
    } catch (e) {
      throw ImportParseException(
          'Inhalt konnte nicht als JSON oder YAML geparst werden: $e');
    }
  }

  /// Gibt den Inhalt des ersten ```json```, ```yaml``` oder ```yml```-Blocks
  /// zurück, oder null wenn keiner gefunden wurde.
  static String? _extractFromCodeBlock(String content) {
    final pattern = RegExp(
      r'```(?:json|yaml|yml)[^\n]*\n([\s\S]*?)\n[ \t]*```',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(content);
    return match?.group(1)?.trim();
  }

  static ImportFile _parseMap(Map<String, dynamic> data) {
    final version = data['version'];
    if (version == null) {
      throw const ImportParseException('Pflichtfeld "version" fehlt.');
    }
    final versionInt =
        version is num ? version.toInt() : int.tryParse(version.toString());
    if (versionInt == null) {
      throw const ImportParseException(
          'Pflichtfeld "version" muss eine Zahl sein.');
    }

    // v1: top-level category Pflichtfeld; v2 (App-Export): category pro Frage
    final topLevelCategory = data['category'] as String?;
    if (versionInt < 2 &&
        (topLevelCategory == null ||
            (topLevelCategory != 'epistemic' &&
                topLevelCategory != 'aleatory'))) {
      throw const ImportParseException(
          'Pflichtfeld "category" muss "epistemic" oder "aleatory" sein.');
    }

    final rawQuestions = data['questions'];
    if (rawQuestions == null || rawQuestions is! List) {
      throw const ImportParseException(
          'Pflichtfeld "questions" muss eine Liste sein.');
    }

    final questions = <ImportQuestion>[];
    for (var i = 0; i < rawQuestions.length; i++) {
      final q = rawQuestions[i];
      if (q is! Map) {
        throw ImportParseException('Frage $i ist kein Objekt.');
      }
      final qMap = Map<String, dynamic>.from(q);

      final text = qMap['text'] as String?;
      if (text == null || text.trim().isEmpty) {
        throw ImportParseException('Frage $i: "text" fehlt oder ist leer.');
      }

      final rawTags = qMap['tags'];
      final tags = rawTags is List
          ? rawTags.map((t) => t.toString()).toList()
          : <String>[];

      DateTime? deadline;
      final rawDeadline = qMap['deadline'];
      if (rawDeadline != null) {
        deadline = DateTime.tryParse(rawDeadline.toString());
      }

      // Vorhersagetyp – 'probability' und unbekannte Werte werden anhand
      // der Kategorie auf 'binary' (aleatorisch) oder 'factual' (epistemisch) gemappt.
      final rawType = qMap['predictionType'] as String?;
      final String predictionType;
      if (rawType == 'binary' || rawType == 'factual' || rawType == 'interval') {
        predictionType = rawType!;
      } else {
        final effectiveCat = topLevelCategory ?? (qMap['category'] as String?);
        predictionType = effectiveCat == 'epistemic' ? 'factual' : 'binary';
      }

      // v2-Export: category pro Frage, answer via hasKnownAnswer+knownAnswer,
      // Schätzfelder im verschachtelten 'estimate'-Objekt
      final String? questionCategory;
      final bool? answer;
      double? probability;
      bool? binaryChoice;
      double? confidenceLevel;
      double? lowerBound;
      double? upperBound;
      String? unit;

      if (versionInt >= 2) {
        questionCategory = qMap['category'] as String?;
        final hasKnownAnswer = qMap['hasKnownAnswer'] as bool? ?? false;
        answer = hasKnownAnswer ? (qMap['knownAnswer'] as bool?) : null;

        final rawEstimate = qMap['estimate'];
        if (rawEstimate is Map) {
          final est = Map<String, dynamic>.from(rawEstimate);
          probability = _readDouble(est['probability'], i, 'probability');
          binaryChoice = est['binaryChoice'] as bool?;
          confidenceLevel =
              _readDouble(est['confidenceLevel'], i, 'confidenceLevel');
          lowerBound = _readDouble(est['lowerBound'], i, 'lowerBound');
          upperBound = _readDouble(est['upperBound'], i, 'upperBound');
          unit = est['unit'] as String?;
        }
        // Fallback: unit auch auf Fragenebene akzeptieren
        unit ??= qMap['unit'] as String?;
      } else {
        questionCategory = null;
        answer = qMap['answer'] as bool?;
        probability = _readDouble(qMap['probability'], i, 'probability');
        binaryChoice = qMap['binaryChoice'] as bool?;
        confidenceLevel =
            _readDouble(qMap['confidenceLevel'], i, 'confidenceLevel');
        lowerBound = _readDouble(qMap['lowerBound'], i, 'lowerBound');
        upperBound = _readDouble(qMap['upperBound'], i, 'upperBound');
        unit = qMap['unit'] as String?;
      }

      _validateRanges(
        index: i,
        probability: probability,
        confidenceLevel: confidenceLevel,
        lowerBound: lowerBound,
        upperBound: upperBound,
      );

      // Resolution: plain Map (v1 und v2) oder obfuskierter String (v2-Export)
      ImportResolution? importResolution;
      final rawRes = qMap['resolution'];
      if (rawRes is String && versionInt >= 2) {
        try {
          final resMap = deobfuscateResolution(rawRes);
          importResolution = _parseResolutionMap(resMap);
        } catch (_) {
          // ungültige Obfuskierung → ignorieren
        }
      } else if (rawRes is Map) {
        importResolution =
            _parseResolutionMap(Map<String, dynamic>.from(rawRes));
      }

      // Eingebettete "probability"-Schätzungen (v1-Format, CLAUDE.md,
      // Beispieldaten) in Richtung + Konfidenz ableiten, statt sie beim
      // Import stillschweigend zu verwerfen.
      if ((predictionType == 'binary' || predictionType == 'factual') &&
          binaryChoice == null &&
          probability != null) {
        binaryChoice = probability >= 0.5;
        final directed = probability >= 0.5 ? probability : 1 - probability;
        confidenceLevel ??=
            ((directed / 0.05).round() * 0.05).clamp(0.5, 1.0).toDouble();
      }

      questions.add(ImportQuestion(
        text: text,
        category: questionCategory,
        tags: tags,
        answer: answer,
        deadline: deadline,
        predictionType: predictionType,
        probability: probability,
        binaryChoice: binaryChoice,
        confidenceLevel: confidenceLevel,
        lowerBound: lowerBound,
        upperBound: upperBound,
        unit: unit,
        resolution: importResolution,
      ));
    }

    // Effektive Gesamtkategorie: top-level wenn angegeben,
    // sonst aus erster Frage ableiten (v2-Export)
    final effectiveCategory = topLevelCategory ??
        questions.map((q) => q.category).whereType<String>().firstOrNull ??
        'epistemic';

    return ImportFile(
      version: versionInt,
      category: effectiveCategory,
      source: data['source'] as String?,
      questions: questions,
    );
  }

  /// Liest einen optionalen Zahlenwert robust (num oder numerischer String).
  /// Wirft eine [ImportParseException] mit Fragen-Index, wenn der Wert
  /// vorhanden, aber keine Zahl ist.
  static double? _readDouble(dynamic value, int index, String field) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final parsed = num.tryParse(value.toString());
    if (parsed == null) {
      throw ImportParseException(
          'Frage $index: "$field" muss eine Zahl sein.');
    }
    return parsed.toDouble();
  }

  /// Prüft Wertebereiche der Schätzfelder, damit ungültige Werte
  /// (z. B. confidenceLevel: 7) nicht Statistik und UI verfälschen.
  static void _validateRanges({
    required int index,
    double? probability,
    double? confidenceLevel,
    double? lowerBound,
    double? upperBound,
  }) {
    if (probability != null && (probability < 0 || probability > 1)) {
      throw ImportParseException(
          'Frage $index: "probability" muss zwischen 0 und 1 liegen.');
    }
    if (confidenceLevel != null &&
        (confidenceLevel < 0 || confidenceLevel > 1)) {
      throw ImportParseException(
          'Frage $index: "confidenceLevel" muss zwischen 0 und 1 liegen.');
    }
    if (lowerBound != null && upperBound != null && lowerBound >= upperBound) {
      throw ImportParseException(
          'Frage $index: "lowerBound" muss kleiner als "upperBound" sein.');
    }
  }

  static ImportResolution _parseResolutionMap(Map<String, dynamic> map) {
    return ImportResolution(
      outcome: map['outcome'] as bool? ?? false,
      numericOutcome: (map['numericOutcome'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
    );
  }

  static Map<String, dynamic> _yamlToMap(dynamic yaml) {
    if (yaml is YamlMap) {
      return yaml.map((k, v) => MapEntry(k.toString(), _convertYaml(v)));
    }
    throw const ImportParseException('YAML-Datei ist kein Objekt.');
  }

  static dynamic _convertYaml(dynamic value) {
    if (value is YamlMap) {
      return value.map((k, v) => MapEntry(k.toString(), _convertYaml(v)));
    }
    if (value is YamlList) {
      return value.map(_convertYaml).toList();
    }
    return value;
  }
}
