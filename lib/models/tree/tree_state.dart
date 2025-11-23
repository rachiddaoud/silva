import 'dart:ui';
import 'package:flutter/foundation.dart';

/// State of a leaf in the dying process
enum LeafHealthState {
  alive,
  dead1,
  dead2,
  dead3,
}

/// Immutable state of a leaf
class LeafState {
  final String id;
  final double tOnBranch; // Position on branch (0.0 to 1.0)
  final int side; // Side of the branch (-1 or 1)
  final double age; // Age in days
  final double maxAge; // Maximum age
  final double randomSizeFactor; // Random size factor (0.8 to 1.2)
  final double currentGrowth; // Current growth level (0.0 to 1.0)
  final LeafHealthState healthState; // Health state
  final int deathAge; // Days since death started

  const LeafState({
    required this.id,
    required this.tOnBranch,
    required this.side,
    this.age = 0.0,
    required this.maxAge,
    required this.randomSizeFactor,
    this.currentGrowth = 0.1,
    this.healthState = LeafHealthState.alive,
    this.deathAge = 0,
  });

  LeafState copyWith({
    String? id,
    double? tOnBranch,
    int? side,
    double? age,
    double? maxAge,
    double? randomSizeFactor,
    double? currentGrowth,
    LeafHealthState? healthState,
    int? deathAge,
  }) {
    return LeafState(
      id: id ?? this.id,
      tOnBranch: tOnBranch ?? this.tOnBranch,
      side: side ?? this.side,
      age: age ?? this.age,
      maxAge: maxAge ?? this.maxAge,
      randomSizeFactor: randomSizeFactor ?? this.randomSizeFactor,
      currentGrowth: currentGrowth ?? this.currentGrowth,
      healthState: healthState ?? this.healthState,
      deathAge: deathAge ?? this.deathAge,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tOnBranch': tOnBranch,
      'side': side,
      'age': age,
      'maxAge': maxAge,
      'randomSizeFactor': randomSizeFactor,
      'currentGrowth': currentGrowth,
      'healthState': healthState.index,
      'deathAge': deathAge,
    };
  }

  factory LeafState.fromJson(Map<String, dynamic> json) {
    return LeafState(
      id: json['id'] as String,
      tOnBranch: (json['tOnBranch'] as num).toDouble(),
      side: json['side'] as int,
      age: (json['age'] as num).toDouble(),
      maxAge: (json['maxAge'] as num).toDouble(),
      randomSizeFactor: (json['randomSizeFactor'] as num).toDouble(),
      currentGrowth: (json['currentGrowth'] as num).toDouble(),
      healthState: LeafHealthState.values[json['healthState'] as int],
      deathAge: json['deathAge'] as int,
    );
  }
}

/// Immutable state of a flower
class FlowerState {
  final String id;
  final double tOnBranch; // Position on branch (0.0 to 1.0)
  final int side; // Side of the branch (-1 or 1)
  final double sizeFactor; // Size factor based on branch depth
  final int flowerType; // Type of flower (0 = flower.png, 1 = jasmin.png)

  const FlowerState({
    required this.id,
    required this.tOnBranch,
    required this.side,
    required this.sizeFactor,
    required this.flowerType,
  });

  FlowerState copyWith({
    String? id,
    double? tOnBranch,
    int? side,
    double? sizeFactor,
    int? flowerType,
  }) {
    return FlowerState(
      id: id ?? this.id,
      tOnBranch: tOnBranch ?? this.tOnBranch,
      side: side ?? this.side,
      sizeFactor: sizeFactor ?? this.sizeFactor,
      flowerType: flowerType ?? this.flowerType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tOnBranch': tOnBranch,
      'side': side,
      'sizeFactor': sizeFactor,
      'flowerType': flowerType,
    };
  }

  factory FlowerState.fromJson(Map<String, dynamic> json) {
    return FlowerState(
      id: json['id'] as String,
      tOnBranch: (json['tOnBranch'] as num).toDouble(),
      side: json['side'] as int,
      sizeFactor: (json['sizeFactor'] as num).toDouble(),
      flowerType: json['flowerType'] as int,
    );
  }
}

/// Immutable state of a branch
class BranchState {
  final String id;
  final List<BranchState> children;
  final List<LeafState> leaves;
  final List<FlowerState> flowers;
  final int age; // Age in days
  
  // Geometry
  final Offset start;
  final Offset end;
  final Offset controlPoint;
  final double thickness;
  final double length;
  final double angle;
  final int depth;

