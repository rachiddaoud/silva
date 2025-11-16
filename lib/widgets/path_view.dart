import 'package:flutter/material.dart';
import 'lottie_tree_widget.dart';

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
  @override
  Widget build(BuildContext context) {
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
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Mon Chemin',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // Animation Lottie - seulement l'arbre, centré et 2x plus grand
          Expanded(
            child: Center(
              child: LottieTreeWidget(
                animationPath: 'assets/animations/tree_growth.json',
                size: (MediaQuery.of(context).size.width * 1.6).clamp(
                  0.0,
                  MediaQuery.of(context).size.height * 0.8,
                ),
                growthLevel: widget.growthLevel,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

