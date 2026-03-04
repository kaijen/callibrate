# Konzepte

## Kalibrierung

Kalibrierung beschreibt, wie gut subjektive Wahrscheinlichkeiten mit der Realität übereinstimmen. Eine Person ist gut kalibriert, wenn von allen Ereignissen, denen sie 70 % Wahrscheinlichkeit gegeben hat, tatsächlich ungefähr 70 % eingetreten sind – und von denen mit 30 % auch ungefähr 30 %.

Schlechte Kalibrierung äußert sich in zwei typischen Mustern:

- **Überschätzung** – man sagt öfter 90 %, als die Realität rechtfertigt. Ereignisse treten seltener ein als erwartet.
- **Unterschätzung** – man ist unnötig vorsichtig und sagt 60 %, wo 85 % angemessen wäre.

Kailibrate misst beides mit Brier Score, Log Loss und der Kalibrierungskurve. Die Kennzahlen allein verbessern nichts – aber sie machen Muster sichtbar, die sonst im Alltag unbemerkt bleiben.

---

## Zwei Kategorien

### Epistemisch (`epistemic`)

Unsicherheit durch Unkenntnis. Die richtige Antwort existiert bereits – man weiß sie nur (noch) nicht. Mehr Information oder Nachdenken würde helfen.

**Anwendungsfälle:** Trivia-Fragen, historische Fakten, geografische Daten, wissenschaftliche Messwerte.

Beispiele:
- „Liegt Santiago de Chile östlich von New York?"
- „Ist der Nil länger als der Amazonas?"
- „In welchem Jahr wurde das Brandenburger Tor gebaut?"

### Aleatorisch (`aleatory`)

Unsicherheit durch inhärente Zufälligkeit. Kein Zusatzwissen beseitigt die Ungewissheit vollständig – das Ergebnis hängt von Faktoren ab, die sich grundsätzlich nicht vollständig vorhersagen lassen.

**Anwendungsfälle:** Wettervorhersagen, Börsenkurse, Sportergebnisse, persönliche Leistungsvorhersagen.

Beispiele:
- „Wird es morgen regnen?"
- „Schließt der DAX am 31.12.2026 über 20 000 Punkten?"
- „Wie viele Kilometer laufe ich im März?"

### Warum die Unterscheidung wichtig ist

Epistemische und aleatorische Unsicherheiten lassen sich in den Statistiken getrennt auswerten. Das hilft zu erkennen, in welchem Bereich die eigene Kalibrierung besser oder schlechter ist – und ob man bei Faktfragen anders abschneidet als bei Prognosen.

---

## Drei Vorhersagetypen

Der Typ bestimmt, wie geschätzt und wie aufgelöst wird.

### Wahr/Falsch mit Konfidenz (`factual`)

Für epistemische Fragen mit bekannter Antwort. Zuerst Richtung wählen (Wahr oder Falsch), dann Konfidenz (50–99 %). Die Antwort existiert – der Nutzer kennt sie nur nicht.

Beispiel: „Liegt Santiago de Chile östlich von New York? → Wahr, 35 % sicher"

### Ja/Nein mit Konfidenz (`binary`)

Für aleatorische Prognosen. Zuerst Richtung wählen (Ja oder Nein), dann Konfidenz (50–99 %). 50 % steht für maximale Unsicherheit; wer unter 50 % liegt, sollte einfach die Richtung umkehren.

Beispiel: „Wird es morgen regnen? → Ja, 65 % sicher"

### Intervall (`interval`)

Für numerische Vorhersagen. Unter- und Obergrenze eines Bereichs eingeben, optional eine Einheit und eine Konfidenz. Das Ergebnis ist wahr, wenn der tatsächliche Wert im Intervall liegt.

Beispiel: „Wie viele Kilometer laufe ich im März? → 20–45 km, 80 % sicher"

Mehr Details zu Typen und Importfeldern: [Vorhersage-Typen](vorhersagen/typen.md)

---

## Drei Zustände einer Vorhersage

| Zustand | Bedeutung |
|---------|-----------|
| **Offen** | Vorhersage erfasst, aber noch keine Schätzung abgegeben |
| **Ausstehend** | Schätzung abgegeben, Ergebnis steht noch aus |
| **Aufgelöst** | Tatsächliches Ergebnis eingetragen, Beitrag zum Score berechnet |

Nur aufgelöste Vorhersagen fließen in Brier Score und Kalibrierungskurve ein.

---

## Tags

Tags sind frei wählbare Schlagworte, die einer Vorhersage zugeordnet werden. Sie dienen zur thematischen Gruppierung und können in der Vorhersagenliste und in den Statistiken als Filter verwendet werden. Mehrere Tags pro Vorhersage sind möglich; die Filterung ist OR-verknüpft (Vorhersagen mit mindestens einem der gewählten Tags werden angezeigt).

---

## Deadlines

Eine Deadline ist ein ISO-8601-Datum, bis wann eine Vorhersage spätestens aufgelöst werden kann. Überschrittene, noch nicht aufgelöste Vorhersagen werden in der Liste mit dem Badge **Überfällig** hervorgehoben. Deadlines können in der Detail-Ansicht gesetzt, geändert und entfernt werden.
