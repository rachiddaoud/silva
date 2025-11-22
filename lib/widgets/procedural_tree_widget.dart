import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ma_bulle/models/tree_model.dart' as tree_model;
import 'package:ma_bulle/services/tree_service.dart';

// Réexporter LeafState pour compatibilité
typedef LeafState = tree_model.LeafState;
typedef TreeParameters = tree_model.TreeParameters;


/// Widget pour afficher un arbre généré procéduralement
class ProceduralTreeWidget extends StatefulWidget {
  final double size;
  final double growthLevel; // 0.0 à 1.0 pour contrôler la progression
  final TreeParameters parameters;
  final TreeController controller;

  const ProceduralTreeWidget({
    super.key,
    this.size = 200,
    this.growthLevel = 0.5,
    required this.parameters,
    required this.controller,
    this.targetLeafCount = 0,
    this.targetFlowerCount = 0,
    this.targetDeadLeafCount = 0,
  });

  final int targetLeafCount;
  final int targetFlowerCount;
  final int targetDeadLeafCount;

  @override
  State<ProceduralTreeWidget> createState() => ProceduralTreeWidgetState();
}

/// GlobalKey pour accéder à l'état du widget depuis l'extérieur
typedef ProceduralTreeWidgetStateKey = GlobalKey<ProceduralTreeWidgetState>;

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
  
  final TreeController _treeController = TreeController();
  
  // Getter pour accéder à l'arbre depuis l'extérieur
  tree_model.Tree? get tree => _treeController.tree;

  @override
  void initState() {
    super.initState();
    _loadLeafImage();
    _loadLeafDead1Image();
    _loadLeafDead2Image();
    _loadLeafDead3Image();
    _loadFlowerImage();
    _loadJasminImage();
    _loadGrassBackgroundImage();
    _loadGrassForegroundImage();
    _loadBarkImage();
    
    // Animation pour l'effet de vent (oscillation continue)
    _windController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    // Animation sinusoïdale pour un mouvement naturel
    _windAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _windController,
        curve: Curves.linear,
      ),
    );
    
    // Initialiser l'arbre
    _updateTree();
    
    // Appliquer les cibles initiales
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateTreeTargets();
    });
  }

  void _updateTree() {
    widget.controller.updateTree(
      growthLevel: widget.growthLevel,
      size: widget.size,
      parameters: widget.parameters,
    );
  }

  Future<void> _loadLeafImage() async {
    try {
      final ByteData data = await rootBundle.load('assets/tree/leaf.png');
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

  Future<void> _loadLeafDead1Image() async {
    try {
      final ByteData data = await rootBundle.load('assets/tree/leaf_dead_1.png');
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _leafDead1Image = frameInfo.image;
        });
      }
    } catch (e) {
      // Si l'image ne peut pas être chargée, on utilisera le dessin vectoriel
      _leafDead1Image = null;
    }
  }

  Future<void> _loadLeafDead2Image() async {
    try {
      final ByteData data = await rootBundle.load('assets/tree/leaf_dead_2.png');
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _leafDead2Image = frameInfo.image;
        });
      }
    } catch (e) {
      // Si l'image ne peut pas être chargée, on utilisera le dessin vectoriel
      _leafDead2Image = null;
    }
  }

  Future<void> _loadLeafDead3Image() async {
    try {
      final ByteData data = await rootBundle.load('assets/tree/leaf_dead_3.png');
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _leafDead3Image = frameInfo.image;
        });
      }
    } catch (e) {
      // Si l'image ne peut pas être chargée, on utilisera le dessin vectoriel
      _leafDead3Image = null;
    }
  }

  Future<void> _loadFlowerImage() async {
    try {
      final ByteData data = await rootBundle.load('assets/tree/flower.png');
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _flowerImage = frameInfo.image;
        });
      }
    } catch (e) {
      // Si l'image ne peut pas être chargée, on ne dessinera pas de fleur
      _flowerImage = null;
    }
  }

  Future<void> _loadJasminImage() async {
    try {
      final ByteData data = await rootBundle.load('assets/tree/jasmin.png');
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _jasminImage = frameInfo.image;
        });
      }
    } catch (e) {
      // Si l'image ne peut pas être chargée, on ne dessinera pas de jasmin
      _jasminImage = null;
    }
  }

  Future<void> _loadGrassBackgroundImage() async {
    try {
      final ByteData data = await rootBundle.load('assets/tree/grass_background.png');
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _grassBackgroundImage = frameInfo.image;
        });
      }
    } catch (e) {
      // Si l'image ne peut pas être chargée, on ne dessinera pas de terre
      if (mounted) {
        setState(() {
          _grassBackgroundImage = null;
        });
      }
    }
  }

  Future<void> _loadGrassForegroundImage() async {
    try {
      final ByteData data = await rootBundle.load('assets/tree/grass_foreground.png');
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _grassForegroundImage = frameInfo.image;
        });
      }
    } catch (e) {
      // Si l'image ne peut pas être chargée, on ne dessinera pas de terre
      if (mounted) {
        setState(() {
          _grassForegroundImage = null;
        });
      }
    }
  }

  Future<void> _loadBarkImage() async {
    try {
      final ByteData data = await rootBundle.load('assets/tree/bark_texture.png');
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _barkImage = frameInfo.image;
        });
      }
    } catch (e) {
      // Si l'image ne peut pas être chargée, on utilisera la couleur unie
      if (mounted) {
        setState(() {
          _barkImage = null;
        });
      }
    }
  }

  @override
  void dispose() {
    // Libérer les images pour éviter les fuites mémoire
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
    _treeController.dispose();
    super.dispose();
  }

  /// Ajoute 1-2 feuilles aléatoirement sur des branches disponibles
  void addRandomLeaves() {
    _treeController.addRandomLeaves();
  }

  /// Ajoute une fleur aléatoirement sur une branche disponible
  void addRandomFlower() {
    widget.controller.addRandomFlower();
  }

  /// Incrémente l'âge de toutes les feuilles vivantes (fait grandir l'arbre d'un jour)
  void growLeaves() {
    widget.controller.growLeaves();
  }

  /// Avance le processus de mort des feuilles
  void advanceLeafDeath() {
    widget.controller.advanceLeafDeath();
  }

  @override
  void didUpdateWidget(ProceduralTreeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Régénérer l'arbre seulement si le growthLevel ou les paramètres changent
    if (oldWidget.growthLevel != widget.growthLevel ||
        oldWidget.size != widget.size ||
        oldWidget.parameters.seed != widget.parameters.seed) {
      
      widget.controller.updateTree(
        growthLevel: widget.growthLevel,
        size: widget.size,
        parameters: widget.parameters,
      );
    }
    
    // Mettre à jour les cibles si elles ont changé
    // Mettre à jour les cibles si elles ont changé
    if (oldWidget.targetLeafCount != widget.targetLeafCount ||
        oldWidget.targetFlowerCount != widget.targetFlowerCount ||
        oldWidget.targetDeadLeafCount != widget.targetDeadLeafCount) {
      _updateTreeTargets();
    }
  }
  
  void _updateTreeTargets() {
    widget.controller.setTargetCounts(
      targetLeafCount: widget.targetLeafCount,
      targetFlowerCount: widget.targetFlowerCount,
      targetDeadLeafCount: widget.targetDeadLeafCount,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_windAnimation, widget.controller]),
      builder: (context, child) {
        if (widget.controller.tree == null) return const SizedBox();
        
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: TreePainter(
              tree: widget.controller.tree!,
              treeSize: widget.size,
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

/// Painter pour dessiner l'arbre procédural
class TreePainter extends CustomPainter {
  final tree_model.Tree tree;
  final double treeSize;
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
  final double windPhase; // Phase du vent (0 à 2π) pour l'animation
  final Map<tree_model.Branch, Offset> _deformedEnds = {}; // Cache des extrémités déformées
  final Map<tree_model.Branch, Offset> _deformedStarts = {}; // Cache des points de départ déformés

  TreePainter({
    required this.tree,
    required this.treeSize,
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
  }) {
    // Mettre à jour les positions de toutes les feuilles et fleurs en parcourant les branches
    for (final branch in tree.getAllBranches()) {
      for (final leaf in branch.leaves) {
        leaf.updatePosition(branch, treeSize);
      }
      for (final flower in branch.flowers) {
        flower.updatePosition(branch, treeSize);
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
    // Dessiner l'arrière-plan (herbe derrière l'arbre)
    _drawGrassBackground(canvas, size);

    // Calculer les positions déformées de manière hiérarchique
    _calculateDeformedPositions();
    
    // Dessiner les branches (du plus profond au moins profond pour le z-ordering)
    final allBranches = tree.getAllBranches();
    final sortedBranches = List<tree_model.Branch>.from(allBranches)
      ..sort((a, b) => b.depth.compareTo(a.depth));
    
    for (final branch in sortedBranches) {
      _drawBranch(canvas, branch);
    }

    // Dessiner les feuilles (filtrer celles qui ont commencé à grandir)
    // Parcourir les branches et leurs feuilles directement (plus efficace)
    for (final branch in sortedBranches) {
      for (final leaf in branch.leaves) {
        if (leaf.currentGrowth > 0.0) {
          _drawLeaf(canvas, leaf, branch);
        }
      }
    }

    // Dessiner les fleurs
    for (final branch in sortedBranches) {
      for (final flower in branch.flowers) {
        _drawFlower(canvas, flower, branch);
      }
    }
    
    // Dessiner l'avant-plan (herbe devant l'arbre)
    _drawGrassForeground(canvas, size);
  }

  /// Dessine l'image de l'herbe en arrière-plan
  void _drawGrassBackground(Canvas canvas, Size size) {
    if (grassBackgroundImage == null) return;
    
    try {
      final imageWidth = grassBackgroundImage!.width.toDouble();
      final imageHeight = grassBackgroundImage!.height.toDouble();
      final aspectRatio = imageWidth / imageHeight;
      
      final groundWidth = treeSize * 0.8;
      final groundHeight = groundWidth / aspectRatio;
      
      final groundX = (size.width - groundWidth) / 2;
      final treeBaseY = treeSize * 0.75;
      final groundY = treeBaseY - groundHeight / 2;
      
      final dstRect = Rect.fromLTWH(
        groundX,
        groundY,
        groundWidth,
        groundHeight,
      );
      
      final srcRect = Rect.fromLTWH(0, 0, imageWidth, imageHeight);
      
      canvas.drawImageRect(
        grassBackgroundImage!,
        srcRect,
        dstRect,
        Paint()..filterQuality = FilterQuality.high,
      );
    } catch (e) {
      return;
    }
  }

  /// Dessine l'image de l'herbe en avant-plan
  void _drawGrassForeground(Canvas canvas, Size size) {
    if (grassForegroundImage == null) return;
    
    try {
      final imageWidth = grassForegroundImage!.width.toDouble();
      final imageHeight = grassForegroundImage!.height.toDouble();
      final aspectRatio = imageWidth / imageHeight;
      
      final groundWidth = treeSize * 0.8;
      final groundHeight = groundWidth / aspectRatio;
      
      final groundX = (size.width - groundWidth) / 2;
      final treeBaseY = treeSize * 0.75;
      final groundY = treeBaseY - groundHeight / 2;
      
      final dstRect = Rect.fromLTWH(
        groundX,
        groundY,
        groundWidth,
        groundHeight,
      );
      
      final srcRect = Rect.fromLTWH(0, 0, imageWidth, imageHeight);
      
      canvas.drawImageRect(
        grassForegroundImage!,
        srcRect,
        dstRect,
        Paint()..filterQuality = FilterQuality.high,
      );
    } catch (e) {
      return;
    }
  }
  
  /// Calcule les positions déformées de toutes les branches de manière hiérarchique
  /// pour que les branches enfants suivent la déformation de leur parent
  void _calculateDeformedPositions() {
    _deformedEnds.clear();
    _deformedStarts.clear();
    
    // Trier les branches par profondeur (du moins profond au plus profond)
    final allBranches = tree.getAllBranches();
    final sortedBranches = List<tree_model.Branch>.from(allBranches)
      ..sort((a, b) => a.depth.compareTo(b.depth));
    
    for (final branch in sortedBranches) {
      // Le point de départ déformé est soit l'extrémité déformée du parent,
      // soit le point de départ original si c'est le tronc
      Offset deformedStart;
      if (branch.depth == 0) {
        // Le tronc commence à la base (pas de déformation à la base)
        deformedStart = branch.start;
      } else {
        // Trouver la branche parent (celle dont l'extrémité correspond au début de cette branche)
        final tolerance = treeSize * 0.01;
        tree_model.Branch? parent;
        try {
          parent = allBranches.firstWhere(
            (b) => b.depth == branch.depth - 1 && 
                   (b.end - branch.start).distance < tolerance,
          );
        } catch (e) {
          parent = null;
        }
        // Utiliser l'extrémité déformée du parent comme point de départ
        deformedStart = parent != null ? (_deformedEnds[parent] ?? branch.start) : branch.start;
      }
      
      _deformedStarts[branch] = deformedStart;
      
      // Calculer l'extrémité déformée de cette branche
      final deformedEnd = _calculateDeformedEnd(branch, deformedStart);
      _deformedEnds[branch] = deformedEnd;
    }
  }
  
  /// Calcule l'extrémité déformée d'une branche en fonction du vent
  Offset _calculateDeformedEnd(tree_model.Branch branch, Offset deformedStart) {
    // Calculer les paramètres du vent pour cette branche
    final depthRatio = branch.depth / parameters.maxDepth;
    final heightFactor = (treeSize - branch.start.dy) / treeSize;
    final flexibilityFactor = depthRatio;
    final windIntensity = 0.4 * heightFactor * flexibilityFactor;
    final branchPhase = windPhase + branch.start.dx * 0.005 + branch.start.dy * 0.005;
    
    // Calculer la direction originale de la branche
    final originalDirection = branch.end - branch.start;
    final originalAngle = math.atan2(originalDirection.dy, originalDirection.dx);
    
    // Calculer la déformation à l'extrémité (t = 1.0)
    final t = 1.0;
    final windAtEnd = math.sin(branchPhase + t * 2.0) * windIntensity * t * t;
    
    // La déformation est perpendiculaire à la direction originale
    final perpAngle = originalAngle + math.pi / 2;
    final windOffsetX = math.cos(perpAngle) * windAtEnd * treeSize * 0.05;
    final windOffsetY = math.sin(perpAngle) * windAtEnd * treeSize * 0.05;
    
    // L'extrémité déformée est calculée depuis le point de départ déformé
    // en suivant la direction originale mais avec la déformation du vent
    return Offset(
      deformedStart.dx + originalDirection.dx + windOffsetX,
      deformedStart.dy + originalDirection.dy + windOffsetY,
    );
  }

  /// Calcule la position de départ du tronc (centre vertical de la terre)
  void _drawBranch(Canvas canvas, tree_model.Branch branch) {
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
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    // Récupérer les positions déformées (calculées hiérarchiquement)
    // Ces variables DOIVENT être définies ici pour être visibles dans toute la fonction
    final deformedStart = _deformedStarts[branch] ?? branch.start;
    final deformedEnd = _deformedEnds[branch] ?? branch.end;

    if (barkImage != null) {
      // Utiliser la texture d'écorce
      // Créer un shader à partir de l'image
      // Mettre à l'échelle la texture pour qu'elle soit visible mais pas trop grosse
      // On utilise une matrice pour transformer la texture
      final matrix = Matrix4.identity();
      
      // Échelle de la texture (ajuster selon la taille de l'image et l'effet désiré)
      // Plus le scale est grand, plus la texture est petite (répétée)
      final scale = 2.0 * (treeSize / 500.0); 
      
      // Ancrer la texture au début de la branche pour éviter l'effet de glissement (swimming)
      // quand l'arbre bouge avec le vent.
      matrix.translate(deformedStart.dx, deformedStart.dy);
      matrix.scale(scale, scale);
      
      paint.shader = ImageShader(
        barkImage!, 
        TileMode.repeated, 
        TileMode.repeated, 
        matrix.storage,
      );
    } else {
      // Fallback couleur unie
      paint.color = branchColor;
    }

    // Vérifier si la branche a des enfants (branches qui commencent à son extrémité)
    final tolerance = treeSize * 0.01; // Tolérance relative à la taille de l'arbre
    final allBranches = tree.getAllBranches();
    final hasChildren = allBranches.any((b) => 
      b.depth == branch.depth + 1 && 
      (b.start - branch.end).distance < tolerance // Tolérance pour les erreurs d'arrondi
    );
    
    // Calculer le point de contrôle déformé
    // Interpoler entre le point de contrôle original et un point basé sur les extrémités déformées
    final originalControl = branch.controlPoint;
    final midPoint = Offset(
      (deformedStart.dx + deformedEnd.dx) / 2,
      (deformedStart.dy + deformedEnd.dy) / 2,
    );
    // Le point de contrôle déformé suit partiellement la déformation
    final deformedControl = Offset(
      originalControl.dx + (midPoint.dx - (branch.start.dx + branch.end.dx) / 2) * 0.7,
      originalControl.dy + (midPoint.dy - (branch.start.dy + branch.end.dy) / 2) * 0.7,
    );

    // Effet de vent sur les branches
    // Les branches plus fines (profondeur élevée) et plus hautes bougent plus
    final heightFactor = (treeSize - branch.start.dy) / treeSize; // 0 (bas) à 1 (haut)
    final flexibilityFactor = depthRatio; // Plus flexible quand plus fine (profondeur élevée)
    final windIntensity = 0.4 * heightFactor * flexibilityFactor; // Intensité du vent (augmentée)
    
    // Phase du vent avec variation par branche pour un effet naturel
    final branchPhase = windPhase + branch.start.dx * 0.005 + branch.start.dy * 0.005;

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
      // Utiliser les points déformés pour la courbe de Bézier
      final point = _bezierPoint(deformedStart, deformedControl, deformedEnd, t);
      
      // Calculer l'angle tangent à la courbe déformée à ce point
      final tangent = _bezierTangent(deformedStart, deformedControl, deformedEnd, t);
      final branchAngle = math.atan2(tangent.dy, tangent.dx);
      final perpAngle = branchAngle + math.pi / 2;
      
      // Effet de vent supplémentaire : déformation perpendiculaire à la branche
      // Le vent est plus fort vers l'extrémité de la branche (t augmente)
      // Mais cette déformation est relative à la branche déjà déformée
      final windAtPoint = math.sin(branchPhase + t * 2.0) * windIntensity * t * t * 0.3;
      // Le vent pousse perpendiculairement à la branche
      final windOffsetX = math.cos(perpAngle) * windAtPoint * treeSize * 0.05;
      final windOffsetY = math.sin(perpAngle) * windAtPoint * treeSize * 0.05;
      
      // Appliquer le déplacement du vent supplémentaire
      final deformedPoint = Offset(
        point.dx + windOffsetX,
        point.dy + windOffsetY,
      );
      
      // Épaisseur interpolée avec une courbe d'ease-out pour une transition plus naturelle
      // Utiliser une fonction quadratique pour créer une pointe plus naturelle
      final easeOut = 1 - (1 - t) * (1 - t); // Courbe d'ease-out quadratique
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

  void _drawLeaf(Canvas canvas, tree_model.Leaf leaf, tree_model.Branch branch) {
    // Ne dessiner que si la feuille a commencé à grandir
    if (leaf.currentGrowth <= 0.0) return;
    
    // Taille de base de la feuille
    final baseSize = treeSize * 0.064;
    
    // Calculer maxSize dynamiquement selon l'état actuel de la branche
    final maxSize = leaf.calculateMaxSize(branch);
    
    // Taille actuelle : baseSize * maxSize * currentGrowth
    final leafSize = baseSize * maxSize * leaf.currentGrowth;
    
    // Si la taille est trop petite, ne pas dessiner
    if (leafSize < 0.01) return;
    
    // VÉRIFICATION DE SÉCURITÉ : Ne jamais dessiner une feuille sur le tronc
    if (branch.depth == 0) {
      debugPrint('⚠️ Feuille sur le tronc détectée au dessin - NON DESSINÉE (id: ${leaf.id})');
      return;
    }
    
    // Récupérer les positions déformées de la branche
    final deformedStart = _deformedStarts[branch] ?? branch.start;
    final deformedEnd = _deformedEnds[branch] ?? branch.end;
    
    // Calculer le point de contrôle déformé (même logique que dans _drawBranch)
    final originalControl = branch.controlPoint;
    final midPoint = Offset(
      (deformedStart.dx + deformedEnd.dx) / 2,
      (deformedStart.dy + deformedEnd.dy) / 2,
    );
    final deformedControl = Offset(
      originalControl.dx + (midPoint.dx - (branch.start.dx + branch.end.dx) / 2) * 0.7,
      originalControl.dy + (midPoint.dy - (branch.start.dy + branch.end.dy) / 2) * 0.7,
    );
    
    // Calculer la position de la feuille sur la branche déformée
    final branchPos = _bezierPoint(deformedStart, deformedControl, deformedEnd, leaf.tOnBranch);
    
    // Utiliser la branche déformée pour calculer la tangente
    final tangent = _bezierTangent(
      deformedStart,
      deformedControl,
      deformedEnd,
      leaf.tOnBranch,
    );
    
    // Calculer l'angle de la tangente (direction de la branche)
    final branchAngle = math.atan2(tangent.dy, tangent.dx);
    
    // Calculer l'angle perpendiculaire à la branche (90°)
    final perpAngle = branchAngle + math.pi / 2;
    
    // Plus la feuille est proche de l'extrémité (tOnBranch proche de 1.0),
    // plus elle doit suivre la tangente de la branche
    final t = leaf.tOnBranch;
    final normalizedT = ((t - 0.3) / 0.7).clamp(0.0, 1.0);
    final alignmentFactor = math.pow(normalizedT, 2.5).toDouble();
    
    // Angle de base : interpolation entre perpendiculaire (avec offset) et tangente
    final angleOffset = leaf.side == 1 ? math.pi / 7.2 : -math.pi / 7.2;
    final basePerpAngle = perpAngle + angleOffset;
    final baseAngle = basePerpAngle * (1.0 - alignmentFactor) + branchAngle * alignmentFactor;
    
    // Calculer l'épaisseur de la branche à ce point
    final thicknessAtPoint = branch.thickness * (1.0 - leaf.tOnBranch * 0.3);
    final branchRadius = thicknessAtPoint / 2;
    
    // Position de la feuille sur la branche déformée
    final isLastLeaf = (leaf.tOnBranch >= 0.99);
    final totalOffset = isLastLeaf ? 0.0 : branchRadius;
    final side = isLastLeaf ? 0 : leaf.side;
    
    final leafPos = Offset(
      branchPos.dx + (isLastLeaf ? 0.0 : math.cos(perpAngle) * totalOffset * side),
      branchPos.dy + (isLastLeaf ? 0.0 : math.sin(perpAngle) * totalOffset * side),
    );
    
    // Effet de vent
    final heightFactor = (treeSize - leafPos.dy) / treeSize;
    final depthFactor = branch.depth / parameters.maxDepth;
    final windIntensity = 0.3 * heightFactor * (0.5 + depthFactor * 0.5);
    
    final leafPhase = windPhase + leafPos.dx * 0.01 + leafPos.dy * 0.01;
    final windOffsetX = math.sin(leafPhase) * windIntensity * treeSize * 0.03 * (1.0 - alignmentFactor * 0.5);
    final windOffsetY = math.cos(leafPhase * 0.7) * windIntensity * treeSize * 0.015 * (1.0 - alignmentFactor * 0.5);
    final windRotation = math.sin(leafPhase * 1.3) * windIntensity * 0.4 * (1.0 - alignmentFactor * 0.7);
    
    final rotation = baseAngle + windRotation;
    
    canvas.save();
    canvas.translate(leafPos.dx + windOffsetX, leafPos.dy + windOffsetY);
    canvas.rotate(rotation);
    
    if (leaf.side == -1 && !isLastLeaf) {
      canvas.scale(-1.0, 1.0);
    }
    
    // Dessiner l'image de la feuille selon son état
    ui.Image? imageToDraw;
    switch (leaf.state) {
      case tree_model.LeafState.alive:
        imageToDraw = leafImage;
        break;
      case tree_model.LeafState.dead1:
        imageToDraw = leafDead1Image;
        break;
      case tree_model.LeafState.dead2:
        imageToDraw = leafDead2Image;
        break;
      case tree_model.LeafState.dead3:
        imageToDraw = leafDead3Image;
        break;
    }
    
    if (imageToDraw != null) {
      _drawLeafImage(canvas, leafSize, imageToDraw);
    } else {
      // Fallback : dessin vectoriel simple (seulement pour alive)
      if (leaf.state == tree_model.LeafState.alive) {
        _drawVectorLeafFallback(canvas, leafSize);
      }
    }
    
    canvas.restore();
  }

  /// Dessine l'image de la feuille
  void _drawLeafImage(Canvas canvas, double size, ui.Image image) {
    // Vérifier que l'image n'a pas été disposée
    try {
      final imageWidth = image.width.toDouble();
      final imageHeight = image.height.toDouble();
      
      // Calculer les dimensions pour garder les proportions
      final aspectRatio = imageWidth / imageHeight;
      final drawWidth = size * 2 / 4; // Réduit par 4
      final drawHeight = drawWidth / aspectRatio;
      
      // Le point d'ancrage est au centre horizontal (x = 50%) et en bas (y = 100%)
      // Donc on doit décaler l'image vers le haut de toute sa hauteur
      // pour que le bas de l'image soit à la position du point de contact avec la branche
      final offsetY = -drawHeight; // Décaler vers le haut pour que le bas soit à y = 0
      
      // Rectangle de destination
      // Le point (0, 0) après translation et rotation correspond au point de contact avec la branche
      // On centre horizontalement et on place le bas de l'image à y = 0
      final dstRect = Rect.fromLTWH(
        -drawWidth / 2, // Centrer horizontalement
        offsetY, // Placer le bas de l'image à y = 0
        drawWidth,
        drawHeight,
      );
      
      // Rectangle source (toute l'image)
      final srcRect = Rect.fromLTWH(0, 0, imageWidth, imageHeight);
      
      // Dessiner l'image
      canvas.drawImageRect(
        image,
        srcRect,
        dstRect,
        Paint()..filterQuality = FilterQuality.high,
      );
    } catch (e) {
      // L'image a été disposée, ne rien dessiner
      return;
    }
  }
  
  /// Dessin vectoriel de fallback si l'image n'est pas disponible
  void _drawVectorLeafFallback(Canvas canvas, double size) {
    final width = size * 1.8 / 4; // Réduit par 4
    final height = size * 3.0 / 4; // Réduit par 4
    
    // Le point d'ancrage est au centre horizontal et en bas
    // Donc on dessine la feuille avec son bas à y = 0
    final offsetY = -height;
    
    final path = Path();
    path.moveTo(0, offsetY + height * 0.5);
    path.quadraticBezierTo(-width * 0.3, offsetY + height * 0.2, -width * 0.35, offsetY - height * 0.1);
    path.quadraticBezierTo(-width * 0.25, offsetY - height * 0.3, 0, offsetY - height * 0.5);
    path.quadraticBezierTo(width * 0.25, offsetY - height * 0.3, width * 0.35, offsetY - height * 0.1);
    path.quadraticBezierTo(width * 0.3, offsetY + height * 0.2, 0, offsetY + height * 0.5);
    path.close();
    
    final paint = Paint()
      ..color = const Color(0xFF66BB6A)
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(path, paint);
  }

  void _drawFlower(Canvas canvas, tree_model.Flower flower, tree_model.Branch branch) {
    // VÉRIFICATION DE SÉCURITÉ : Ne jamais dessiner une fleur sur le tronc
    if (branch.depth == 0) {
      debugPrint('⚠️ Fleur sur le tronc détectée au dessin - NON DESSINÉE (id: ${flower.id})');
      return;
    }
    
    // Récupérer les positions déformées de la branche
    final deformedStart = _deformedStarts[branch] ?? branch.start;
    final deformedEnd = _deformedEnds[branch] ?? branch.end;
    
    // Calculer le point de contrôle déformé (même logique que dans _drawBranch)
    final originalControl = branch.controlPoint;
    final midPoint = Offset(
      (deformedStart.dx + deformedEnd.dx) / 2,
      (deformedStart.dy + deformedEnd.dy) / 2,
    );
    final deformedControl = Offset(
      originalControl.dx + (midPoint.dx - (branch.start.dx + branch.end.dx) / 2) * 0.7,
      originalControl.dy + (midPoint.dy - (branch.start.dy + branch.end.dy) / 2) * 0.7,
    );
    
    // Calculer la position de la fleur sur la branche déformée
    final branchPos = _bezierPoint(deformedStart, deformedControl, deformedEnd, flower.tOnBranch);
    
    // Utiliser la branche déformée pour calculer la tangente
    final tangent = _bezierTangent(
      deformedStart,
      deformedControl,
      deformedEnd,
      flower.tOnBranch,
    );
    
    // Calculer l'angle de la tangente (direction de la branche)
    final branchAngle = math.atan2(tangent.dy, tangent.dx);
    
    // Calculer l'angle perpendiculaire à la branche (90°)
    final perpAngle = branchAngle + math.pi / 2;
    
    // Calculer l'épaisseur de la branche à ce point
    final thicknessAtPoint = branch.thickness * (1.0 - flower.tOnBranch * 0.3);
    final branchRadius = thicknessAtPoint / 2;
    
    // Position de la fleur sur la branche déformée
    final flowerPos = Offset(
      branchPos.dx + math.cos(perpAngle) * branchRadius * flower.side,
      branchPos.dy + math.sin(perpAngle) * branchRadius * flower.side,
    );
    
    // Effet de vent (plus léger que pour les feuilles)
    final heightFactor = (treeSize - flowerPos.dy) / treeSize;
    final depthFactor = branch.depth / parameters.maxDepth;
    final windIntensity = 0.2 * heightFactor * (0.5 + depthFactor * 0.5);
    
    final flowerPhase = windPhase + flowerPos.dx * 0.01 + flowerPos.dy * 0.01;
    final windOffsetX = math.sin(flowerPhase) * windIntensity * treeSize * 0.02;
    final windOffsetY = math.cos(flowerPhase * 0.7) * windIntensity * treeSize * 0.01;
    final windRotation = math.sin(flowerPhase * 1.3) * windIntensity * 0.2;
    
    // Angle de la fleur : perpendiculaire à la branche avec un léger offset
    final angleOffset = flower.side == 1 ? math.pi / 7.2 : -math.pi / 7.2;
    final rotation = perpAngle + angleOffset + windRotation;
    
    canvas.save();
    canvas.translate(flowerPos.dx + windOffsetX, flowerPos.dy + windOffsetY);
    canvas.rotate(rotation);
    
    if (flower.side == -1) {
      canvas.scale(-1.0, 1.0);
    }
    
    // Dessiner l'image de la fleur selon son type
    ui.Image? imageToDraw;
    if (flower.flowerType == 0) {
      imageToDraw = flowerImage;
    } else {
      imageToDraw = jasminImage;
    }
    
    if (imageToDraw != null) {
      _drawFlowerImage(canvas, flower.sizeFactor, imageToDraw);
    }
    
    canvas.restore();
  }

  /// Dessine l'image de la fleur
  void _drawFlowerImage(Canvas canvas, double sizeFactor, ui.Image image) {
    // Vérifier que l'image n'a pas été disposée
    try {
      final imageWidth = image.width.toDouble();
      final imageHeight = image.height.toDouble();
      
      // Taille de base de la fleur
      final baseSize = treeSize * 0.08;
      
      // Taille finale : baseSize * sizeFactor (dépend de la profondeur)
      final flowerSize = baseSize * sizeFactor;
      
      // Calculer les dimensions pour garder les proportions
      final aspectRatio = imageWidth / imageHeight;
      final drawWidth = flowerSize;
      final drawHeight = drawWidth / aspectRatio;
      
      // Le point d'ancrage est au centre de la fleur
      final dstRect = Rect.fromLTWH(
        -drawWidth / 2, // Centrer horizontalement
        -drawHeight / 2, // Centrer verticalement
        drawWidth,
        drawHeight,
      );
      
      // Rectangle source (toute l'image)
      final srcRect = Rect.fromLTWH(0, 0, imageWidth, imageHeight);
      
      // Dessiner l'image
      canvas.drawImageRect(
        image,
        srcRect,
        dstRect,
        Paint()..filterQuality = FilterQuality.high,
      );
    } catch (e) {
      // L'image a été disposée, ne rien dessiner
      return;
    }
  }



  @override
  bool shouldRepaint(TreePainter oldDelegate) {
    return oldDelegate.tree != tree ||
        oldDelegate.treeSize != treeSize ||
        oldDelegate.parameters != parameters ||
        oldDelegate.leafImage != leafImage ||
        oldDelegate.leafDead1Image != leafDead1Image ||
        oldDelegate.leafDead2Image != leafDead2Image ||
        oldDelegate.leafDead3Image != leafDead3Image ||
        oldDelegate.flowerImage != flowerImage ||
        oldDelegate.jasminImage != jasminImage ||
        oldDelegate.grassBackgroundImage != grassBackgroundImage ||
        oldDelegate.grassForegroundImage != grassForegroundImage ||
        oldDelegate.windPhase != windPhase;
  }
}
