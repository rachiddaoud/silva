

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
  final bool hasClaimed7DayFlower; // Track if 7-day flower reward claimed
  final bool hasClaimed30DayFlower; // Track if 30-day flower reward claimed

  const TreeResources({
    this.leafCount = 0,
    this.flowerCount = 0,
    this.streak = 0,
    this.lastWatered,
    this.lastFlowerUsed,
    this.lastLeafUsed,
    required this.lastDailyReset,
    this.lastStreakUpdate,
    this.hasClaimed7DayFlower = false,
    this.hasClaimed30DayFlower = false,
  });

  TreeResources copyWith({
    int? leafCount,
    int? flowerCount,
    int? streak,
    DateTime? lastWatered,
    DateTime? lastFlowerUsed,
    DateTime? lastLeafUsed,
    DateTime? lastDailyReset,
    DateTime? lastStreakUpdate,
    bool? hasClaimed7DayFlower,
    bool? hasClaimed30DayFlower,
  }) {
    return TreeResources(
      leafCount: leafCount ?? this.leafCount,
      flowerCount: flowerCount ?? this.flowerCount,
      streak: streak ?? this.streak,
      lastWatered: lastWatered ?? this.lastWatered,
      lastFlowerUsed: lastFlowerUsed ?? this.lastFlowerUsed,
      lastLeafUsed: lastLeafUsed ?? this.lastLeafUsed,
      lastDailyReset: lastDailyReset ?? this.lastDailyReset,
      lastStreakUpdate: lastStreakUpdate ?? this.lastStreakUpdate,
      hasClaimed7DayFlower: hasClaimed7DayFlower ?? this.hasClaimed7DayFlower,
      hasClaimed30DayFlower: hasClaimed30DayFlower ?? this.hasClaimed30DayFlower,
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
      'hasClaimed7DayFlower': hasClaimed7DayFlower,
      'hasClaimed30DayFlower': hasClaimed30DayFlower,
    };
  }

  factory TreeResources.fromJson(Map<String, dynamic> json) {
    return TreeResources(
      leafCount: json['leafCount'] as int? ?? 0,
      flowerCount: json['flowerCount'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
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
      hasClaimed7DayFlower: json['hasClaimed7DayFlower'] as bool? ?? false,
      hasClaimed30DayFlower: json['hasClaimed30DayFlower'] as bool? ?? false,
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
      hasClaimed7DayFlower: false,
      hasClaimed30DayFlower: false,
    );
  }

  @override
  String toString() {
    return 'TreeResources(leafs: $leafCount, flowers: $flowerCount, streak: $streak, '
           'canWater: ${canWater()}, canUseFlower: ${canUseFlower()}, canUseLeaf: ${canUseLeaf()}, '
           'claimed7: $hasClaimed7DayFlower, claimed30: $hasClaimed30DayFlower)';
  }
}
