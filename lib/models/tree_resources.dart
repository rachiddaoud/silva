

/// Manages tree resources and cooldown timers
class TreeResources {
  final int leafCount;           // From victories
  final int flowerCount;         // 5 per day, +1 every 5 minutes
  final DateTime? lastWatered;    // Track last water time
  final DateTime? lastFlowerUsed; // Track last flower use
  final DateTime? lastLeafUsed;   // Track last leaf use
  final DateTime lastDailyReset;  // Track daily flower reset

  const TreeResources({
    this.leafCount = 0,
    this.flowerCount = 5,
    this.lastWatered,
    this.lastFlowerUsed,
    this.lastLeafUsed,
    required this.lastDailyReset,
  });

  TreeResources copyWith({
    int? leafCount,
    int? flowerCount,
    DateTime? lastWatered,
    DateTime? lastFlowerUsed,
    DateTime? lastLeafUsed,
    DateTime? lastDailyReset,
  }) {
    return TreeResources(
      leafCount: leafCount ?? this.leafCount,
      flowerCount: flowerCount ?? this.flowerCount,
      lastWatered: lastWatered ?? this.lastWatered,
      lastFlowerUsed: lastFlowerUsed ?? this.lastFlowerUsed,
      lastLeafUsed: lastLeafUsed ?? this.lastLeafUsed,
      lastDailyReset: lastDailyReset ?? this.lastDailyReset,
    );
  }

  /// Check if water is available (5 seconds cooldown)
  bool canWater() {
    if (lastWatered == null) return true;
    final now = DateTime.now();
    return now.difference(lastWatered!).inMilliseconds >= 5000;
  }

  /// Check if flower can be used (5 seconds cooldown)
  bool canUseFlower() {
    if (flowerCount <= 0) return false;
    if (lastFlowerUsed == null) return true;
    final now = DateTime.now();
    return now.difference(lastFlowerUsed!).inMilliseconds >= 5000;
  }

  /// Check if leaf can be used (5 seconds cooldown)
  bool canUseLeaf() {
    if (leafCount <= 0) return false;
    if (lastLeafUsed == null) return true;
    final now = DateTime.now();
    return now.difference(lastLeafUsed!).inMilliseconds >= 5000;
  }

  /// Get remaining cooldown for water
  Duration getWaterCooldownRemaining() {
    if (lastWatered == null) return Duration.zero;
    final now = DateTime.now();
    final elapsed = now.difference(lastWatered!);
    final remaining = const Duration(seconds: 5) - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Get remaining cooldown for flower
  Duration getFlowerCooldownRemaining() {
    if (lastFlowerUsed == null) return Duration.zero;
    final now = DateTime.now();
    final elapsed = now.difference(lastFlowerUsed!);
    final remaining = const Duration(seconds: 5) - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Get remaining cooldown for leaf
  Duration getLeafCooldownRemaining() {
    if (lastLeafUsed == null) return Duration.zero;
    final now = DateTime.now();
    final elapsed = now.difference(lastLeafUsed!);
    final remaining = const Duration(seconds: 5) - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Check if we should reset daily flowers
  bool shouldResetDailyFlowers() {
    final now = DateTime.now();
    final lastReset = lastDailyReset;
    
    // Different day?
    return now.year != lastReset.year ||
           now.month != lastReset.month ||
           now.day != lastReset.day;
  }

  /// Calculate current flower count with time-based increments
  /// Each 5 minutes adds 1 flower, up to 5 max per day
  int getCurrentFlowerCount() {
    // final now = DateTime.now(); // Unused for now
    
    // If we should reset daily, return 5
    if (shouldResetDailyFlowers()) {
      return 5;
    }
    
    // Temporary fix: just return flowerCount to avoid clamping to 0
    return flowerCount;
  }

  Map<String, dynamic> toJson() {
    return {
      'leafCount': leafCount,
      'flowerCount': flowerCount,
      'lastWatered': lastWatered?.toIso8601String(),
      'lastFlowerUsed': lastFlowerUsed?.toIso8601String(),
      'lastLeafUsed': lastLeafUsed?.toIso8601String(),
      'lastDailyReset': lastDailyReset.toIso8601String(),
    };
  }

  factory TreeResources.fromJson(Map<String, dynamic> json) {
    return TreeResources(
      leafCount: json['leafCount'] as int? ?? 0,
      flowerCount: json['flowerCount'] as int? ?? 5,
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
    );
  }

  /// Create default resources
  factory TreeResources.initial() {
    return TreeResources(
      leafCount: 0,
      flowerCount: 5,
      lastWatered: null,
      lastFlowerUsed: null,
      lastLeafUsed: null,
      lastDailyReset: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'TreeResources(leafs: $leafCount, flowers: $flowerCount, '
           'canWater: ${canWater()}, canUseFlower: ${canUseFlower()}, canUseLeaf: ${canUseLeaf()})';
  }
}
