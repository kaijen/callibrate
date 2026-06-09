import 'dart:convert';

/// ROT13-dann-Base64-Kodierung für Auflösungen in geteilten Exporten
/// (v2-Format).
///
/// Das ist reiner **Spoiler-Schutz**, kein Sicherheitsfeature: Die Kodierung
/// ist trivial umkehrbar. Notizen können sensible Inhalte enthalten und
/// wandern bei Export/Teilen dekodierbar mit.
String obfuscateResolution(Map<String, dynamic> resolution) {
  final plain = jsonEncode(resolution);
  return base64Encode(utf8.encode(_rot13(plain)));
}

/// Kehrt [obfuscateResolution] um (Base64 dekodieren, dann ROT13).
Map<String, dynamic> deobfuscateResolution(String obfuscated) {
  final rot13encoded = utf8.decode(base64Decode(obfuscated));
  return jsonDecode(_rot13(rot13encoded)) as Map<String, dynamic>;
}

String _rot13(String input) {
  return String.fromCharCodes(input.codeUnits.map((c) {
    if (c >= 65 && c <= 90) return (c - 65 + 13) % 26 + 65;
    if (c >= 97 && c <= 122) return (c - 97 + 13) % 26 + 97;
    return c;
  }));
}
