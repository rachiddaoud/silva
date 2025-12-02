import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/chart_data_utils.dart';

class VictoryBarChart extends StatelessWidget {
  final Map<String, int> victoryData;
  final bool isWeekly;

  const VictoryBarChart({
    super.key,
    required this.victoryData,
    required this.isWeekly,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dates = ChartDataUtils.getDatesForPeriod(isWeekly ? 7 : 30);
    final maxCount = ChartDataUtils.getMaxVictoryCount(victoryData);

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxCount.toDouble() + 1,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => theme.colorScheme.surface.withValues(alpha: 0.95),
              tooltipRoundedRadius: 12,
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              tooltipBorder: BorderSide(
                color: theme.colorScheme.secondary.withValues(alpha: 0.2),
                width: 1,
              ),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final date = dates[group.x.toInt()];
                final count = rod.toY.toInt();
                return BarTooltipItem(
                  '⭐ $count victoire${count > 1 ? 's' : ''}',
                  TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < dates.length) {
                    // For monthly view, only show every 5th label to reduce crowding
                    if (!isWeekly && value.toInt() % 5 != 0) {
                      return const SizedBox.shrink();
                    }
                    
                    final date = dates[value.toInt()];
                    final label = ChartDataUtils.getDateLabel(date, isWeekly);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value == meta.max || value == meta.min) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
                reservedSize: 28,
                interval: 2,
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 2,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            },
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                width: 1,
              ),
              left: BorderSide(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          barGroups: _buildBarGroups(dates, theme),
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(List<DateTime> dates, ThemeData theme) {
    return dates.asMap().entries.map((entry) {
      final index = entry.key;
      final date = entry.value;
      final dateKey = ChartDataUtils.formatDateKey(date);
      final count = victoryData[dateKey] ?? 0;

      // Color intensity based on count
      final intensity = count > 0 ? (count / 9).clamp(0.4, 1.0) : 0.15;
      final barColor = count > 0
          ? theme.colorScheme.secondary.withValues(alpha: intensity)
          : theme.colorScheme.onSurface.withValues(alpha: 0.08);

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            color: barColor,
            width: isWeekly ? 24 : 12,
            borderRadius: BorderRadius.circular(6),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: (victoryData.values.reduce((a, b) => a > b ? a : b)).toDouble() + 1,
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            gradient: count > 0
                ? LinearGradient(
                    colors: [
                      theme.colorScheme.secondary.withValues(alpha: intensity),
                      theme.colorScheme.secondary.withValues(alpha: intensity * 0.7),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  )
                : null,
          ),
        ],
      );
    }).toList();
  }
}

