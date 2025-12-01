import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Offset;
import 'package:silva/models/day_entry.dart';
import 'package:silva/models/tree/tree_parameters.dart';
import 'package:silva/models/tree/tree_state.dart';
import 'package:silva/logic/tree_logic.dart';
import 'dart:math' as math;

/// Controller to manage tree state and interactions
class TreeController extends ChangeNotifier {
  TreeState? _tree;
  TreeState? get tree => _tree;
  TreeParameters _parameters = const TreeParameters(); // Store parameters
  
  // Track last added items for animations
  String? _lastAddedLeafId;
  String? _lastAddedFlowerId;

  String? get lastAddedLeafId => _lastAddedLeafId;
  String? get lastAddedFlowerId => _lastAddedFlowerId;

  void setTree(TreeState tree) {
    _tree = tree;

    notifyListeners();
  }

  /// Initializes or updates the tree
  void updateTree({
    required double growthLevel,
    required double size,
    required TreeParameters parameters,
    bool resetAge = false,
    bool forceRegenerate = false,
  }) {
    _parameters = parameters; // Update stored parameters
    // If loaded from JSON, we generally want to keep the structure unless:
    // 1. forceRegenerate is true (explicit reset)
    // 2. growthLevel has changed (tree is growing)
    // 3. parameters have changed
    
    // However, we must be careful not to reset a complex tree to a simple one just because of a reload.
    // But here, updateTree is called by the widget when parameters/growth change.
    
    final existingLeaves = _tree?.getAllLeaves() ?? [];
    final existingFlowers = _tree?.getAllFlowers() ?? [];
    final oldAge = _tree?.age ?? 0;
    
    // User requested to start with 3 days of growth
    final effectiveAge = resetAge ? 3 : oldAge;
    final effectiveGrowthLevel = resetAge ? 0.03 : growthLevel;
    
    _tree = TreeGenerator.generateTree(
      growthLevel: effectiveGrowthLevel,
      treeSize: size,
      parameters: parameters,
      treeAge: effectiveAge,
    );
    
    // Reapply items if we have a new tree
    if (_tree != null && !resetAge) {
      if (existingLeaves.isNotEmpty) {
        _tree = _reapplyLeaves(_tree!, existingLeaves);
      }
      if (existingFlowers.isNotEmpty) {
        _tree = _reapplyFlowers(_tree!, existingFlowers);
      }
    }
    
    notifyListeners();
  }

  TreeState _reapplyLeaves(TreeState tree, List<LeafState> leaves) {
    var currentTree = tree;
    for (final leaf in leaves) {
      // Try to find the branch ID. ID format: branchId_t_side or branchId_dead_t_side
      // But wait, our generator makes deterministic IDs: 0_0_1 etc.
      // If the tree structure is similar (just grown), IDs should match.
      
      final parts = leaf.id.split('_');
      // We need to extract the branch ID.
      // Standard format from _addSingleRandomLeaf: ${branch.id}_${t}_${side}
      // But branch IDs can contain underscores too (0_1_0).
      // The last two parts are t and side.
      
      if (parts.length < 3) continue;
      
      // Reconstruct branch ID by removing the last two parts (t and side)
      // If it's a dead leaf, it might have 'dead' in it, but our new model doesn't put 'dead' in ID for state, 
      // it uses healthState.
      // However, if we loaded old data, it might be different. 
      // But we are using new LeafState which has healthState.
      
      final branchId = parts.sublist(0, parts.length - 2).join('_');
      
      // Check if this branch exists in the new tree
      if (_findBranch(currentTree.trunk, branchId) != null) {
        currentTree = _addLeafToBranch(currentTree, branchId, leaf);
      }
    }
    return currentTree;
  }

  TreeState _reapplyFlowers(TreeState tree, List<FlowerState> flowers) {
    var currentTree = tree;
    for (final flower in flowers) {
      final parts = flower.id.split('_');
      // Format: flower_${branch.id}_${t}_${side}
      // Remove 'flower' (first) and last two (t, side)
      if (parts.length < 4) continue;
      
      final branchId = parts.sublist(1, parts.length - 2).join('_');
      
      if (_findBranch(currentTree.trunk, branchId) != null) {
        currentTree = _addFlowerToBranch(currentTree, branchId, flower);
      }
    }
    return currentTree;
  }

