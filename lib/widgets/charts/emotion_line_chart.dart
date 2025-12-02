import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/chart_data_utils.dart';
import '../../models/emotion.dart';

class EmotionLineChart extends StatelessWidget {
  final Map<String, double?> emotionData;
  final bool isWeekly;

  const EmotionLineChart({
    super.key,
    required this.emotionData,
    required this.isWeekly,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dates = ChartDataUtils.getDatesForPeriod(isWeekly ? 7 : 30);

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          minY: -0.5,
          maxY: 5.5,
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => theme.colorScheme.surface.withValues(alpha: 0.95),
              tooltipRoundedRadius: 12,
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              tooltipBorder: BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                width: 1,
              ),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final emotion = ChartDataUtils.valueToEmotion(spot.y);
                  if (emotion == null) {
                    return null;
                  }
                  return LineTooltipItem(
                    emotion.description,
                    TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  );
                }).toList();
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
                  // Show doodle images on the left axis
                  final emotion = ChartDataUtils.valueToEmotion(value);
                  if (emotion != null && value == value.roundToDouble()) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Image.asset(
                        emotion.imagePath,
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                reservedSize: 32,
                interval: 1,
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
            horizontalInterval: 1,
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
          lineBarsData: [
            LineChartBarData(
              spots: _buildSpots(dates),
              isCurved: true,
              curveSmoothness: 0.35,
              color: theme.colorScheme.primary,
              barWidth: 3.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  final emotion = ChartDataUtils.valueToEmotion(spot.y);
                  final color = emotion?.moodColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.3);
                  return FlDotCirclePainter(
                    radius: 5,
                    color: color,
                    strokeWidth: 3,
                    strokeColor: theme.colorScheme.surface,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.25),
                    theme.colorScheme.primary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              shadow: Shadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _buildSpots(List<DateTime> dates) {
    final spots = <FlSpot>[];
    
    for (int i = 0; i < dates.length; i++) {
      final date = dates[i];
      final dateKey = ChartDataUtils.formatDateKey(date);
      final value = emotionData[dateKey];
      
      if (value != null) {
        spots.add(FlSpot(i.toDouble(), value));
      }
    }
    
    // If no data points, don't show the line
    if (spots.isEmpty) {
      return [];
    }
    
    return spots;
  }
}

