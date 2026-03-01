# Format-Referenz

## Datei-Header

Jede Import-Datei beginnt mit einem Header:

| Feld | Pflicht | Beschreibung |
|------|---------|--------------|
| `version` | ja | Schema-Version. Aktuell: `1` (manuell) oder `2` (App-Export) |
| `category` | ja | `epistemic` oder `aleatory` – gilt für alle Fragen der Datei |
| `source` | nein | Bezeichnung der Fragensammlung, z.B. „Geografie-Trivia" |
| `questions` | ja | Liste der Fragen (s.u.) |

---

## Felder pro Frage

### Pflichtfeld

| Feld | Beschreibung |
|------|--------------|
| `text` | Fragentext als Zeichenkette |

### Metadaten (optional)

| Feld | Beschreibung |
|------|--------------|
| `tags` | Liste von Schlagworten, z.B. `["geography", "europe"]` |
| `deadline` | ISO-8601-Datum, bis wann die Frage aufgelöst werden soll, z.B. `"2026-12-31"` |
| `answer` | Bekannte Antwort `true`/`false` für Trivia-Fragen. Dient nur als Referenz – löst die Vorhersage **nicht** automatisch auf. |

### Schätzfelder (optional)

Schätzfelder enthalten eine vorausgefüllte Schätzung. Fehlen sie, muss der Nutzer selbst schätzen.

| Feld | Werte | Beschreibung |
|------|-------|--------------|
| `predictionType` | `probability` (Standard), `binary`, `interval` | Bestimmt, welche weiteren Schätzfelder gelesen werden |
| `probability` | 0–1 | Schätzwert für Typ `probability`, z.B. `0.7` für 70 % |
| `binaryChoice` | `true` / `false` | Richtungswahl für Typ `binary` (Ja / Nein) |
| `confidenceLevel` | 0–1, Standard: `0.9` | Konfidenz für Typen `binary` und `interval` |
| `lowerBound` | Zahl | Untergrenze für Typ `interval` |
| `upperBound` | Zahl | Obergrenze für Typ `interval` |
| `unit` | Zeichenkette | Einheit für `interval`, z.B. `"km"`, `"°C"`, `"Mio. €"` |

### Auflösungsfelder (optional)

Auflösungsfelder enthalten das bekannte Ergebnis. Die App verhält sich je nach Kombination mit Schätzfeldern unterschiedlich – siehe [Importverhalten](#importverhalten).

| Feld | Werte | Beschreibung |
|------|-------|--------------|
| `resolution.outcome` | `true` / `false` | Ob das Ereignis eingetreten ist |
| `resolution.notes` | Zeichenkette | Freitext zur Auflösung, z.B. Quelle oder Erklärung |
| `resolution.numericOutcome` | Zahl | Tatsächlicher Messwert für Typ `interval` |

---

## Importverhalten

Die Kombination aus Schätz- und Auflösungsfeldern bestimmt den Zustand nach dem Import:

| Schätzung | Auflösung | Zustand nach Import |
|-----------|-----------|---------------------|
| fehlt | fehlt | **Offen** – Nutzer schätzt und löst manuell auf |
| vorhanden | fehlt | **Ausstehend** – Schätzung gespeichert, Nutzer löst manuell auf |
| vorhanden | vorhanden | **Sofort aufgelöst** – Schätzung und Ergebnis direkt gespeichert |
| fehlt | vorhanden | **„Lösung vorhanden"** – Auflösung wartet; nach Schätzung des Nutzers wird sie automatisch angewendet |

Der letzte Fall ist der Schlüssel für **Kalibrierungsübungen mit versteckten Antworten**: Das LLM oder ein Fragenkatalog liefert die Auflösung mit, aber der Nutzer schätzt zuerst – ohne die Antwort zu sehen.

---

## Format-Versionen

**Version 1** – Manuell erstellte Fragenkataloge. `category` gilt für alle Fragen der Datei.

**Version 2** – App-eigenes Export-Format. Kategorie und Metadaten können pro Frage abweichen. `resolution`-Felder sind mit ROT13 + Base64 obfuskiert, damit geteilte Kataloge keine Spoiler enthalten. Beim Import dekodiert die App automatisch.
