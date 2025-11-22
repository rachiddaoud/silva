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

  // Icons for each view mode
  IconData _getIcon(ViewMode mode) {
    switch (mode) {
      case ViewMode.today:
        return Icons.today_rounded;
      case ViewMode.history:
        return Icons.history_rounded;

    }
  }

  // Labels for each view mode
  String _getLabel(ViewMode mode) {
    switch (mode) {
      case ViewMode.today:
        return 'Aujourd\'hui';
      case ViewMode.history:
        return 'Historique';

    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const iconButtonWidth = 42.0; // Width for unselected icon-only buttons
    const selectedButtonWidth = 150.0; // Width for selected button with icon + text
    
    // Calculate positions for the animated background
    double leftPosition = 0.0;
    double backgroundWidth = selectedButtonWidth;
    
    if (selectedMode == ViewMode.today) {
      leftPosition = 0;
    } else if (selectedMode == ViewMode.history) {
      leftPosition = iconButtonWidth;
    }

    
    // Total width: 1 icon button + 1 selected button
    final totalWidth = iconButtonWidth + selectedButtonWidth;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      width: totalWidth,
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
          // Animated background indicator
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: leftPosition,
            top: 0,
            bottom: 0,
            width: backgroundWidth,
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
          // Buttons row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildToggleButton(
                context,
                ViewMode.today,
                theme,
                iconButtonWidth,
                selectedButtonWidth,
              ),
              _buildToggleButton(
                context,
                ViewMode.history,
                theme,
                iconButtonWidth,
                selectedButtonWidth,
              ),

            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    BuildContext context,
    ViewMode mode,
    ThemeData theme,
    double iconButtonWidth,
    double selectedButtonWidth,
  ) {
    final isSelected = selectedMode == mode;
    final buttonWidth = isSelected ? selectedButtonWidth : iconButtonWidth;
    final icon = _getIcon(mode);
    final label = _getLabel(mode);
    
    return GestureDetector(
      onTap: () => onModeChanged(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: buttonWidth,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12 : 0,
          vertical: 12,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: isSelected ? 22 : 20,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

