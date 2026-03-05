import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/utils/calibration_math.dart';

class CalibrationChart extends StatelessWidget {
  final List<CalibrationBin> bins;
  final bool expand;

  const CalibrationChart({super.key, required this.bins, this.expand = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Perfect calibration line spots
    final diagonalSpots = [
      const FlSpot(0, 0),
      const FlSpot(1, 1),
    ];

    // Actual data spots
    final dataSpots = bins.map((b) => FlSpot(b.binCenter, b.hitRate)).toList();
    final maxCount = bins.fold(0, (m, b) => b.count > m ? b.count : m);

    final chart = Padding(
      padding: const EdgeInsets.all(16),
      child: LineChart(
          LineChartData(
            minX: 0,
            maxX: 1,
            minY: 0,
            maxY: 1,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              getDrawingHorizontalLine: (_) => FlLine(
                color: cs.outline.withOpacity(0.2),
                strokeWidth: 1,
              ),
              getDrawingVerticalLine: (_) => FlLine(
                color: cs.outline.withOpacity(0.2),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: cs.outline.withOpacity(0.4)),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                axisNameWidget: const Text('Trefferquote'),
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (v, _) => Text(
                    '${(v * 100).toInt()}%',
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                axisNameWidget: const Text('Geschätzte Wahrscheinlichkeit'),
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  getTitlesWidget: (v, _) => Text(
                    '${(v * 100).toInt()}%',
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            lineBarsData: [
              // Perfect calibration (diagonal)
              LineChartBarData(
                spots: diagonalSpots,
                isCurved: false,
                color: cs.outline.withOpacity(0.5),
                barWidth: 1,
                dashArray: [6, 4],
                dotData: const FlDotData(show: false),
              ),
              // Actual calibration
              if (dataSpots.isNotEmpty)
                LineChartBarData(
                  spots: dataSpots,
                  isCurved: false,
                  color: cs.primary,
                  barWidth: 2,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, __, ___) {
                      final bin = bins.firstWhere(
                          (b) => (b.binCenter - spot.x).abs() < 0.01);
                      final t = maxCount > 0 ? bin.count / maxCount : 0.0;
                      final radius = 3.0 + t * 5.0;
                      return FlDotCirclePainter(
                        radius: radius,
                        color: cs.primary,
                        strokeColor: cs.onPrimary,
                        strokeWidth: 1.5,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
    );
    return expand ? chart : AspectRatio(aspectRatio: 1, child: chart);
  }
}
