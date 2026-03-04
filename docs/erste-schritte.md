# Erste Schritte

## App installieren

Das aktuelle Release ist auf [GitHub Releases](https://github.com/kaijen/kailibrate/releases) verfügbar. APK herunterladen und auf dem Android-Gerät öffnen. Bei der ersten Installation muss „Installation aus unbekannten Quellen" für den Browser oder Dateimanager erlaubt werden.

---

## Weg 1 – Fragenkatalog importieren (empfohlen zum Einstieg)

Der schnellste Einstieg: einen fertigen Fragenkatalog importieren und sofort mit dem Schätzen beginnen.

1. Im Menü **Import** wählen.
2. Eine JSON- oder YAML-Datei auswählen, oder Text direkt aus der Zwischenablage einfügen.
3. Die Vorschau zeigt Anzahl, Kategorie und ob Schätzungen enthalten sind – dann **Importieren** bestätigen.
4. Die importierten Fragen erscheinen in der Vorhersagenliste. Offene Fragen warten auf deine Schätzung.

Enthält ein Katalog bereits Auflösungen (versteckte Antworten), erscheint in der Liste „Lösung vorhanden". Du schätzt zuerst – erst danach zeigt die App, ob du recht hattest.

Mehr zum Format: [Import & Export](import-export/index.md)

---

## Weg 2 – Erste Vorhersage manuell erfassen

1. Auf das **+**-Symbol tippen.
2. Frage eingeben, z. B. „Wird Deutschland die Fußball-WM 2026 gewinnen?"
3. Kategorie wählen: **Aleatorisch** für Prognosen über zukünftige Ereignisse, **Epistemisch** für Faktfragen.
4. Vorhersagetyp wählen: Ja/Nein, Wahr/Falsch oder Intervall.
5. Optional sofort schätzen und Deadline setzen.
6. Speichern.

---

## Schätzen und Auflösen

Jede Vorhersage durchläuft drei Zustände:

| Zustand | Bedeutung | Nächste Aktion |
|---------|-----------|----------------|
| **Offen** | Noch keine Schätzung | Karte antippen → Schätzen |
| **Ausstehend** | Geschätzt, Ergebnis steht noch aus | Karte antippen → Detail-Ansicht, Auflösen per Button |
| **Aufgelöst** | Ergebnis eingetragen | Karte antippen → Detail-Ansicht mit Feedback |

Nach dem Auflösen zeigt die App ein Feedback-Sheet mit dem Brier-Beitrag dieser Schätzung und dem aktuellen Gesamtscore.

---

## KI-Generator nutzen

Der KI-Generator erzeugt automatisch Fragenkataloge zu einem beliebigen Thema.

Voraussetzung: ein OpenRouter-API-Key (kostenlos erhältlich unter [openrouter.ai](https://openrouter.ai)), der einmalig in **Einstellungen → API-Key** hinterlegt wird.

Dann: Tab **KI-Generator** öffnen, Thema eingeben, Vorlage und Modell wählen, generieren. Die erzeugten Fragen lassen sich direkt importieren.

Details: [KI-Generator](ki-generator.md)

---

## Statistiken lesen

Sobald mindestens eine Vorhersage aufgelöst ist, stehen Statistiken bereit. Den Tab **Statistiken** öffnen – dort stehen Brier Score, Log Loss und die Kalibrierungskurve.

Die Kurve zeigt auf einen Blick, ob du systematisch zu selbstsicher (Punkte unterhalb der Diagonale) oder zu vorsichtig bist (Punkte oberhalb).

Details: [Statistiken](statistiken.md)
