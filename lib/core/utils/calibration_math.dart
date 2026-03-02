import 'dart:math';

class ScorePoint {
  final int index;         // 1-basierte Schätzungsnummer (chronologisch)
  final double brierScore; // kumulativer Durchschnitt bis zu diesem Punkt
  final double logLoss;    // kumulativer Durchschnitt bis zu diesem Punkt

  const ScorePoint({
    required this.index,
    required this.brierScore,
    required this.logLoss,
  });
}

class CalibrationBin {
  final double binCenter; // e.g. 0.05 for the 0–10% bin
  final int count;
  final double hitRate; // actual fraction correct in this bin

  const CalibrationBin({
    required this.binCenter,
    required this.count,
    required this.hitRate,
  });
}

class CalibrationStats {
  final double brierScore;
  final double logLoss;
  final int totalCount;
  final List<CalibrationBin> bins;

  const CalibrationStats({
    required this.brierScore,
    required this.logLoss,
    required this.totalCount,
    required this.bins,
  });

  static CalibrationStats empty() => const CalibrationStats(
        brierScore: 0,
        logLoss: 0,
        totalCount: 0,
        bins: [],
      );

  static CalibrationStats compute(
      List<({double probability, double outcome})> pairs) {
    if (pairs.isEmpty) return empty();

    final n = pairs.length;

    // Brier Score
    final brier =
        pairs.map((p) => pow(p.probability - p.outcome, 2)).reduce((a, b) => a + b) /
            n;

    // Log Loss (clamp to avoid log(0))
    double ll = 0;
    for (final p in pairs) {
      final prob = p.probability.clamp(1e-7, 1 - 1e-7);
      ll += p.outcome * log(prob) + (1 - p.outcome) * log(1 - prob);
    }
    ll = -ll / n;

    // Calibration bins (10 bins: 0–10%, 10–20%, …, 90–100%)
    final binData = List.generate(10, (_) => <double>[]);
    for (final p in pairs) {
      final binIdx = (p.probability * 10).floor().clamp(0, 9);
      binData[binIdx].add(p.outcome);
    }

    final bins = <CalibrationBin>[];
    for (var i = 0; i < 10; i++) {
      if (binData[i].isEmpty) continue;
      final hitRate =
          binData[i].reduce((a, b) => a + b) / binData[i].length;
      bins.add(CalibrationBin(
        binCenter: (i * 0.1) + 0.05,
        count: binData[i].length,
        hitRate: hitRate,
      ));
    }

    return CalibrationStats(
      brierScore: brier.toDouble(),
      logLoss: ll,
      totalCount: n,
      bins: bins,
    );
  }

  /// Berechnet den kumulativen Brier Score und Log Loss nach jeder Schätzung.
  /// Die Reihenfolge der [pairs] bestimmt die X-Achse (Schätzung 1, 2, 3 …).
  static List<ScorePoint> computeHistory(
      List<({double probability, double outcome})> pairs) {
    if (pairs.isEmpty) return [];
    final result = <ScorePoint>[];
    double brierSum = 0;
    double llSum = 0;
    for (var i = 0; i < pairs.length; i++) {
      final p = pairs[i];
      brierSum += pow(p.probability - p.outcome, 2);
      final prob = p.probability.clamp(1e-7, 1 - 1e-7);
      llSum -= p.outcome * log(prob) + (1 - p.outcome) * log(1 - prob);
      result.add(ScorePoint(
        index: i + 1,
        brierScore: brierSum / (i + 1),
        logLoss: llSum / (i + 1),
      ));
    }
    return result;
  }
}
