import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Centralized analytics service wrapping Firebase Analytics
/// Provides type-safe event tracking and user identification
class AnalyticsService {
  static AnalyticsService? _instance;
  static AnalyticsService get instance {
    _instance ??= AnalyticsService._();
    return _instance!;
  }

  AnalyticsService._();

  FirebaseAnalytics? _analytics;
  bool _isInitialized = false;

  /// Initialize the analytics service
  /// Should be called after Firebase.initializeApp()
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _analytics = FirebaseAnalytics.instance;
      _isInitialized = true;
      debugPrint('✅ AnalyticsService initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize AnalyticsService: $e');
    }
  }

  /// Set the user ID for analytics
  /// Call this when a user signs in
  Future<void> setUserId(String? userId) async {
    if (!_isInitialized || _analytics == null) return;

    try {
      await _analytics!.setUserId(id: userId);
      debugPrint('📊 Analytics: User ID set to ${userId ?? "null"}');
    } catch (e) {
      debugPrint('❌ Failed to set user ID: $e');
    }
  }

  /// Set user properties (e.g., email, locale, onboarding cohort)
  Future<void> setUserProperties({
    String? email,
    String? locale,
    String? onboardingCohort,
  }) async {
    if (!_isInitialized || _analytics == null) return;

    try {
      if (email != null) {
        await _analytics!.setUserProperty(name: 'email', value: email);
      }
      if (locale != null) {
        await _analytics!.setUserProperty(name: 'locale', value: locale);
      }
      if (onboardingCohort != null) {
        await _analytics!.setUserProperty(
          name: 'onboarding_cohort',
          value: onboardingCohort,
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to set user properties: $e');
    }
  }

  /// Enable or disable analytics collection
  /// Use this to respect user privacy preferences
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    if (!_isInitialized || _analytics == null) return;

    try {
      await _analytics!.setAnalyticsCollectionEnabled(enabled);
      debugPrint('📊 Analytics collection ${enabled ? "enabled" : "disabled"}');
    } catch (e) {
      debugPrint('❌ Failed to set analytics collection: $e');
    }
  }

  /// Log a custom event
  /// Use the AnalyticsEvents constants for event names
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (!_isInitialized || _analytics == null) {
      debugPrint('⚠️ Analytics not initialized, skipping event: $name');
      return;
    }

    try {
      await _analytics!.logEvent(
        name: name,
        parameters: parameters,
      );
      if (kDebugMode) {
        debugPrint('📊 Analytics event: $name ${parameters != null ? "with params: $parameters" : ""}');
      }
    } catch (e) {
      debugPrint('❌ Failed to log event $name: $e');
    }
  }

  /// Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!_isInitialized || _analytics == null) return;

    try {
      await _analytics!.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    } catch (e) {
      debugPrint('❌ Failed to log screen view: $e');
    }
  }
}

/// Centralized event name constants
/// Follows Firebase naming conventions: snake_case, <=40 chars
class AnalyticsEvents {
  // Authentication events
  static const String loginAttempt = 'login_attempt';
  static const String loginSuccess = 'login_success';
  static const String loginFailure = 'login_failure';
  static const String signupStart = 'signup_start';
  static const String signupComplete = 'signup_complete';
  static const String logout = 'logout';

  // Profile events
  static const String profileViewed = 'profile_viewed';
  static const String profileUpdated = 'profile_updated';
  static const String consentUpdated = 'consent_updated';

  // App lifecycle
  static const String appOpen = 'app_open';

  // Mood & activity tracking
  static const String moodSelectorOpened = 'mood_selector_opened';
  static const String moodSelected = 'mood_selected';
  static const String activityCardViewed = 'activity_card_viewed';
  static const String activityStarted = 'activity_started';
  static const String activityCompleted = 'activity_completed';

  // Day completion
  static const String dailySummaryViewed = 'daily_summary_viewed';
  static const String dailyGoalCompleted = 'daily_goal_completed';
  static const String treeGrowthLevelUp = 'tree_growth_level_up';

  // Sharing & engagement
  static const String shareInitiated = 'share_initiated';
  static const String notificationReceived = 'notification_received';
  static const String notificationOpened = 'notification_opened';

  // Settings
  static const String settingsOpened = 'settings_opened';
  static const String languageChanged = 'language_changed';
  static const String reminderToggled = 'reminder_toggled';

  // Error tracking
  static const String unexpectedError = 'unexpected_error';
  static const String apiRetry = 'api_retry';
}

/// Event parameter name constants
class AnalyticsParams {
  // Common parameters
  static const String provider = 'provider';
  static const String errorCode = 'error_code';
  static const String screen = 'screen';
  static const String userId = 'user_id';

  // Mood parameters
  static const String mood = 'mood';
  static const String intensity = 'intensity';
  static const String timeBucket = 'time_bucket';

  // Activity parameters
  static const String activityType = 'activity_type';
  static const String durationSec = 'duration_sec';

  // Day completion parameters
  static const String streakLength = 'streak_length';
  static const String newLevel = 'new_level';
  static const String victoryCount = 'victory_count';

  // Sharing parameters
  static const String channel = 'channel';

  // Notification parameters
  static const String campaign = 'campaign';

  // Settings parameters
  static const String reminderType = 'reminder_type';
  static const String language = 'language';
  static const String theme = 'theme';
}



