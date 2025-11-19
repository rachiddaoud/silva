import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'procedural_tree_widget.dart';

/// Vue simple du chemin avec seulement l'animation de l'arbre
class PathView extends StatefulWidget {
  const PathView({super.key});

  @override
  State<PathView> createState() => _PathViewState();
}

class _PathViewState extends State<PathView> {
  late TreeParameters _treeParameters;
  double _growthLevel = 0.30; // Commence avec quelques branches (30%) pour permettre l'ajout de feuilles
  final TextEditingController _seedController = TextEditingController();
  final GlobalKey<ProceduralTreeWidgetState> _treeKey = GlobalKey<ProceduralTreeWidgetState>();

  @override
  void initState() {
    super.initState();
    _treeParameters = const TreeParameters();
    _seedController.text = _treeParameters.seed.toString();
    _seedController.addListener(_onSeedChanged);
    
    // Créer 2 feuilles initiales après le premier build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_treeKey.currentState != null && mounted) {
        // Appeler addRandomLeaves() deux fois pour créer 2 feuilles
        _treeKey.currentState!.addRandomLeaves();
        // Attendre un peu avant d'ajouter la deuxième feuille pour éviter les conflits
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _treeKey.currentState != null) {
            _treeKey.currentState!.addRandomLeaves();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _seedController.dispose();
    super.dispose();
  }

  void _onSeedChanged() {
    final seedText = _seedController.text;
    if (seedText.isNotEmpty) {
      final seed = int.tryParse(seedText);
      if (seed != null && seed != _treeParameters.seed) {
        setState(() {
          _treeParameters = _treeParameters.copyWith(seed: seed);
        });
      }
    }
  }

  void _changeSeed(int delta) {
    final newSeed = (_treeParameters.seed + delta).clamp(0, 999999);
    setState(() {
      _treeParameters = _treeParameters.copyWith(seed: newSeed);
      _seedController.text = newSeed.toString();
    });
  }

  void _growTree() {
    setState(() {
      // Faire grandir les feuilles (fait grandir l'arbre d'un jour)
      _treeKey.currentState?.growLeaves();
      
      // Augmenter le growthLevel pour la génération procédurale
      _growthLevel = _growthLevel + 0.02; // 2% par clic, peut dépasser 100%
      
      // Le growthLevel ne doit jamais être négatif
      if (_growthLevel < 0) {
        _growthLevel = 0;
      }
    });
  }

  Widget _buildEmojiButton({
    required String emoji,
    required VoidCallback onPressed,
    required ThemeData theme,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final treeSize = math.min(screenSize.width * 0.8, screenSize.height * 0.5);
    
    return ColoredBox(
      color: Colors.transparent,
      child: Column(
        children: [
          // Titre avec contrôle du seed pour debug
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.eco,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Mon Chemin',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                // Contrôle du seed pour debug
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Seed:',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: () => _changeSeed(-1),
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(4.0),
                        minimumSize: const Size(32, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: _seedController,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: theme.colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 8.0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: () => _changeSeed(1),
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(4.0),
                        minimumSize: const Size(32, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Arbre procédural - centré avec taille fixe
          Expanded(
            child: Center(
              child: ProceduralTreeWidget(
                key: _treeKey,
                size: treeSize,
                growthLevel: _growthLevel,
                parameters: _treeParameters,
              ),
            ),
          ),

          // Barre de boutons en bas avec emojis
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor.withOpacity(0.9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Bouton feuilles (ajouter des feuilles)
                  _buildEmojiButton(
                    emoji: '🍃',
                    onPressed: () {
                      if (_treeKey.currentState != null) {
                        _treeKey.currentState!.addRandomLeaves();
                      }
                    },
                    theme: theme,
                  ),
                  // Bouton jour (faire grandir l'arbre)
                  _buildEmojiButton(
                    emoji: '☀️',
                    onPressed: _growTree,
                    theme: theme,
                  ),
                  // Bouton feuilles jaune (tuer des feuilles)
                  _buildEmojiButton(
                    emoji: '🍂',
                    onPressed: () {
                      if (_treeKey.currentState != null) {
                        _treeKey.currentState!.advanceLeafDeath();
                      }
                    },
                    theme: theme,
                  ),
                  // Bouton fleur (ajouter une fleur)
                  _buildEmojiButton(
                    emoji: '🌸',
                    onPressed: () {
                      if (_treeKey.currentState != null) {
                        _treeKey.currentState!.addRandomFlower();
                      }
                    },
                    theme: theme,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

