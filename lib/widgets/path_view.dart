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
  double _growthLevel = 0.05; // Commence petit comme une graine (5%)
  final TextEditingController _seedController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _treeParameters = const TreeParameters();
    _seedController.text = _treeParameters.seed.toString();
    _seedController.addListener(_onSeedChanged);
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
      // Augmenter le niveau de croissance progressivement (moins qu'un niveau complet)
      // Incrément très petit pour voir la croissance visuellement à chaque clic
      // Avec maxDepth=10, chaque niveau = 10%, donc 0.02 = 2% = fraction visible d'un niveau
      // Permettre de continuer au-delà de 100% pour le cycle de vie des feuilles
      _growthLevel = _growthLevel + 0.02; // 2% par clic, peut dépasser 100%
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
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

          // Arbre procédural - centré
          Expanded(
            child: Center(
              child: ProceduralTreeWidget(
                size: math.min(
                  MediaQuery.of(context).size.width * 0.8,
                  MediaQuery.of(context).size.height * 0.6,
                ),
                growthLevel: _growthLevel,
                parameters: _treeParameters,
              ),
            ),
          ),

          // Bouton pour faire grandir l'arbre
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: ElevatedButton.icon(
              onPressed: _growTree,
              icon: const Icon(Icons.arrow_upward),
              label: Text(
                _growthLevel >= 1.0
                    ? 'Ajouter des feuilles (${((_growthLevel - 1.0) * 100).toStringAsFixed(0)}%)'
                    : 'Faire grandir (${(_growthLevel * 100).toStringAsFixed(0)}%)',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 12.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

