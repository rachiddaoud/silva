import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:ma_bulle/models/tree/tree_parameters.dart';
import 'package:ma_bulle/models/tree/tree_state.dart';
import 'package:ma_bulle/logic/tree_logic.dart';

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

    // Draw leaves
    for (final branch in sortedBranches) {
      for (final leaf in branch.leaves) {
        if (leaf.currentGrowth > 0.0) {
          _drawLeaf(canvas, leaf, branch);
        }
      }
    }

    // Draw flowers
    for (final branch in sortedBranches) {
      for (final flower in branch.flowers) {
        _drawFlower(canvas, flower, branch);
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
        // Find parent branch
        // We can't easily find parent by object reference since we have immutable states
        // But we can infer it from the ID structure or search.
        // ID structure is parentId_index.
        // Or we can assume the parent's end is close to this branch's start.
        // A more robust way with the new state would be to pass parent down or map IDs.
        // For now, let's use the ID parsing which is reliable with our generator.
        
        final lastUnderscore = branch.id.lastIndexOf('_');
        final parentId = lastUnderscore != -1 ? branch.id.substring(0, lastUnderscore) : null;
        
        if (parentId != null && _deformedEnds.containsKey(parentId)) {
           deformedStart = _deformedEnds[parentId]!;
        } else {
           // Fallback to original start if parent not found (shouldn't happen if sorted correctly)
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
    const numSegments = 20;
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

  void _drawLeaf(Canvas canvas, LeafState leaf, BranchState branch) {
    if (leaf.currentGrowth <= 0.0) return;
    
    final deformedStart = _deformedStarts[branch.id] ?? branch.start;
    final deformedEnd = _deformedEnds[branch.id] ?? branch.end;
    
    // Approximate deformed control point (same logic as in _drawBranch)
    final originalControl = branch.controlPoint;
    final midPoint = Offset(
      (deformedStart.dx + deformedEnd.dx) / 2,
      (deformedStart.dy + deformedEnd.dy) / 2,
    );
    final deformedControl = Offset(
      originalControl.dx + (midPoint.dx - (branch.start.dx + branch.end.dx) / 2) * 0.7,
      originalControl.dy + (midPoint.dy - (branch.start.dy + branch.end.dy) / 2) * 0.7,
    );

    // Calculate position on deformed branch
    final t = leaf.tOnBranch;
    final point = TreeGeometry.bezierPoint(deformedStart, deformedControl, deformedEnd, t);
    final tangent = TreeGeometry.bezierTangent(deformedStart, deformedControl, deformedEnd, t);
    final branchAngle = math.atan2(tangent.dy, tangent.dx);
    final perpAngle = branchAngle + math.pi / 2;
    
    // Apply wind effect at this point
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

    // Determine which image to use based on health state
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

    // Calculate size
    final depthFactor = 1.5 - (branch.depth - 1) * 0.3;
    final clampedDepthFactor = depthFactor.clamp(0.4, 1.5);
    final ageFactor = 0.5 + (branch.age / 20.0).clamp(0.0, 0.5);
    final maxSize = clampedDepthFactor * ageFactor * leaf.randomSizeFactor;
    final currentSize = maxSize * leaf.currentGrowth;
    
    final baseSize = tree.treeSize * 0.06;
    final leafSize = baseSize * currentSize;

    if (imageToUse != null) {
      canvas.save();
      canvas.translate(leafPos.dx, leafPos.dy);
      
      // Rotate leaf to lean along the branch tangent
      // The image points UP (negative Y) from its anchor.
      // side = 1 means right side, side = -1 means left side
      // We want leaves to point somewhat along the branch but not perfectly perpendicular
      // Use perpAngle as base but reduce the offset to lean toward the tangent
      
      final leafAngle = perpAngle + (leaf.side * math.pi / 6); // perpendicular ± 30°
      final windRotation = math.sin(windPhase + t * 5) * 0.2;
      canvas.rotate(leafAngle + windRotation);
      
      final imageAspectRatio = imageToUse.width.toDouble() / imageToUse.height.toDouble();
      final height = leafSize;
      final width = height * imageAspectRatio;
      
      final srcRect = Rect.fromLTWH(0, 0, imageToUse.width.toDouble(), imageToUse.height.toDouble());
      
      // Anchor at bottom center (stem)
      final dstRect = Rect.fromLTWH(
        -width / 2,
        -height,
        width,
        height,
      );
      
      canvas.drawImageRect(imageToUse, srcRect, dstRect, Paint()..filterQuality = FilterQuality.medium);
      canvas.restore();
    } else {
      // Fallback drawing
      final paint = Paint()
        ..color = leaf.healthState == LeafHealthState.alive ? Colors.green : Colors.brown
        ..style = PaintingStyle.fill;
      canvas.drawCircle(leafPos, leafSize / 2, paint);
    }
  }

  void _drawFlower(Canvas canvas, FlowerState flower, BranchState branch) {
    final deformedStart = _deformedStarts[branch.id] ?? branch.start;
    final deformedEnd = _deformedEnds[branch.id] ?? branch.end;
    
    // Approximate deformed control point
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
    
    // Wind effect
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

    final imageToUse = flower.flowerType == 1 ? jasminImage : flowerImage;
    
    // Scale flower size based on tree age - smaller flowers for young trees
    final ageFactor = tree.age < 30 
        ? 0.5 + (tree.age / 30.0) * 0.5  // 50% to 100% over first 30 days
        : 1.0;  // Full size after 30 days
    
    final baseSize = tree.treeSize * 0.08 * ageFactor;
    final flowerSize = baseSize * flower.sizeFactor;

    if (imageToUse != null) {
      canvas.save();
      canvas.translate(flowerPos.dx, flowerPos.dy);
      
      // Flowers rotate less with wind, mostly just bob
      canvas.rotate(branchAngle + (math.sin(windPhase + t * 3) * 0.1));
      
      final srcRect = Rect.fromLTWH(0, 0, imageToUse.width.toDouble(), imageToUse.height.toDouble());
      final dstRect = Rect.fromCenter(
        center: Offset.zero,
        width: flowerSize,
        height: flowerSize,
      );
      
      canvas.drawImageRect(imageToUse, srcRect, dstRect, Paint()..filterQuality = FilterQuality.medium);
      canvas.restore();
    } else {
      final paint = Paint()
        ..color = flower.flowerType == 1 ? Colors.white : Colors.pink
        ..style = PaintingStyle.fill;
      canvas.drawCircle(flowerPos, flowerSize / 2, paint);
    }
  }

  @override
  bool shouldRepaint(TreePainter oldDelegate) {
    return oldDelegate.tree != tree ||
           oldDelegate.windPhase != windPhase ||
           oldDelegate.parameters != parameters;
  }
}
