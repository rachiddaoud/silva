

/// Manages tree resources and cooldown timers
class TreeResources {
  final int leafCount;           // From victories
  final int flowerCount;         // From streaks
  final int streak;              // Current daily streak
  final DateTime? lastWatered;    // Track last water time
  final DateTime? lastFlowerUsed; // Track last flower use
  final DateTime? lastLeafUsed;   // Track last leaf use
  final DateTime lastDailyReset;  // Track daily reset
  final DateTime? lastStreakUpdate; // Track last streak increment
  final int lastClaimed7DayMilestone; // Last 7-day milestone where flower was claimed (0, 7, 14, 21...)
  final int lastClaimed30DayMilestone; // Last 30-day milestone where flower was claimed (0, 30, 60...)

  const TreeResources({
    this.leafCount = 0,
    this.flowerCount = 0,
    this.streak = 0,
    this.lastWatered,
    this.lastFlowerUsed,
    this.lastLeafUsed,
    required this.lastDailyReset,
    this.lastStreakUpdate,
    this.lastClaimed7DayMilestone = 0,
    this.lastClaimed30DayMilestone = 0,
  });

  /// Check if 7-day special flower is available to claim
  bool get hasSpecial7DayFlower {
    if (streak < 7) return false;
    final currentMilestone = (streak ~/ 7) * 7;
    return currentMilestone > lastClaimed7DayMilestone;
  }

  /// Check if 30-day special flower is available to claim
  bool get hasSpecial30DayFlower {
    if (streak < 30) return false;
    final currentMilestone = (streak ~/ 30) * 30;
    return currentMilestone > lastClaimed30DayMilestone;
  }

  /// Get current 7-day milestone
  int get current7DayMilestone => (streak ~/ 7) * 7;
  
  /// Get current 30-day milestone
  int get current30DayMilestone => (streak ~/ 30) * 30;

  // Backwards compatibility properties
  bool get hasClaimed7DayFlower => !hasSpecial7DayFlower;
  bool get hasClaimed30DayFlower => !hasSpecial30DayFlower;

  TreeResources copyWith({
    int? leafCount,
    int? flowerCount,
    int? streak,
    DateTime? lastWatered,
    DateTime? lastFlowerUsed,
    DateTime? lastLeafUsed,
    DateTime? lastDailyReset,
    DateTime? lastStreakUpdate,
    int? lastClaimed7DayMilestone,
    int? lastClaimed30DayMilestone,
    // Backwards compatibility - convert bool to milestone if passed
    bool? hasClaimed7DayFlower,
    bool? hasClaimed30DayFlower,
  }) {
    int new7DayMilestone = lastClaimed7DayMilestone ?? this.lastClaimed7DayMilestone;
    int new30DayMilestone = lastClaimed30DayMilestone ?? this.lastClaimed30DayMilestone;
    
    // Handle backwards compatibility with boolean flags
    final effectiveStreak = streak ?? this.streak;
    if (hasClaimed7DayFlower == true) {
      new7DayMilestone = (effectiveStreak ~/ 7) * 7;
    } else if (hasClaimed7DayFlower == false) {
      // Only reset if explicitly set to false (streak lost)
      new7DayMilestone = 0;
    }
    if (hasClaimed30DayFlower == true) {
      new30DayMilestone = (effectiveStreak ~/ 30) * 30;
    } else if (hasClaimed30DayFlower == false) {
      new30DayMilestone = 0;
    }
    
    return TreeResources(
      leafCount: leafCount ?? this.leafCount,
      flowerCount: flowerCount ?? this.flowerCount,
      streak: effectiveStreak,
      lastWatered: lastWatered ?? this.lastWatered,
      lastFlowerUsed: lastFlowerUsed ?? this.lastFlowerUsed,
      lastLeafUsed: lastLeafUsed ?? this.lastLeafUsed,
      lastDailyReset: lastDailyReset ?? this.lastDailyReset,
      lastStreakUpdate: lastStreakUpdate ?? this.lastStreakUpdate,
      lastClaimed7DayMilestone: new7DayMilestone,
      lastClaimed30DayMilestone: new30DayMilestone,
    );
  }

  /// Check if water is available (0.5 seconds cooldown)
  bool canWater() {
    if (lastWatered == null) return true;
    final now = DateTime.now();
    return now.difference(lastWatered!).inMilliseconds >= 500;
  }

  /// Check if already watered today
  bool isWateredToday() {
    if (lastWatered == null) return false;
    final now = DateTime.now();
    return now.year == lastWatered!.year &&
           now.month == lastWatered!.month &&
           now.day == lastWatered!.day;
  }

  /// Check if flower was used today
  bool isFlowerUsedToday() {
    if (lastFlowerUsed == null) return false;
    final now = DateTime.now();
    return now.year == lastFlowerUsed!.year &&
           now.month == lastFlowerUsed!.month &&
           now.day == lastFlowerUsed!.day;
  }

