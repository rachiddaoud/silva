import 'package:flutter/material.dart';

enum ViewMode { today, history }

class TodayHistoryToggle extends StatelessWidget {
  final ViewMode selectedMode;
  final ValueChanged<ViewMode> onModeChanged;

  const TodayHistoryToggle({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const buttonWidth = 120.0;
    final isHistory = selectedMode == ViewMode.history;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      width: buttonWidth * 2,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Pastille animée
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: isHistory ? buttonWidth : 0.0,
            top: 0,
            bottom: 0,
            width: buttonWidth,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          // Boutons avec texte
          Row(
            children: [
              _buildToggleButton(
                context,
                'Aujourd\'hui',
                ViewMode.today,
                theme,
                buttonWidth,
              ),
              _buildToggleButton(
                context,
                'Historique',
                ViewMode.history,
                theme,
                buttonWidth,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    BuildContext context,
    String label,
    ViewMode mode,
    ThemeData theme,
    double width,
  ) {
    final isSelected = selectedMode == mode;
    
    return GestureDetector(
      onTap: () => onModeChanged(mode),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 15,
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

