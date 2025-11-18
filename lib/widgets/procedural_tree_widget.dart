import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Information sur une feuille avec sa position et celle de sa branche
class LeafInfo {
  final Offset position;
  final Offset branchPosition; // Position sur la branche pour calculer l'orientation
  final Offset branchStart; // Début de la branche
  final Offset branchEnd; // Fin de la branche
  final Offset branchControl; // Point de contrôle de la branche (pour courbe Bézier)

  LeafInfo({
    required this.position,
    required this.branchPosition,
    required this.branchStart,
    required this.branchEnd,
    required this.branchControl,
  });
}

/// Classe représentant une branche d'arbre
class TreeBranch {
  final Offset start;
  final Offset end;
  final Offset controlPoint; // Point de contrôle pour la courbe
  final double angle;
  final double length;
  final double thickness;
  final int depth;
  final List<LeafInfo> leaves; // Informations sur les feuilles le long de la branche

  TreeBranch({
    required this.start,
    required this.end,
    required this.controlPoint,
    required this.angle,
    required this.length,
    required this.thickness,
    required this.depth,
    this.leaves = const [],
  });
}

/// Paramètres de génération de l'arbre
class TreeParameters {
  final int maxDepth;
  final double baseBranchAngle; // en radians
  final double lengthRatio;
  final double thicknessRatio;
  final double angleVariation;
  final double curveIntensity;
  final int seed;

  const TreeParameters({
    this.maxDepth = 6,
    this.baseBranchAngle = 32.2 * math.pi / 180,
    this.lengthRatio = 0.78,
    this.thicknessRatio = 0.54,
    this.angleVariation = 0.25,
    this.curveIntensity = 0.20,
    this.seed = 610940,
  });

  TreeParameters copyWith({
    int? maxDepth,
    double? baseBranchAngle,
    double? lengthRatio,
    double? thicknessRatio,
    double? angleVariation,
    double? curveIntensity,
    int? seed,
  }) {
    return TreeParameters(
      maxDepth: maxDepth ?? this.maxDepth,
      baseBranchAngle: baseBranchAngle ?? this.baseBranchAngle,
      lengthRatio: lengthRatio ?? this.lengthRatio,
      thicknessRatio: thicknessRatio ?? this.thicknessRatio,
      angleVariation: angleVariation ?? this.angleVariation,
      curveIntensity: curveIntensity ?? this.curveIntensity,
      seed: seed ?? this.seed,
    );
  }

  /// Génère des paramètres aléatoires
  factory TreeParameters.random(math.Random random) {
    return TreeParameters(
      maxDepth: 8 + random.nextInt(5), // 8-12
      baseBranchAngle: (15.0 + random.nextDouble() * 20.0) * math.pi / 180, // 15-35 degrés
      lengthRatio: 0.5 + random.nextDouble() * 0.3, // 0.5-0.8
      thicknessRatio: 0.5 + random.nextDouble() * 0.3, // 0.5-0.8
      angleVariation: 0.2 + random.nextDouble() * 0.4, // 0.2-0.6
      curveIntensity: 0.1 + random.nextDouble() * 0.4, // 0.1-0.5
      seed: random.nextInt(1000000),
    );
  }
}

/// Widget pour afficher un arbre généré procéduralement
class ProceduralTreeWidget extends StatefulWidget {
  final double size;
  final double growthLevel; // 0.0 à 1.0 pour contrôler la progression
  final TreeParameters parameters;

  const ProceduralTreeWidget({
    super.key,
    this.size = 200,
    this.growthLevel = 0.5,
    required this.parameters,
  });

  @override
  State<ProceduralTreeWidget> createState() => _ProceduralTreeWidgetState();
}

class _ProceduralTreeWidgetState extends State<ProceduralTreeWidget> {
  ui.Image? _leafImage;
  ui.Image? _groundImage;

  @override
  void initState() {
    super.initState();
    _loadLeafImage();
    _loadGroundImage();
  }

