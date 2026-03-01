# Beispiele

## Epistemisches Quiz (JSON)

Trivia-Fragen mit bekannter Antwort und eingebetteter Schätzung:

```json
{
  "version": 1,
  "category": "epistemic",
  "source": "Geografie-Trivia",
  "questions": [
    {
      "text": "Liegt Santiago de Chile östlich von New York?",
      "tags": ["geography"],
      "answer": true,
      "probability": 0.35
    },
    {
      "text": "Hat Australien mehr Schafe als Einwohner?",
      "tags": ["geography", "animals"],
      "answer": true,
      "probability": 0.7
    },
    {
      "text": "Ist der Nil länger als der Amazonas?",
      "tags": ["geography"],
      "answer": false
    }
  ]
}
```

Die Felder `answer` und `probability` sind optional. Ohne `probability` wird die Frage als offen importiert und muss manuell geschätzt werden.

---

## Aleatorische Prognosen (YAML)

Alltags- und Sportprognosen mit verschiedenen Typen:

```yaml
version: 1
category: aleatory
source: Alltagsprognosen
questions:
  - text: Wird es morgen regnen?
    tags: [weather, daily]
    predictionType: binary
    binaryChoice: true
    confidenceLevel: 0.65

  - text: Wie viele Kilometer werde ich im März laufen?
    tags: [health, sport]
    predictionType: interval
    lowerBound: 20
    upperBound: 45
    confidenceLevel: 0.8
    unit: km

  - text: Schließt der DAX am 31.03.2026 über 21000 Punkten?
    tags: [finance, dax]
    deadline: "2026-03-31"
```

---

## Mit eingebetteter Auflösung

Fragen mit bekanntem Ergebnis werden beim Import sofort aufgelöst:

```json
{
  "version": 1,
  "category": "epistemic",
  "source": "Historische Fakten",
  "questions": [
    {
      "text": "War Neil Armstrong der erste Mensch auf dem Mond?",
      "tags": ["history", "space"],
      "probability": 0.95,
      "resolution": {
        "outcome": true,
        "notes": "Apollo 11, 20. Juli 1969"
      }
    }
  ]
}
```
