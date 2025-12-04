import 'package:flutter/material.dart';

/// A widget that displays a victory doodle image.
class VictoryImage extends StatelessWidget {
  final String imagePath;
  final double size;

  const VictoryImage({
    super.key,
    required this.imagePath,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        imagePath,
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}

/// @Deprecated('Use VictoryImage instead')
/// Legacy widget for backwards compatibility during migration.
/// Will be removed in a future version.
class SpriteDisplay extends StatelessWidget {
  final int victoryId;
  final double size;
  final bool showBorder;

  const SpriteDisplay({
    super.key,
    required this.victoryId,
    this.size = 64,
    this.showBorder = true,
  });

  static String _getImagePathForVictory(int victoryId) {
    final int safeId = victoryId.clamp(0, 8);
    const imagePaths = [
      'assets/doodles/drink-removebg-preview.png',
      'assets/doodles/shower-removebg-preview.png',
      'assets/doodles/help-removebg-preview.png',
      'assets/doodles/eat-removebg-preview.png',
      'assets/doodles/breath-removebg-preview.png',
      'assets/doodles/sleep-removebg-preview.png',
      'assets/doodles/stop-removebg-preview.png',
      'assets/doodles/smile-removebg-preview.png',
      'assets/doodles/walk-removebg-preview.png',
    ];
    return imagePaths[safeId];
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = _getImagePathForVictory(victoryId);
    return VictoryImage(imagePath: imagePath, size: size);
  }
}
