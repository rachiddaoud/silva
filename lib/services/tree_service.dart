import 'package:flutter/foundation.dart';
import 'package:ma_bulle/models/day_entry.dart';
import 'package:ma_bulle/models/tree/tree_parameters.dart';
import 'package:ma_bulle/models/tree/tree_state.dart';
import 'package:ma_bulle/logic/tree_logic.dart';
import 'dart:math' as math;

/// Controller to manage tree state and interactions
class TreeController extends ChangeNotifier {
  TreeState? _tree;
  TreeState? get tree => _tree;


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
    // If loaded from JSON, we generally want to keep the structure unless:
    // 1. forceRegenerate is true (explicit reset)
    // 2. growthLevel has changed (tree is growing)
    // 3. parameters have changed
    
    // However, we must be careful not to reset a complex tree to a simple one just because of a reload.
    // But here, updateTree is called by the widget when parameters/growth change.
    
    final existingLeaves = _tree?.getAllLeaves() ?? [];
    final existingFlowers = _tree?.getAllFlowers() ?? [];
    final oldAge = _tree?.age ?? 0;
    
    _tree = TreeGenerator.generateTree(
      growthLevel: growthLevel,
      treeSize: size,
      parameters: parameters,
      treeAge: resetAge ? 0 : oldAge,
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
  Map<String, int> simulateDay(DayEntry? entry) {
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

    if (entry != null) {
      // 2. Victories -> Leaves
      final victories = entry.victoryCards.where((v) => v.isAccomplished).length;
      for (int i = 0; i < victories; i++) {
        if (addLeaf()) {
          stats['leavesAdded'] = (stats['leavesAdded'] ?? 0) + 1;
        }
      }

      // 3. Emotions
      if (entry.emotion != null) {
        final emotionLabel = entry.emotion!.name.toLowerCase();
        
        if (['joyeux', 'fier', 'paisible', 'excité', 'joyful', 'proud', 'peaceful', 'excited'].contains(emotionLabel)) {
           if (addFlower()) {
             stats['flowersAdded'] = (stats['flowersAdded'] ?? 0) + 1;
           }
        } 
        else if (['triste', 'anxieux', 'en colère', 'fatigué', 'sad', 'anxious', 'angry', 'tired'].contains(emotionLabel)) {
           if (decayLeaf()) {
             stats['deadLeavesAdded'] = (stats['deadLeavesAdded'] ?? 0) + 1;
           }
        }
      }
    }
    
    notifyListeners();
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
        age: 0, // Start at age 0
        maxAge: maxAge,
        randomSizeFactor: 0.8 + math.Random().nextDouble() * 0.4,
        currentGrowth: 0.0, // Start at size 0
        healthState: LeafHealthState.alive,
      );

      _tree = _addLeafToBranch(_tree!, branchId, newLeaf);
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
  bool addFlower({String? branchId, double? t, int? side}) {
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
        // Flowers might need age/growth too if we want them to grow
        // Assuming FlowerState has no age currently, but if we want it to grow, we should add it.
        // For now, we'll just add it. If the user wants flower growth, we need to update FlowerState.
      );

      _tree = _addFlowerToBranch(_tree!, branchId, newFlower);
      notifyListeners();
      return true;
    } else {
      return _addRandomFlower();
    }
  }

  bool _addRandomFlower() {
    if (_tree == null) return false;
    
    final allBranches = _tree!.getAllBranches();
    final candidates = allBranches.where((b) => b.depth > 0).toList();
    
    if (candidates.isEmpty) return false;
    
    final random = math.Random();
    final branch = candidates[random.nextInt(candidates.length)];
    
    final t = 0.2 + random.nextDouble() * 0.8;
    final side = random.nextBool() ? 1 : -1;
    
    return addFlower(branchId: branch.id, t: t, side: side);
  }

  /// 4. DECAY LEAF: Starts decaying a random leaf
  bool decayLeaf() {
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
    
    notifyListeners();
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
}
