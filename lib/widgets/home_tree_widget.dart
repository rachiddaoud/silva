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
  // Removed global timer: _resourceUpdateTimer
  final List<SparkleData> _sparkles = [];

  @override
  void initState() {
    super.initState();
    _treeParameters = const TreeParameters(seed: 12345);
    _loadTree();
    _loadResources();
  }

  @override
  void dispose() {
    // No timer to cancel
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
    
    try {
      await action();
      _saveTree();
      _saveResources();
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
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
    final canUse = _resources.canUseLeaf();
    
    if (!canUse) return;

    _handleAction(() async {
      _treeController.addLeaf();
      
      // Get actual position of the added leaf
      final leafPos = _treeController.getLastLeafPosition(250.0);
      if (leafPos != null) {
        _addSparkle(leafPos, Colors.green);
      }
      
      // Decrement leaf count and update cooldown
      setState(() {
        _resources = _resources.copyWith(
          leafCount: _resources.leafCount - 1,
          lastLeafUsed: DateTime.now(),
        );
      });
    });
  }

  void _handleWaterButton() {
    final canWater = _resources.canWater();
    
    if (!canWater) return;

    _handleAction(() async {
      _treeController.grow(); // Add +1 day of life
      
      setState(() {
        _resources = _resources.copyWith(lastWatered: DateTime.now());
      });
    });
  }

  void _handleFlowerButton() {
    final canUse = _resources.canUseFlower();
    
    if (!canUse) return;

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

  /// Callback when a button cooldown finishes
  void _onCooldownFinished() {
    if (mounted) {
      setState(() {
        // Just rebuild to refresh the 'isAvailable' state
      });
    }
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
      height: 350, // Increased height to accommodate bottom button
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Tree centered
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 250,
            child: Center(
              child: ProceduralTreeWidget(
                size: 250,
                growthLevel: _treeController.tree?.getGrowthLevel() ?? 0.0,
                parameters: _treeParameters,
                controller: _treeController,
              ),
            ),
          ),
          ..._sparkles.map((sparkle) => SparkleAnimation(
            position: sparkle.position,
            color: sparkle.color,
          )),
          
          // Info Button (Top Right)
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.info_outline, size: 20, color: Colors.grey),
              onPressed: _showTreeInfo,
              tooltip: 'Infos arbre',
            ),
          ),
          
          // Reset Button (Top Left)
          Positioned(
            top: 0,
            left: 0,
            child: IconButton(
              icon: const Icon(Icons.refresh, size: 20, color: Colors.grey),
              onPressed: _handleResetTree,
              tooltip: 'Reset',
            ),
          ),

          // --- Action Buttons ---

          // Leaf Button (Left of Tree)
          Positioned(
            bottom: 80,
            left: 20,
            child: CooldownButton(
              imagePath: 'assets/tree/leaf.png',
              label: 'Leaf',
              count: _resources.leafCount,
              color: Colors.green,
              isAvailable: _resources.canUseLeaf(),
              remainingCooldown: _resources.getLeafCooldownRemaining(),
              totalCooldown: const Duration(seconds: 5),
              onTap: _handleLeafButton,
              onCooldownFinished: _onCooldownFinished,
            ),
          ),

          // Flower Button (Right of Tree)
          Positioned(
            bottom: 80,
            right: 20,
            child: CooldownButton(
              imagePath: 'assets/tree/flower.png',
              label: 'Flower',
              count: currentFlowerCount,
              color: Colors.pink,
              isAvailable: _resources.canUseFlower(),
              remainingCooldown: _resources.getFlowerCooldownRemaining(),
              totalCooldown: const Duration(seconds: 5),
              onTap: _handleFlowerButton,
              onCooldownFinished: _onCooldownFinished,
            ),
          ),

          // Water Button (Below Tree)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Center(
              child: CooldownButton(
                imagePath: null, // Use icon for water
                icon: Icons.water_drop,
                label: 'Water',
                count: null,
                color: Colors.blue,
                isAvailable: _resources.canWater(),
                remainingCooldown: _resources.getWaterCooldownRemaining(),
                totalCooldown: const Duration(seconds: 5),
                onTap: _handleWaterButton,
                onCooldownFinished: _onCooldownFinished,
              ),
            ),
          ),
        ],
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

