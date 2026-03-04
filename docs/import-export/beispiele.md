# Beispiele

## Epistemisches Quiz (JSON)

Trivia-Fragen mit versteckten Antworten. `resolution` enthält die Antwort – der Nutzer schätzt zuerst, dann zeigt die App das Ergebnis.

```json
{
  "version": 1,
  "category": "epistemic",
  "source": "Geografie-Trivia",
  "questions": [
    {
      "text": "Liegt Santiago de Chile östlich von New York?",
      "tags": ["geography"],
      "predictionType": "factual",
      "resolution": {
        "outcome": true,
        "notes": "Santiago liegt auf ca. 70° W, New York auf ca. 74° W – Santiago ist östlicher."
      }
    },
    {
      "text": "Hat Australien mehr Schafe als Einwohner?",
      "tags": ["geography", "animals"],
      "predictionType": "factual",
      "resolution": {
        "outcome": true,
        "notes": "Ca. 70 Mio. Schafe bei 26 Mio. Einwohnern (Stand 2024)."
      }
    },
    {
      "text": "Ist der Nil länger als der Amazonas?",
      "tags": ["geography"],
      "predictionType": "factual",
      "resolution": {
        "outcome": false,
        "notes": "Der Amazonas ist mit ca. 6992 km länger als der Nil (ca. 6650 km)."
      }
    }
  ]
}
```

---

## Aleatorische Prognosen (YAML)

Zukunftsbezogene Ereignisse – keine Auflösungen, weil das Ergebnis noch nicht feststeht.

```yaml
version: 1
category: aleatory
source: Alltagsprognosen
questions:
  - text: Wird es morgen regnen?
    tags: [weather, daily]
    predictionType: binary
    deadline: "2026-03-05"

  - text: Wie viele Kilometer werde ich im März laufen?
    tags: [health, sport]
    predictionType: interval
    unit: km
    deadline: "2026-04-01"

  - text: Schließt der DAX am 31.12.2026 über 21000 Punkten?
    tags: [finance, dax]
    predictionType: binary
    deadline: "2026-12-31"
```

---

## Epistemische Intervall-Fragen (JSON)

Numerische Schätzfragen mit bekanntem Ergebnis:

```json
{
  "version": 1,
  "category": "epistemic",
  "source": "Historische Zahlen",
  "questions": [
    {
      "text": "Wie viele Kilometer ist die Chinesische Mauer lang?",
      "tags": ["history", "china"],
      "predictionType": "interval",
      "unit": "km",
      "resolution": {
        "outcome": true,
        "numericOutcome": 21196,
        "notes": "Gesamtlänge aller Abschnitte laut chinesischer Archäologiebehörde 2012."
      }
    },
    {
      "text": "In welchem Jahr wurde das Brandenburger Tor fertiggestellt?",
      "tags": ["history", "germany"],
      "predictionType": "interval",
      "unit": "Jahr",
      "resolution": {
        "outcome": true,
        "numericOutcome": 1791,
        "notes": "Fertiggestellt 1791, eingeweiht am 6. August 1791."
      }
    }
  ]
}
```

---

## Mit vorausgefüllter Schätzung

Enthält der Import Schätzfelder, werden sie direkt gespeichert und die Vorhersage ist sofort **Ausstehend**:

```json
{
  "version": 1,
  "category": "aleatory",
  "source": "Sportprognosen",
  "questions": [
    {
      "text": "Gewinnt Deutschland die Fußball-WM 2026?",
      "tags": ["football", "germany"],
      "predictionType": "binary",
      "binaryChoice": true,
      "confidenceLevel": 0.30,
      "deadline": "2026-07-20"
    }
  ]
}
```

Schätzung und Auflösung kombiniert – Vorhersage wird beim Import sofort als aufgelöst gespeichert:

```json
{
  "version": 1,
  "category": "epistemic",
  "source": "Klassische Trivia",
  "questions": [
    {
      "text": "War Neil Armstrong der erste Mensch auf dem Mond?",
      "tags": ["history", "space"],
      "predictionType": "factual",
      "binaryChoice": true,
      "confidenceLevel": 0.95,
      "resolution": {
        "outcome": true,
        "notes": "Apollo 11, 20. Juli 1969."
      }
    }
  ]
}
```
