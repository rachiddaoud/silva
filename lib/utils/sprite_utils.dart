import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// Represents a sprite position and size in the sprite sheet
class SpriteInfo {
  final int row;
  final int column;
  final int totalRows;
  final int totalColumns;

  const SpriteInfo({
    required this.row,
    required this.column,
    this.totalRows = 4,
    this.totalColumns = 6,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpriteInfo &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          column == other.column &&
          totalRows == other.totalRows &&
          totalColumns == other.totalColumns;

  @override
  int get hashCode =>
      row.hashCode ^ column.hashCode ^ totalRows.hashCode ^ totalColumns.hashCode;
}

/// Victory sprite mapping
/// The sprite sheet has 4 rows and 6 columns = 24 sprites
/// Mapped to 9 victory types based on the illustration content
class VictorySpriteMapper {
  static const spriteSheet = 'assets/doodles/spritesheat.png';

  /// Map victory types to sprite positions
  /// Row 0: Sleep, Self-care, Mindfulness, Confusion?, Stress-relief, Meditation
  /// Row 1: Neutral, Meditation, Celebration, Care, Heart-care
  /// Row 2: Hands/Love, Shower/Bath, Meditation, Wind/Breathing, Bath/Relax
  /// Row 3: Stop/Hand, Outdoor, Meditation, Couch/Rest
  static SpriteInfo getSpriteForVictory(int victoryId) {
    final Map<int, SpriteInfo> spriteMap = {
      0: const SpriteInfo(row: 1, column: 4), // Water - Hands with heart
      1: const SpriteInfo(row: 2, column: 4), // Shower - Shower scene
      2: const SpriteInfo(row: 2, column: 0), // Help - Hands with heart
      3: const SpriteInfo(row: 0, column: 2), // Meal - Meditation (calm eating)
      4: const SpriteInfo(row: 2, column: 3), // Breathing - Wind
      5: const SpriteInfo(row: 3, column: 3), // Rest baby - Sleep
      6: const SpriteInfo(row: 3, column: 0), // Say No - Stop hand
      7: const SpriteInfo(row: 0, column: 1), // Smile - Celebration
      8: const SpriteInfo(row: 3, column: 2), // Sun - Self-care/hug
    };

    return spriteMap[victoryId] ?? const SpriteInfo(row: 0, column: 0);
  }
}

/// A widget that properly extracts and displays a sprite from the sheet
class SpriteDisplay extends StatefulWidget {
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
  State<SpriteDisplay> createState() => _SpriteDisplayState();
}

class _SpriteDisplayState extends State<SpriteDisplay> {
  @override
  Widget build(BuildContext context) {
    final spriteInfo = VictorySpriteMapper.getSpriteForVictory(widget.victoryId);
    
    const int totalRows = 4;
    const int totalColumns = 6;

    // No container, no decoration - just the sprite
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: _SpriteExtractorPainter(
          spriteInfo: spriteInfo,
          totalRows: totalRows,
          totalColumns: totalColumns,
          assetPath: VictorySpriteMapper.spriteSheet,
        ),
        size: Size(widget.size, widget.size),
      ),
    );
  }
}

/// Custom painter that extracts and renders a single sprite from the sprite sheet
class _SpriteExtractorPainter extends CustomPainter {
  final SpriteInfo spriteInfo;
  final int totalRows;
  final int totalColumns;
  final String assetPath;
  ui.Image? _cachedImage;

  _SpriteExtractorPainter({
    required this.spriteInfo,
    required this.totalRows,
    required this.totalColumns,
    required this.assetPath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // This will be handled by async image loading
    if (_cachedImage == null) {
      _loadImage(canvas, size);
    } else {
      _drawSprite(canvas, size);
    }
  }

  void _loadImage(Canvas canvas, Size size) {
    ImageProvider provider = AssetImage(assetPath);
    provider.resolve(ImageConfiguration.empty).addListener(
      ImageStreamListener((image, synchronousCall) {
        _cachedImage = image.image;
        _drawSprite(canvas, size);
      }),
    );
  }

  void _drawSprite(Canvas canvas, Size size) {
    if (_cachedImage == null) return;

    final image = _cachedImage!;
    
    // Calculate sprite dimensions in the original image
    final spriteWidth = image.width / totalColumns;
    final spriteHeight = image.height / totalRows;
    
    // Calculate source rectangle (which part of the sprite sheet to draw)
    final srcRect = Rect.fromLTWH(
      spriteInfo.column * spriteWidth,
      spriteInfo.row * spriteHeight,
      spriteWidth,
      spriteHeight,
    );
    
    // Calculate destination rectangle (where to draw it)
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Draw the sprite - no background, just the image with its transparency
    canvas.drawImageRect(image, srcRect, dstRect, Paint());
  }

  @override
  bool shouldRepaint(_SpriteExtractorPainter oldDelegate) =>
      oldDelegate.spriteInfo != spriteInfo;
}