  BranchState? _findBranch(BranchState branch, String id) {
    if (branch.id == id) return branch;
    for (final child in branch.children) {
      final found = _findBranch(child, id);
      if (found != null) return found;
    }
    return null;
  }

  /// Simulates a day of growth based on daily data
  Map<String, int> simulateDay(DayEntry? entry, {bool notify = true}) {
    final stats = {
      'leavesAdded': 0,
      'flowersAdded': 0,
      'deadLeavesAdded': 0,
      'leavesRemoved': 0,
      'flowersRemoved': 0,
    };
    
    if (_tree == null) return stats;

    // 1. Natural growth
    _tree = TreeLogic.growOneDay(_tree!);
    
    // 1.5 Update structure based on new age
    // We need to regenerate the skeleton to match the new age/growth level
    // but keep the leaves and flowers we just grew/kept.
    final newGrowthLevel = _tree!.getGrowthLevel();
    final currentLeaves = _tree!.getAllLeaves();
    final currentFlowers = _tree!.getAllFlowers();
    
    // Generate new skeleton
    var newTree = TreeGenerator.generateTree(
      growthLevel: newGrowthLevel,
      treeSize: _tree!.treeSize,
      parameters: _parameters,
      treeAge: _tree!.age,
    );
    
    // Reapply items
    if (currentLeaves.isNotEmpty) {
      newTree = _reapplyLeaves(newTree, currentLeaves);
    }
    if (currentFlowers.isNotEmpty) {
      newTree = _reapplyFlowers(newTree, currentFlowers);
    }
    
    _tree = newTree;

    if (entry != null) {
      // 2. Victories -> Leaves
      final victories = entry.victoryCards.where((v) => v.isAccomplished).length;
      
      // Rule: When young (< 30 days), 3 victories = 1 leaf. Otherwise 1 victory = 1 leaf.
      int leavesToAdd = victories;
      if (_tree!.age < 30) {
        leavesToAdd = victories ~/ 3;
      }
      
      for (int i = 0; i < leavesToAdd; i++) {
        if (addLeaf(notify: false)) { // Don't notify for individual leaves in simulation
          stats['leavesAdded'] = (stats['leavesAdded'] ?? 0) + 1;
        }
      }

      // 3. Emotions
      if (entry.emotion != null) {
        final emotionLabel = entry.emotion!.name.toLowerCase();
        
        if (['joyeux', 'fier', 'paisible', 'excité', 'joyful', 'proud', 'peaceful', 'excited'].contains(emotionLabel)) {
           if (addFlower(notify: false)) {
             stats['flowersAdded'] = (stats['flowersAdded'] ?? 0) + 1;
           }
        } 
        else if (['triste', 'anxieux', 'en colère', 'fatigué', 'sad', 'anxious', 'angry', 'tired'].contains(emotionLabel)) {
           if (decayLeaf(notify: false)) {
             stats['deadLeavesAdded'] = (stats['deadLeavesAdded'] ?? 0) + 1;
           }
        }
      }
    }
    
    if (notify) notifyListeners();
    return stats;
  }

  /// 1. GROW: Advances the tree by one day
  void grow() {
    if (_tree == null) return;
    _tree = TreeLogic.growOneDay(_tree!);
    notifyListeners();
  }

  /// 2. ADD LEAF: Adds a leaf to a specific branch or a random one
  bool addLeaf({String? branchId, double? t, int? side, bool notify = true}) {
    if (_tree == null) return false;

    if (branchId != null && t != null && side != null) {
      // Add specific leaf
      final leafId = '${branchId}_${t.toStringAsFixed(3)}_$side';
      // Calculate maxAge based on branch depth (we'd need to find the branch first to get depth)
      // For simplicity, we'll find the branch first.
      final branch = _findBranch(_tree!.trunk, branchId);
      if (branch == null) return false;

      final depthFactor = 1.0 - (branch.depth - 1) * 0.12;
      final clampedDepthFactor = depthFactor.clamp(0.3, 1.0);
      final maxAge = 10.0 + (clampedDepthFactor * 20.0); // Days to reach full size

      final newLeaf = LeafState(
        id: leafId,
        tOnBranch: t,
        side: side,
        age: 4.0, // Start at age 4 (was 2, added 2 days for visibility)
        maxAge: maxAge,
        randomSizeFactor: 0.8 + math.Random().nextDouble() * 0.4,
        currentGrowth: 4.0 / maxAge, // Start at size corresponding to age 4
        healthState: LeafHealthState.alive,
      );

      _tree = _addLeafToBranch(_tree!, branchId, newLeaf);
      _lastAddedLeafId = leafId; // Track for animations
      if (notify) notifyListeners();
      return true;
    } else {
      // Add random leaf
      return _addRandomLeaf(notify: notify);
    }
  }

