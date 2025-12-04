import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:silva/models/tree/tree_parameters.dart';
import 'package:silva/models/tree/tree_state.dart';
import 'package:silva/logic/tree_logic.dart';

/// Painter for rendering the procedural tree
class TreePainter extends CustomPainter {
  final TreeState tree;
  final TreeParameters parameters;
  final ui.Image? leafImage;
  final ui.Image? leafDead1Image;
  final ui.Image? leafDead2Image;
  final ui.Image? leafDead3Image;
  final ui.Image? flowerImage;
  final ui.Image? jasminImage;
  final ui.Image? blueFlowerImage;
  final ui.Image? yellowFlowerImage;
  final ui.Image? grassBackgroundImage;
  final ui.Image? grassForegroundImage;
  final ui.Image? barkImage;
  final double windPhase; // Wind phase (0 to 2π)
  
  // Cache for deformed positions to avoid recalculating for leaves/flowers
  final Map<String, Offset> _deformedEnds = {};
  final Map<String, Offset> _deformedStarts = {};

  TreePainter({
    required this.tree,
    required this.parameters,
    this.leafImage,
    this.leafDead1Image,
    this.leafDead2Image,
    this.leafDead3Image,
    this.flowerImage,
    this.jasminImage,
    this.blueFlowerImage,
    this.yellowFlowerImage,
    this.grassBackgroundImage,
    this.grassForegroundImage,
    this.barkImage,
    this.windPhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background (grass behind tree)
    _drawGrassBackground(canvas, size);

    // Calculate deformed positions hierarchically
    _calculateDeformedPositions();
    
    // Draw branches (sorted by depth for z-ordering)
    final allBranches = tree.getAllBranches();
    final sortedBranches = List<BranchState>.from(allBranches)
      ..sort((a, b) => b.depth.compareTo(a.depth));
    
    for (final branch in sortedBranches) {
      _drawBranch(canvas, branch);
    }

    // Draw leaves using Atlas if images are available
    if (leafImage != null) {
      _drawLeavesAtlas(canvas, sortedBranches);
    } else {
      // Fallback for missing images
      for (final branch in sortedBranches) {
        for (final leaf in branch.leaves) {
          if (leaf.currentGrowth > 0.0) {
            _drawLeafFallback(canvas, leaf, branch);
          }
        }
      }
    }

    // Draw flowers using Atlas if images are available
    if (flowerImage != null || jasminImage != null || blueFlowerImage != null || yellowFlowerImage != null) {
      _drawFlowersAtlas(canvas, sortedBranches);
    } else {
      // Fallback
      for (final branch in sortedBranches) {
        for (final flower in branch.flowers) {
          _drawFlowerFallback(canvas, flower, branch);
        }
      }
    }
    
    // Draw foreground (grass in front of tree)
    _drawGrassForeground(canvas, size);
  }

  void _drawGrassBackground(Canvas canvas, Size size) {
    if (grassBackgroundImage == null) return;
    _drawGroundImage(canvas, size, grassBackgroundImage!);
  }

  void _drawGrassForeground(Canvas canvas, Size size) {
    if (grassForegroundImage == null) return;
    _drawGroundImage(canvas, size, grassForegroundImage!);
  }

  void _drawGroundImage(Canvas canvas, Size size, ui.Image image) {
    try {
      final imageWidth = image.width.toDouble();
      final imageHeight = image.height.toDouble();
      final aspectRatio = imageWidth / imageHeight;
      
      final groundWidth = tree.treeSize * 0.8;
      final groundHeight = groundWidth / aspectRatio;
      
      final groundX = (size.width - groundWidth) / 2;
      final treeBaseY = tree.treeSize * 0.75;
      final groundY = treeBaseY - groundHeight / 2;
      
      final dstRect = Rect.fromLTWH(
        groundX,
        groundY,
        groundWidth,
        groundHeight,
      );
      
      final srcRect = Rect.fromLTWH(0, 0, imageWidth, imageHeight);
      
      canvas.drawImageRect(
        image,
        srcRect,
        dstRect,
        Paint()..filterQuality = FilterQuality.high,
      );
    } catch (e) {
      // Ignore errors
    }
  }

  void _calculateDeformedPositions() {
    _deformedEnds.clear();
    _deformedStarts.clear();
    
    final allBranches = tree.getAllBranches();
    final sortedBranches = List<BranchState>.from(allBranches)
      ..sort((a, b) => a.depth.compareTo(b.depth));
    
    for (final branch in sortedBranches) {
      Offset deformedStart;
      if (branch.depth == 0) {
        deformedStart = branch.start;
      } else {
        final lastUnderscore = branch.id.lastIndexOf('_');
        final parentId = lastUnderscore != -1 ? branch.id.substring(0, lastUnderscore) : null;
        
        if (parentId != null && _deformedEnds.containsKey(parentId)) {
           deformedStart = _deformedEnds[parentId]!;
        } else {
           deformedStart = branch.start;
        }
      }
      
      _deformedStarts[branch.id] = deformedStart;
      final deformedEnd = _calculateDeformedEnd(branch, deformedStart);
      _deformedEnds[branch.id] = deformedEnd;
    }
  }
  
  Offset _calculateDeformedEnd(BranchState branch, Offset deformedStart) {
    final depthRatio = branch.depth / parameters.maxDepth;
    final heightFactor = (tree.treeSize - branch.start.dy) / tree.treeSize;
    final flexibilityFactor = depthRatio;
    final windIntensity = 0.4 * heightFactor * flexibilityFactor;
    final branchPhase = windPhase + branch.start.dx * 0.005 + branch.start.dy * 0.005;
    
    final originalDirection = branch.end - branch.start;
    final originalAngle = math.atan2(originalDirection.dy, originalDirection.dx);
    
    final t = 1.0;
    final windAtEnd = math.sin(branchPhase + t * 2.0) * windIntensity * t * t;
    
    final perpAngle = originalAngle + math.pi / 2;
    final windOffsetX = math.cos(perpAngle) * windAtEnd * tree.treeSize * 0.05;
    final windOffsetY = math.sin(perpAngle) * windAtEnd * tree.treeSize * 0.05;
    
    return Offset(
      deformedStart.dx + originalDirection.dx + windOffsetX,
      deformedStart.dy + originalDirection.dy + windOffsetY,
    );
  }

  void _drawBranch(Canvas canvas, BranchState branch) {
    final depthRatio = branch.depth / parameters.maxDepth;
    final brown = Color.lerp(
      const Color(0xFF5D4037),
      const Color(0xFF8D6E63),
      depthRatio.clamp(0.0, 1.0),
    )!;
    final green = Color.lerp(
      const Color(0xFF6B8E23),
      const Color(0xFF9ACD32),
      depthRatio.clamp(0.0, 1.0),
    )!;
    final branchColor = Color.lerp(brown, green, depthRatio * 0.5)!;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final deformedStart = _deformedStarts[branch.id] ?? branch.start;
    final deformedEnd = _deformedEnds[branch.id] ?? branch.end;

    if (barkImage != null) {
      final matrix = Matrix4.identity();
      final scale = 2.0 * (tree.treeSize / 500.0); 
      matrix.translate(deformedStart.dx, deformedStart.dy, 0.0);
      matrix.multiply(Matrix4.diagonal3Values(scale, scale, 1.0));
      
      paint.shader = ImageShader(
        barkImage!, 
        TileMode.repeated, 
        TileMode.repeated, 
        matrix.storage,
      );
    } else {
      paint.color = branchColor;
    }

    final hasChildren = branch.children.isNotEmpty;
    
    final originalControl = branch.controlPoint;
    final midPoint = Offset(
      (deformedStart.dx + deformedEnd.dx) / 2,
      (deformedStart.dy + deformedEnd.dy) / 2,
    );
    final deformedControl = Offset(
      originalControl.dx + (midPoint.dx - (branch.start.dx + branch.end.dx) / 2) * 0.7,
      originalControl.dy + (midPoint.dy - (branch.start.dy + branch.end.dy) / 2) * 0.7,
    );

    final heightFactor = (tree.treeSize - branch.start.dy) / tree.treeSize;
    final flexibilityFactor = depthRatio;
    final windIntensity = 0.4 * heightFactor * flexibilityFactor;
    final branchPhase = windPhase + branch.start.dx * 0.005 + branch.start.dy * 0.005;

    final path = Path();
    // OPTIMIZATION: Reduced from 20 to 8 segments
    const numSegments = 8;
    final halfThicknessStart = (branch.thickness / parameters.thicknessRatio) / 2;
    final halfThicknessEnd = hasChildren 
      ? branch.thickness / 2 
      : branch.thickness * 0.05;
    
    final topPoints = <Offset>[];
    final bottomPoints = <Offset>[];
    
    for (int i = 0; i <= numSegments; i++) {
      final t = i / numSegments;
      final point = TreeGeometry.bezierPoint(deformedStart, deformedControl, deformedEnd, t);
      final tangent = TreeGeometry.bezierTangent(deformedStart, deformedControl, deformedEnd, t);
      final branchAngle = math.atan2(tangent.dy, tangent.dx);
      final perpAngle = branchAngle + math.pi / 2;
      
      final windAtPoint = math.sin(branchPhase + t * 2.0) * windIntensity * t * t * 0.3;
      final windOffsetX = math.cos(perpAngle) * windAtPoint * tree.treeSize * 0.05;
      final windOffsetY = math.sin(perpAngle) * windAtPoint * tree.treeSize * 0.05;
      
      final deformedPoint = Offset(
        point.dx + windOffsetX,
        point.dy + windOffsetY,
      );
      
      final easeOut = 1 - (1 - t) * (1 - t);
      final thickness = halfThicknessStart * (1 - easeOut) + halfThicknessEnd * easeOut;
      
      topPoints.add(Offset(
        deformedPoint.dx + math.cos(perpAngle) * thickness,
        deformedPoint.dy + math.sin(perpAngle) * thickness,
      ));
      bottomPoints.add(Offset(
        deformedPoint.dx - math.cos(perpAngle) * thickness,
        deformedPoint.dy - math.sin(perpAngle) * thickness,
      ));
    }
    
    path.moveTo(topPoints[0].dx, topPoints[0].dy);
    for (int i = 1; i < topPoints.length; i++) {
      path.lineTo(topPoints[i].dx, topPoints[i].dy);
    }
    for (int i = bottomPoints.length - 1; i >= 0; i--) {
      path.lineTo(bottomPoints[i].dx, bottomPoints[i].dy);
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }

  void _drawLeavesAtlas(Canvas canvas, List<BranchState> sortedBranches) {
    // Group transforms by image type to minimize drawAtlas calls
    final Map<ui.Image, List<RSTransform>> transforms = {};
    final Map<ui.Image, List<Rect>> rects = {};
    
    // Helper to add to batch
    void addToBatch(ui.Image img, RSTransform transform, Rect rect) {
      if (!transforms.containsKey(img)) {
        transforms[img] = [];
        rects[img] = [];
      }
      transforms[img]!.add(transform);
      rects[img]!.add(rect);
    }

    for (final branch in sortedBranches) {
      if (branch.leaves.isEmpty) continue;

      final deformedStart = _deformedStarts[branch.id] ?? branch.start;
      final deformedEnd = _deformedEnds[branch.id] ?? branch.end;
      
      final originalControl = branch.controlPoint;
      final midPoint = Offset(
        (deformedStart.dx + deformedEnd.dx) / 2,
        (deformedStart.dy + deformedEnd.dy) / 2,
      );
      final deformedControl = Offset(
        originalControl.dx + (midPoint.dx - (branch.start.dx + branch.end.dx) / 2) * 0.7,
        originalControl.dy + (midPoint.dy - (branch.start.dy + branch.end.dy) / 2) * 0.7,
      );

      final depthRatio = branch.depth / parameters.maxDepth;
      final heightFactor = (tree.treeSize - branch.start.dy) / tree.treeSize;
      final flexibilityFactor = depthRatio;
      final windIntensity = 0.4 * heightFactor * flexibilityFactor;
      final branchPhase = windPhase + branch.start.dx * 0.005 + branch.start.dy * 0.005;

      for (final leaf in branch.leaves) {
        if (leaf.currentGrowth <= 0.0) continue;

        // --- Calculate Position (Same as before) ---
        final t = leaf.tOnBranch;
        final point = TreeGeometry.bezierPoint(deformedStart, deformedControl, deformedEnd, t);
        final tangent = TreeGeometry.bezierTangent(deformedStart, deformedControl, deformedEnd, t);
        final branchAngle = math.atan2(tangent.dy, tangent.dx);
        final perpAngle = branchAngle + math.pi / 2;
        
        final windAtPoint = math.sin(branchPhase + t * 2.0) * windIntensity * t * t * 0.3;
        final windOffsetX = math.cos(perpAngle) * windAtPoint * tree.treeSize * 0.05;
        final windOffsetY = math.sin(perpAngle) * windAtPoint * tree.treeSize * 0.05;
        
        final deformedPoint = Offset(
          point.dx + windOffsetX,
          point.dy + windOffsetY,
        );
        
        final thicknessAtPoint = branch.thickness * (1.0 - t * 0.3);
        final branchRadius = thicknessAtPoint / 2;
        
        final leafPos = Offset(
          deformedPoint.dx + math.cos(perpAngle) * branchRadius * leaf.side,
          deformedPoint.dy + math.sin(perpAngle) * branchRadius * leaf.side,
        );

        // --- Determine Image ---
        ui.Image? imageToUse;
        switch (leaf.healthState) {
          case LeafHealthState.alive:
            imageToUse = leafImage;
            break;
          case LeafHealthState.dead1:
            imageToUse = leafDead1Image ?? leafImage;
            break;
          case LeafHealthState.dead2:
            imageToUse = leafDead2Image ?? leafDead1Image ?? leafImage;
            break;
          case LeafHealthState.dead3:
            imageToUse = leafDead3Image ?? leafDead2Image ?? leafImage;
            break;
        }

        if (imageToUse == null) continue;

        // --- Calculate Size and Rotation ---
        final depthFactor = 1.5 - (branch.depth - 1) * 0.14; // Reduced reduction for deeper branches (was 0.2)
        final clampedDepthFactor = depthFactor.clamp(0.4, 1.5);
        final ageFactor = 0.5 + (branch.age / 20.0).clamp(0.0, 0.5);
        final maxSize = clampedDepthFactor * ageFactor * leaf.randomSizeFactor;
        final currentSize = maxSize * leaf.currentGrowth;
        
        final baseSize = tree.treeSize * 0.06;
        final leafSize = baseSize * currentSize;

        final leafAngle = perpAngle + (leaf.side * math.pi / 6);
        final windRotation = math.sin(windPhase + t * 5) * 0.2;
        final totalRotation = leafAngle + windRotation;

        final imageAspectRatio = imageToUse.width.toDouble() / imageToUse.height.toDouble();
        final height = leafSize;
        final width = height * imageAspectRatio;

        // RSTransform: scos, ssin, tx, ty
        // We want to rotate around the bottom center of the leaf (stem)
        // The anchor point in the image is (width/2, height)
        // We need to translate so that (width/2, height) maps to leafPos
        
        final cosVal = math.cos(totalRotation);
        final sinVal = math.sin(totalRotation);
        
        // Anchor offset in local rotated space
        final anchorX = width / 2;
        final anchorY = height;
        
        // Calculate the top-left corner position (tx, ty) required for RSTransform
        // RSTransform applies rotation around (0,0) of the rect, then translates.
        // But drawAtlas uses RSTransform differently:
        // It transforms the source rect to the destination.
        // RSTransform(scos, ssin, tx, ty)
        // x' = scos * x - ssin * y + tx
        // y' = ssin * x + scos * y + ty
        // We want the point (width/2, height) in local space to map to leafPos.
        // leafPos.dx = cos * (width/2) - sin * (height) + tx
        // leafPos.dy = sin * (width/2) + cos * (height) + ty
        // => tx = leafPos.dx - (cos * width/2 - sin * height)
        // => ty = leafPos.dy - (sin * width/2 + cos * height)
        
        final scos = cosVal * (width / imageToUse.width.toDouble()); // Scale included in scos/ssin? 
        // No, RSTransform is usually rotation + scale + translation.
        // But drawAtlas takes a list of RSTransforms and a list of Rects.
        // The Rect is the source rect.
        // The transform maps the source rect to the canvas.
        // Actually, RSTransform is defined as:
        // scos = scale * cos(rotation)
        // ssin = scale * sin(rotation)
        // tx, ty = translation
        
        // We need to scale the source image to 'width' and 'height'.
        // Source width = imageToUse.width
        // Scale = width / imageToUse.width
        
        final scale = width / imageToUse.width.toDouble();
        final rScos = scale * cosVal;
        final rSsin = scale * sinVal;
        
        // We want the source point (srcWidth/2, srcHeight) to map to leafPos.
        // Let's call source anchor (ax, ay).
        // Target x = rScos * ax - rSsin * ay + tx
        // Target y = rSsin * ax + rScos * ay + ty
        // We want Target = leafPos.
        // tx = leafPos.dx - (rScos * ax - rSsin * ay)
        // ty = leafPos.dy - (rSsin * ax + rScos * ay)
        
        final ax = imageToUse.width.toDouble() / 2;
        final ay = imageToUse.height.toDouble();
        
        final tx = leafPos.dx - (rScos * ax - rSsin * ay);
        final ty = leafPos.dy - (rSsin * ax + rScos * ay);
        
        addToBatch(
          imageToUse,
          RSTransform(rScos, rSsin, tx, ty),
          Rect.fromLTWH(0, 0, imageToUse.width.toDouble(), imageToUse.height.toDouble()),
        );
      }
    }

    // Execute batches
    final paint = Paint()..filterQuality = FilterQuality.medium;
    transforms.forEach((img, transList) {
      canvas.drawAtlas(
        img,
        transList,
        rects[img]!,
        null, // colors
        BlendMode.srcIn, // blendMode
        null, // cullRect
        paint,
      );
    });
  }

  void _drawFlowersAtlas(Canvas canvas, List<BranchState> sortedBranches) {
    final Map<ui.Image, List<RSTransform>> transforms = {};
    final Map<ui.Image, List<Rect>> rects = {};
    
    void addToBatch(ui.Image img, RSTransform transform, Rect rect) {
      if (!transforms.containsKey(img)) {
        transforms[img] = [];
        rects[img] = [];
      }
      transforms[img]!.add(transform);
      rects[img]!.add(rect);
    }

    for (final branch in sortedBranches) {
      if (branch.flowers.isEmpty) continue;

      final deformedStart = _deformedStarts[branch.id] ?? branch.start;
      final deformedEnd = _deformedEnds[branch.id] ?? branch.end;
      
      final originalControl = branch.controlPoint;
      final midPoint = Offset(
        (deformedStart.dx + deformedEnd.dx) / 2,
        (deformedStart.dy + deformedEnd.dy) / 2,
      );
      final deformedControl = Offset(
        originalControl.dx + (midPoint.dx - (branch.start.dx + branch.end.dx) / 2) * 0.7,
        originalControl.dy + (midPoint.dy - (branch.start.dy + branch.end.dy) / 2) * 0.7,
      );

      final depthRatio = branch.depth / parameters.maxDepth;
      final heightFactor = (tree.treeSize - branch.start.dy) / tree.treeSize;
      final flexibilityFactor = depthRatio;
      final windIntensity = 0.4 * heightFactor * flexibilityFactor;
      final branchPhase = windPhase + branch.start.dx * 0.005 + branch.start.dy * 0.005;

      for (final flower in branch.flowers) {
        final t = flower.tOnBranch;
        final point = TreeGeometry.bezierPoint(deformedStart, deformedControl, deformedEnd, t);
        final tangent = TreeGeometry.bezierTangent(deformedStart, deformedControl, deformedEnd, t);
        final branchAngle = math.atan2(tangent.dy, tangent.dx);
        final perpAngle = branchAngle + math.pi / 2;
        
        final windAtPoint = math.sin(branchPhase + t * 2.0) * windIntensity * t * t * 0.3;
        final windOffsetX = math.cos(perpAngle) * windAtPoint * tree.treeSize * 0.05;
        final windOffsetY = math.sin(perpAngle) * windAtPoint * tree.treeSize * 0.05;
        
        final deformedPoint = Offset(
          point.dx + windOffsetX,
          point.dy + windOffsetY,
        );
        
        final thicknessAtPoint = branch.thickness * (1.0 - t * 0.3);
        final branchRadius = thicknessAtPoint / 2;
        
        final flowerPos = Offset(
          deformedPoint.dx + math.cos(perpAngle) * branchRadius * flower.side,
          deformedPoint.dy + math.sin(perpAngle) * branchRadius * flower.side,
        );

        ui.Image? imageToUse;
        switch (flower.flowerType) {
          case 0:
            imageToUse = flowerImage;
            break;
          case 1:
            imageToUse = jasminImage;
            break;
          case 2:
            imageToUse = blueFlowerImage;
            break;
          case 3:
            imageToUse = yellowFlowerImage;
            break;
          default:
            imageToUse = flowerImage;
        }
        if (imageToUse == null) continue;

        final ageFactor = tree.age < 30 
            ? 0.5 + (tree.age / 30.0) * 0.5
            : 1.0;
        
        final baseSize = tree.treeSize * 0.08 * ageFactor;
        final flowerSize = baseSize * flower.sizeFactor;

        final rotation = branchAngle + (math.sin(windPhase + t * 3) * 0.1);
        
        // Anchor is center for flowers
        final scale = flowerSize / imageToUse.width.toDouble();
        final cosVal = math.cos(rotation);
        final sinVal = math.sin(rotation);
        
        final rScos = scale * cosVal;
        final rSsin = scale * sinVal;
        
        final ax = imageToUse.width.toDouble() / 2;
        final ay = imageToUse.height.toDouble() / 2;
        
        final tx = flowerPos.dx - (rScos * ax - rSsin * ay);
        final ty = flowerPos.dy - (rSsin * ax + rScos * ay);

        addToBatch(
          imageToUse,
          RSTransform(rScos, rSsin, tx, ty),
          Rect.fromLTWH(0, 0, imageToUse.width.toDouble(), imageToUse.height.toDouble()),
        );
      }
    }

    final paint = Paint()..filterQuality = FilterQuality.medium;
    
    // Draw regular flowers first
    for (final img in transforms.keys) {
      if (img == blueFlowerImage || img == yellowFlowerImage) continue;
      
      canvas.drawAtlas(
        img,
        transforms[img]!,
        rects[img]!,
        null,
        BlendMode.srcIn,
        null,
        paint,
      );
    }
    
    // Draw special flowers on top (Blue then Yellow)
    if (blueFlowerImage != null && transforms.containsKey(blueFlowerImage)) {
      canvas.drawAtlas(
        blueFlowerImage!,
        transforms[blueFlowerImage!]!,
        rects[blueFlowerImage!]!,
        null,
        BlendMode.srcIn,
        null,
        paint,
      );
    }
    
    if (yellowFlowerImage != null && transforms.containsKey(yellowFlowerImage)) {
      canvas.drawAtlas(
        yellowFlowerImage!,
        transforms[yellowFlowerImage!]!,
        rects[yellowFlowerImage!]!,
        null,
        BlendMode.srcIn,
        null,
        paint,
      );
    }
  }

  void _drawLeafFallback(Canvas canvas, LeafState leaf, BranchState branch) {
    final deformedStart = _deformedStarts[branch.id] ?? branch.start;
    final deformedEnd = _deformedEnds[branch.id] ?? branch.end;
    
    final originalControl = branch.controlPoint;
    final midPoint = Offset(
      (deformedStart.dx + deformedEnd.dx) / 2,
      (deformedStart.dy + deformedEnd.dy) / 2,
    );
    final deformedControl = Offset(
      originalControl.dx + (midPoint.dx - (branch.start.dx + branch.end.dx) / 2) * 0.7,
      originalControl.dy + (midPoint.dy - (branch.start.dy + branch.end.dy) / 2) * 0.7,
    );

    final t = leaf.tOnBranch;
    final point = TreeGeometry.bezierPoint(deformedStart, deformedControl, deformedEnd, t);
    final tangent = TreeGeometry.bezierTangent(deformedStart, deformedControl, deformedEnd, t);
    final branchAngle = math.atan2(tangent.dy, tangent.dx);
    final perpAngle = branchAngle + math.pi / 2;
    
    final depthRatio = branch.depth / parameters.maxDepth;
    final heightFactor = (tree.treeSize - branch.start.dy) / tree.treeSize;
    final flexibilityFactor = depthRatio;
    final windIntensity = 0.4 * heightFactor * flexibilityFactor;
    final branchPhase = windPhase + branch.start.dx * 0.005 + branch.start.dy * 0.005;
    final windAtPoint = math.sin(branchPhase + t * 2.0) * windIntensity * t * t * 0.3;
    final windOffsetX = math.cos(perpAngle) * windAtPoint * tree.treeSize * 0.05;
    final windOffsetY = math.sin(perpAngle) * windAtPoint * tree.treeSize * 0.05;
    
    final deformedPoint = Offset(
      point.dx + windOffsetX,
      point.dy + windOffsetY,
    );
    
    final thicknessAtPoint = branch.thickness * (1.0 - t * 0.3);
    final branchRadius = thicknessAtPoint / 2;
    
    final leafPos = Offset(
      deformedPoint.dx + math.cos(perpAngle) * branchRadius * leaf.side,
      deformedPoint.dy + math.sin(perpAngle) * branchRadius * leaf.side,
    );

    final baseSize = tree.treeSize * 0.06;
    final leafSize = baseSize * leaf.currentGrowth;

    final paint = Paint()
      ..color = leaf.healthState == LeafHealthState.alive ? Colors.green : Colors.brown
      ..style = PaintingStyle.fill;
    canvas.drawCircle(leafPos, leafSize / 2, paint);
  }

  void _drawFlowerFallback(Canvas canvas, FlowerState flower, BranchState branch) {
    final deformedStart = _deformedStarts[branch.id] ?? branch.start;
    final deformedEnd = _deformedEnds[branch.id] ?? branch.end;
    
    final originalControl = branch.controlPoint;
    final midPoint = Offset(
      (deformedStart.dx + deformedEnd.dx) / 2,
      (deformedStart.dy + deformedEnd.dy) / 2,
    );
    final deformedControl = Offset(
      originalControl.dx + (midPoint.dx - (branch.start.dx + branch.end.dx) / 2) * 0.7,
      originalControl.dy + (midPoint.dy - (branch.start.dy + branch.end.dy) / 2) * 0.7,
    );

    final t = flower.tOnBranch;
    final point = TreeGeometry.bezierPoint(deformedStart, deformedControl, deformedEnd, t);
    final tangent = TreeGeometry.bezierTangent(deformedStart, deformedControl, deformedEnd, t);
    final branchAngle = math.atan2(tangent.dy, tangent.dx);
    final perpAngle = branchAngle + math.pi / 2;
    
    final depthRatio = branch.depth / parameters.maxDepth;
    final heightFactor = (tree.treeSize - branch.start.dy) / tree.treeSize;
    final flexibilityFactor = depthRatio;
    final windIntensity = 0.4 * heightFactor * flexibilityFactor;
    final branchPhase = windPhase + branch.start.dx * 0.005 + branch.start.dy * 0.005;
    final windAtPoint = math.sin(branchPhase + t * 2.0) * windIntensity * t * t * 0.3;
    final windOffsetX = math.cos(perpAngle) * windAtPoint * tree.treeSize * 0.05;
    final windOffsetY = math.sin(perpAngle) * windAtPoint * tree.treeSize * 0.05;
    
    final deformedPoint = Offset(
      point.dx + windOffsetX,
      point.dy + windOffsetY,
    );
    
    final thicknessAtPoint = branch.thickness * (1.0 - t * 0.3);
    final branchRadius = thicknessAtPoint / 2;
    
    final flowerPos = Offset(
      deformedPoint.dx + math.cos(perpAngle) * branchRadius * flower.side,
      deformedPoint.dy + math.sin(perpAngle) * branchRadius * flower.side,
    );

    final ageFactor = tree.age < 30 
        ? 0.5 + (tree.age / 30.0) * 0.5
        : 1.0;
    
    final baseSize = tree.treeSize * 0.08 * ageFactor;
    final flowerSize = baseSize * flower.sizeFactor;

    Color color;
    switch (flower.flowerType) {
      case 0:
        color = Colors.pink;
        break;
      case 1:
        color = Colors.white;
        break;
      case 2:
        color = Colors.blue;
        break;
      case 3:
        color = Colors.yellow;
        break;
      default:
        color = Colors.pink;
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(flowerPos, flowerSize / 2, paint);
  }

  @override
  bool shouldRepaint(TreePainter oldDelegate) {
    // Always repaint if wind phase changed (for animation)
    if (oldDelegate.windPhase != windPhase) return true;
    
    // Repaint if tree structure changed
    if (oldDelegate.tree.age != tree.age) return true;
    if (oldDelegate.tree.treeSize != tree.treeSize) return true;
    if (oldDelegate.tree.getTotalLeafCount() != tree.getTotalLeafCount()) return true;
    if (oldDelegate.tree.getTotalFlowerCount() != tree.getTotalFlowerCount()) return true;
    
    // Repaint if parameters changed (TreeParameters has equality operator)
    if (oldDelegate.parameters != parameters) return true;
    
    // Repaint if images changed (loaded/unloaded)
    if (oldDelegate.leafImage != leafImage) return true;
    if (oldDelegate.flowerImage != flowerImage) return true;
    if (oldDelegate.jasminImage != jasminImage) return true;
    if (oldDelegate.blueFlowerImage != blueFlowerImage) return true;
    if (oldDelegate.yellowFlowerImage != yellowFlowerImage) return true;
    if (oldDelegate.barkImage != barkImage) return true;
    if (oldDelegate.grassBackgroundImage != grassBackgroundImage) return true;
    if (oldDelegate.grassForegroundImage != grassForegroundImage) return true;
    
    // No changes detected
    return false;
  }
}
