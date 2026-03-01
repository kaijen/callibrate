# Import & Export

## Import

Fragenkataloge lassen sich als JSON oder YAML importieren – per Dateiauswahl oder direkt aus der Zwischenablage. Die App erkennt das Format automatisch.

**Ablauf:**

1. Im Menü **Import** wählen.
2. Datei auswählen oder Text aus Zwischenablage einfügen.
3. Vorschau prüfen: Anzahl der Fragen, Kategorie, enthaltene Schätzungen.
4. **Importieren** bestätigen.

Enthält eine Frage bereits Schätzfelder, speichert die App sie sofort. Enthält sie eine Auflösung, wird die Vorhersage direkt als aufgelöst markiert.

Bei Duplikaten (identischer Fragentext) kann konfiguriert werden, ob vorhandene Fragen übersprungen oder ersetzt werden.

Fehler bei ungültigem Schema führen zu einem Fehlerdialog mit Zeilennummer. Es wird kein partieller Import durchgeführt.

---

## Export

Der App-eigene Export erzeugt ein vollständiges JSON-Backup aller Vorhersagen, Schätzungen und Auflösungen. Das Backup wird per Android-Share-Sheet geteilt.

Auflösungen sind im Export mit ROT13 + Base64 obfuskiert. Damit enthält eine geteilte Datei keine Spoiler, wenn man einen Fragenkatalog weitergibt.

Das Export-Format (Version 2) ist importkompatibel – ein Backup lässt sich auf einem anderen Gerät vollständig wiederherstellen.

Mehr zum Format unter [Format-Referenz](format.md).