  bool _addRandomLeaf({bool notify = true}) {
    if (_tree == null) return false;
    
    // Calculate number of leaves to add based on age
    // Example: 1 leaf base, +1 for every 20 days of age, max 5
    final count = math.min(1 + (_tree!.age ~/ 20), 5);
    
    bool addedAny = false;
    final random = math.Random();
    
    for (int i = 0; i < count; i++) {
      // Need to re-fetch branches as tree state changes in the loop
      final allBranches = _tree!.getAllBranches();
      final candidates = allBranches.where((b) => b.depth > 0 && TreeLogic.canAddLeaf(b)).toList();
      
      if (candidates.isEmpty) break;
      
      final branch = candidates[random.nextInt(candidates.length)];
      final t = 0.2 + random.nextDouble() * 0.8;
      final side = random.nextBool() ? 1 : -1;
      
      // Add without notifying until the end
      if (addLeaf(branchId: branch.id, t: t, side: side, notify: false)) {
        addedAny = true;
      }
    }
    
    if (addedAny && notify) {
      notifyListeners();
    }
    return addedAny;
  }

  /// 3. ADD FLOWER: Adds a flower to a specific branch or a random one
  bool addFlower({String? branchId, double? t, int? side, bool notify = true}) {
    if (_tree == null) return false;

    if (branchId != null && t != null && side != null) {
      final flowerId = 'flower_${branchId}_${t.toStringAsFixed(3)}_$side';
      final branch = _findBranch(_tree!.trunk, branchId);
      if (branch == null) return false;

      final depthFactor = 1.0 - (branch.depth - 1) * 0.12;
      final sizeFactor = depthFactor.clamp(0.3, 1.0);

      final newFlower = FlowerState(
        id: flowerId,
        tOnBranch: t,
        side: side,
        sizeFactor: sizeFactor,
        flowerType: math.Random().nextInt(2),
      );

      _tree = _addFlowerToBranch(_tree!, branchId, newFlower);
      _lastAddedFlowerId = flowerId; // Track for animations
      if (notify) notifyListeners();
      return true;
    } else {
      return _addRandomFlower(notify: notify);
    }
  }

  bool _addRandomFlower({bool notify = true}) {
    if (_tree == null) return false;
    
    final allBranches = _tree!.getAllBranches();
    final candidates = allBranches.where((b) => b.depth > 0).toList();
    
    if (candidates.isEmpty) return false;
    
    final random = math.Random();
    final branch = candidates[random.nextInt(candidates.length)];
    
    final t = 0.2 + random.nextDouble() * 0.8;
    final side = random.nextBool() ? 1 : -1;
    
    return addFlower(branchId: branch.id, t: t, side: side, notify: notify);
  }

  /// 4. DECAY LEAF: Starts decaying a random leaf
  bool decayLeaf({bool notify = true}) {
    if (_tree == null) return false;
    
    final allLeaves = _tree!.getAllLeaves();
    final aliveLeaves = allLeaves.where((l) => l.healthState == LeafHealthState.alive).toList();
    
    if (aliveLeaves.isEmpty) return false;
    
    final random = math.Random();
    final leafToKill = aliveLeaves[random.nextInt(aliveLeaves.length)];
    
    _tree = _updateTreeWithLeafChange(_tree!, leafToKill.id, (l) => l.copyWith(
      healthState: LeafHealthState.dead1,
      deathAge: 0,
    ));
    
    if (notify) notifyListeners();
    return true;
  }

  // Helper to update the tree structure immutably
  TreeState _updateTreeWithLeafChange(TreeState tree, String leafId, LeafState Function(LeafState) updater) {
    return tree.copyWith(
      trunk: _updateBranchWithLeafChange(tree.trunk, leafId, updater),
    );
  }

