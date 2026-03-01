# Erste Schritte

## APK installieren

Das aktuelle Release ist auf [GitHub Releases](https://github.com/kaijen/calibrate/releases) verfügbar. Die APK-Datei herunterladen und auf dem Android-Gerät öffnen. Bei der ersten Installation muss „Installation aus unbekannten Quellen" erlaubt sein.

## Erste Vorhersage erfassen

1. Dashboard öffnen – beim ersten Start ist die Datenbank leer.
2. Auf das **+**-Symbol tippen.
3. Frage eingeben, z.B. „Wird es morgen regnen?".
4. Kategorie wählen: `aleatory` für inhärente Zufälligkeit, `epistemic` für Faktfragen.
5. Optional: Typ wählen (Wahrscheinlichkeit, Ja/Nein, Intervall) und sofort schätzen.
6. Speichern.

## Schätzen und Auflösen

Vorhersagen durchlaufen drei Zustände:

| Zustand | Bedeutung |
|---------|-----------|
| Offen | Noch keine Schätzung |
| Ausstehend | Geschätzt, aber noch nicht aufgelöst |
| Aufgelöst | Ergebnis eingetragen |

Auf eine offene Vorhersage tippen → Schätzscreen. Auf eine ausstehende Vorhersage tippen → Auflösen. Auf eine aufgelöste Vorhersage tippen → Detail-Ansicht.

## Fragenkatalog importieren

Der schnellste Weg zum Ausprobieren: eine Beispieldatei importieren.

1. Im Menü **Import** wählen.
2. **Datei wählen** tippen oder Text aus der Zwischenablage einfügen.
3. Vorschau prüfen, dann **Importieren** bestätigen.

Die App erkennt JSON und YAML automatisch. Enthält die Datei bereits Schätzungen, werden sie direkt gespeichert. Enthält sie Auflösungen, werden die Fragen sofort als aufgelöst markiert.

Mehr zum Importformat unter [Import & Export](import-export/index.md).
