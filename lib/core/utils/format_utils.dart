/// Formatiert einen Double-Wert für die Anzeige.
/// Ganze Zahlen erscheinen ohne Nachkommastellen (45 statt 45.0).
/// Dezimalzahlen werden auf maximal zwei Stellen gerundet, Nullen am Ende entfernt.
String formatNum(double? value) {
  if (value == null) return '?';
  if (value == value.truncateToDouble()) {
    return value.toInt().toString();
  }
  return value
      .toStringAsFixed(2)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '');
}
