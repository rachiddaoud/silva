import '../models/day_entry.dart';
import '../models/emotion.dart';

/// Utility class for processing history data into chart-friendly formats
class ChartDataUtils {
  /// Get victory count data for the specified number of days
  /// Returns a map of date (as string YYYY-MM-DD) to victory count
  static Map<String, int> getVictoryDataForPeriod(
    List<DayEntry> history,
    int days,
  ) {
    final now = DateTime.now();
    final data = <String, int>{};

    // Initialize all days with 0 victories
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: days - 1 - i));
      final dateKey = formatDateKey(date);
      data[dateKey] = 0;
    }

    // Fill in actual data from history
    for (final entry in history) {
      final dateKey = formatDateKey(entry.date);
      if (data.containsKey(dateKey)) {
        data[dateKey] = entry.victoryCards.length;
      }
    }

    return data;
  }

  /// Get emotion data for the specified number of days
  /// Returns a map of date (as string YYYY-MM-DD) to emotion value (0-4 scale)
  /// Missing days will have null values
  static Map<String, double?> getEmotionDataForPeriod(
    List<DayEntry> history,
    int days,
  ) {
    final now = DateTime.now();
    final data = <String, double?>{};

    // Initialize all days with null
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: days - 1 - i));
      final dateKey = formatDateKey(date);
      data[dateKey] = null;
    }

    // Fill in actual data from history
    for (final entry in history) {
      final dateKey = formatDateKey(entry.date);
      if (data.containsKey(dateKey)) {
        data[dateKey] = emotionToValue(entry.emotion);
      }
    }

    return data;
  }

  /// Convert an emotion to a numeric value (0-4 scale)
  /// Null emotion returns null
  static double? emotionToValue(Emotion? emotion) {
    if (emotion == null) return null;
    
    // Find the index of this emotion in the emotions list
    final index = Emotion.emotions.indexOf(emotion);
    if (index < 0) return null;
    
    // Map to 0-4 scale (higher is better mood)
    // Assuming emotions are ordered from worst to best
    return index.toDouble();
  }

  /// Convert a numeric value back to the closest emotion
  static Emotion? valueToEmotion(double? value) {
    if (value == null) return null;
    
    final index = value.round();
    if (index < 0 || index >= Emotion.emotions.length) return null;
    
    return Emotion.emotions[index];
  }

  /// Format a DateTime as YYYY-MM-DD for consistent key usage
  static String formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get a short label for a date relative to today
  /// Returns abbreviated day name (M, T, W, etc.) for weekly view
  /// Returns day number for monthly view
  static String getDateLabel(DateTime date, bool isWeekly) {
    if (isWeekly) {
      // Return first letter of weekday
      const weekdays = ['L', 'M', 'M', 'J', 'V', 'S', 'D']; // French abbreviations
      return weekdays[date.weekday - 1];
    } else {
      // Return day number
      return date.day.toString();
    }
  }

  /// Get the maximum victory count from the data for chart scaling
  static int getMaxVictoryCount(Map<String, int> data) {
    if (data.isEmpty) return 9; // Default max for empty data
    final max = data.values.reduce((a, b) => a > b ? a : b);
    return max > 0 ? max : 9; // At least 9 to show full scale
  }

  /// Get a list of dates for the period
  static List<DateTime> getDatesForPeriod(int days) {
    final now = DateTime.now();
    final dates = <DateTime>[];
    
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: days - 1 - i));
      dates.add(date);
    }
    
    return dates;
  }
}