  Future<void> _loadLeafImage() async {
    try {
      final ByteData data = await rootBundle.load('assets/leaf.png');
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _leafImage = frameInfo.image;
        });
      }
    } catch (e) {
      // Si l'image ne peut pas être chargée, on utilisera le dessin vectoriel
      _leafImage = null;
    }
  }

  Future<void> _loadGroundImage() async {
    try {
      final ByteData data = await rootBundle.load('assets/terre.png');
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _groundImage = frameInfo.image;
        });
      }
    } catch (e) {
      // Si l'image ne peut pas être chargée, on ne dessinera pas de terre
      _groundImage = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
            painter: TreePainter(
              growthLevel: widget.growthLevel,
              treeSize: widget.size,
              parameters: widget.parameters,
              leafImage: _leafImage,
              groundImage: _groundImage,
            ),
      ),
    );
  }
}

/// Painter pour dessiner l'arbre procédural
class TreePainter extends CustomPainter {
  final double growthLevel;
  final double treeSize;
  final TreeParameters parameters;
  final ui.Image? leafImage;
  final ui.Image? groundImage;
  late final List<TreeBranch> _branches;
  List<LeafInfo> _leaves = []; // Mutable car réassigné dans _optimizeLeafDistribution
  late final double _fractionalDepth; // Profondeur fractionnaire pour croissance progressive

  TreePainter({
    required this.growthLevel,
    required this.treeSize,
    required this.parameters,
    this.leafImage,
    this.groundImage,
  }) {
    // Calculer la profondeur fractionnaire pour croissance progressive
    _fractionalDepth = parameters.maxDepth * growthLevel.clamp(0.0, 1.0);
    _branches = [];
    _leaves = [];
    _generateTree();
    // Collecter toutes les feuilles depuis les branches
    for (final branch in _branches) {
      _leaves.addAll(branch.leaves);
    }
    // Optimiser la distribution des feuilles pour éviter les chevauchements
    _optimizeLeafDistribution();
  }

  /// Optimise la distribution des feuilles pour éviter les chevauchements
  void _optimizeLeafDistribution() {
    if (_leaves.isEmpty) return;
    
    // Taille estimée d'une feuille pour calculer l'espacement minimal
    final leafSize = treeSize * 0.08; // Taille estimée d'une feuille (2x plus grande)
    final minDistance = leafSize * 1.3; // Distance minimale entre feuilles (30% d'espace)
    
    // Créer une map pour trouver rapidement la profondeur d'une feuille
    final leafDepthMap = <LeafInfo, int>{};
    for (final branch in _branches) {
      for (final leaf in branch.leaves) {
        leafDepthMap[leaf] = branch.depth;
      }
    }
    
    // Trier les feuilles par profondeur (les plus profondes en premier)
    _leaves.sort((a, b) {
      final depthA = leafDepthMap[a] ?? 0;
      final depthB = leafDepthMap[b] ?? 0;
      return depthB.compareTo(depthA); // Plus profond d'abord
    });
    
    // Liste des positions validées
    final validLeaves = <LeafInfo>[];
    
    for (final leaf in _leaves) {
      bool tooClose = false;
      
      // Vérifier la distance avec les feuilles déjà validées
      for (final validLeaf in validLeaves) {
        final distance = (leaf.position - validLeaf.position).distance;
        if (distance < minDistance) {
          tooClose = true;
          break;
        }
      }
      
      // Si la feuille n'est pas trop proche, l'ajouter
      if (!tooClose) {
        validLeaves.add(leaf);
      }
    }
    
    _leaves = validLeaves;
  }

