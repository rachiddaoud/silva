import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Widget simple pour afficher l'animation Lottie de l'arbre avec effet de vent
class LottieTreeWidget extends StatefulWidget {
  final double size;
  final String animationPath;
  final double growthLevel; // 0.0 à 1.0 pour contrôler la progression de l'animation

  const LottieTreeWidget({
    super.key,
    this.size = 200,
    this.animationPath = 'assets/animations/tree_growth.json',
    this.growthLevel = 0.5, // Par défaut à 50%
  });

  @override
  State<LottieTreeWidget> createState() => _LottieTreeWidgetState();
}

class _LottieTreeWidgetState extends State<LottieTreeWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _windController;
  late Animation<double> _windAnimation;

  @override
  void initState() {
    super.initState();
    
    // Controller pour la progression de l'animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    
    // Animation de vent - oscillation continue
    _windController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    
    // Animation de vent avec courbe sinusoïdale
    _windAnimation = Tween<double>(
      begin: -0.03, // Rotation maximale à gauche (en radians, ~1.7 degrés)
      end: 0.03,    // Rotation maximale à droite
    ).animate(CurvedAnimation(
      parent: _windController,
      curve: Curves.easeInOutSine,
    ));
    
    _updateProgress();
  }

  void _updateProgress() {
    // Mapper le niveau de croissance (0.0-1.0) à la progression de l'animation
    _controller.value = widget.growthLevel.clamp(0.0, 1.0);
  }

  @override
  void didUpdateWidget(LottieTreeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.growthLevel != widget.growthLevel) {
      _updateProgress();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _windController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _windAnimation,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.bottomCenter, // Pivot en bas pour que l'arbre pivote depuis sa base
          transform: Matrix4.identity()
            ..rotateZ(_windAnimation.value) // Rotation selon le vent
            ..setEntry(3, 0, 0.001) // Perspective légère
            ..scale(1.0 - (_windAnimation.value.abs() * 0.02)), // Légère compression
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Lottie.asset(
              widget.animationPath,
              controller: _controller,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
              repeat: false,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Icon(
                    Icons.error_outline,
                    size: widget.size * 0.3,
                    color: Theme.of(context).colorScheme.error,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

