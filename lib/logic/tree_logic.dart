import 'dart:math' as math;
import 'dart:ui';
import 'package:ma_bulle/models/tree/tree_parameters.dart';
import 'package:ma_bulle/models/tree/tree_state.dart';

/// Pure logic for tree geometry calculations
class TreeGeometry {
  /// Calculates a point on a quadratic Bezier curve
  static Offset bezierPoint(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1 - t;
    final tt = t * t;
    final uu = u * u;

    return Offset(
      uu * p0.dx + 2 * u * t * p1.dx + tt * p2.dx,
      uu * p0.dy + 2 * u * t * p1.dy + tt * p2.dy,
    );
  }

  /// Calculates the tangent to a quadratic Bezier curve
  static Offset bezierTangent(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1 - t;
    return Offset(
      2 * u * (p1.dx - p0.dx) + 2 * t * (p2.dx - p1.dx),
      2 * u * (p1.dy - p0.dy) + 2 * t * (p2.dy - p1.dy),
    );
  }

  /// Calculates the position of a leaf or flower on a branch
  static Offset getAttachmentPosition(BranchState branch, double t, int side) {
    final branchPos = bezierPoint(
      branch.start,
      branch.controlPoint,
      branch.end,
      t,
    );

    final tangent = bezierTangent(
      branch.start,
      branch.controlPoint,
      branch.end,
      t,
    );

    final branchAngle = math.atan2(tangent.dy, tangent.dx);
    final perpAngle = branchAngle + math.pi / 2;

    final thicknessAtPoint = branch.thickness * (1.0 - t * 0.3);
    final branchRadius = thicknessAtPoint / 2;

    return Offset(
      branchPos.dx + math.cos(perpAngle) * branchRadius * side,
      branchPos.dy + math.sin(perpAngle) * branchRadius * side,
    );
  }
}

/// Pure logic for tree generation
class TreeGenerator {
  /// Generates the initial tree structure
  static TreeState generateTree({
    required double growthLevel,
    required double treeSize,
    required TreeParameters parameters,
    int treeAge = 0,
  }) {
    final random = math.Random(parameters.seed);
    final fractionalDepth = parameters.maxDepth * growthLevel.clamp(0.0, 1.0);
    final effectiveDepth = fractionalDepth.floor();
    final depthFraction = fractionalDepth - effectiveDepth;

    // Base position
    final groundWidth = treeSize * 0.4;
    final groundHeight = groundWidth; // Aspect ratio 1.0
    final groundX = (treeSize - groundWidth) / 2;
    final treeBaseY = treeSize * 0.75;
    final groundY = treeBaseY - groundHeight / 2;
    final treeBase = Offset(groundX + groundWidth / 2, groundY + groundHeight / 2);

    if (effectiveDepth == 0 && depthFraction < 0.01) {
      // Too young, just a stump
      final trunk = BranchState(
        id: '0',
        start: treeBase,
        end: treeBase,
        controlPoint: treeBase,
        thickness: 0.01,
        length: 0.01,
        angle: -math.pi / 2,
        depth: 0,
        age: treeAge,
      );
      return TreeState(
        age: treeAge,
        trunk: trunk,
        treeSize: treeSize,
      );
    }

    final growthFactor = growthLevel.clamp(0.0, 1.0);
    final trunkLength = treeSize * (0.05 + 0.20 * growthFactor);
    final thicknessGrowth = growthFactor * growthFactor;
    final trunkThickness = treeSize * (0.01 + 0.05 * thicknessGrowth);
    final trunkAngle = -math.pi / 2;

    final trunkEnd = Offset(
      treeBase.dx + math.cos(trunkAngle) * trunkLength,
      treeBase.dy + math.sin(trunkAngle) * trunkLength,
    );

    final trunkControl = Offset(
      treeBase.dx + math.cos(trunkAngle) * trunkLength * 0.5 + (random.nextDouble() - 0.5) * treeSize * 0.05,
      treeBase.dy + math.sin(trunkAngle) * trunkLength * 0.5,
    );

    final trunk = BranchState(
      id: '0',
      start: treeBase,
      end: trunkEnd,
      controlPoint: trunkControl,
      thickness: trunkThickness,
      length: trunkLength,
      angle: trunkAngle,
      depth: 0,
      age: treeAge,
    );

    final children = _generateChildren(
      trunk,
      effectiveDepth,
      depthFraction,
      parameters,
      treeSize,
      treeAge,
    );

    return TreeState(
      age: treeAge,
      trunk: trunk.copyWith(children: children),
      treeSize: treeSize,
    );
  }

