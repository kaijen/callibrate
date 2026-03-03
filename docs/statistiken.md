# Statistiken

Calibrate berechnet drei Kennzahlen, um die Qualität von Schätzungen zu messen.

## Brier Score

Mittlerer quadratischer Fehler der Schätzungen:

```
BS = (1/N) × Σ (pᵢ - oᵢ)²
```

- `pᵢ` – geschätzte Wahrscheinlichkeit (0–1)
- `oᵢ` – tatsächliches Ergebnis (0 oder 1)
- Wertebereich: 0 (perfekt) bis 1 (maximal falsch)

Ein Brier Score von 0,25 entspricht dem Ergebnis, das man durch blindes Schätzen von 50 % erreicht. Je niedriger, desto besser.

---

## Log Loss

Empfindlicher gegenüber extremen Fehlschätzungen als der Brier Score:

```
LL = -(1/N) × Σ [oᵢ × log(pᵢ) + (1-oᵢ) × log(1-pᵢ)]
```

Wer ein eingetretenes Ereignis mit 1 % schätzt, wird stärker bestraft als beim Brier Score. Gut für Anwender, die Überkorrektur vermeiden wollen.

---

## Kalibrierungskurve

Schätzungen werden in 10-%-Bins gruppiert (0–10 %, 10–20 %, …). Pro Bin zeigt die Kurve:

- **X-Achse** – Mitte des Bins (erwartete Trefferquote)
- **Y-Achse** – tatsächliche Trefferquote in diesem Bin

Eine perfekt kalibrierte Person liegt auf der Diagonale: Wer 70 % sagt, hat in 70 % der Fälle recht.

Abweichungen nach oben bedeuten Unterschätzung (zu bescheiden), nach unten Überschätzung (zu selbstsicher).

---

## Diagramme in der App

| Diagramm | Inhalt |
|----------|--------|
| Kalibrierungskurve | Bin-Mitte vs. Trefferquote, Diagonale als Referenz |
| Brier-Score-Verlauf | Kumulativer Durchschnitt nach jeder Schätzung |
| Log-Loss-Verlauf | Kumulativer Durchschnitt nach jeder Schätzung |

Die Verlaufsdiagramme zeigen, wie sich Brier Score und Log Loss mit jeder weiteren aufgelösten Schätzung entwickeln. Die gestrichelte Linie markiert das Münzwurf-Niveau (0,25 bzw. ≈ 0,69). Mit dem Selektor oben rechts lässt sich der sichtbare Ausschnitt auf die letzten 25, 50 oder 100 Schätzungen einschränken.

Ein Tipp auf ein Diagramm öffnet es als Vollbild-Ansicht im Querformat.

Die Statistiken lassen sich mit drei kombinierbaren Filtern eingrenzen:

| Filter | Optionen |
|--------|----------|
| Kategorie | Alle · Epistemisch · Aleatorisch (Einfachauswahl) |
| Schätzungstyp | Wahrscheinlichkeit · Ja/Nein · Intervall (Mehrfachauswahl) |
| Tags | FilterChips aus vorhandenen Tags, OR-verknüpft |

Alle drei Filter wirken gleichzeitig: Nur Vorhersagen, die allen aktiven Kriterien entsprechen, fließen in die Berechnung ein.
