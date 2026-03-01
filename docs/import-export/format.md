# Format-Referenz

## Datei-Header

Jede Import-Datei beginnt mit einem Header:

| Feld | Pflicht | Beschreibung |
|------|---------|--------------|
| `version` | ja | Schema-Version. Aktuell: `1` (manuell) oder `2` (App-Export) |
| `category` | ja | `epistemic` oder `aleatory` |
| `source` | nein | Bezeichnung der Fragensammlung, z.B. „Geografie-Trivia" |
| `questions` | ja | Liste der Fragen (s.u.) |

## Felder pro Frage

| Feld | Pflicht | Beschreibung |
|------|---------|--------------|
| `text` | ja | Fragentext |
| `tags` | nein | Liste von Schlagworten |
| `answer` | nein | Bekannte Antwort `true`/`false` (für Trivia/Historisches) |
| `deadline` | nein | ISO-8601-Datum, wann die Frage aufgelöst wird |
| `predictionType` | nein | `probability` (Standard), `binary` oder `interval` |
| `probability` | nein | Schätzwert 0–1 (für `probability`-Typ) |
| `binaryChoice` | nein | `true` = Ja, `false` = Nein (für `binary`-Typ) |
| `confidenceLevel` | nein | Konfidenz 0–1 (für `binary` und `interval`, Standard: 0,9) |
| `lowerBound` | nein | Untergrenze (für `interval`-Typ) |
| `upperBound` | nein | Obergrenze (für `interval`-Typ) |
| `unit` | nein | Einheit des Intervalls, z.B. `km`, `°C` |
| `resolution.outcome` | nein | Bekanntes Ergebnis `true`/`false` – löst die Vorhersage sofort auf |
| `resolution.notes` | nein | Freitext zur Auflösung |
| `resolution.numericOutcome` | nein | Tatsächlicher Messwert (für `interval`-Typ) |

## Format-Versionen

**Version 1** – Manuell erstellte Fragenkataloge. Kategorie gilt für alle Fragen der Datei.

**Version 2** – App-eigenes Export-Format. Kategorie und weitere Metadaten können pro Frage abweichen. Auflösungen sind mit ROT13 + Base64 obfuskiert. Wird beim Import automatisch dekodiert.
