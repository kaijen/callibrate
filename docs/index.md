# Calibrate

Android-App zum Kalibrieren persönlicher Wahrscheinlichkeitsschätzungen.

Wer sagt „70 % Wahrscheinlichkeit", sollte damit in 70 % der Fälle recht behalten. Calibrate misst, ob das stimmt – und zeigt, wo Schätzungen systematisch zu hoch oder zu niedrig ausfallen.

---

## Was die App kann

- **Vorhersagen erfassen** – manuell oder per JSON/YAML-Import (Datei oder Zwischenablage)
- **Wahrscheinlichkeit schätzen** – direkt beim Erfassen oder nachträglich; drei Eingabeformen: Slider, Ja/Nein mit Konfidenz, Intervall
- **Ergebnis auflösen** – nach Eintreten oder Nicht-Eintreten des Ereignisses
- **Detail-Ansicht** – Tippen auf eine aufgelöste Vorhersage zeigt Schätzung, Ergebnis und Notizen
- **Statistiken auswerten** – Brier Score, Log Loss, Kalibrierungskurve
- **Nach Tags filtern** – horizontaler FilterChip-Streifen in der Vorhersagenliste
- **Daten exportieren** – vollständiges JSON-Backup per Android-Share-Sheet; Auflösungen werden obfuskiert, damit geteilte Dateien keine Spoiler enthalten
- **Import mit Auflösungen** – Fragenkataloge können Schätzungen und Auflösungen enthalten; bereits aufgelöste Fragen werden sofort korrekt markiert

---

## Zwei Kategorien

| Kategorie | Bedeutung | Beispiele |
|-----------|-----------|-----------|
| `epistemic` | Unkenntnis reduzierbar durch Information | Trivia, Historisches, Faktfragen |
| `aleatory` | Inhärente Zufälligkeit | Wetter, Börsenkurse, Sportergebnisse |

Die Kategorie beeinflusst die Darstellung und kann in den Statistiken separat ausgewertet werden. Mehr dazu unter [Kategorien](kategorien.md).
