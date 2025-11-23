import 'dart:math' as math;

/// Configuration parameters for tree generation.
/// These parameters define the "DNA" of the tree and do not change during the tree's life
/// (unless the user explicitly changes the tree type).
class TreeParameters {
  final int maxDepth;
  final double baseBranchAngle; // in radians
  final double lengthRatio;
  final double thicknessRatio;
  final double angleVariation;
  final double curveIntensity;
  final int seed;

  const TreeParameters({
    this.maxDepth = 6,
    this.baseBranchAngle = 32.2 * math.pi / 180,
    this.lengthRatio = 0.78,
    this.thicknessRatio = 0.54,
    this.angleVariation = 0.25,
    this.curveIntensity = 0.20,
    this.seed = 610940,
  });

  TreeParameters copyWith({
    int? maxDepth,
    double? baseBranchAngle,
    double? lengthRatio,
    double? thicknessRatio,
    double? angleVariation,
    double? curveIntensity,
    int? seed,
  }) {
    return TreeParameters(
      maxDepth: maxDepth ?? this.maxDepth,
      baseBranchAngle: baseBranchAngle ?? this.baseBranchAngle,
      lengthRatio: lengthRatio ?? this.lengthRatio,
      thicknessRatio: thicknessRatio ?? this.thicknessRatio,
      angleVariation: angleVariation ?? this.angleVariation,
      curveIntensity: curveIntensity ?? this.curveIntensity,
      seed: seed ?? this.seed,
    );
  }

  /// Generates random parameters
  factory TreeParameters.random(math.Random random) {
    return TreeParameters(
      maxDepth: 8 + random.nextInt(5), // 8-12
      baseBranchAngle: (15.0 + random.nextDouble() * 20.0) * math.pi / 180, // 15-35 degrees
      lengthRatio: 0.5 + random.nextDouble() * 0.3, // 0.5-0.8
      thicknessRatio: 0.5 + random.nextDouble() * 0.3, // 0.5-0.8
      angleVariation: 0.2 + random.nextDouble() * 0.4, // 0.2-0.6
      curveIntensity: 0.1 + random.nextDouble() * 0.4, // 0.1-0.5
      seed: random.nextInt(1000000),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxDepth': maxDepth,
      'baseBranchAngle': baseBranchAngle,
      'lengthRatio': lengthRatio,
      'thicknessRatio': thicknessRatio,
      'angleVariation': angleVariation,
      'curveIntensity': curveIntensity,
      'seed': seed,
    };
  }

  factory TreeParameters.fromJson(Map<String, dynamic> json) {
    return TreeParameters(
      maxDepth: json['maxDepth'] as int,
      baseBranchAngle: (json['baseBranchAngle'] as num).toDouble(),
      lengthRatio: (json['lengthRatio'] as num).toDouble(),
      thicknessRatio: (json['thicknessRatio'] as num).toDouble(),
      angleVariation: (json['angleVariation'] as num).toDouble(),
      curveIntensity: (json['curveIntensity'] as num).toDouble(),
      seed: json['seed'] as int,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TreeParameters &&
        other.maxDepth == maxDepth &&
        other.baseBranchAngle == baseBranchAngle &&
        other.lengthRatio == lengthRatio &&
        other.thicknessRatio == thicknessRatio &&
        other.angleVariation == angleVariation &&
        other.curveIntensity == curveIntensity &&
        other.seed == seed;
  }

  @override
  int get hashCode {
    return Object.hash(
      maxDepth,
      baseBranchAngle,
      lengthRatio,
      thicknessRatio,
      angleVariation,
      curveIntensity,
      seed,
    );
  }
}
