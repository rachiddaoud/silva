import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:silva/services/database_service.dart';
import 'package:silva/models/tree/tree_parameters.dart';
import 'package:silva/services/preferences_service.dart';
import 'package:silva/services/tree_service.dart';
import 'package:silva/widgets/procedural_tree_widget.dart';

class HomeTreeWidget extends StatefulWidget {
  const HomeTreeWidget({super.key});

  @override
  State<HomeTreeWidget> createState() => _HomeTreeWidgetState();
}

class _HomeTreeWidgetState extends State<HomeTreeWidget> {
  late TreeParameters _treeParameters;
  final TreeController _treeController = TreeController();

  @override
  void initState() {
    super.initState();
    _treeParameters = const TreeParameters(seed: 12345);
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

  bool _isProcessing = false;

  Future<void> _handleDebugAction(Future<void> Function() action) async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    await action();
    _saveTree();
    
    if (mounted) {
      setState(() {
        _isProcessing = false;
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
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.info_outline, size: 20, color: Colors.grey),
              onPressed: _showTreeInfo,
              tooltip: 'Infos arbre',
            ),
          ),
          // Debug buttons
          Positioned(
            right: 16,
            top: 40,
            child: Column(
              children: [
                _buildDebugButton(
                  icon: Icons.add,
                  label: "Leaf",
                  color: Colors.green,
                  onTap: () => _handleDebugAction(() async {
                    _treeController.addLeaf();
                  }),
                ),
                const SizedBox(height: 6),
                _buildDebugButton(
                  icon: Icons.local_florist,
                  label: "Flower",
                  color: Colors.pink,
                  onTap: () => _handleDebugAction(() async {
                    _treeController.addFlower();
                  }),
                ),
                const SizedBox(height: 6),
                _buildDebugButton(
                  icon: Icons.delete_outline,
                  label: "Kill",
                  color: Colors.brown,
                  onTap: () => _handleDebugAction(() async {
                    _treeController.decayLeaf();
                  }),
                ),
                const SizedBox(height: 6),
                _buildDebugButton(
                  icon: Icons.wb_sunny,
                  label: "+1 Day",
                  color: Colors.orange,
                  onTap: () => _handleDebugAction(() async {
                    _treeController.grow();
                  }),
                ),
                const SizedBox(height: 6),
                _buildDebugButton(
                  icon: Icons.history,
                  label: "Replay",
                  color: Colors.purple,
                  onTap: () => _handleDebugAction(() async {
                    await _regenerateFromHistory();
                  }),
                ),
                const SizedBox(height: 6),
                _buildDebugButton(
                  icon: Icons.refresh,
                  label: "Reset",
                  color: Colors.red,
                  onTap: () => _handleDebugAction(() async {
                    _treeController.updateTree(
                      growthLevel: 0.0,
                      size: 250.0,
                      parameters: const TreeParameters(),
                      resetAge: true,
                      forceRegenerate: true,
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _regenerateFromHistory() async {
    debugPrint('🔄 Regenerating tree from history...');
    
    // 1. Fetch history
    List<dynamic> history = [];
    
    // Try Firebase first if logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      history = await DatabaseService().getHistory(user.uid);
    } 
    
    // If no Firebase history (or not logged in), try local
    if (history.isEmpty) {
      history = await PreferencesService.getHistory();
    }
    
    if (history.isEmpty) {
      debugPrint('⚠️ No history found to replay.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun historique trouvé pour régénérer l\'arbre.')),
        );
      }
      return;
    }
    
    // 2. Sort history by date (oldest first)
    history.sort((a, b) => a.date.compareTo(b.date));
    
    // 3. Reset tree
    _treeController.updateTree(
      growthLevel: 0.0,
      size: 250.0,
      parameters: const TreeParameters(),
      resetAge: true,
      forceRegenerate: true,
    );
    
    // 4. Replay each day
    int daysProcessed = 0;
    for (final entry in history) {
      final stats = _treeController.simulateDay(entry, notify: false);
      daysProcessed++;
      
      final dateStr = "${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}";
      debugPrint('📅 $dateStr: +${stats['leavesAdded']} leaves, +${stats['flowersAdded']} flowers, +${stats['deadLeavesAdded']} dead leaves');
    }
    
    // 5. Finalize
    if (_treeController.tree != null) {
      _treeController.setTree(_treeController.tree!);
    }
    
    debugPrint('✅ Tree regenerated from $daysProcessed days of history.');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Arbre régénéré à partir de $daysProcessed jours d\'historique.')),
      );
    }
  }

  void _showTreeInfo() {
    final tree = _treeController.tree;
    if (tree == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('À propos de votre arbre'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Votre arbre grandit avec vous ! 🌱\n\n'
              '• Chaque victoire ajoute une feuille 🍃\n'
              '• Les jours positifs font fleurir l\'arbre 🌸\n'
              '• Les jours difficiles peuvent causer des feuilles mortes 🍂\n'
              '• L\'arbre vieillit et grandit chaque jour 🌳',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text('Âge: ${tree.age} jours'),
            Text('Branches: ${tree.getAllBranches().length}'),
            Text('Feuilles: ${tree.getAllLeaves().length}'),
            Text('Fleurs: ${tree.getAllFlowers().length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
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
}
