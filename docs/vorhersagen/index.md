# Vorhersagen

Eine Vorhersage besteht aus einer Frage und durchläuft drei Schritte: Erfassen, Schätzen, Auflösen.

## Ablauf

```
Erfassen → Schätzen → Auflösen
```

**Erfassen** – Frage formulieren, Kategorie und Typ festlegen. Optional direkt schätzen.

**Schätzen** – Wahrscheinlichkeit eingeben. Je nach Typ: Slider (0–100 %), Ja/Nein mit Konfidenz, oder Intervall mit Konfidenz.

**Auflösen** – Tatsächliches Ergebnis eintragen. Die App berechnet daraus Brier Score und Log Loss.

## Navigation

| Aktion | Geste |
|--------|-------|
| Neue Vorhersage | **+**-Symbol tippen |
| Schätzen | Offene Karte tippen |
| Auflösen | Ausstehende Karte tippen |
| Detail-Ansicht | Aufgelöste Karte tippen |

## Tags

Jede Vorhersage kann beliebig viele Tags tragen. In der Vorhersagenliste filtert ein horizontaler Chip-Streifen nach Tags.