  void _generateTree() {
    final random = math.Random(parameters.seed);
    final effectiveDepth = _fractionalDepth.floor();
    final depthFraction = _fractionalDepth - effectiveDepth; // Fraction du dernier niveau (0.0 à 1.0)
    
    if (effectiveDepth == 0 && depthFraction < 0.01) return;

    // Position de départ : centre vertical de la terre (où l'arbre sort de la terre)
    final treeBase = _getTreeBasePosition();
    final startX = treeBase.dx;
    final startY = treeBase.dy;
    
    // Le tronc grandit progressivement avec le niveau de croissance
    // Commence très petit (comme une graine) et s'élargit au fur et à mesure
    final growthFactor = growthLevel.clamp(0.0, 1.0); // Facteur de croissance (0.0 à 1.0)
    
    // Longueur du tronc : commence à 5% et grandit jusqu'à 25% de la taille de l'arbre
    final trunkLength = treeSize * (0.05 + 0.20 * growthFactor);
    
    // Épaisseur du tronc : commence très fine (1%) et s'élargit jusqu'à 6% de la taille de l'arbre
    // Utiliser une courbe pour que l'élargissement soit plus visible au début
    final thicknessGrowth = growthFactor * growthFactor; // Courbe quadratique pour un élargissement progressif
    final trunkThickness = treeSize * (0.01 + 0.05 * thicknessGrowth);

    // Calcul de l'extrémité du tronc
    final trunkAngle = -math.pi / 2; // Vers le haut
    final trunkEnd = Offset(
      startX + math.cos(trunkAngle) * trunkLength,
      startY + math.sin(trunkAngle) * trunkLength,
    );

    // Point de contrôle pour courber légèrement le tronc
    final trunkControl = Offset(
      startX + math.cos(trunkAngle) * trunkLength * 0.5 + (random.nextDouble() - 0.5) * treeSize * 0.05,
      startY + math.sin(trunkAngle) * trunkLength * 0.5,
    );

    // Création du tronc principal
    final trunk = TreeBranch(
      start: Offset(startX, startY),
      end: trunkEnd,
      controlPoint: trunkControl,
      angle: trunkAngle,
      length: trunkLength,
      thickness: trunkThickness,
      depth: 0,
      leaves: [],
    );

    // Génération récursive des branches
    _branches.add(trunk);
    _generateBranches(trunk, effectiveDepth, depthFraction, random);
  }

