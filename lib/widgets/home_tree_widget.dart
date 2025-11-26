import 'package:flutter/material.dart';
import 'dart:async';
import '../l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:silva/services/database_service.dart';
import 'package:silva/models/tree/tree_parameters.dart';
import 'package:silva/services/preferences_service.dart';
import 'package:silva/services/tree_service.dart';
import 'package:silva/widgets/procedural_tree_widget.dart';
import 'package:silva/models/tree_resources.dart';
import 'package:silva/widgets/sparkle_animation.dart';

class HomeTreeWidget extends StatefulWidget {
  const HomeTreeWidget({super.key});

  @override
  State<HomeTreeWidget> createState() => _HomeTreeWidgetState();
}

class _HomeTreeWidgetState extends State<HomeTreeWidget> {
  late TreeParameters _treeParameters;
  final TreeController _treeController = TreeController();
  TreeResources _resources = TreeResources.initial();
  Timer? _resourceUpdateTimer;
  final List<SparkleData> _sparkles = [];

  @override
  void initState() {
    super.initState();
    _treeParameters = const TreeParameters(seed: 12345);
    _loadTree();
    _loadResources();
    
    // Update UI every minute to refresh cooldown states
    _resourceUpdateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _resourceUpdateTimer?.cancel();
    super.dispose();
  }

  void _loadTree() async {
    // 1. Try local storage first (fastest)
    var savedTree = await PreferencesService.getTreeState();
    
    // 2. If no local tree, try Firebase (sync)
    if (savedTree == null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        debugPrint('☁️ Checking Firebase for tree...');
        savedTree = await DatabaseService().getTreeState(user.uid);
        if (savedTree != null) {
          debugPrint('☁️ Tree found in Firebase! Saving locally...');
          await PreferencesService.saveTreeState(savedTree);
        }
      }
    }

