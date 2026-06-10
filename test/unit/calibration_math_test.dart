import 'package:flutter_test/flutter_test.dart';
import 'package:kailibrate/core/utils/calibration_math.dart';

void main() {
  group('WinklerStats.compute()', () {
    test('returns null for empty input', () {
      expect(WinklerStats.compute([]), isNull);
    });

    test('hit scores only the interval width', () {
      final stats = WinklerStats.compute([
        (lower: 10.0, upper: 20.0, alpha: 0.1, actual: 15.0),
      ]);
      expect(stats!.score, closeTo(10.0, 1e-9));
      expect(stats.hitCount, 1);
      expect(stats.count, 1);
      expect(stats.hitRate, 1.0);
    });

    test('boundary values count as hits', () {
      final stats = WinklerStats.compute([
        (lower: 10.0, upper: 20.0, alpha: 0.1, actual: 10.0),
        (lower: 10.0, upper: 20.0, alpha: 0.1, actual: 20.0),
      ]);
      expect(stats!.hitCount, 2);
      expect(stats.score, closeTo(10.0, 1e-9));
    });

    test('miss below adds 2·distance/alpha penalty', () {
      // width 10, distance 5, alpha 0.1 → 10 + 2·5/0.1 = 110
      final stats = WinklerStats.compute([
        (lower: 10.0, upper: 20.0, alpha: 0.1, actual: 5.0),
      ]);
      expect(stats!.score, closeTo(110.0, 1e-9));
      expect(stats.hitCount, 0);
    });

    test('miss above adds 2·distance/alpha penalty', () {
      // width 10, distance 5, alpha 0.1 → 10 + 2·5/0.1 = 110
      final stats = WinklerStats.compute([
        (lower: 10.0, upper: 20.0, alpha: 0.1, actual: 25.0),
      ]);
      expect(stats!.score, closeTo(110.0, 1e-9));
    });

    test('higher confidence (smaller alpha) is penalized harder on a miss',
        () {
      // 95 % confidence → alpha 0.05; 55 % confidence → alpha 0.45
      final confident = WinklerStats.compute([
        (lower: 10.0, upper: 20.0, alpha: 0.05, actual: 30.0),
      ]);
      final cautious = WinklerStats.compute([
        (lower: 10.0, upper: 20.0, alpha: 0.45, actual: 30.0),
      ]);
      expect(confident!.score, greaterThan(cautious!.score));
    });

    test('averages over all intervals', () {
      final stats = WinklerStats.compute([
        (lower: 0.0, upper: 10.0, alpha: 0.1, actual: 5.0), // 10
        (lower: 0.0, upper: 10.0, alpha: 0.1, actual: 15.0), // 10+2·5/0.1=110
      ]);
      expect(stats!.score, closeTo(60.0, 1e-9));
      expect(stats.hitCount, 1);
      expect(stats.hitRate, 0.5);
    });
  });

  group('WinklerStats.computeHistory()', () {
    test('returns one point per interval with hit flag and question id', () {
      final history = WinklerStats.computeHistory([
        (lower: 0.0, upper: 10.0, alpha: 0.1, actual: 5.0, questionId: 7),
        (lower: 0.0, upper: 10.0, alpha: 0.1, actual: 20.0, questionId: 9),
      ]);
      expect(history.length, 2);
      expect(history[0].index, 1);
      expect(history[0].score, closeTo(10.0, 1e-9));
      expect(history[0].isHit, isTrue);
      expect(history[0].questionId, 7);
      expect(history[1].index, 2);
      expect(history[1].score, closeTo(10.0 + 2 * 10.0 / 0.1, 1e-9));
      expect(history[1].isHit, isFalse);
      expect(history[1].questionId, 9);
    });
  });

  group('CalibrationStats.computeHistory()', () {
    test('returns empty list for empty input', () {
      expect(CalibrationStats.computeHistory([]), isEmpty);
    });

    test('computes cumulative averages per estimate', () {
      final history = CalibrationStats.computeHistory([
        (probability: 0.5, outcome: 1.0), // brier 0.25
        (probability: 1.0, outcome: 1.0), // brier 0 → avg 0.125
      ]);
      expect(history.length, 2);
      expect(history[0].index, 1);
      expect(history[0].brierScore, closeTo(0.25, 1e-9));
      expect(history[1].index, 2);
      expect(history[1].brierScore, closeTo(0.125, 1e-9));
    });

    test('log loss history matches CalibrationStats.compute at each prefix',
        () {
      final pairs = [
        (probability: 0.7, outcome: 1.0),
        (probability: 0.6, outcome: 0.0),
        (probability: 0.9, outcome: 1.0),
      ];
      final history = CalibrationStats.computeHistory(pairs);
      for (var i = 0; i < pairs.length; i++) {
        final prefixStats = CalibrationStats.compute(pairs.sublist(0, i + 1));
        expect(history[i].brierScore, closeTo(prefixStats.brierScore, 1e-9));
        expect(history[i].logLoss, closeTo(prefixStats.logLoss, 1e-9));
      }
    });
  });

  group('CalibrationStats.empty()', () {
    test('returns zero values', () {
      final stats = CalibrationStats.empty();
      expect(stats.brierScore, 0);
      expect(stats.logLoss, 0);
      expect(stats.totalCount, 0);
      expect(stats.bins, isEmpty);
    });
  });

  group('CalibrationStats.compute()', () {
    test('returns empty stats for empty input', () {
      final stats = CalibrationStats.compute([]);
      expect(stats.totalCount, 0);
      expect(stats.bins, isEmpty);
    });

    test('perfect forecast (p=1 when outcome=1) gives brier=0', () {
      final pairs = [
        (probability: 0.99, outcome: 1.0),
        (probability: 0.99, outcome: 1.0),
        (probability: 0.01, outcome: 0.0),
      ];
      final stats = CalibrationStats.compute(pairs);
      // Brier score should be very small for near-perfect forecasts
      expect(stats.brierScore, lessThan(0.01));
      expect(stats.totalCount, 3);
    });

    test('worst forecast (p=1 when outcome=0) gives high brier', () {
      final pairs = [
        (probability: 0.99, outcome: 0.0),
      ];
      final stats = CalibrationStats.compute(pairs);
      // Brier score should be close to 1 (= 0.99^2 ≈ 0.98)
      expect(stats.brierScore, greaterThan(0.9));
    });

    test('random forecast at 50% gives brier ~0.25', () {
      // For p=0.5 always: brier = (0.5-1)^2 = 0.25 or (0.5-0)^2 = 0.25
      final pairs = [
        (probability: 0.5, outcome: 1.0),
        (probability: 0.5, outcome: 0.0),
        (probability: 0.5, outcome: 1.0),
        (probability: 0.5, outcome: 0.0),
      ];
      final stats = CalibrationStats.compute(pairs);
      expect(stats.brierScore, closeTo(0.25, 0.001));
    });

    test('brier score is between 0 and 1 for valid inputs', () {
      final pairs = [
        (probability: 0.3, outcome: 1.0),
        (probability: 0.7, outcome: 0.0),
        (probability: 0.6, outcome: 1.0),
        (probability: 0.4, outcome: 0.0),
        (probability: 0.8, outcome: 1.0),
      ];
      final stats = CalibrationStats.compute(pairs);
      expect(stats.brierScore, greaterThanOrEqualTo(0.0));
      expect(stats.brierScore, lessThanOrEqualTo(1.0));
    });

    test('log loss is non-negative', () {
      final pairs = [
        (probability: 0.7, outcome: 1.0),
        (probability: 0.3, outcome: 0.0),
      ];
      final stats = CalibrationStats.compute(pairs);
      expect(stats.logLoss, greaterThanOrEqualTo(0.0));
    });

    test('total count matches input length', () {
      final pairs = List.generate(
        10,
        (i) => (probability: 0.5, outcome: i % 2 == 0 ? 1.0 : 0.0),
      );
      final stats = CalibrationStats.compute(pairs);
      expect(stats.totalCount, 10);
    });

    test('bins snap to 5% points between 50% and 100%', () {
      final pairs = [
        (probability: 0.56, outcome: 1.0),
        (probability: 0.54, outcome: 0.0),
      ];
      final stats = CalibrationStats.compute(pairs);
      expect(stats.bins.length, 1);
      expect(stats.bins.first.binCenter, closeTo(0.55, 1e-9));
    });

    test('hit rate in bin is between 0 and 1', () {
      final pairs = [
        (probability: 0.55, outcome: 1.0),
        (probability: 0.56, outcome: 0.0),
        (probability: 0.57, outcome: 1.0),
        (probability: 0.58, outcome: 1.0),
        (probability: 0.59, outcome: 0.0),
      ];
      final stats = CalibrationStats.compute(pairs);
      for (final bin in stats.bins) {
        expect(bin.hitRate, greaterThanOrEqualTo(0.0));
        expect(bin.hitRate, lessThanOrEqualTo(1.0));
      }
    });

    test('bins only contain non-empty bins', () {
      // Only probability in range 50–60%
      final pairs = [
        (probability: 0.55, outcome: 1.0),
      ];
      final stats = CalibrationStats.compute(pairs);
      // Should only have one bin
      expect(stats.bins.length, 1);
      expect(stats.bins.first.count, 1);
      expect(stats.bins.first.hitRate, 1.0);
    });

    test('bin count accumulates correctly', () {
      final pairs = [
        (probability: 0.72, outcome: 1.0),
        (probability: 0.7, outcome: 0.0),
        (probability: 0.68, outcome: 1.0),
      ];
      final stats = CalibrationStats.compute(pairs);
      // All snap to the 70% point
      expect(stats.bins.length, 1);
      expect(stats.bins.first.binCenter, closeTo(0.7, 1e-9));
      expect(stats.bins.first.count, 3);
      expect(stats.bins.first.hitRate, closeTo(2 / 3, 0.001));
    });

    test('multiple bins are in ascending order of bin center', () {
      final pairs = [
        (probability: 0.55, outcome: 1.0),
        (probability: 0.75, outcome: 0.0),
        (probability: 0.95, outcome: 1.0),
      ];
      final stats = CalibrationStats.compute(pairs);
      expect(stats.bins.length, 3);
      for (var i = 1; i < stats.bins.length; i++) {
        expect(stats.bins[i].binCenter,
            greaterThan(stats.bins[i - 1].binCenter));
      }
    });

    test('legacy probabilities below 50% are mirrored into the upper half',
        () {
      // p=0.2 with outcome 0 is the same statement as p=0.8 with outcome 1.
      final pairs = [
        (probability: 0.2, outcome: 0.0),
      ];
      final stats = CalibrationStats.compute(pairs);
      expect(stats.bins.length, 1);
      expect(stats.bins.first.binCenter, closeTo(0.8, 1e-9));
      expect(stats.bins.first.hitRate, 1.0);
    });

    test('mirrored values share the bin with their upper-half counterpart',
        () {
      final pairs = [
        (probability: 0.25, outcome: 0.0), // ≙ 75% eingetreten
        (probability: 0.75, outcome: 1.0),
      ];
      final stats = CalibrationStats.compute(pairs);
      expect(stats.bins.length, 1);
      expect(stats.bins.first.binCenter, closeTo(0.75, 1e-9));
      expect(stats.bins.first.count, 2);
      expect(stats.bins.first.hitRate, 1.0);
    });
  });
}