class CooldownButton extends StatelessWidget {
  final String? imagePath;
  final IconData? icon;
  final String label;
  final int? count;
  final Color color;
  final bool isAvailable;
  final Duration remainingCooldown;
  final Duration totalCooldown;
  final VoidCallback onTap;
  final VoidCallback? onCooldownFinished;

  const CooldownButton({
    super.key,
    this.imagePath,
    this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.isAvailable,
    required this.remainingCooldown,
    required this.totalCooldown,
    required this.onTap,
    this.onCooldownFinished,
  });

  @override
  Widget build(BuildContext context) {
    // If available, show static full button
    if (isAvailable) {
      return _buildButtonContent(1.0);
    }

    // If cooldown, animate from current progress to 1.0
    final double initialProgress = 1.0 - (remainingCooldown.inMilliseconds / totalCooldown.inMilliseconds).clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      key: ValueKey(isAvailable), // Force recreation when availability changes
      tween: Tween(begin: initialProgress, end: 1.0),
      duration: remainingCooldown,
      onEnd: onCooldownFinished,
      builder: (context, value, child) {
        return _buildButtonContent(value);
      },
    );
  }

  Widget _buildButtonContent(double progress) {
    const double buttonSize = 50.0;
    const double imageSize = 40.0; // Larger image

    return Stack(
      clipBehavior: Clip.none, // Allow overflowing image and badge
      alignment: Alignment.center,
      children: [
        // Main Button Background (Circle)
        Tooltip(
          message: label,
          child: Material(
            color: Colors.black.withValues(alpha: 0.3), // Dark transparent interior
            shape: CircleBorder(
              side: BorderSide(
                color: color.withValues(alpha: 0.5), // Subtle border
                width: 1,
              ),
            ),
            child: InkWell(
              onTap: isAvailable ? onTap : null,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: buttonSize,
                height: buttonSize,
                child: Stack(
                  children: [
                    // Radial sweep overlay (only when on cooldown)
                    if (!isAvailable)
                      CustomPaint(
                        size: const Size(buttonSize, buttonSize),
                        painter: CooldownSweepPainter(progress: progress),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // Overflowing Image/Icon (Placed on top, ignoring hits if needed, but we want it to look part of button)
        // Since it's on top of InkWell, we should wrap it in IgnorePointer so clicks go through to InkWell?
        // Or wrap InkWell around everything?
        // If we wrap InkWell around everything, the ripple will be square or large.
        // Let's keep InkWell on the circle, and put Image on top. 
        // If Image is larger, clicks on the overflowing part won't trigger InkWell unless we expand InkWell.
        // For now, let's assume user clicks the circle.
        IgnorePointer(
          child: Center(
            child: imagePath != null
                ? Image.asset(
                    imagePath!,
                    width: imageSize, 
                    height: imageSize,
                    fit: BoxFit.contain,
                  )
                : Icon(
                    icon ?? Icons.help,
                    color: color, // Use button color for icon
                    size: 30,
                  ),
          ),
        ),

        // Count badge (Bottom Right)
        if (count != null)
          Positioned(
            bottom: -5,
            right: -5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              constraints: const BoxConstraints(minWidth: 18),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

/// Custom painter for RPG-style radial sweep cooldown overlay
class CooldownSweepPainter extends CustomPainter {
  final double progress; // 0.0 = full cooldown, 1.0 = ready

  CooldownSweepPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate sweep angle (0 = ready, 2π = full cooldown)
    final sweepAngle = (1.0 - progress) * 2 * 3.14159265359; // 2π radians

    if (sweepAngle > 0) {
      final paint = Paint()
        ..color = Colors.black.withValues(alpha: 0.6) // Semi-transparent dark overlay
        ..style = PaintingStyle.fill;

      final center = Offset(size.width / 2, size.height / 2);
      final radius = size.width / 2;

      // Draw arc starting from the current progress point and sweeping to the top
      // This creates a "wiper" effect that clears clockwise
      
      final startAngle = -3.14159265359 / 2 + (progress * 2 * 3.14159265359);
       canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle, 
        true,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CooldownSweepPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
