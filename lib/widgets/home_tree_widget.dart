import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import '../l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:silva/services/database_service.dart';
import 'package:silva/models/tree/tree_parameters.dart';
import 'package:silva/services/preferences_service.dart';
import 'package:silva/services/tree_service.dart';
import 'package:silva/widgets/procedural_tree_widget.dart';
import 'package:silva/models/tree_resources.dart';
import 'package:silva/widgets/sparkle_animation.dart';
import 'package:silva/models/tree/tree_state.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final GlobalKey<ProceduralTreeWidgetState> _treeWidgetKey = GlobalKey<ProceduralTreeWidgetState>();
  final GlobalKey _treeContainerKey = GlobalKey();
  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _shareableTreeKey = GlobalKey();
  final GlobalKey _shareButtonKey = GlobalKey();

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
    debugPrint('🍃 Leaf button clicked');
    // Debug mode: always allow
    final canUse = _resources.canUseLeaf();
    
    if (!canUse) {
      debugPrint('❌ Leaf button disabled (cooldown or no resources)');
      return;
    }

    _handleAction(() async {
      _treeController.addLeaf();
      debugPrint('✅ Leaf added to tree');
      
      // Get actual position of the added leaf with current wind phase
      final windPhase = _treeWidgetKey.currentState?.currentWindPhase ?? 0.0;
      final leafPos = _treeController.getLastLeafPosition(250.0, windPhase: windPhase);
      if (leafPos != null && mounted) {
        // Convert tree coordinates to Stack coordinates using render box
        final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
        final treeWidgetBox = _treeWidgetKey.currentContext?.findRenderObject() as RenderBox?;
        if (stackBox != null && treeWidgetBox != null) {
          // Get the tree widget's position relative to the Stack
          final treeWidgetGlobalPos = treeWidgetBox.localToGlobal(Offset.zero);
          final stackGlobalPos = stackBox.localToGlobal(Offset.zero);
          final treeOffset = treeWidgetGlobalPos - stackGlobalPos;
          
          // Convert tree coordinates (relative to tree widget) to Stack coordinates
          final stackPos = treeOffset + leafPos;
          _addSparkle(stackPos, Colors.green);
        } else {
          // Fallback to manual calculation
          final screenWidth = MediaQuery.of(context).size.width;
          final treeSize = 250.0;
          final stackPos = Offset(
            screenWidth / 2 - treeSize / 2 + leafPos.dx,
            leafPos.dy,
          );
          _addSparkle(stackPos, Colors.green);
        }
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
    debugPrint('💧 Water button clicked');
    final canWater = _resources.canWater();
    
    if (!canWater) {
      debugPrint('❌ Water button disabled (cooldown)');
      return;
    }

    _handleAction(() async {
      _treeController.grow(); // Add +1 day of life
      debugPrint('✅ Tree watered (Day added)');
      
      // Add sparkle at the base of the trunk (lower side)
      if (mounted) {
        final screenWidth = MediaQuery.of(context).size.width;
        final treeSize = 250.0;
        // Trunk base is at treeSize * 0.75 = 187.5, centered horizontally
        final trunkBaseY = treeSize * 0.75;
        _addSparkle(Offset(screenWidth / 2, trunkBaseY), Colors.blue);
      }
      
      setState(() {
        _resources = _resources.copyWith(lastWatered: DateTime.now());
      });
    });
  }

  void _handleFlowerButton() {
    debugPrint('🌸 Flower button clicked');
    final canUse = _resources.canUseFlower();
    
    if (!canUse) {
      debugPrint('❌ Flower button disabled (cooldown or no resources)');
      return;
    }

    _handleAction(() async {
      _treeController.addFlower();
      debugPrint('✅ Flower added to tree');
      
      // Get actual position of the added flower with current wind phase
      final windPhase = _treeWidgetKey.currentState?.currentWindPhase ?? 0.0;
      final flowerPos = _treeController.getLastFlowerPosition(250.0, windPhase: windPhase);
      if (flowerPos != null && mounted) {
        // Convert tree coordinates to Stack coordinates using render box
        final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
        final treeWidgetBox = _treeWidgetKey.currentContext?.findRenderObject() as RenderBox?;
        if (stackBox != null && treeWidgetBox != null) {
          // Get the tree widget's position relative to the Stack
          final treeWidgetGlobalPos = treeWidgetBox.localToGlobal(Offset.zero);
          final stackGlobalPos = stackBox.localToGlobal(Offset.zero);
          final treeOffset = treeWidgetGlobalPos - stackGlobalPos;
          
          // Convert tree coordinates (relative to tree widget) to Stack coordinates
          final stackPos = treeOffset + flowerPos;
          _addSparkle(stackPos, Colors.pink);
        } else {
          // Fallback to manual calculation
          final screenWidth = MediaQuery.of(context).size.width;
          final treeSize = 250.0;
          final stackPos = Offset(
            screenWidth / 2 - treeSize / 2 + flowerPos.dx,
            flowerPos.dy,
          );
          _addSparkle(stackPos, Colors.pink);
        }
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
        content: const Text('Reset tree to age 10 with no leaves or flowers?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleAction(() async {
                // Reset tree to age 10 with no leaves or flowers
                // Use forceRegenerate to get a fresh tree, then set age to 10
                _treeController.updateTree(
                  growthLevel: 0.10, // Growth level for age 10
                  size: 250.0,
                  parameters: const TreeParameters(),
                  resetAge: false, // We'll set age manually
                  forceRegenerate: true, // This creates a fresh tree without leaves/flowers
                );
                // Manually set age to 10 and ensure all leaves and flowers are cleared
                if (_treeController.tree != null) {
                  final clearedTree = _clearAllLeavesAndFlowers(_treeController.tree!);
                  _treeController.setTree(
                    clearedTree.copyWith(age: 10),
                  );
                }
                // Reset resources to 0 leaves and 0 flowers
                setState(() {
                  _resources = _resources.copyWith(
                    leafCount: 0,
                    flowerCount: 0,
                  );
                });
              });
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  /// Helper method to recursively clear all leaves and flowers from the tree
  TreeState _clearAllLeavesAndFlowers(TreeState tree) {
    return tree.copyWith(
      trunk: _clearBranchLeavesAndFlowers(tree.trunk),
    );
  }

  BranchState _clearBranchLeavesAndFlowers(BranchState branch) {
    final clearedChildren = branch.children
        .map((child) => _clearBranchLeavesAndFlowers(child))
        .toList();
    
    return branch.copyWith(
      leaves: const [],
      flowers: const [],
      children: clearedChildren,
    );
  }

  /// Callback when a button cooldown finishes
  void _onCooldownFinished() {
    // Add a small delay to ensure the cooldown time has definitely passed
    // relative to the initial timestamp check.
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() {
          // Just rebuild to refresh the 'isAvailable' state
        });
      }
    });
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
      key: _stackKey,
      height: 280, // Reduced height to remove gap
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Hidden shareable tree (with branding) - Positioned off-screen
          Transform.translate(
            offset: const Offset(-10000, -10000),
            child: RepaintBoundary(
              key: _shareableTreeKey,
              child: _ShareableTreeContent(
                treeWidget: ProceduralTreeWidget(
                  key: ValueKey('shareable_${_treeWidgetKey}'),
                  size: 250,
                  growthLevel: _treeController.tree?.getGrowthLevel() ?? 0.0,
                  parameters: _treeParameters,
                  controller: _treeController,
                ),
              ),
            ),
          ),

          // Tree centered
          Positioned(
            key: _treeContainerKey,
            top: 0,
            left: 0,
            right: 0,
            height: 250,
            child: Center(
              child: ProceduralTreeWidget(
                key: _treeWidgetKey,
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
          
          // Share Button (Top Right)
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              key: _shareButtonKey,
              icon: const Icon(Icons.share_rounded, size: 20, color: Colors.grey),
              onPressed: _shareTree,
              tooltip: 'Partager',
            ),
          ),
          
          // Info Button (Below Share Button)
          Positioned(
            top: 40,
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
            top: 100,
            left: 20,
            child: CooldownButton(
              emoji: '🍃',
              label: 'Leaf',
              count: _resources.leafCount,
              color: Colors.green,
              isAvailable: _resources.canUseLeaf(),
              remainingCooldown: _resources.getLeafCooldownRemaining(),
              totalCooldown: const Duration(milliseconds: 500),
              onTap: _handleLeafButton,
              onCooldownFinished: _onCooldownFinished,
            ),
          ),

          // Flower Button (Right of Tree)
          Positioned(
            top: 100,
            right: 20,
            child: CooldownButton(
              emoji: '🌸',
              label: 'Flower',
              count: currentFlowerCount,
              color: Colors.pink,
              isAvailable: _resources.canUseFlower(),
              remainingCooldown: _resources.getFlowerCooldownRemaining(),
              totalCooldown: const Duration(milliseconds: 500),
              onTap: _handleFlowerButton,
              onCooldownFinished: _onCooldownFinished,
            ),
          ),

          // Water Button (Below Tree)
          Positioned(
            bottom: 50, // Moved up further
            left: 0,
            right: 0,
            child: Center(
              child: CooldownButton(
                emoji: '💧',
                label: 'Water',
                count: null,
                color: Colors.blue,
                isAvailable: _resources.canWater(),
                remainingCooldown: _resources.getWaterCooldownRemaining(),
                totalCooldown: const Duration(milliseconds: 500),
                onTap: _handleWaterButton,
                onCooldownFinished: _onCooldownFinished,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareTree() async {
    try {
      // Ensure the widget is built and rendered
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Find the render boundary
      final boundary = _shareableTreeKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        debugPrint('Share boundary not found');
        return;
      }

      // Capture image
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        debugPrint('Failed to convert image to byte data');
        return;
      }

      final pngBytes = byteData.buffer.asUint8List();

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/tree.png').create();
      await file.writeAsBytes(pngBytes);

      // Get the share button position for iOS/macOS
      final RenderBox? shareButtonBox = _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
      Rect? sharePositionOrigin;
      if (shareButtonBox != null) {
        final sharePosition = shareButtonBox.localToGlobal(Offset.zero);
        final shareSize = shareButtonBox.size;
        sharePositionOrigin = Rect.fromLTWH(
          sharePosition.dx,
          sharePosition.dy,
          shareSize.width,
          shareSize.height,
        );
      }

      // Share with Silva branding
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Mon arbre de croissance 🌳✨ #Silva',
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      debugPrint('Error sharing tree: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du partage: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
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
              onPressed: () {
                setState(() {
                  _resources = _resources.copyWith(
                    leafCount: _resources.leafCount + 10,
                    flowerCount: _resources.flowerCount + 10,
                  );
                });
                _saveResources();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added 10 leaves and 10 flowers (Debug)')),
                );
              },
              child: const Text('+10 Resources (Debug)'),
            ),
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
  final String emoji;
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
    required this.emoji,
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
    const double buttonSize = 45.0;
    const double emojiSize = 24.0;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Main Button Background (Flat Circle)
        Tooltip(
          message: label,
          child: Material(
            color: Colors.white,
            elevation: 2,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: isAvailable ? () {
                debugPrint('🔘 CooldownButton tapped: $label');
                onTap();
              } : () {
                debugPrint('🚫 CooldownButton tapped but disabled: $label');
              },
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: buttonSize,
                height: buttonSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Emoji
                    Text(
                      emoji,
                      style: TextStyle(fontSize: emojiSize),
                    ),
                    
                    // Radial sweep overlay (only when on cooldown)
                    if (!isAvailable)
                      CustomPaint(
                        size: Size(buttonSize, buttonSize),
                        painter: CooldownSweepPainter(progress: progress, color: color),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Count badge (Bottom Right)
        if (count != null)
          Positioned(
            bottom: 0,
            right: 0,
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
  final Color color;

  CooldownSweepPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate sweep angle (0 = ready, 2π = full cooldown)
    final sweepAngle = (1.0 - progress) * 2 * 3.14159265359; // 2π radians

    if (sweepAngle > 0) {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.8) // Semi-transparent white overlay to "grey out"
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
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// Widget for shareable tree with Silva branding
class _ShareableTreeContent extends StatelessWidget {
  final Widget treeWidget;

  const _ShareableTreeContent({
    required this.treeWidget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: 400,
      height: 500,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Tree - reduced size to fit
          Flexible(
            child: SizedBox(
              width: 280,
              height: 280,
              child: Center(child: treeWidget),
            ),
          ),
          const SizedBox(height: 20),
          // Decorative Divider
          Container(
            width: 40,
            height: 2,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          // Branding
          Text(
            "Silva",
            style: GoogleFonts.greatVibes(
              fontSize: 28,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Mon arbre de croissance",
            style: GoogleFonts.inter(
              fontSize: 12,
              letterSpacing: 1,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
