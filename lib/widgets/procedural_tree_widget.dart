import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:silva/models/tree/tree_parameters.dart';
import 'package:silva/models/tree/tree_state.dart';
import 'package:silva/services/tree_service.dart';
import 'package:silva/painting/tree_painter.dart';

/// Widget to display the procedural tree
class ProceduralTreeWidget extends StatefulWidget {
  final double size;
  final double growthLevel;
  final TreeParameters parameters;
  final TreeController controller;

  const ProceduralTreeWidget({
    super.key,
    this.size = 200,
    this.growthLevel = 0.5,
    required this.parameters,
    required this.controller,
  });

  @override
  State<ProceduralTreeWidget> createState() => ProceduralTreeWidgetState();
}

class ProceduralTreeWidgetState extends State<ProceduralTreeWidget>
    with SingleTickerProviderStateMixin {
  ui.Image? _leafImage;
  ui.Image? _leafDead1Image;
  ui.Image? _leafDead2Image;
  ui.Image? _leafDead3Image;
  ui.Image? _flowerImage;
  ui.Image? _jasminImage;
  ui.Image? _grassBackgroundImage;
  ui.Image? _grassForegroundImage;
  ui.Image? _barkImage;
  late AnimationController _windController;
  late Animation<double> _windAnimation;
  
  TreeState? get tree => widget.controller.tree;
  
  /// Get the current wind phase for position calculations
  double get currentWindPhase => _windAnimation.value;

  @override
  void initState() {
    super.initState();
    _loadImages();
    
    _windController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _windAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _windController,
        curve: Curves.linear,
      ),
    );
    
    if (widget.controller.tree == null) {
      _updateTree();
    }
  }

  void _updateTree() {
    widget.controller.updateTree(
      growthLevel: widget.growthLevel,
      size: widget.size,
      parameters: widget.parameters,
    );
  }

  Future<void> _loadImages() async {
    _leafImage = await _loadImage('assets/tree/leaf.png');
    _leafDead1Image = await _loadImage('assets/tree/leaf_dead_1.png');
    _leafDead2Image = await _loadImage('assets/tree/leaf_dead_2.png');
    _leafDead3Image = await _loadImage('assets/tree/leaf_dead_3.png');
    _flowerImage = await _loadImage('assets/tree/flower.png');
    _jasminImage = await _loadImage('assets/tree/jasmin.png');
    _grassBackgroundImage = await _loadImage('assets/tree/grass_background.png');
    _grassForegroundImage = await _loadImage('assets/tree/grass_foreground.png');
    _barkImage = await _loadImage('assets/tree/bark_texture.png');
    
    if (mounted) setState(() {});
  }

  Future<ui.Image?> _loadImage(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      return frameInfo.image;
    } catch (e) {
      debugPrint('❌ Error loading $assetPath: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _leafImage?.dispose();
    _leafDead1Image?.dispose();
    _leafDead2Image?.dispose();
    _leafDead3Image?.dispose();
    _flowerImage?.dispose();
    _jasminImage?.dispose();
    _grassBackgroundImage?.dispose();
    _grassForegroundImage?.dispose();
    _barkImage?.dispose();
    _windController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ProceduralTreeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    

    
    // Check if parameters changed
    final parametersChanged = oldWidget.growthLevel != widget.growthLevel ||
        oldWidget.size != widget.size ||
        oldWidget.parameters.seed != widget.parameters.seed;
    
    if (parametersChanged) {
      widget.controller.updateTree(
        growthLevel: widget.growthLevel,
        size: widget.size,
        parameters: widget.parameters,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_windAnimation, widget.controller]),
      builder: (context, child) {
        if (widget.controller.tree == null) {
          return const SizedBox();
        }
        
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            key: ValueKey('${_leafImage != null}'),
            painter: TreePainter(
              tree: widget.controller.tree!,
              parameters: widget.parameters,
              leafImage: _leafImage,
              leafDead1Image: _leafDead1Image,
              leafDead2Image: _leafDead2Image,
              leafDead3Image: _leafDead3Image,
              flowerImage: _flowerImage,
              jasminImage: _jasminImage,
              grassBackgroundImage: _grassBackgroundImage,
              grassForegroundImage: _grassForegroundImage,
              barkImage: _barkImage,
              windPhase: _windAnimation.value,
            ),
          ),
        );
      },
    );
  }
}
