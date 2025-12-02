import 'package:flutter/material.dart';

/// Victory sprite mapping
/// Maps victory IDs to individual image files
class VictorySpriteMapper {
  /// Map victory types to image paths
  /// victoryId 0-8 maps to individual PNG files
  static String getImagePathForVictory(int victoryId) {
    // Ensure ID is within bounds (0-8)
    final int safeId = victoryId.clamp(0, 8);
    
    // Map victory IDs to their corresponding image files
    // Based on victory card definitions:
    // 0: drink, 1: shower, 2: help, 3: eat, 4: breath, 
    // 5: baby (sleep), 6: stop, 7: smile, 8: sun (walk)
    const imagePaths = [
      'assets/doodles/drink-removebg-preview.png',      // 0: drink
      'assets/doodles/shower-removebg-preview.png',     // 1: shower
      'assets/doodles/help-removebg-preview.png',       // 2: help
      'assets/doodles/eat-removebg-preview.png',        // 3: eat
      'assets/doodles/breath-removebg-preview.png',     // 4: breath
      'assets/doodles/sleep-removebg-preview.png',      // 5: baby (put baby down)
      'assets/doodles/stop-removebg-preview.png',       // 6: stop
      'assets/doodles/smile-removebg-preview.png',      // 7: smile
      'assets/doodles/walk-removebg-preview.png',       // 8: sun (see sun/walk)
    ];
    
    return imagePaths[safeId];
  }
}

/// A widget that displays a victory sprite from individual image files
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

  @override
  Widget build(BuildContext context) {
    final imagePath = VictorySpriteMapper.getImagePathForVictory(victoryId);
    
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
