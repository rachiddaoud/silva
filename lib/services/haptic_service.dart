import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'preferences_service.dart';

/// Service for managing haptic feedback throughout the app
class HapticService {
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();

  /// Perform light haptic feedback (gentle nudge)
  /// Use for: minor UI interactions, button taps
  Future<void> light() async {
    if (!await _isEnabled()) return;
    
    try {
      await HapticFeedback.lightImpact();
      debugPrint('📳 Haptic: light');
    } catch (e) {
      debugPrint('⚠ Failed to perform light haptic: $e');
    }
  }

  /// Perform medium haptic feedback (moderate impact)
  /// Use for: significant actions, confirmations
  Future<void> medium() async {
    if (!await _isEnabled()) return;
    
    try {
      await HapticFeedback.mediumImpact();
      debugPrint('📳 Haptic: medium');
    } catch (e) {
      debugPrint('⚠ Failed to perform medium haptic: $e');
    }
  }

  /// Perform heavy haptic feedback (strong impact)
  /// Use for: important alerts, major completions
  Future<void> heavy() async {
    if (!await _isEnabled()) return;
    
    try {
      await HapticFeedback.heavyImpact();
      debugPrint('📳 Haptic: heavy');
    } catch (e) {
      debugPrint('⚠ Failed to perform heavy haptic: $e');
    }
  }

  /// Perform selection click haptic (soft pulse)
  /// Use for: scrolling through options, page changes
  Future<void> selection() async {
    if (!await _isEnabled()) return;
    
    try {
      await HapticFeedback.selectionClick();
      debugPrint('📳 Haptic: selection');
    } catch (e) {
      debugPrint('⚠ Failed to perform selection haptic: $e');
    }
  }

  /// Perform vibration for errors or important alerts
  Future<void> vibrate() async {
    if (!await _isEnabled()) return;
    
    try {
      await HapticFeedback.vibrate();
      debugPrint('📳 Haptic: vibrate');
    } catch (e) {
      debugPrint('⚠ Failed to vibrate: $e');
    }
  }

  /// Check if haptic feedback is enabled in user preferences
  Future<bool> _isEnabled() async {
    return await PreferencesService.getHapticEnabled();
  }
}