  BranchState _updateBranchWithLeafChange(BranchState branch, String leafId, LeafState Function(LeafState) updater) {
    // Check if leaf is here
    final leafIndex = branch.leaves.indexWhere((l) => l.id == leafId);
    if (leafIndex != -1) {
      final newLeaves = List<LeafState>.from(branch.leaves);
      newLeaves[leafIndex] = updater(newLeaves[leafIndex]);
      return branch.copyWith(leaves: newLeaves);
    }
    
    // Check children
    final newChildren = <BranchState>[];
    bool changed = false;
    for (final child in branch.children) {
      final newChild = _updateBranchWithLeafChange(child, leafId, updater);
      newChildren.add(newChild);
      if (newChild != child) changed = true;
    }
    
    if (changed) {
      return branch.copyWith(children: newChildren);
    }
    
    return branch;
  }

  TreeState _addLeafToBranch(TreeState tree, String branchId, LeafState leaf) {
    return tree.copyWith(
      trunk: _addLeafToBranchRecursive(tree.trunk, branchId, leaf),
    );
  }

  BranchState _addLeafToBranchRecursive(BranchState branch, String branchId, LeafState leaf) {
    if (branch.id == branchId) {
      return branch.copyWith(leaves: [...branch.leaves, leaf]);
    }
    
    final newChildren = branch.children.map((c) => _addLeafToBranchRecursive(c, branchId, leaf)).toList();
    return branch.copyWith(children: newChildren);
  }

  TreeState _addFlowerToBranch(TreeState tree, String branchId, FlowerState flower) {
    return tree.copyWith(
      trunk: _addFlowerToBranchRecursive(tree.trunk, branchId, flower),
    );
  }

  BranchState _addFlowerToBranchRecursive(BranchState branch, String branchId, FlowerState flower) {
    if (branch.id == branchId) {
      return branch.copyWith(flowers: [...branch.flowers, flower]);
    }
    
    final newChildren = branch.children.map((c) => _addFlowerToBranchRecursive(c, branchId, flower)).toList();
    return branch.copyWith(children: newChildren);
  }

  /// Calculate the screen position of a leaf or flower for animations
  /// This uses the same logic as TreePainter including wind effects and deformed positions
  Offset? calculateItemPosition(String itemId, double treeSize, {double windPhase = 0.0}) {
    if (_tree == null) return null;

    // Find the leaf or flower
    LeafState? leaf;
    FlowerState? flower;
    BranchState? branch;

    // Check if it's a leaf or flower based on ID format
    final isFlower = itemId.startsWith('flower_');

    // Find the item and its branch
    for (final b in _tree!.getAllBranches()) {
      if (isFlower) {
        flower = b.flowers.firstWhere((f) => f.id == itemId, orElse: () => const FlowerState(id: '', tOnBranch: 0, side: 0, sizeFactor: 0, flowerType: 0));
        if (flower.id.isNotEmpty) {
          branch = b;
          break;
        }
      } else {
        leaf = b.leaves.firstWhere((l) => l.id == itemId, orElse: () => const LeafState(id: '', tOnBranch: 0, side: 0, maxAge: 0, randomSizeFactor: 0));
        if (leaf.id.isNotEmpty) {
          branch = b;
          break;
        }
      }
    }

    if (branch == null || (leaf == null && flower == null)) return null;

    // Calculate deformed positions (same as TreePainter)
    final deformedStart = _calculateDeformedStart(branch, windPhase, treeSize);
    final deformedEnd = _calculateDeformedEnd(branch, deformedStart, windPhase, treeSize);
    
    // Approximate deformed control point (same logic as TreePainter)
    final originalControl = branch.controlPoint;
    final midPoint = Offset(
      (deformedStart.dx + deformedEnd.dx) / 2,
      (deformedStart.dy + deformedEnd.dy) / 2,
    );
    final deformedControl = Offset(
      originalControl.dx + (midPoint.dx - (branch.start.dx + branch.end.dx) / 2) * 0.7,
      originalControl.dy + (midPoint.dy - (branch.start.dy + branch.end.dy) / 2) * 0.7,
    );

    final t = isFlower ? flower!.tOnBranch : leaf!.tOnBranch;
    final side = isFlower ? flower!.side : leaf!.side;

    // Calculate position on deformed branch using Bezier curve
    final point = TreeGeometry.bezierPoint(deformedStart, deformedControl, deformedEnd, t);
    final tangent = TreeGeometry.bezierTangent(deformedStart, deformedControl, deformedEnd, t);
    final branchAngle = math.atan2(tangent.dy, tangent.dx);
    final perpAngle = branchAngle + math.pi / 2;
    
    // Apply wind effect at this point (same as TreePainter)
    final depthRatio = branch.depth / _parameters.maxDepth;
    final heightFactor = (treeSize - branch.start.dy) / treeSize;
    final flexibilityFactor = depthRatio;
    final windIntensity = 0.4 * heightFactor * flexibilityFactor;
    final branchPhase = windPhase + branch.start.dx * 0.005 + branch.start.dy * 0.005;
    final windAtPoint = math.sin(branchPhase + t * 2.0) * windIntensity * t * t * 0.3;
    final windOffsetX = math.cos(perpAngle) * windAtPoint * treeSize * 0.05;
    final windOffsetY = math.sin(perpAngle) * windAtPoint * treeSize * 0.05;
    
    final deformedPoint = Offset(
      point.dx + windOffsetX,
      point.dy + windOffsetY,
    );

    // Calculate thickness at this point
    final thicknessAtPoint = branch.thickness * (1.0 - t * 0.3);
    final branchRadius = thicknessAtPoint / 2;

    // Calculate item position offset from branch
    final itemPos = Offset(
      deformedPoint.dx + math.cos(perpAngle) * branchRadius * side,
      deformedPoint.dy + math.sin(perpAngle) * branchRadius * side,
    );

    return itemPos;
  }