  static List<BranchState> _generateChildren(
    BranchState parent,
    int effectiveDepth,
    double depthFraction,
    TreeParameters parameters,
    double treeSize,
    int treeAge,
  ) {
    final branchSeed = parameters.seed + _stableStringHash(parent.id);
    final random = math.Random(branchSeed);

    final numBranches = random.nextBool() ? 2 : 3;
    final newDepth = parent.depth + 1;
    final maxDepth = depthFraction > 0.0 ? effectiveDepth + 1 : effectiveDepth;

    if (newDepth > maxDepth) return [];

    final children = <BranchState>[];

    for (int i = 0; i < numBranches; i++) {
      final angleVariationFactor = (random.nextDouble() - 0.5) * parameters.angleVariation;
      final branchAngle = parent.angle +
          parameters.baseBranchAngle * (i % 2 == 0 ? 1 : -1) +
          angleVariationFactor;

      final lengthVariation = 0.85 + random.nextDouble() * 0.3;
      var branchLength = parent.length * parameters.lengthRatio * lengthVariation;

      if (newDepth == maxDepth && depthFraction > 0.0 && depthFraction < 1.0) {
        branchLength *= depthFraction;
      }

      final branchThickness = parent.thickness * parameters.thicknessRatio;
      final branchStart = parent.end;
      final branchEnd = Offset(
        branchStart.dx + math.cos(branchAngle) * branchLength,
        branchStart.dy + math.sin(branchAngle) * branchLength,
      );

      final curveOffset = (random.nextDouble() - 0.5) * parameters.curveIntensity;
      final midPoint = Offset(
        (branchStart.dx + branchEnd.dx) / 2,
        (branchStart.dy + branchEnd.dy) / 2,
      );
      final perpAngle = branchAngle + math.pi / 2;
      final branchControl = Offset(
        midPoint.dx + math.cos(perpAngle) * branchLength * curveOffset,
        midPoint.dy + math.sin(perpAngle) * branchLength * curveOffset,
      );

      final branchId = '${parent.id}_$i';
      final branch = BranchState(
        id: branchId,
        start: branchStart,
        end: branchEnd,
        controlPoint: branchControl,
        thickness: branchThickness,
        length: branchLength,
        angle: branchAngle,
        depth: newDepth,
        age: treeAge,
      );

      final grandChildren = newDepth < maxDepth
          ? _generateChildren(
              branch,
              effectiveDepth,
              depthFraction,
              parameters,
              treeSize,
              treeAge,
            )
          : <BranchState>[];

      children.add(branch.copyWith(children: grandChildren));
    }

    return children;
  }

  static int _stableStringHash(String s) {
    var hash = 0;
    for (var i = 0; i < s.length; i++) {
      hash = 0x1fffffff & (hash + s.codeUnitAt(i));
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash = hash ^ (hash >> 6);
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Pure logic for tree growth and evolution
class TreeLogic {
  /// Advances the tree by one day
  static TreeState growOneDay(TreeState tree) {
    final newAge = tree.age + 1;
    final newTrunk = _growBranch(tree.trunk);
    return tree.copyWith(
      age: newAge,
      trunk: newTrunk,
    );
  }

  static BranchState _growBranch(BranchState branch) {
    final newAge = branch.age + 1;

    // Grow leaves
    final newLeaves = <LeafState>[];
    for (final leaf in branch.leaves) {
      final grownLeaf = _growLeaf(leaf);
      // Remove dead leaves that have been dead for too long (dead3 + 1 day)
      if (!(grownLeaf.healthState == LeafHealthState.dead3 && grownLeaf.deathAge >= 4)) {
        newLeaves.add(grownLeaf);
      }
    }

    // Grow children recursively
    final newChildren = branch.children.map(_growBranch).toList();

    return branch.copyWith(
      age: newAge,
      leaves: newLeaves,
      children: newChildren,
    );
  }

  static LeafState _growLeaf(LeafState leaf) {
    if (leaf.healthState == LeafHealthState.alive && leaf.age < leaf.maxAge) {
      final newAge = leaf.age + 1.0;
      final newGrowth = (newAge / leaf.maxAge).clamp(0.0, 1.0);
      return leaf.copyWith(
        age: newAge,
        currentGrowth: newGrowth,
      );
    } else if (leaf.healthState != LeafHealthState.alive) {
      final newDeathAge = leaf.deathAge + 1;
      var newState = leaf.healthState;
      
      if (newDeathAge == 2) {
        newState = LeafHealthState.dead2;
      } else if (newDeathAge >= 3) {
        newState = LeafHealthState.dead3;
      }
      
      return leaf.copyWith(
        deathAge: newDeathAge,
        healthState: newState,
      );
    }
    return leaf;
  }

  /// Calculates max capacity of leaves for a branch
  static int getLeafCapacity(BranchState branch) {
    final baseCapacity = (branch.length / 50.0).ceil();
    final depthFactor = 1.5 - (branch.depth * 0.12).clamp(0.0, 0.7);
    final ageFactor = 1.0 + (branch.age / 30.0).clamp(0.0, 0.5);
    final totalCapacity = (baseCapacity * depthFactor * ageFactor).ceil();
    return totalCapacity.clamp(1, 25);
  }

  /// Checks if a branch can add a leaf
  static bool canAddLeaf(BranchState branch) {
    return branch.leaves.length < getLeafCapacity(branch);
  }
}
