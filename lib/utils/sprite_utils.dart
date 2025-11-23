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
    this.totalRows = 3,
    this.totalColumns = 3,
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
  static const spriteSheet = 'assets/doodles/spritesheat_v2.png';

  /// Map victory types to sprite positions
  /// The new sprite sheet is a 3x3 grid where the position directly corresponds
  /// to the victory ID (0-8) reading left-to-right, top-to-bottom.
  static SpriteInfo getSpriteForVictory(int victoryId) {
    // Ensure ID is within bounds (0-8)
    final int safeId = victoryId.clamp(0, 8);
    
    return SpriteInfo(
      row: safeId ~/ 3,
      column: safeId % 3,
      totalRows: 3,
      totalColumns: 3,
    );
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
  ui.Image? _cachedImage;
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void dispose() {
    if (_imageStream != null && _imageListener != null) {
      _imageStream!.removeListener(_imageListener!);
    }
    super.dispose();
  }

  void _loadImage() {
    final ImageProvider provider = AssetImage(VictorySpriteMapper.spriteSheet);
    final ImageStream stream = provider.resolve(ImageConfiguration.empty);
    
    _imageListener = ImageStreamListener((ImageInfo imageInfo, bool synchronousCall) {
      if (mounted) {
        setState(() {
          _cachedImage = imageInfo.image;
        });
      }
    });
    
    _imageStream = stream;
    stream.addListener(_imageListener!);
  }

  @override
  Widget build(BuildContext context) {
    final spriteInfo = VictorySpriteMapper.getSpriteForVictory(widget.victoryId);
    
    const int totalRows = 3;
    const int totalColumns = 3;

    // No container, no decoration - just the sprite
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: _SpriteExtractorPainter(
          spriteInfo: spriteInfo,
          totalRows: totalRows,
          totalColumns: totalColumns,
          cachedImage: _cachedImage,
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
  final ui.Image? cachedImage;

  _SpriteExtractorPainter({
    required this.spriteInfo,
    required this.totalRows,
    required this.totalColumns,
    required this.cachedImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (cachedImage == null) return;

    final image = cachedImage!;
    
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
      oldDelegate.spriteInfo != spriteInfo ||
      oldDelegate.cachedImage != cachedImage;
}
