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
  final int victoryCount;

  const HomeTreeWidget({
    super.key,
    required this.victoryCount,
  });

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
  bool _isDebugUnlimited = false;

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

  @override
  void didUpdateWidget(HomeTreeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload resources and tree state when widget updates (e.g., when victory count changes)
    // This ensures the leaf counter and tree state are updated when a victory is checked or deleted
    if (oldWidget.victoryCount != widget.victoryCount) {
      _loadResources();
      // Also reload tree state in case leaves were removed
      _loadTree();
      // Check if daily progress triggers streak/growth
      _checkDailyProgress();
    }
  }

  /// Public method to refresh resources (can be called from parent)
  void refreshResources() {
    _loadResources();
  }

  /// Public method to refresh tree state (can be called from parent)
  void refreshTree() {
    _loadTree();
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
    debugPrint('📖 LOADED RESOURCES: $resources');
    if (mounted) {
      // Use addPostFrameCallback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _resources = resources;
          });
        }
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
    debugPrint('💾 SAVING RESOURCES: $_resources');
    await PreferencesService.saveTreeResources(_resources);
    debugPrint('💾 RESOURCES SAVED');
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
    final canUse = _isDebugUnlimited || _resources.canUseLeaf();
    
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

  /// Automatically check and update streak when user has 1+ victory today
  void _checkDailyProgress() {
    if (widget.victoryCount < 1) return; // Need at least 1 victory
    
    final now = DateTime.now();
    final lastUpdate = _resources.lastStreakUpdate;
    
    // Check if already updated today
    if (lastUpdate != null) {
      final wasToday = lastUpdate.year == now.year &&
                       lastUpdate.month == now.month &&
                       lastUpdate.day == now.day;
      if (wasToday) return; // Already processed today
    }
    
    debugPrint('🌱 AUTO GROWTH: Checking daily progress...');
    debugPrint('🌱 AUTO GROWTH: Victory count = ${widget.victoryCount}');
    
    _handleAction(() async {
      // Grow tree by one day
      _treeController.grow();
      debugPrint('✅ Tree grew by one day');
      
      // Update Streak Logic
      int newStreak = _resources.streak;
      bool resetClaimedFlowers = false;
      
      if (lastUpdate == null) {
        // First time ever
        newStreak = 1;
        debugPrint('🔍 STREAK: First time, setting streak to 1');
      } else {
        final yesterday = now.subtract(const Duration(days: 1));
        final wasYesterday = lastUpdate.year == yesterday.year && 
                             lastUpdate.month == yesterday.month && 
                             lastUpdate.day == yesterday.day;
        
        if (wasYesterday) {
          // Consecutive day
          newStreak++;
          debugPrint('🔍 STREAK: Consecutive day, now at $newStreak');
        } else {
          // Missed a day or more
          newStreak = 1;
          resetClaimedFlowers = true;
          debugPrint('🔍 STREAK: Missed day(s), resetting to 1');
        }
      }
      
      // Award flower for daily streak
      final newFlowerCount = _resources.flowerCount + 1;
      
      if (mounted) {
        // Show growth feedback
        final screenWidth = MediaQuery.of(context).size.width;
        final treeSize = 250.0;
        final trunkBaseY = treeSize * 0.75;
        _addSparkle(Offset(screenWidth / 2, trunkBaseY), Colors.green);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.wateredStreakFlower(newStreak))),
        );
      }
      
      setState(() {
        _resources = _resources.copyWith(
          lastStreakUpdate: now,
          streak: newStreak,
          flowerCount: newFlowerCount,
          // Only reset milestones when streak is lost
          lastClaimed7DayMilestone: resetClaimedFlowers ? 0 : null,
          lastClaimed30DayMilestone: resetClaimedFlowers ? 0 : null,
        );
      });
      
      // Check for special flower unlock (7 or 30 day milestone)
      if (newStreak == 7 || newStreak == 30) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('🎉'),
              content: Text(AppLocalizations.of(context)!.specialFlowerUnlocked),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.close),
                ),
              ],
            ),
          );
        }
      }
      
      debugPrint('🌱 AUTO GROWTH: Complete. Streak = $newStreak');
    });
  }

  void _handleFlowerButton() {
    debugPrint('🌸 Flower button clicked');
    
    if (!_isDebugUnlimited && _resources.isFlowerUsedToday()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.alreadyAddedFlowerToday)),
      );
      return;
    }
    
    final canUse = _isDebugUnlimited || _resources.canUseFlower();
    
    if (!canUse) {
      debugPrint('❌ Flower button disabled (cooldown)');
      return;
    }

    // Determine flower type based on streak and available special flowers
    int flowerType;
    int? newMilestone7;
    int? newMilestone30;
    
    if (_resources.hasSpecial30DayFlower) {
      flowerType = 3; // Yellow
      newMilestone30 = _resources.current30DayMilestone;
    } else if (_resources.hasSpecial7DayFlower) {
      flowerType = 2; // Blue
      newMilestone7 = _resources.current7DayMilestone;
    } else {
      flowerType = DateTime.now().millisecond % 2; // 0 or 1 (Pink or White)
    }

    _handleAction(() async {
      _treeController.addFlower(flowerType: flowerType);
      debugPrint('✅ Flower added to tree (Type: $flowerType)');
      
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
          
          Color sparkleColor;
          switch (flowerType) {
            case 2: sparkleColor = Colors.blue; break;
            case 3: sparkleColor = Colors.yellow; break;
            case 1: sparkleColor = Colors.white; break;
            default: sparkleColor = Colors.pink;
          }
          _addSparkle(stackPos, sparkleColor);
        } else {
          // Fallback to manual calculation
          final screenWidth = MediaQuery.of(context).size.width;
          final treeSize = 250.0;
          final stackPos = Offset(
            screenWidth / 2 - treeSize / 2 + flowerPos.dx,
            flowerPos.dy,
          );
          
          Color sparkleColor;
          switch (flowerType) {
            case 2: sparkleColor = Colors.blue; break;
            case 3: sparkleColor = Colors.yellow; break;
            case 1: sparkleColor = Colors.white; break;
            default: sparkleColor = Colors.pink;
          }
          _addSparkle(stackPos, sparkleColor);
        }
      }
      
      // Update cooldown and claim milestones
      setState(() {
        _resources = _resources.copyWith(
          lastFlowerUsed: DateTime.now(),
          lastClaimed7DayMilestone: newMilestone7,
          lastClaimed30DayMilestone: newMilestone30,
        );
      });
    });
  }

  void _handleResetTree() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.resetTreeTitle),
        content: Text(AppLocalizations.of(context)!.resetTreeConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
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
                // Reset resources to 0 leaves and 0 flowers, and reset flower usage
                setState(() {
                  _resources = _resources.copyWith(
                    leafCount: 0,
                    flowerCount: 0,
                    lastFlowerUsed: null,
                  );
                });
              });
            },
            child: Text(AppLocalizations.of(context)!.reset),
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

  /// Get message for when leaf button will be available
  String? _getLeafDisabledMessage() {
    if (_resources.leafCount <= 0) {
      return AppLocalizations.of(context)!.noLeavesAvailable;
    }
    final remaining = _resources.getLeafCooldownRemaining();
    if (remaining.inMilliseconds > 0) {
      final seconds = (remaining.inMilliseconds / 1000).ceil();
      return 'Leaf button available in $seconds second${seconds != 1 ? 's' : ''}';
    }
    return null;
  }



  /// Get message for when flower button will be available
  String? _getFlowerDisabledMessage() {
    if (_resources.isFlowerUsedToday()) {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final timeUntil = tomorrow.difference(now);
      final hours = timeUntil.inHours;
      final minutes = timeUntil.inMinutes % 60;
      if (hours > 0) {
        return AppLocalizations.of(context)!.alreadyFlowerAvailableIn(hours, minutes);
      } else {
        return AppLocalizations.of(context)!.alreadyFlowerAvailableInMinutes(minutes);
      }
    }
    final remaining = _resources.getFlowerCooldownRemaining();
    if (remaining.inMilliseconds > 0) {
      final seconds = (remaining.inMilliseconds / 1000).ceil();
      return 'Flower button available in $seconds second${seconds != 1 ? 's' : ''}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the original build content with a Stack to add the FAB
    return Stack(
      children: [
        _buildTreeContent(context),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            onPressed: _showDebugDialog,
            child: const Icon(Icons.bug_report),
          ),
        ),
      ],
    );
  }

  Widget _buildTreeContent(BuildContext context) {
    if (_treeController.tree == null) {
      return const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Get theme colors
    // Get theme colors
    final theme = Theme.of(context);
    // primaryColor removed as it was only used for water button
    final secondaryColor = theme.colorScheme.secondary;
    final tertiaryColor = theme.colorScheme.tertiary;


    
    // Check flower availability (once per day)
    final bool canUseFlower = _isDebugUnlimited || _resources.canUseFlower();
    
    // Determine next flower type for button icon
    String flowerEmoji = '🌸';
    String? flowerImagePath;
    Color flowerButtonColor = canUseFlower ? secondaryColor : Colors.grey;
    
    if (_resources.hasSpecial30DayFlower) {
      flowerEmoji = '🌼'; // Yellow flower representation
      flowerImagePath = 'assets/tree/yellow.png';
      flowerButtonColor = canUseFlower ? Colors.yellow : Colors.grey;
    } else if (_resources.hasSpecial7DayFlower) {
      flowerEmoji = '💠'; // Blue flower representation
      flowerImagePath = 'assets/tree/blue.png';
      flowerButtonColor = canUseFlower ? Colors.blue : Colors.grey;
    }

    return SizedBox(
      key: _stackKey,
      height: 280, // Reduced height to reduce margin
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
          
          // Streak Display (Under Tree)
          Positioned(
            top: 200, // Moved up to avoid overlap with water button
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)!.streakDays(_resources.streak),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
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
              tooltip: AppLocalizations.of(context)!.share,
            ),
          ),
          
          // Info Button (Top Left)
          Positioned(
            top: 0,
            left: 0,
            child: IconButton(
              icon: const Icon(Icons.info_outline, size: 20, color: Colors.grey),
              onPressed: _showTreeInfo,
              tooltip: AppLocalizations.of(context)!.treeInfoTooltip,
            ),
          ),
          


          // --- Action Buttons ---

          // Leaf Button (Left of Tree)
          Positioned(
            top: 100,
            left: 20,
            child: CooldownButton(
              emoji: '🍃',
              label: AppLocalizations.of(context)!.leafButton,
              count: _resources.leafCount,
              color: _resources.canUseLeaf() ? tertiaryColor : Colors.grey,
              isAvailable: _resources.canUseLeaf(),
              remainingCooldown: _resources.getLeafCooldownRemaining(),
              totalCooldown: const Duration(milliseconds: 500),
              onTap: _handleLeafButton,
              onCooldownFinished: _onCooldownFinished,
              disabledMessage: (_isDebugUnlimited || _resources.canUseLeaf()) ? null : _getLeafDisabledMessage(),
            ),
          ),


          // Flower Button (Right of Tree)
          Positioned(
            top: 100,
            right: 20,
            child: CooldownButton(
              emoji: flowerEmoji,
              label: AppLocalizations.of(context)!.flowerButton,
              count: null, // No counter, once per day
              color: flowerButtonColor,
              isAvailable: canUseFlower,
              remainingCooldown: _resources.getFlowerCooldownRemaining(),
              totalCooldown: const Duration(milliseconds: 500),
              onTap: _handleFlowerButton,
              onCooldownFinished: _onCooldownFinished,
              disabledMessage: canUseFlower ? null : _getFlowerDisabledMessage(),
              imageAssetPath: flowerImagePath,
            ),
          ),
        ],
      ),
    );
  }

  void _showDebugDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Tools'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Unlimited toggle
            SwitchListTile(
              title: const Text('Unlimited Flowers & Leaves'),
              subtitle: Text(_isDebugUnlimited ? 'Enabled' : 'Disabled'),
              value: _isDebugUnlimited,
              onChanged: (value) {
                setState(() {
                  _isDebugUnlimited = value;
                });
                Navigator.pop(context);
                _showDebugDialog(); // Reopen to show updated state
              },
            ),
            const Divider(),
            // Reset Tree button
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _handleResetTree();
              },
              child: const Text('Reset Tree'),
            ),
            const SizedBox(height: 8),
            // Add 10 Leaves button
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _resources = _resources.copyWith(
                    leafCount: _resources.leafCount + 10,
                  );
                });
                _saveResources();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added 10 leaves to counter!')),
                );
              },
              child: const Text('Add 10 Leaves'),
            ),
            const SizedBox(height: 8),
            // Add 1 Day button
            ElevatedButton(
              onPressed: () {
                _treeController.grow();
                _saveTree();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tree grew by 1 day!')),
                );
                setState(() {});
              },
              child: const Text('Add 1 Day'),
            ),
            const SizedBox(height: 8),
            // Streak +1 button
            ElevatedButton(
              onPressed: () {
                final newStreak = _resources.streak + 1;
                setState(() {
                  _resources = _resources.copyWith(streak: newStreak);
                });
                _saveResources();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Streak: $newStreak (Special 7: ${_resources.hasSpecial7DayFlower}, 30: ${_resources.hasSpecial30DayFlower})')),
                );
              },
              child: const Text('Streak +1'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          '🌳',
                          style: TextStyle(fontSize: 32),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.treeInfoTitle,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.treeInfoSubtitle,
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Explanation
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.treeInfoDescription,
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface.withValues(alpha: 0.8),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // How it works section
                  Text(
                    l10n.treeInfoHowItWorks,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildInfoCard(
                    context,
                    '🍃',
                    l10n.treeInfoLeavesTitle,
                    l10n.treeInfoLeavesDescription,
                    Colors.green,
                  ),
                  const SizedBox(height: 12),
                  
                  _buildInfoCard(
                    context,
                    '🌸',
                    l10n.treeInfoFlowersTitle,
                    l10n.treeInfoFlowersDescription,
                    Colors.pink,
                  ),
                  const SizedBox(height: 12),
                  
                  // Special flowers box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.purple.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '✨',
                          style: TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.treeInfoSpecialFlowersTitle,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.treeInfoSpecialFlowersDescription,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Stats Section (Compact Grid)
                  Text(
                    l10n.treeInfoStats,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Compact stats grid
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildCompactStatBadge(
                        context,
                        Icons.calendar_today,
                        l10n.treeAge(tree.age),
                        colorScheme.primary,
                      ),
                      _buildCompactStatBadge(
                        context,
                        Icons.eco,
                        l10n.treeLeaves(tree.getAllLeaves().length),
                        Colors.green,
                      ),
                      _buildCompactStatBadge(
                        context,
                        Icons.local_florist,
                        l10n.treeFlowers(tree.getAllFlowers().length),
                        Colors.pink,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(l10n.close),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactStatBadge(BuildContext context, IconData icon, String text, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String emoji, String title, String description, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
  final String? disabledMessage; // Message to show when disabled button is clicked
  final String? imageAssetPath;

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
    this.disabledMessage,
    this.imageAssetPath,
  });

  @override
  Widget build(BuildContext context) {
    // If available, show static full button
    if (isAvailable) {
      return _buildButtonContent(context, 1.0);
    }

    // If cooldown, animate from current progress to 1.0
    final double initialProgress = 1.0 - (remainingCooldown.inMilliseconds / totalCooldown.inMilliseconds).clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      key: ValueKey(isAvailable), // Force recreation when availability changes
      tween: Tween(begin: initialProgress, end: 1.0),
      duration: remainingCooldown,
      onEnd: onCooldownFinished,
      builder: (context, value, child) {
        return _buildButtonContent(context, value);
      },
    );
  }

  Widget _buildButtonContent(BuildContext context, double progress) {
    const double buttonSize = 45.0;
    const double emojiSize = 24.0;

    Widget buttonContent = Material(
      color: isAvailable ? Colors.white : Colors.grey.shade200,
      elevation: isAvailable ? 2 : 1,
      shape: const CircleBorder(),
      child: SizedBox(
        width: buttonSize,
        height: buttonSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Emoji with opacity when disabled
            // Emoji or Image with opacity when disabled
            Opacity(
              opacity: isAvailable ? 1.0 : 0.5,
              child: imageAssetPath != null
                  ? Image.asset(
                      imageAssetPath!,
                      width: emojiSize,
                      height: emojiSize,
                      fit: BoxFit.contain,
                    )
                  : Text(
                      emoji,
                      style: TextStyle(fontSize: emojiSize),
                    ),
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
    );

    // Wrap with InkWell only if available, otherwise use GestureDetector for disabled message
    if (isAvailable) {
      buttonContent = InkWell(
        onTap: () {
          debugPrint('🔘 CooldownButton tapped: $label');
          onTap();
        },
        customBorder: const CircleBorder(),
        child: buttonContent,
      );
    } else if (disabledMessage != null) {
      buttonContent = GestureDetector(
        onTap: () {
          debugPrint('🚫 CooldownButton tapped but disabled: $label');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(disabledMessage!),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: buttonContent,
      );
    } else {
      // If no disabled message, make it non-interactive
      buttonContent = AbsorbPointer(
        child: buttonContent,
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Main Button Background (Flat Circle)
        Tooltip(
          message: label,
          child: buttonContent,
        ),

        // Count badge (Bottom Right) - only show if count is not null and button is available
        if (count != null && isAvailable)
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