  void _generateBranches(
    TreeBranch parent,
    int maxDepth,
    double depthFraction,
    math.Random random,
  ) {
    // Nombre de branches (2 ou 3)
    final numBranches = random.nextBool() ? 2 : 3;

    final newDepth = parent.depth + 1;
    
    for (int i = 0; i < numBranches; i++) {
      // Angle de branchement avec variation
      final angleVariationFactor = (random.nextDouble() - 0.5) * parameters.angleVariation;
      final branchAngle = parent.angle +
          parameters.baseBranchAngle * (i % 2 == 0 ? 1 : -1) +
          angleVariationFactor;

      // Longueur avec variation
      final lengthVariation = 0.85 + random.nextDouble() * 0.3; // 0.85 à 1.15
      var branchLength = parent.length * parameters.lengthRatio * lengthVariation;
      
      // Si on est au dernier niveau partiel, réduire la longueur progressivement
      if (newDepth == maxDepth && depthFraction < 1.0) {
        branchLength *= depthFraction; // Réduire la longueur selon la fraction
      }

      // Épaisseur décroissante
      final branchThickness = parent.thickness * parameters.thicknessRatio;

      // Position de départ (extrémité de la branche parent)
      final branchStart = parent.end;

      // Calcul de l'extrémité
      final branchEnd = Offset(
        branchStart.dx + math.cos(branchAngle) * branchLength,
        branchStart.dy + math.sin(branchAngle) * branchLength,
      );

      // Point de contrôle pour créer une courbe arrondie
      // Le point de contrôle est décalé perpendiculairement pour créer une courbe naturelle
      final curveOffset = (random.nextDouble() - 0.5) * parameters.curveIntensity;
      final midPoint = Offset(
        (branchStart.dx + branchEnd.dx) / 2,
        (branchStart.dy + branchEnd.dy) / 2,
      );
      final perpAngle = branchAngle + math.pi / 2;
      final branchControl = Offset(
        midPoint.dx + math.cos(perpAngle) * branchLength * curveOffset,
        midPoint.dy + math.sin(perpAngle) * branchLength * curveOffset,
      );

      // Générer des positions de feuilles le long de la branche
      final leaves = <LeafInfo>[];
      
      // Calculer le nombre de feuilles en fonction de la taille de l'arbre et de la longueur de la branche
      // Plus la branche est longue et plus on est profond, plus il y a de feuilles
      if (newDepth >= 2) {
        // Nombre de feuilles basé sur la longueur de la branche et la profondeur
        // Formule : longueur de branche normalisée * facteur de profondeur
        final normalizedLength = branchLength / treeSize; // Normaliser par rapport à la taille de l'arbre
        final depthFactor = (newDepth - 1) / parameters.maxDepth; // Facteur basé sur la profondeur
        final baseLeafCount = (normalizedLength * 30 * (1 + depthFactor)).round(); // 30 feuilles par unité de longueur (augmenté de 15)
        final numLeaves = math.max(2, baseLeafCount + random.nextInt(3) - 1); // Variation de ±1, minimum 2
        
        // Espacement le long de la branche pour éviter les chevauchements
        final leafSpacing = 1.0 / (numLeaves + 1); // Espacement uniforme
        
        for (int j = 0; j < numLeaves; j++) {
          // Position le long de la branche avec espacement régulier
          final t = 0.3 + (j + 1) * leafSpacing * 0.7; // Entre 30% et 100% de la branche
          
          // Calculer la position sur la courbe de Bézier (position sur la branche)
          final branchPos = _bezierPoint(branchStart, branchControl, branchEnd, t);
          
          // Distance entre la branche et la feuille (plus loin des branches)
          final baseOffset = branchLength * 0.25; // 25% de la longueur de la branche (augmenté de 12%)
          final randomOffset = (random.nextDouble() - 0.5) * branchLength * 0.08; // Légère variation
          final totalOffset = baseOffset + randomOffset;
          
          // Angle perpendiculaire à la branche à ce point (90° exactement)
          final tangent = _bezierTangent(branchStart, branchControl, branchEnd, t);
          final perpAngle = math.atan2(tangent.dy, tangent.dx) + math.pi / 2; // Exactement 90°
          
          // Choisir le côté (gauche ou droite) pour orienter vers l'extérieur
          // Alterner ou choisir aléatoirement pour plus de naturel
          final side = (j % 2 == 0) ? 1 : -1; // Alterner les côtés
          
          // Position de la feuille (décalée perpendiculairement à la branche)
          final leafPos = Offset(
            branchPos.dx + math.cos(perpAngle) * totalOffset * side,
            branchPos.dy + math.sin(perpAngle) * totalOffset * side,
          );
          
          leaves.add(LeafInfo(
            position: leafPos,
            branchPosition: branchPos,
            branchStart: branchStart,
            branchEnd: branchEnd,
            branchControl: branchControl,
          ));
        }
      }

      // Ajouter une feuille à l'extrémité si c'est la dernière profondeur
      if (newDepth >= maxDepth) {
        // Calculer la direction de la branche à l'extrémité
        final endTangent = _bezierTangent(branchStart, branchControl, branchEnd, 0.95);
        final endPerpAngle = math.atan2(endTangent.dy, endTangent.dx) + math.pi / 2; // 90° exactement
        final endOffset = branchLength * 0.25; // Plus loin (augmenté de 0.1)
        
        leaves.add(LeafInfo(
          position: Offset(
            branchEnd.dx + math.cos(endPerpAngle) * endOffset,
            branchEnd.dy + math.sin(endPerpAngle) * endOffset,
          ),
          branchPosition: branchEnd,
          branchStart: branchStart,
          branchEnd: branchEnd,
          branchControl: branchControl,
        ));
      }

      // Création de la branche
      final branch = TreeBranch(
        start: branchStart,
        end: branchEnd,
        controlPoint: branchControl,
        angle: branchAngle,
        length: branchLength,
        thickness: branchThickness,
        depth: newDepth,
        leaves: leaves,
      );

      _branches.add(branch);

      // Récursion pour les branches enfants
      if (newDepth < maxDepth) {
        _generateBranches(branch, maxDepth, depthFraction, random);
      }
    }
  }