    if (savedTree != null) {
      debugPrint('📦 Loading tree: ${savedTree.getAllBranches().length} branches');
      _treeController.setTree(savedTree);
    } else {
      debugPrint('🌱 No saved tree found (local or remote), creating new tree');
      _treeController.updateTree(
        growthLevel: 0.0,
        size: 250.0,
        parameters: _treeParameters,
        resetAge: true,
      );
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  void _loadResources() async {
    final resources = await PreferencesService.getTreeResources();
    if (mounted) {
      setState(() {
        _resources = resources;
      });
    }
  }

  void _saveTree() async {
    if (_treeController.tree != null) {
      // 1. Save locally
      await PreferencesService.saveTreeState(_treeController.tree!);
      
      // 2. Save to Firebase if logged in
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Fire and forget (don't await to block UI)
        DatabaseService().saveTreeState(user.uid, _treeController.tree!).catchError((e) {
          debugPrint('❌ Error saving tree to Firebase: $e');
        });
      }
    }
  }

  void _saveResources() async {
    await PreferencesService.saveTreeResources(_resources);
  }

  bool _isProcessing = false;

  Future<void> _handleAction(Future<void> Function() action) async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    await action();
    _saveTree();
    _saveResources();
    
    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _addSparkle(Offset position, Color color) {
    setState(() {
      _sparkles.add(SparkleData(
        position: position,
        color: color,
        timestamp: DateTime.now(),
      ));
    });

    // Remove sparkle after animation completes
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _sparkles.removeWhere((s) => 
            DateTime.now().difference(s.timestamp).inMilliseconds > 1000
          );
        });
      }
    });
  }

  void _handleLeafButton() {
    // Debug mode: always allow
    final canUse = _resources.leafCount > 0;
    
    if (!canUse) {
      // Show toast for debug mode
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🐛 Debug: Leaf count is 0 but still adding'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    _handleAction(() async {
      _treeController.addLeaf();
      
      // Get actual position of the added leaf
      final leafPos = _treeController.getLastLeafPosition(250.0);
      if (leafPos != null) {
        _addSparkle(leafPos, Colors.green);
      }
      
      // Decrement leaf count (can go negative in debug)
      setState(() {
        _resources = _resources.copyWith(leafCount: _resources.leafCount - 1);
      });
    });
  }

  void _handleWaterButton() {
    final canWater = _resources.canWater();
    
    if (!canWater) {
      final remaining = _resources.getWaterCooldownRemaining();
      final hours = remaining.inHours;
      final minutes = remaining.inMinutes % 60;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '💧 ${hours > 0 ? "$hours hour${hours > 1 ? 's' : ''} " : ""}$minutes minute${minutes != 1 ? 's' : ''} remaining',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Debug mode: still allow
      debugPrint('🐛 Debug: Water on cooldown but still allowing');
    }

    _handleAction(() async {
      _treeController.grow(); // Add +1 day of life
      
      setState(() {
        _resources = _resources.copyWith(lastWatered: DateTime.now());
      });
    });
  }

  void _handleFlowerButton() {
    final canUse = _resources.canUseFlower();
    
    if (!canUse) {
      if (_resources.flowerCount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🐛 Debug: Flower count is 0 but still adding'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        final remaining = _resources.getFlowerCooldownRemaining();
        final minutes = remaining.inMinutes;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🌸 $minutes minute${minutes != 1 ? 's' : ''} remaining'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }

    _handleAction(() async {
      _treeController.addFlower();
      
      // Get actual position of the added flower
      final flowerPos = _treeController.getLastFlowerPosition(250.0);
      if (flowerPos != null) {
        _addSparkle(flowerPos, Colors.pink);
      }
      
      // Decrement flower count and update cooldown
      setState(() {
        _resources = _resources.copyWith(
          flowerCount: _resources.flowerCount - 1,
          lastFlowerUsed: DateTime.now(),
        );
      });
    });
  }

  void _handleResetTree() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Tree'),
        content: const Text('Reset tree to age 5 with no leaves or flowers?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleAction(() async {
                _treeController.updateTree(
                  growthLevel: 0.05,
                  size: 250.0,
                  parameters: const TreeParameters(),
                  resetAge: false,
                  forceRegenerate: true,
                );
                // Manually set age to 5
                if (_treeController.tree != null) {
                  _treeController.setTree(
                    _treeController.tree!.copyWith(age: 5),
                  );
                }
              });
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_treeController.tree == null) {
      return const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Get current flower count (handles time-based regeneration)
    final currentFlowerCount = _resources.getCurrentFlowerCount();

    return SizedBox(
      height: 250,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: ProceduralTreeWidget(
              size: 250,
              growthLevel: _treeController.tree?.getGrowthLevel() ?? 0.0,
              parameters: _treeParameters,
              controller: _treeController,
            ),
          ),
          // Sparkle animations
          ..._sparkles.map((sparkle) => SparkleAnimation(
            position: sparkle.position,
            color: sparkle.color,
          )),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.info_outline, size: 20, color: Colors.grey),
              onPressed: _showTreeInfo,
              tooltip: 'Infos arbre',
            ),
          ),
          // Resource buttons
          Positioned(
            right: 16,
            top: 40,
            child: Column(
              children: [
                _buildResourceButton(
                  icon: Icons.eco,
                  label: 'Leaf',
                  count: _resources.leafCount,
                  color: Colors.green,
                  isAvailable: _resources.leafCount > 0,
                  onTap: _handleLeafButton,
                ),
                const SizedBox(height: 6),
                _buildResourceButton(
                  icon: Icons.water_drop,
                  label: 'Water',
                  count: null, // No counter for water
                  color: Colors.blue,
                  isAvailable: _resources.canWater(),
                  onTap: _handleWaterButton,
                ),
                const SizedBox(height: 6),
                _buildResourceButton(
                  icon: Icons.local_florist,
                  label: 'Flower',
                  count: currentFlowerCount,
                  color: Colors.pink,
                  isAvailable: _resources.canUseFlower(),
                  onTap: _handleFlowerButton,
                ),
                const SizedBox(height: 12),
                // Reset button
                _buildDebugButton(
                  icon: Icons.refresh,
                  label: 'Reset',
                  color: Colors.red,
                  onTap: _handleResetTree,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceButton({
    required IconData icon,
    required String label,
    required int? count,
    required Color color,
    required bool isAvailable,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isAvailable 
                ? Colors.white.withValues(alpha: 0.9) 
                : Colors.grey.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  icon,
                  color: isAvailable ? color : Colors.grey,
                  size: 24,
                ),
              ),
              if (count != null)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebugButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
      ),
    );
  }

  void _showTreeInfo() {
    final tree = _treeController.tree;
    if (tree == null) return;

    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: const Text('🌳'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${l10n.treeInfo1}\n'
                '${l10n.treeInfo2}\n'
                '${l10n.treeInfo3}\n'
                '\n'
                '${l10n.treeAge(tree.age)}\n'
                '${l10n.treeBranches(tree.getAllBranches().length)}\n'
                '${l10n.treeLeaves(tree.getAllLeaves().length)}\n'
                '${l10n.treeFlowers(tree.getAllFlowers().length)}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class SparkleData {
  final Offset position;
  final Color color;
  final DateTime timestamp;

  SparkleData({
    required this.position,
    required this.color,
    required this.timestamp,
  });
}
