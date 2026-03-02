import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:calibrate/core/utils/import_parser.dart';

// Hilfsfunktionen: spiegeln die Obfuskierung in app_database.dart
String _rot13(String input) {
  return String.fromCharCodes(input.codeUnits.map((c) {
    if (c >= 65 && c <= 90) return (c - 65 + 13) % 26 + 65;
    if (c >= 97 && c <= 122) return (c - 97 + 13) % 26 + 97;
    return c;
  }));
}

String _obfuscate(Map<String, dynamic> data) {
  final json = jsonEncode(data);
  final rot13 = _rot13(json);
  return base64Encode(utf8.encode(rot13));
}

void main() {
  group('ImportParser.parse() with JSON', () {
    test('parses valid epistemic JSON', () {
      const content = '''
{
  "version": 1,
  "category": "epistemic",
  "source": "Test Source",
  "questions": [
    {
      "text": "Ist die Erde rund?",
      "tags": ["science"],
      "answer": true
    }
  ]
}
''';
      final result = ImportParser.parse(content, 'test.json');
      expect(result.version, 1);
      expect(result.category, 'epistemic');
      expect(result.source, 'Test Source');
      expect(result.questions.length, 1);
      expect(result.questions.first.text, 'Ist die Erde rund?');
      expect(result.questions.first.tags, ['science']);
      expect(result.questions.first.answer, true);
    });

    test('parses valid aleatory JSON without answer', () {
      const content = '''
{
  "version": 1,
  "category": "aleatory",
  "questions": [
    {
      "text": "Wird es morgen regnen?",
      "tags": ["weather"]
    }
  ]
}
''';
      final result = ImportParser.parse(content, 'test.json');
      expect(result.category, 'aleatory');
      expect(result.questions.first.answer, isNull);
      expect(result.source, isNull);
    });

    test('parses multiple questions', () {
      const content = '''
{
  "version": 1,
  "category": "epistemic",
  "questions": [
    {"text": "Frage 1"},
    {"text": "Frage 2"},
    {"text": "Frage 3"}
  ]
}
''';
      final result = ImportParser.parse(content, 'test.json');
      expect(result.questions.length, 3);
    });

    test('parses question with deadline', () {
      const content = '''
{
  "version": 1,
  "category": "aleatory",
  "questions": [
    {
      "text": "Frage mit Deadline",
      "deadline": "2026-12-31"
    }
  ]
}
''';
      final result = ImportParser.parse(content, 'test.json');
      expect(result.questions.first.deadline, isNotNull);
      expect(result.questions.first.deadline!.year, 2026);
      expect(result.questions.first.deadline!.month, 12);
      expect(result.questions.first.deadline!.day, 31);
    });

    test('parses question with empty tags list', () {
      const content = '''
{
  "version": 1,
  "category": "epistemic",
  "questions": [
    {"text": "Frage ohne Tags", "tags": []}
  ]
}
''';
      final result = ImportParser.parse(content, 'test.json');
      expect(result.questions.first.tags, isEmpty);
    });

    test('throws ImportParseException when version is missing', () {
      const content = '''
{
  "category": "epistemic",
  "questions": [{"text": "Frage"}]
}
''';
      expect(
        () => ImportParser.parse(content, 'test.json'),
        throwsA(isA<ImportParseException>()),
      );
    });

    test('throws ImportParseException when category is missing', () {
      const content = '''
{
  "version": 1,
  "questions": [{"text": "Frage"}]
}
''';
      expect(
        () => ImportParser.parse(content, 'test.json'),
        throwsA(isA<ImportParseException>()),
      );
    });

    test('throws ImportParseException when category is invalid', () {
      const content = '''
{
  "version": 1,
  "category": "unknown",
  "questions": [{"text": "Frage"}]
}
''';
      expect(
        () => ImportParser.parse(content, 'test.json'),
        throwsA(isA<ImportParseException>()),
      );
    });

    test('throws ImportParseException when questions is missing', () {
      const content = '''
{
  "version": 1,
  "category": "epistemic"
}
''';
      expect(
        () => ImportParser.parse(content, 'test.json'),
        throwsA(isA<ImportParseException>()),
      );
    });

    test('throws ImportParseException when question text is empty', () {
      const content = '''
{
  "version": 1,
  "category": "epistemic",
  "questions": [{"text": "   "}]
}
''';
      expect(
        () => ImportParser.parse(content, 'test.json'),
        throwsA(isA<ImportParseException>()),
      );
    });

    test('throws ImportParseException for unsupported file extension', () {
      const content = '{}';
      expect(
        () => ImportParser.parse(content, 'test.csv'),
        throwsA(isA<ImportParseException>()),
      );
    });
  });

  group('ImportParser.parse() with YAML', () {
    test('parses valid epistemic YAML', () {
      const content = '''
version: 1
category: epistemic
source: YAML Source
questions:
  - text: Liegt Paris in Frankreich?
    tags: [geography]
    answer: true
''';
      final result = ImportParser.parse(content, 'test.yaml');
      expect(result.version, 1);
      expect(result.category, 'epistemic');
      expect(result.source, 'YAML Source');
      expect(result.questions.length, 1);
      expect(result.questions.first.text, 'Liegt Paris in Frankreich?');
      expect(result.questions.first.answer, true);
    });

    test('parses valid aleatory YAML', () {
      const content = '''
version: 1
category: aleatory
questions:
  - text: Werde ich heute Sport treiben?
    tags: [health, daily]
  - text: Werde ich pünktlich sein?
    tags: [habits]
''';
      final result = ImportParser.parse(content, 'test.yaml');
      expect(result.category, 'aleatory');
      expect(result.questions.length, 2);
      expect(result.questions[0].tags, ['health', 'daily']);
      expect(result.questions[1].tags, ['habits']);
    });

    test('also accepts .yml extension', () {
      const content = '''
version: 1
category: aleatory
questions:
  - text: Eine Frage?
''';
      final result = ImportParser.parse(content, 'test.yml');
      expect(result.category, 'aleatory');
      expect(result.questions.length, 1);
    });

    test('throws ImportParseException for invalid YAML category', () {
      const content = '''
version: 1
category: invalid
questions:
  - text: Frage?
''';
      expect(
        () => ImportParser.parse(content, 'test.yaml'),
        throwsA(isA<ImportParseException>()),
      );
    });
  });

  group('ImportParser – v2 App-Export', () {
    test('parst v2-Export ohne top-level category', () {
      const content = '''
{
  "version": 2,
  "exportedAt": "2026-03-01T12:00:00.000Z",
  "questions": [
    {
      "id": 1,
      "text": "Liegt Santiago de Chile östlich von New York?",
      "category": "epistemic",
      "predictionType": "probability",
      "tags": ["geography"],
      "source": "Geografie-Trivia",
      "hasKnownAnswer": true,
      "knownAnswer": true,
      "deadline": null,
      "createdAt": "2026-03-01T10:00:00.000Z",
      "estimate": {
        "probability": 0.35,
        "lowerBound": null,
        "upperBound": null,
        "unit": null,
        "confidenceLevel": 0.9,
        "binaryChoice": null,
        "createdAt": "2026-03-01T10:05:00.000Z"
      }
    }
  ]
}
''';
      final result = ImportParser.parse(content, 'export.json');
      expect(result.version, 2);
      expect(result.category, 'epistemic');
      expect(result.questions.length, 1);
      final q = result.questions.first;
      expect(q.text, 'Liegt Santiago de Chile östlich von New York?');
      expect(q.category, 'epistemic');
      expect(q.answer, true);
      expect(q.probability, 0.35);
      expect(q.confidenceLevel, 0.9);
    });

    test('liest hasKnownAnswer=false als answer=null', () {
      const content = '''
{
  "version": 2,
  "exportedAt": "2026-03-01T12:00:00.000Z",
  "questions": [
    {
      "text": "Frage ohne bekannte Antwort",
      "category": "aleatory",
      "predictionType": "probability",
      "tags": [],
      "hasKnownAnswer": false,
      "knownAnswer": null,
      "createdAt": "2026-03-01T10:00:00.000Z"
    }
  ]
}
''';
      final result = ImportParser.parse(content, 'export.json');
      expect(result.questions.first.answer, isNull);
    });

    test('liest Schätzfelder aus verschachteltem estimate-Objekt', () {
      const content = '''
{
  "version": 2,
  "exportedAt": "2026-03-01T12:00:00.000Z",
  "questions": [
    {
      "text": "Intervall-Frage",
      "category": "aleatory",
      "predictionType": "interval",
      "tags": [],
      "hasKnownAnswer": false,
      "knownAnswer": null,
      "createdAt": "2026-03-01T10:00:00.000Z",
      "estimate": {
        "probability": 0.8,
        "lowerBound": 20.0,
        "upperBound": 45.0,
        "unit": "km",
        "confidenceLevel": 0.8,
        "binaryChoice": null,
        "createdAt": "2026-03-01T10:05:00.000Z"
      }
    }
  ]
}
''';
      final result = ImportParser.parse(content, 'export.json');
      final q = result.questions.first;
      expect(q.predictionType, 'interval');
      expect(q.lowerBound, 20.0);
      expect(q.upperBound, 45.0);
      expect(q.unit, 'km');
      expect(q.confidenceLevel, 0.8);
    });

    test('leitet category aus erster Frage ab bei gemischtem Export', () {
      const content = '''
{
  "version": 2,
  "exportedAt": "2026-03-01T12:00:00.000Z",
  "questions": [
    {
      "text": "Episteme Frage",
      "category": "epistemic",
      "predictionType": "probability",
      "tags": [],
      "hasKnownAnswer": false,
      "knownAnswer": null,
      "createdAt": "2026-03-01T10:00:00.000Z"
    },
    {
      "text": "Aleatorische Frage",
      "category": "aleatory",
      "predictionType": "probability",
      "tags": [],
      "hasKnownAnswer": false,
      "knownAnswer": null,
      "createdAt": "2026-03-01T10:00:00.000Z"
    }
  ]
}
''';
      final result = ImportParser.parse(content, 'export.json');
      expect(result.category, 'epistemic'); // aus erster Frage
      expect(result.questions[0].category, 'epistemic');
      expect(result.questions[1].category, 'aleatory');
    });

    test('parst Resolution als Plain-Map (Rückwärtskompatibilität)', () {
      const content = '''
{
  "version": 2,
  "exportedAt": "2026-03-01T12:00:00.000Z",
  "questions": [
    {
      "text": "Frage mit Resolution",
      "category": "epistemic",
      "predictionType": "probability",
      "tags": [],
      "hasKnownAnswer": false,
      "knownAnswer": null,
      "createdAt": "2026-03-01T10:00:00.000Z",
      "estimate": {
        "probability": 0.7,
        "lowerBound": null,
        "upperBound": null,
        "unit": null,
        "confidenceLevel": 0.9,
        "binaryChoice": null,
        "createdAt": "2026-03-01T10:05:00.000Z"
      },
      "resolution": {
        "outcome": true,
        "numericOutcome": null,
        "notes": "Hat geklappt",
        "resolvedAt": "2026-03-01T14:00:00.000Z"
      }
    }
  ]
}
''';
      final result = ImportParser.parse(content, 'export.json');
      final q = result.questions.first;
      expect(q.hasResolution, isTrue);
      expect(q.resolution!.outcome, isTrue);
      expect(q.resolution!.notes, 'Hat geklappt');
      expect(q.resolution!.numericOutcome, isNull);
    });

    test('parst obfuskierte Resolution (Base64+ROT13)', () {
      final obfuscatedResolution = _obfuscate({
        'outcome': false,
        'numericOutcome': 42.5,
        'notes': 'Test-Notiz',
        'resolvedAt': '2026-03-01T14:00:00.000Z',
      });
      final content = jsonEncode({
        'version': 2,
        'exportedAt': '2026-03-01T12:00:00.000Z',
        'questions': [
          {
            'text': 'Frage mit obfuskierter Resolution',
            'category': 'aleatory',
            'predictionType': 'probability',
            'tags': [],
            'hasKnownAnswer': false,
            'knownAnswer': null,
            'createdAt': '2026-03-01T10:00:00.000Z',
            'resolution': obfuscatedResolution,
          }
        ],
      });
      final result = ImportParser.parseAutoDetect(content);
      final q = result.questions.first;
      expect(q.hasResolution, isTrue);
      expect(q.resolution!.outcome, isFalse);
      expect(q.resolution!.numericOutcome, 42.5);
      expect(q.resolution!.notes, 'Test-Notiz');
    });

    test('Frage ohne Resolution hat hasResolution=false', () {
      const content = '''
{
  "version": 2,
  "exportedAt": "2026-03-01T12:00:00.000Z",
  "questions": [
    {
      "text": "Frage ohne Resolution",
      "category": "epistemic",
      "predictionType": "probability",
      "tags": [],
      "hasKnownAnswer": false,
      "knownAnswer": null,
      "createdAt": "2026-03-01T10:00:00.000Z"
    }
  ]
}
''';
      final result = ImportParser.parse(content, 'export.json');
      expect(result.questions.first.hasResolution, isFalse);
    });

    test('v1: fehlende category wirft weiterhin Exception', () {
      const content = '''
{
  "version": 1,
  "questions": [{"text": "Frage"}]
}
''';
      expect(
        () => ImportParser.parse(content, 'test.json'),
        throwsA(isA<ImportParseException>()),
      );
    });
  });

  group('ImportParseException', () {
    test('toString includes message', () {
      const ex = ImportParseException('Testfehler');
      expect(ex.toString(), contains('Testfehler'));
    });
  });

  group('ImportParser – v1 mit resolution-Feld', () {
    test('parst plain-Map-Resolution in v1-Datei', () {
      const content = '''
{
  "version": 1,
  "category": "epistemic",
  "source": "FC Schalke 04",
  "questions": [
    {
      "text": "In welchem Jahr wurde der FC Schalke 04 gegründet?",
      "predictionType": "interval",
      "tags": ["football", "schalke"],
      "unit": "Jahr",
      "resolution": {
        "outcome": true,
        "numericOutcome": 1904,
        "notes": "Gegründet am 4. Mai 1904."
      }
    }
  ]
}
''';
      final result = ImportParser.parseAutoDetect(content);
      final q = result.questions.first;
      expect(q.hasResolution, isTrue);
      expect(q.resolution!.outcome, isTrue);
      expect(q.resolution!.numericOutcome, 1904.0);
      expect(q.resolution!.notes, 'Gegründet am 4. Mai 1904.');
    });

    test('v1-Resolution ohne numericOutcome funktioniert', () {
      const content = '''
{
  "version": 1,
  "category": "epistemic",
  "questions": [
    {
      "text": "Liegt Santiago de Chile östlich von New York?",
      "resolution": {
        "outcome": true,
        "notes": "Santiago liegt auf 70°W."
      }
    }
  ]
}
''';
      final result = ImportParser.parseAutoDetect(content);
      final q = result.questions.first;
      expect(q.hasResolution, isTrue);
      expect(q.resolution!.outcome, isTrue);
      expect(q.resolution!.numericOutcome, isNull);
    });
  });

  group('parseAutoDetect – Markdown-Code-Block-Extraktion', () {
    const jsonPayload = '''
{
  "version": 1,
  "category": "epistemic",
  "questions": [{"text": "Frage aus Code-Block"}]
}''';

    const yamlPayload = '''version: 1
category: epistemic
questions:
  - text: Frage aus YAML-Block''';

    test('extrahiert JSON aus ```json-Block', () {
      final content = '```json\n$jsonPayload\n```';
      final result = ImportParser.parseAutoDetect(content);
      expect(result.questions.first.text, 'Frage aus Code-Block');
    });

    test('extrahiert YAML aus ```yaml-Block', () {
      final content = '```yaml\n$yamlPayload\n```';
      final result = ImportParser.parseAutoDetect(content);
      expect(result.questions.first.text, 'Frage aus YAML-Block');
    });

    test('extrahiert JSON aus ```yml-Block', () {
      final content = '```yml\n$jsonPayload\n```';
      final result = ImportParser.parseAutoDetect(content);
      expect(result.questions.first.text, 'Frage aus Code-Block');
    });

    test('ignoriert umgebenden LLM-Text und nutzt ersten Code-Block', () {
      final content = '''
Hier sind deine Kalibrierungsfragen:

```json
$jsonPayload
```

**Import:** Text kopieren → Calibrate öffnen → Import
''';
      final result = ImportParser.parseAutoDetect(content);
      expect(result.questions.first.text, 'Frage aus Code-Block');
    });

    test('JSON ohne Code-Block wird wie bisher geparst', () {
      final result = ImportParser.parseAutoDetect(jsonPayload);
      expect(result.questions.first.text, 'Frage aus Code-Block');
    });

    test('wirft Exception bei leerem Code-Block-Inhalt', () {
      const content = 'Text\n```json\n{}\n```';
      expect(
        () => ImportParser.parseAutoDetect(content),
        throwsA(isA<ImportParseException>()),
      );
    });
  });
}