  /// Calcule un point sur une courbe de Bézier quadratique
  Offset _bezierPoint(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1 - t;
    final tt = t * t;
    final uu = u * u;
    
    return Offset(
      uu * p0.dx + 2 * u * t * p1.dx + tt * p2.dx,
      uu * p0.dy + 2 * u * t * p1.dy + tt * p2.dy,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Dessiner l'arbre en premier (en arrière-plan)
    // Dessiner les branches (du plus profond au moins profond pour le z-ordering)
    final sortedBranches = List<TreeBranch>.from(_branches)
      ..sort((a, b) => b.depth.compareTo(a.depth));
    
    for (final branch in sortedBranches) {
      _drawBranch(canvas, branch);
    }

    // Dessiner les feuilles
    for (final leafInfo in _leaves) {
      _drawLeaf(canvas, leafInfo);
    }
    
    // Dessiner la terre par-dessus (en premier plan) pour que l'arbre soit derrière
    _drawGround(canvas, size);
  }

  /// Dessine l'image de terre à la base de l'arbre
  void _drawGround(Canvas canvas, Size size) {
    if (groundImage == null) return;
    
    // Dimensions de l'image de terre
    final imageWidth = groundImage!.width.toDouble();
    final imageHeight = groundImage!.height.toDouble();
    final aspectRatio = imageWidth / imageHeight;
    
    // Largeur de la terre : un peu plus large que l'arbre pour un effet naturel
    final groundWidth = treeSize * 0.8;
    final groundHeight = groundWidth / aspectRatio;
    
    // Position : centrée horizontalement, positionnée pour que le centre vertical soit à la base de l'arbre
    final groundX = (size.width - groundWidth) / 2;
    // Le centre vertical de la terre doit être à la position de départ du tronc
    final treeBaseY = treeSize * 0.75;
    final groundY = treeBaseY - groundHeight / 2; // Centrer verticalement sur la base de l'arbre
    
    // Rectangle de destination
    final dstRect = Rect.fromLTWH(
      groundX,
      groundY,
      groundWidth,
      groundHeight,
    );
    
    // Rectangle source (toute l'image)
    final srcRect = Rect.fromLTWH(0, 0, imageWidth, imageHeight);
    
    // Dessiner l'image de terre
    canvas.drawImageRect(
      groundImage!,
      srcRect,
      dstRect,
      Paint()..filterQuality = FilterQuality.high,
    );
  }
  
  /// Calcule la position de départ du tronc (centre vertical de la terre)
  Offset _getTreeBasePosition() {
    if (groundImage == null) {
      // Fallback si pas d'image de terre
      return Offset(treeSize / 2, treeSize * 0.75);
    }
    
    // Dimensions de l'image de terre
    final imageWidth = groundImage!.width.toDouble();
    final imageHeight = groundImage!.height.toDouble();
    final aspectRatio = imageWidth / imageHeight;
    
    // Largeur de la terre
    final groundWidth = treeSize * 0.8;
    final groundHeight = groundWidth / aspectRatio;
    
    // Position de la terre
    final groundX = (treeSize - groundWidth) / 2;
    final treeBaseY = treeSize * 0.75;
    final groundY = treeBaseY - groundHeight / 2;
    
    // Le centre vertical de la terre (où l'arbre doit commencer)
    final groundCenterX = groundX + groundWidth / 2;
    final groundCenterY = groundY + groundHeight / 2;
    
    return Offset(groundCenterX, groundCenterY);
  }

  void _drawBranch(Canvas canvas, TreeBranch branch) {
    // Calcul de la couleur selon la profondeur
    // Du brun foncé (tronc) au vert/brun clair (extrémités)
    final depthRatio = branch.depth / parameters.maxDepth;
    final brown = Color.lerp(
      const Color(0xFF5D4037), // Brun foncé
      const Color(0xFF8D6E63), // Brun moyen
      depthRatio.clamp(0.0, 1.0),
    )!;
    final green = Color.lerp(
      const Color(0xFF6B8E23), // Vert olive
      const Color(0xFF9ACD32), // Vert jaune
      depthRatio.clamp(0.0, 1.0),
    )!;
    final branchColor = Color.lerp(brown, green, depthRatio * 0.5)!;

    final paint = Paint()
      ..color = branchColor
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    // Vérifier si la branche a des enfants (branches qui commencent à son extrémité)
    final tolerance = treeSize * 0.01; // Tolérance relative à la taille de l'arbre
    final hasChildren = _branches.any((b) => 
      b.depth == branch.depth + 1 && 
      (b.start - branch.end).distance < tolerance // Tolérance pour les erreurs d'arrondi
    );

    // Dessiner la branche avec une courbe de Bézier arrondie
    // On crée un path avec une épaisseur variable le long de la courbe
    final path = Path();
    
    // Nombre de segments pour créer une courbe lisse
    const numSegments = 20;
    final halfThicknessStart = (branch.thickness / parameters.thicknessRatio) / 2;
    
    // Si la branche n'a pas d'enfants, elle se termine en pointe (épaisseur proche de zéro)
    // Sinon, elle garde une épaisseur minimale pour se connecter aux branches enfants
    final halfThicknessEnd = hasChildren 
      ? branch.thickness / 2 // Épaisseur normale si elle a des enfants
      : branch.thickness * 0.05; // Presque zéro pour terminer en pointe
    
    // Points le long de la courbe pour créer le contour
    final topPoints = <Offset>[];
    final bottomPoints = <Offset>[];
    
    for (int i = 0; i <= numSegments; i++) {
      final t = i / numSegments;
      final point = _bezierPoint(branch.start, branch.controlPoint, branch.end, t);
      
      // Calculer l'angle tangent à la courbe à ce point
      final tangent = _bezierTangent(branch.start, branch.controlPoint, branch.end, t);
      final perpAngle = math.atan2(tangent.dy, tangent.dx) + math.pi / 2;
      
      // Épaisseur interpolée avec une courbe d'ease-out pour une transition plus naturelle
      // Utiliser une fonction quadratique pour créer une pointe plus naturelle
      final easeOut = 1 - (1 - t) * (1 - t); // Courbe d'ease-out quadratique
      final thickness = halfThicknessStart * (1 - easeOut) + halfThicknessEnd * easeOut;
      
      topPoints.add(Offset(
        point.dx + math.cos(perpAngle) * thickness,
        point.dy + math.sin(perpAngle) * thickness,
      ));
      bottomPoints.add(Offset(
        point.dx - math.cos(perpAngle) * thickness,
        point.dy - math.sin(perpAngle) * thickness,
      ));
    }
    
    // Créer le path fermé
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

  /// Calcule la tangente à une courbe de Bézier quadratique
  Offset _bezierTangent(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1 - t;
    return Offset(
      2 * u * (p1.dx - p0.dx) + 2 * t * (p2.dx - p1.dx),
      2 * u * (p1.dy - p0.dy) + 2 * t * (p2.dy - p1.dy),
    );
  }

  void _drawLeaf(Canvas canvas, LeafInfo leafInfo) {
    final random = math.Random((leafInfo.position.dx * 1000 + leafInfo.position.dy).toInt());
    
    // Taille de la feuille - deux fois plus grande
    final baseSize = treeSize * 0.08; // 2x plus grand (0.04 * 2 = 0.08)
    final leafSize = baseSize * (0.9 + random.nextDouble() * 0.2); // Légère variation 0.9-1.1
    
    // Calculer l'angle perpendiculaire à la branche
    // Trouver le paramètre t sur la courbe de Bézier le plus proche de la position de la feuille
    double t = 0.5; // Valeur par défaut
    double minDist = double.infinity;
    
    // Chercher le point le plus proche sur la courbe
    for (int i = 0; i <= 20; i++) {
      final testT = i / 20.0;
      final pointOnBranch = _bezierPoint(
        leafInfo.branchStart,
        leafInfo.branchControl,
        leafInfo.branchEnd,
        testT,
      );
      final dist = (pointOnBranch - leafInfo.branchPosition).distance;
      if (dist < minDist) {
        minDist = dist;
        t = testT;
      }
    }
    
    // Calculer la tangente à la courbe de Bézier au point t
    final tangent = _bezierTangent(
      leafInfo.branchStart,
      leafInfo.branchControl,
      leafInfo.branchEnd,
      t,
    );
    
    // Angle perpendiculaire à la tangente (90° exactement)
    // La feuille est orientée perpendiculairement à la branche
    var rotation = math.atan2(tangent.dy, tangent.dx) + math.pi / 2; // Exactement 90°
    
    // Compenser l'orientation diagonale de l'image de la feuille
    // L'image est orientée à environ -45° (diagonale), donc on ajuste pour qu'elle soit droite
    final leafImageAngle = -math.pi / 4; // -45° pour compenser l'orientation diagonale de l'image
    rotation += leafImageAngle;
    
    // Sauvegarder l'état du canvas
    canvas.save();
    
    // Appliquer la rotation et translation
    canvas.translate(leafInfo.position.dx, leafInfo.position.dy);
    canvas.rotate(rotation);
    
    // Dessiner l'image de la feuille si disponible, sinon dessin vectoriel
    if (leafImage != null) {
      _drawLeafImage(canvas, leafSize);
    } else {
      // Fallback : dessin vectoriel simple
      _drawVectorLeafFallback(canvas, leafSize);
    }
    
    // Restaurer l'état du canvas
    canvas.restore();
  }

  /// Dessine l'image de la feuille
  void _drawLeafImage(Canvas canvas, double size) {
    if (leafImage == null) return;
    
    final imageWidth = leafImage!.width.toDouble();
    final imageHeight = leafImage!.height.toDouble();
    
    // Calculer les dimensions pour garder les proportions
    final aspectRatio = imageWidth / imageHeight;
    final drawWidth = size * 2;
    final drawHeight = drawWidth / aspectRatio;
    
    // Rectangle de destination centré
    final dstRect = Rect.fromCenter(
      center: Offset.zero,
      width: drawWidth,
      height: drawHeight,
    );
    
    // Rectangle source (toute l'image)
    final srcRect = Rect.fromLTWH(0, 0, imageWidth, imageHeight);
    
    // Dessiner l'image
    canvas.drawImageRect(
      leafImage!,
      srcRect,
      dstRect,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  /// Dessin vectoriel de fallback si l'image n'est pas disponible
  void _drawVectorLeafFallback(Canvas canvas, double size) {
    final width = size * 1.8;
    final height = size * 3.0;
    
    final path = Path();
    path.moveTo(0, height * 0.5);
    path.quadraticBezierTo(-width * 0.3, height * 0.2, -width * 0.35, -height * 0.1);
    path.quadraticBezierTo(-width * 0.25, -height * 0.3, 0, -height * 0.5);
    path.quadraticBezierTo(width * 0.25, -height * 0.3, width * 0.35, -height * 0.1);
    path.quadraticBezierTo(width * 0.3, height * 0.2, 0, height * 0.5);
    path.close();
    
    final paint = Paint()
      ..color = const Color(0xFF66BB6A)
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(path, paint);
  }


  @override
  bool shouldRepaint(TreePainter oldDelegate) {
    return oldDelegate.growthLevel != growthLevel ||
        oldDelegate.treeSize != treeSize ||
        oldDelegate.leafImage != leafImage ||
        oldDelegate.groundImage != groundImage ||
        oldDelegate.parameters.seed != parameters.seed ||
        oldDelegate.parameters.maxDepth != parameters.maxDepth ||
        oldDelegate.parameters.baseBranchAngle != parameters.baseBranchAngle ||
        oldDelegate.parameters.lengthRatio != parameters.lengthRatio ||
        oldDelegate.parameters.thicknessRatio != parameters.thicknessRatio ||
        oldDelegate.parameters.angleVariation != parameters.angleVariation ||
        oldDelegate.parameters.curveIntensity != parameters.curveIntensity;
  }
}

