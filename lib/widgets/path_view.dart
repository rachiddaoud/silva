import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'procedural_tree_widget.dart';

/// Vue simple du chemin avec seulement l'animation de l'arbre
class PathView extends StatefulWidget {
  final double growthLevel; // 0.0 à 1.0 (0% à 100%)

  const PathView({
    super.key,
    this.growthLevel = 0.5,
  });

  @override
  State<PathView> createState() => _PathViewState();
}

class _PathViewState extends State<PathView> {
  late TreeParameters _treeParameters;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _treeParameters = const TreeParameters();
  }

  void _randomizeTree() {
    setState(() {
      _treeParameters = TreeParameters.random(_random);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ColoredBox(
      color: Colors.transparent,
      child: Column(
        children: [
          // Titre
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
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
          ),

          // Arbre procédural - généré mathématiquement
          Expanded(
            child: Center(
              child: ProceduralTreeWidget(
                size: (MediaQuery.of(context).size.width * 0.7).clamp(
                  0.0,
                  MediaQuery.of(context).size.height * 0.5,
                ),
                growthLevel: widget.growthLevel,
                parameters: _treeParameters,
              ),
            ),
          ),

          // Bouton de randomisation et paramètres
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              children: [
                // Bouton de randomisation
                ElevatedButton.icon(
                  onPressed: _randomizeTree,
                  icon: const Icon(Icons.shuffle),
                  label: const Text('Randomiser l\'arbre'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 12.0,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                
                // Affichage des paramètres
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paramètres actuels:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      _buildParameterRow('maxDepth', _treeParameters.maxDepth.toString()),
                      _buildParameterRow(
                        'baseBranchAngle',
                        '${(_treeParameters.baseBranchAngle * 180 / math.pi).toStringAsFixed(1)}°',
                      ),
                      _buildParameterRow(
                        'lengthRatio',
                        _treeParameters.lengthRatio.toStringAsFixed(2),
                      ),
                      _buildParameterRow(
                        'thicknessRatio',
                        _treeParameters.thicknessRatio.toStringAsFixed(2),
                      ),
                      _buildParameterRow(
                        'angleVariation',
                        _treeParameters.angleVariation.toStringAsFixed(2),
                      ),
                      _buildParameterRow(
                        'curveIntensity',
                        _treeParameters.curveIntensity.toStringAsFixed(2),
                      ),
                      _buildParameterRow('seed', _treeParameters.seed.toString()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontFamily: 'monospace',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