  const BranchState({
    required this.id,
    this.children = const [],
    this.leaves = const [],
    this.flowers = const [],
    this.age = 0,
    required this.start,
    required this.end,
    required this.controlPoint,
    required this.thickness,
    required this.length,
    required this.angle,
    required this.depth,
  });

  BranchState copyWith({
    String? id,
    List<BranchState>? children,
    List<LeafState>? leaves,
    List<FlowerState>? flowers,
    int? age,
    Offset? start,
    Offset? end,
    Offset? controlPoint,
    double? thickness,
    double? length,
    double? angle,
    int? depth,
  }) {
    return BranchState(
      id: id ?? this.id,
      children: children ?? this.children,
      leaves: leaves ?? this.leaves,
      flowers: flowers ?? this.flowers,
      age: age ?? this.age,
      start: start ?? this.start,
      end: end ?? this.end,
      controlPoint: controlPoint ?? this.controlPoint,
      thickness: thickness ?? this.thickness,
      length: length ?? this.length,
      angle: angle ?? this.angle,
      depth: depth ?? this.depth,
    );
  }

  /// Returns all branches recursively
  List<BranchState> getAllBranches() {
    final branches = <BranchState>[this];
    for (final child in children) {
      branches.addAll(child.getAllBranches());
    }
    return branches;
  }

  /// Returns all leaves recursively
  List<LeafState> getAllLeaves() {
    final allLeaves = <LeafState>[...leaves];
    for (final child in children) {
      allLeaves.addAll(child.getAllLeaves());
    }
    return allLeaves;
  }

  /// Returns all flowers recursively
  List<FlowerState> getAllFlowers() {
    final allFlowers = <FlowerState>[...flowers];
    for (final child in children) {
      allFlowers.addAll(child.getAllFlowers());
    }
    return allFlowers;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'children': children.map((c) => c.toJson()).toList(),
      'leaves': leaves.map((l) => l.toJson()).toList(),
      'flowers': flowers.map((f) => f.toJson()).toList(),
      'age': age,
      'start': {'dx': start.dx, 'dy': start.dy},
      'end': {'dx': end.dx, 'dy': end.dy},
      'controlPoint': {'dx': controlPoint.dx, 'dy': controlPoint.dy},
      'thickness': thickness,
      'length': length,
      'angle': angle,
      'depth': depth,
    };
  }

  factory BranchState.fromJson(Map<String, dynamic> json) {
    return BranchState(
      id: json['id'] as String,
      children: (json['children'] as List?)
              ?.map((c) => BranchState.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      leaves: (json['leaves'] as List?)
              ?.map((l) => LeafState.fromJson(l as Map<String, dynamic>))
              .toList() ??
          [],
      flowers: (json['flowers'] as List?)
              ?.map((f) => FlowerState.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
      age: json['age'] as int,
      start: Offset(
        (json['start']['dx'] as num).toDouble(),
        (json['start']['dy'] as num).toDouble(),
      ),
      end: Offset(
        (json['end']['dx'] as num).toDouble(),
        (json['end']['dy'] as num).toDouble(),
      ),
      controlPoint: Offset(
        (json['controlPoint']['dx'] as num).toDouble(),
        (json['controlPoint']['dy'] as num).toDouble(),
      ),
      thickness: (json['thickness'] as num).toDouble(),
      length: (json['length'] as num).toDouble(),
      angle: (json['angle'] as num).toDouble(),
      depth: json['depth'] as int,
    );
  }
}

/// Immutable state of the entire tree
class TreeState {
  final int age; // Total age in days
  final BranchState trunk; // Root branch
  final double treeSize; // Canvas size used for generation

  const TreeState({
    required this.age,
    required this.trunk,
    required this.treeSize,
  });

  TreeState copyWith({
    int? age,
    BranchState? trunk,
    double? treeSize,
  }) {
    return TreeState(
      age: age ?? this.age,
      trunk: trunk ?? this.trunk,
      treeSize: treeSize ?? this.treeSize,
    );
  }

  List<BranchState> getAllBranches() => trunk.getAllBranches();
  List<LeafState> getAllLeaves() => trunk.getAllLeaves();
  List<FlowerState> getAllFlowers() => trunk.getAllFlowers();

  double getGrowthLevel() {
    return (age * 0.01).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() {
    return {
      'age': age,
      'trunk': trunk.toJson(),
      'treeSize': treeSize,
    };
  }

  factory TreeState.fromJson(Map<String, dynamic> json) {
    return TreeState(
      age: json['age'] as int,
      trunk: BranchState.fromJson(json['trunk'] as Map<String, dynamic>),
      treeSize: (json['treeSize'] as num).toDouble(),
    );
  }
}
