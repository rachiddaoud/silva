import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/day_entry.dart';
import '../services/database_service.dart';
import '../utils/chart_data_utils.dart';
import '../widgets/charts/victory_bar_chart.dart';
import '../widgets/charts/emotion_line_chart.dart';
import '../l10n/app_localizations.dart';

enum ChartPeriod { weekly, monthly }

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  ChartPeriod _selectedPeriod = ChartPeriod.weekly;
  List<DayEntry> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _history = [];
          _isLoading = false;
        });
      }
      return;
    }

    final history = await DatabaseService().getHistory(user.uid);
    history.sort((a, b) => b.date.compareTo(a.date));

    if (mounted) {
      setState(() {
        _history = history;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final days = _selectedPeriod == ChartPeriod.weekly ? 7 : 30;

    final victoryData = ChartDataUtils.getVictoryDataForPeriod(_history, days);
    final emotionData = ChartDataUtils.getEmotionDataForPeriod(_history, days);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.statistics,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.insert_chart_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noDataYet,
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.startAddingVictories,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Period toggle
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _PeriodButton(
                                label: l10n.weekly,
                                isSelected: _selectedPeriod == ChartPeriod.weekly,
                                onTap: () {
                                  setState(() {
                                    _selectedPeriod = ChartPeriod.weekly;
                                  });
                                },
                              ),
                              _PeriodButton(
                                label: l10n.monthly,
                                isSelected: _selectedPeriod == ChartPeriod.monthly,
                                onTap: () {
                                  setState(() {
                                    _selectedPeriod = ChartPeriod.monthly;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Victory chart section
                      _ChartSection(
                        title: l10n.victoriesChart,
                        icon: Icons.star_rounded,
                        iconColor: theme.colorScheme.secondary,
                        child: VictoryBarChart(
                          victoryData: victoryData,
                          isWeekly: _selectedPeriod == ChartPeriod.weekly,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Emotion chart section
                      _ChartSection(
                        title: l10n.moodTrend,
                        icon: Icons.favorite_rounded,
                        iconColor: theme.colorScheme.primary,
                        child: EmotionLineChart(
                          emotionData: emotionData,
                          isWeekly: _selectedPeriod == ChartPeriod.weekly,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

class _ChartSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _ChartSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: iconColor,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}