  /// Check if flower can be used (once per day, 0.5 seconds cooldown)
  bool canUseFlower() {
    if (isFlowerUsedToday()) return false; // Already used today
    if (lastFlowerUsed == null) return true;
    final now = DateTime.now();
    return now.difference(lastFlowerUsed!).inMilliseconds >= 500;
  }

  /// Check if leaf can be used (0.5 seconds cooldown)
  bool canUseLeaf() {
    if (leafCount <= 0) return false;
    if (lastLeafUsed == null) return true;
    final now = DateTime.now();
    return now.difference(lastLeafUsed!).inMilliseconds >= 500;
  }

  /// Get remaining cooldown for water
  Duration getWaterCooldownRemaining() {
    if (lastWatered == null) return Duration.zero;
    final now = DateTime.now();
    final elapsed = now.difference(lastWatered!);
    final remaining = const Duration(milliseconds: 500) - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Get remaining cooldown for flower
  Duration getFlowerCooldownRemaining() {
    if (lastFlowerUsed == null) return Duration.zero;
    final now = DateTime.now();
    final elapsed = now.difference(lastFlowerUsed!);
    final remaining = const Duration(milliseconds: 500) - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Get remaining cooldown for leaf
  Duration getLeafCooldownRemaining() {
    if (lastLeafUsed == null) return Duration.zero;
    final now = DateTime.now();
    final elapsed = now.difference(lastLeafUsed!);
    final remaining = const Duration(milliseconds: 500) - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Map<String, dynamic> toJson() {
    return {
      'leafCount': leafCount,
      'flowerCount': flowerCount,
      'streak': streak,
      'lastWatered': lastWatered?.toIso8601String(),
      'lastFlowerUsed': lastFlowerUsed?.toIso8601String(),
      'lastLeafUsed': lastLeafUsed?.toIso8601String(),
      'lastDailyReset': lastDailyReset.toIso8601String(),
      'lastStreakUpdate': lastStreakUpdate?.toIso8601String(),
      'lastClaimed7DayMilestone': lastClaimed7DayMilestone,
      'lastClaimed30DayMilestone': lastClaimed30DayMilestone,
    };
  }

  factory TreeResources.fromJson(Map<String, dynamic> json) {
    // Handle migration from old boolean format to new milestone format
    int milestone7 = json['lastClaimed7DayMilestone'] as int? ?? 0;
    int milestone30 = json['lastClaimed30DayMilestone'] as int? ?? 0;
    final streak = json['streak'] as int? ?? 0;
    
    // Migrate from old boolean format
    if (json.containsKey('hasClaimed7DayFlower') && !json.containsKey('lastClaimed7DayMilestone')) {
      if (json['hasClaimed7DayFlower'] == true) {
        milestone7 = (streak ~/ 7) * 7;
      }
    }
    if (json.containsKey('hasClaimed30DayFlower') && !json.containsKey('lastClaimed30DayMilestone')) {
      if (json['hasClaimed30DayFlower'] == true) {
        milestone30 = (streak ~/ 30) * 30;
      }
    }
    
    return TreeResources(
      leafCount: json['leafCount'] as int? ?? 0,
      flowerCount: json['flowerCount'] as int? ?? 0,
      streak: streak,
      lastWatered: json['lastWatered'] != null
          ? DateTime.parse(json['lastWatered'] as String)
          : null,
      lastFlowerUsed: json['lastFlowerUsed'] != null
          ? DateTime.parse(json['lastFlowerUsed'] as String)
          : null,
      lastLeafUsed: json['lastLeafUsed'] != null
          ? DateTime.parse(json['lastLeafUsed'] as String)
          : null,
      lastDailyReset: json['lastDailyReset'] != null
          ? DateTime.parse(json['lastDailyReset'] as String)
          : DateTime.now(),
      lastStreakUpdate: json['lastStreakUpdate'] != null
          ? DateTime.parse(json['lastStreakUpdate'] as String)
          : null,
      lastClaimed7DayMilestone: milestone7,
      lastClaimed30DayMilestone: milestone30,
    );
  }

  /// Create default resources
  factory TreeResources.initial() {
    return TreeResources(
      leafCount: 0,
      flowerCount: 0,
      streak: 0,
      lastWatered: null,
      lastFlowerUsed: null,
      lastLeafUsed: null,
      lastDailyReset: DateTime.now(),
      lastStreakUpdate: null,
      lastClaimed7DayMilestone: 0,
      lastClaimed30DayMilestone: 0,
    );
  }

  @override
  String toString() {
    return 'TreeResources(leafs: $leafCount, flowers: $flowerCount, streak: $streak, '
           'canWater: ${canWater()}, canUseFlower: ${canUseFlower()}, canUseLeaf: ${canUseLeaf()}, '
           'milestone7: $lastClaimed7DayMilestone, milestone30: $lastClaimed30DayMilestone, '
           'hasSpecial7: $hasSpecial7DayFlower, hasSpecial30: $hasSpecial30DayFlower)';
  }
}
