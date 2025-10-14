import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/constants.dart';

class WeeklySpendingChart extends StatelessWidget {
  final Map<DateTime, double> data;
  const WeeklySpendingChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = data.keys.toList()..sort();
    final maxY = ((data.values.fold<double>(0, (p, c) => c > p ? c : p) * 1.3)).clamp(10.0, double.infinity);

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: Radii.md),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Last 7 days', style: theme.textTheme.titleMedium?.copyWith(color: AppColors.darkText)),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= days.length) return const SizedBox.shrink();
                        final d = days[idx];
                        const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
                        return Text(labels[d.weekday % 7], style: const TextStyle(color: AppColors.subtleText));
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (int i = 0; i < days.length; i++)
                    BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: data[days[i]] ?? 0,
                        color: AppColors.primaryBlue,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        width: 16,
                      )
                    ])
                ],
                maxY: maxY,
              ),
              swapAnimationDuration: AppDurations.slow,
              swapAnimationCurve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppDurations.normal).slideY(begin: 0.1, end: 0);
  }
}