  /// Calculate deformed start position for a branch (hierarchical, same as TreePainter)
  Offset _calculateDeformedStart(BranchState branch, double windPhase, double treeSize) {
    if (branch.depth == 0) {
      return branch.start;
    }
    
    // Find parent branch by ID structure
    final lastUnderscore = branch.id.lastIndexOf('_');
    final parentId = lastUnderscore != -1 ? branch.id.substring(0, lastUnderscore) : null;
    
    if (parentId != null) {
      // Find parent branch
      for (final b in _tree!.getAllBranches()) {
        if (b.id == parentId) {
          // Recursively calculate parent's deformed end
          final parentDeformedStart = _calculateDeformedStart(b, windPhase, treeSize);
          return _calculateDeformedEnd(b, parentDeformedStart, windPhase, treeSize);
        }
      }
    }
    
    // Fallback to original start
    return branch.start;
  }

  /// Calculate deformed end position for a branch (same as TreePainter)
  Offset _calculateDeformedEnd(BranchState branch, Offset deformedStart, double windPhase, double treeSize) {
    final depthRatio = branch.depth / _parameters.maxDepth;
    final heightFactor = (treeSize - branch.start.dy) / treeSize;
    final flexibilityFactor = depthRatio;
    final windIntensity = 0.4 * heightFactor * flexibilityFactor;
    final branchPhase = windPhase + branch.start.dx * 0.005 + branch.start.dy * 0.005;
    
    final originalDirection = branch.end - branch.start;
    final originalAngle = math.atan2(originalDirection.dy, originalDirection.dx);
    
    final t = 1.0;
    final windAtEnd = math.sin(branchPhase + t * 2.0) * windIntensity * t * t;
    
    final perpAngle = originalAngle + math.pi / 2;
    final windOffsetX = math.cos(perpAngle) * windAtEnd * treeSize * 0.05;
    final windOffsetY = math.sin(perpAngle) * windAtEnd * treeSize * 0.05;
    
    return Offset(
      deformedStart.dx + originalDirection.dx + windOffsetX,
      deformedStart.dy + originalDirection.dy + windOffsetY,
    );
  }

  /// Get position of last added leaf
  Offset? getLastLeafPosition(double treeSize, {double windPhase = 0.0}) {
    if (_lastAddedLeafId == null) return null;
    return calculateItemPosition(_lastAddedLeafId!, treeSize, windPhase: windPhase);
  }

  /// Get position of last added flower  
  Offset? getLastFlowerPosition(double treeSize, {double windPhase = 0.0}) {
    if (_lastAddedFlowerId == null) return null;
    return calculateItemPosition(_lastAddedFlowerId!, treeSize, windPhase: windPhase);
  }
}
