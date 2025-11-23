import 'package:flutter/material.dart';
import 'package:ma_bulle/models/tree/tree_parameters.dart';
import 'package:ma_bulle/services/preferences_service.dart';
import 'package:ma_bulle/services/tree_service.dart';
import 'package:ma_bulle/widgets/procedural_tree_widget.dart';

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

  void _loadTree() {
    PreferencesService.getTreeState().then((savedTree) {
      if (savedTree != null) {
        debugPrint('📦 Loading tree from JSON: ${savedTree.getAllBranches().length} branches, ${savedTree.getAllLeaves().length} leaves, ${savedTree.getAllFlowers().length} flowers');
        _treeController.setTree(savedTree);
      } else {
        debugPrint('🌱 No saved tree found, creating new tree');
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
    });
  }

  void _saveTree() {
    if (_treeController.tree != null) {
      PreferencesService.saveTreeState(_treeController.tree!);
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
                  onTap: () {
                    _treeController.addLeaf();
                    _saveTree();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 6),
                _buildDebugButton(
                  icon: Icons.local_florist,
                  label: "Flower",
                  color: Colors.pink,
                  onTap: () {
                    _treeController.addFlower();
                    _saveTree();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 6),
                _buildDebugButton(
                  icon: Icons.delete_outline,
                  label: "Kill",
                  color: Colors.brown,
                  onTap: () {
                    _treeController.decayLeaf();
                    _saveTree();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 6),
                _buildDebugButton(
                  icon: Icons.wb_sunny,
                  label: "+1 Day",
                  color: Colors.orange,
                  onTap: () {
                    _treeController.simulateDay(null);
                    _saveTree();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 6),
                _buildDebugButton(
                  icon: Icons.refresh,
                  label: "Reset",
                  color: Colors.red,
                  onTap: () {
                    _treeController.updateTree(
                      growthLevel: 0.0,
                      size: 250.0,
                      parameters: const TreeParameters(),
                      resetAge: true,
                      forceRegenerate: true,
                    );
                    _saveTree();
                    setState(() {});
                  },
                ),
              ],
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
