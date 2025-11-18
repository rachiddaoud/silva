import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Information sur une feuille avec sa position et celle de sa branche
class LeafInfo {
  Offset position; // Mutable pour permettre la mise à jour
  Offset branchPosition; // Position sur la branche pour calculer l'orientation
  final TreeBranch branch; // Référence à la branche d'origine pour suivre son évolution
  final double tOnBranch; // Position sur la branche (0.0 à 1.0) pour suivre la branche
  final int side; // Côté de la branche (-1 ou 1) pour maintenir la position
  final double appearanceTime; // Niveau de growthLevel où la feuille apparaît
  final double maxSize; // Taille maximale (variation aléatoire)
  double currentGrowth; // Niveau de croissance actuel (0.0 à 1.0)

  LeafInfo({
    required this.position,
    required this.branchPosition,
    required this.branch,
    required this.tOnBranch,
    required this.side,
    required this.appearanceTime,
    required this.maxSize,
    this.currentGrowth = 0.0,
  });
  
  /// Met à jour la position de la feuille pour suivre sa branche d'origine
  void updatePosition(double treeSize) {
    // 1. Calculer la position exacte sur la branche au paramètre tOnBranch
    // Le tOnBranch reste constant, donc la position relative sur la branche reste la même
    final branchPos = _bezierPoint(
      branch.start,
      branch.controlPoint,
      branch.end,
      tOnBranch,
    );
    
    // 2. Calculer la tangente à la branche à ce point (direction de la branche)
    final tangent = _bezierTangent(
      branch.start,
      branch.controlPoint,
      branch.end,
      tOnBranch,
    );
    
    // 3. Calculer l'angle perpendiculaire à la branche (90°)
    final branchAngle = math.atan2(tangent.dy, tangent.dx);
    final perpAngle = branchAngle + math.pi / 2; // Angle perpendiculaire
    
    // 4. Calculer l'épaisseur de la branche à ce point (interpolation entre start et end)
    // L'épaisseur diminue progressivement le long de la branche
    final thicknessAtPoint = branch.thickness * (1.0 - tOnBranch * 0.3); // Réduction de 30% à la fin
    final branchRadius = thicknessAtPoint / 2; // Rayon de la branche à ce point (épaisseur / 2)
    
    // 5. Position finale : depuis le centre de la branche, aller vers l'extérieur
    // La feuille doit s'éloigner du centre de la branche d'une distance égale à l'épaisseur de la branche / 2
    // Le point d'ancrage (base de la feuille) touche le bord de la branche
    final totalOffset = branchRadius; // Distance du centre = épaisseur / 2
    
    // 7. Mettre à jour la position (vers l'extérieur selon le côté)
    // La position reste collée à la même position relative sur la branche grâce à tOnBranch constant
    position = Offset(
      branchPos.dx + math.cos(perpAngle) * totalOffset * side,
      branchPos.dy + math.sin(perpAngle) * totalOffset * side,
    );
    branchPosition = branchPos;
  }
  
  /// Fonctions helper pour calculer les points Bézier
  static Offset _bezierPoint(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1 - t;
    final tt = t * t;
    final uu = u * u;
    return Offset(
      uu * p0.dx + 2 * u * t * p1.dx + tt * p2.dx,
      uu * p0.dy + 2 * u * t * p1.dy + tt * p2.dy,
    );
  }
  
  static Offset _bezierTangent(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1 - t;
    return Offset(
      2 * u * (p1.dx - p0.dx) + 2 * t * (p2.dx - p1.dx),
      2 * u * (p1.dy - p0.dy) + 2 * t * (p2.dy - p1.dy),
    );
  }
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

  TreeBranch({
    required this.start,
    required this.end,
    required this.controlPoint,
    required this.angle,
    required this.length,
    required this.thickness,
    required this.depth,
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
      if (mounted) {
        setState(() {
          _groundImage = null;
        });
      }
    }
  }

  @override
  void dispose() {
    // Libérer les images pour éviter les fuites mémoire
    _leafImage?.dispose();
    _groundImage?.dispose();
    super.dispose();
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
    // Générer l'arbre d'abord
    _generateTree();
    // Générer les feuilles de base de façon séparée et semi-aléatoire
    _generateLeaves();
    // Si l'arbre est à 100%, ajouter progressivement de nouvelles feuilles jusqu'à saturation
    if (growthLevel >= 1.0) {
      _addNewLeavesAfterMaturity();
    }
    // Mettre à jour la croissance des feuilles
    _updateLeaves();
    // Mettre à jour les positions des feuilles pour suivre leurs branches
    _updateLeafPositions();
    // Logger l'état de l'arbre et des feuilles
    _logTreeAndLeavesState();
  }
  
  /// Log l'état de l'arbre et des feuilles
  void _logTreeAndLeavesState() {
    debugPrint('=== TREE STATE ===');
    debugPrint('Growth Level: ${growthLevel.toStringAsFixed(3)}');
    debugPrint('Tree Size: $treeSize');
    debugPrint('Fractional Depth: ${_fractionalDepth.toStringAsFixed(3)}');
    debugPrint('Parameters:');
    debugPrint('  - maxDepth: ${parameters.maxDepth}');
    debugPrint('  - baseBranchAngle: ${(parameters.baseBranchAngle * 180 / math.pi).toStringAsFixed(2)}°');
    debugPrint('  - lengthRatio: ${parameters.lengthRatio.toStringAsFixed(3)}');
    debugPrint('  - thicknessRatio: ${parameters.thicknessRatio.toStringAsFixed(3)}');
    debugPrint('  - angleVariation: ${parameters.angleVariation.toStringAsFixed(3)}');
    debugPrint('  - curveIntensity: ${parameters.curveIntensity.toStringAsFixed(3)}');
    debugPrint('  - seed: ${parameters.seed}');
    debugPrint('');
    debugPrint('Branches: ${_branches.length}');
    // Grouper les branches par profondeur
    final branchesByDepth = <int, List<TreeBranch>>{};
    for (final branch in _branches) {
      branchesByDepth.putIfAbsent(branch.depth, () => []).add(branch);
    }
    for (final depth in branchesByDepth.keys.toList()..sort()) {
      final branches = branchesByDepth[depth]!;
      debugPrint('  Depth $depth: ${branches.length} branches');
      for (int i = 0; i < branches.length && i < 3; i++) {
        final branch = branches[i];
        debugPrint('    Branch $i: length=${branch.length.toStringAsFixed(2)}, thickness=${branch.thickness.toStringAsFixed(2)}, angle=${(branch.angle * 180 / math.pi).toStringAsFixed(2)}°');
      }
      if (branches.length > 3) {
        debugPrint('    ... and ${branches.length - 3} more branches');
      }
    }
    debugPrint('');
    debugPrint('Leaves: ${_leaves.length}');
    // Compter les feuilles par état de croissance
    final visibleLeaves = _leaves.where((leaf) => leaf.currentGrowth > 0.0).length;
    final fullyGrownLeaves = _leaves.where((leaf) => leaf.currentGrowth >= 1.0).length;
    final growingLeaves = _leaves.where((leaf) => leaf.currentGrowth > 0.0 && leaf.currentGrowth < 1.0).length;
    debugPrint('  Visible: $visibleLeaves');
    debugPrint('  Fully grown: $fullyGrownLeaves');
    debugPrint('  Growing: $growingLeaves');
    debugPrint('  Not yet appeared: ${_leaves.length - visibleLeaves}');
    // Grouper les feuilles par profondeur de branche
    final leavesByBranchDepth = <int, List<LeafInfo>>{};
    for (final leaf in _leaves) {
      leavesByBranchDepth.putIfAbsent(leaf.branch.depth, () => []).add(leaf);
    }
    for (final depth in leavesByBranchDepth.keys.toList()..sort()) {
      final leaves = leavesByBranchDepth[depth]!;
      debugPrint('  On depth $depth branches: ${leaves.length} leaves');
    }
    // Afficher quelques détails sur les premières feuilles
    debugPrint('  Sample leaves (first 5):');
    for (int i = 0; i < _leaves.length && i < 5; i++) {
      final leaf = _leaves[i];
      debugPrint('    Leaf $i:');
      debugPrint('      Position: (${leaf.position.dx.toStringAsFixed(2)}, ${leaf.position.dy.toStringAsFixed(2)})');
      debugPrint('      Branch depth: ${leaf.branch.depth}');
      debugPrint('      tOnBranch: ${leaf.tOnBranch.toStringAsFixed(3)}');
      debugPrint('      Side: ${leaf.side == 1 ? "right" : "left"}');
      debugPrint('      Appearance time: ${leaf.appearanceTime.toStringAsFixed(3)}');
      debugPrint('      Current growth: ${leaf.currentGrowth.toStringAsFixed(3)}');
      debugPrint('      Max size: ${leaf.maxSize.toStringAsFixed(3)}');
    }
    if (_leaves.length > 5) {
      debugPrint('    ... and ${_leaves.length - 5} more leaves');
    }
    debugPrint('=== END TREE STATE ===');
  }
  
  /// Met à jour les positions des feuilles pour suivre leurs branches d'origine
  void _updateLeafPositions() {
    for (final leaf in _leaves) {
      leaf.updatePosition(treeSize);
    }
  }

  /// Met à jour la croissance de toutes les feuilles selon le niveau de croissance actuel
  void _updateLeaves() {
    // Utiliser un growthLevel étendu pour continuer le cycle de vie après 100%
    // Après 100%, on continue à partir de 1.0 avec un temps virtuel qui augmente
    final extendedGrowthLevel = growthLevel > 1.0 
        ? 1.0 + (growthLevel - 1.0) * 2.0  // Accélérer le temps après 100% (x2)
        : growthLevel;
    
    for (final leaf in _leaves) {
      // S'assurer que la feuille commence toujours à 0.0
      if (extendedGrowthLevel <= leaf.appearanceTime) {
        // La feuille n'est pas encore apparue
        leaf.currentGrowth = 0.0;
      } else {
        // Temps écoulé depuis l'apparition (normalisé entre 0.0 et 1.0)
        // On suppose qu'une feuille met environ 0.6 unités de growthLevel pour grandir complètement
        // (augmenté de 0.3 à 0.6 pour ralentir la croissance)
        final growthDuration = 0.6;
        final elapsed = (extendedGrowthLevel - leaf.appearanceTime) / growthDuration;
        
        // Courbe ease-out cubique : croissance rapide au début, ralentit à la fin
        // Formule : 1 - (1 - t)³
        final clampedElapsed = elapsed.clamp(0.0, 1.0);
        final growth = 1 - math.pow(1 - clampedElapsed, 3).toDouble();
        leaf.currentGrowth = growth.clamp(0.0, 1.0);
      }
    }
  }
  
  /// Ajoute progressivement de nouvelles feuilles après que l'arbre soit mature (100%)
  /// jusqu'à atteindre la saturation
  void _addNewLeavesAfterMaturity() {
    if (_branches.isEmpty) return;
    
    final baseLeafSize = treeSize * 0.064; // Réduit de 20% (0.08 * 0.8 = 0.064)
    
    // Limite de saturation : nombre maximum de feuilles par branche
    // Réduire drastiquement la limite pour les extrémités
    int getMaxLeavesForBranch(TreeBranch branch) {
      if (branch.depth >= parameters.maxDepth) {
        return 2; // Très peu de feuilles pour les branches finales
      } else if (branch.depth >= parameters.maxDepth - 1) {
        return 5; // Limite réduite pour les branches proches des extrémités
      } else if (branch.depth >= parameters.maxDepth - 2) {
        return 10; // Limite modérée pour les branches moyennes
      }
      return 15; // Limite normale pour les autres branches
    }
    
    // Calculer combien de nouvelles feuilles on peut ajouter
    // Basé sur le temps écoulé depuis 100% (growthLevel - 1.0)
    final timeSinceMaturity = growthLevel - 1.0;
    final newLeavesInterval = 0.1; // Ajouter des feuilles toutes les 0.1 unités de growthLevel
    final numNewLeavesBatches = (timeSinceMaturity / newLeavesInterval).floor();
    
    // Utiliser un Set pour tracker les feuilles déjà générées (basé sur seed + position)
    final existingLeafIds = <String>{};
    for (final leaf in _leaves) {
      // Créer un ID unique basé sur la branche et tOnBranch
      final leafId = '${leaf.branch.depth}_${leaf.branch.start.dx.toStringAsFixed(2)}_${leaf.tOnBranch.toStringAsFixed(3)}_${leaf.side}';
      existingLeafIds.add(leafId);
    }
    
    // Parcourir toutes les branches (sauf le tronc)
    int branchCounter = 0;
    for (final branch in _branches) {
      if (branch.depth == 0) {
        branchCounter++;
        continue; // Ignorer le tronc
      }
      
      // Compter les feuilles existantes sur cette branche
      final existingLeavesOnBranch = _leaves.where((leaf) => 
        leaf.branch == branch
      ).length;
      
      // Obtenir la limite de saturation pour cette branche
      final maxLeavesForBranch = getMaxLeavesForBranch(branch);
      
      // Si on a atteint la saturation pour cette branche, passer à la suivante
      if (existingLeavesOnBranch >= maxLeavesForBranch) {
        branchCounter++;
        continue;
      }
      
      // Calculer combien de nouvelles feuilles ajouter pour cette branche
      // Une feuille par batch, mais pas plus que la limite de saturation
      final maxNewLeaves = maxLeavesForBranch - existingLeavesOnBranch;
      final leavesToAdd = math.min(maxNewLeaves, numNewLeavesBatches);
      
      if (leavesToAdd <= 0) {
        branchCounter++;
        continue;
      }
      
      // Seed pour générer de nouvelles feuilles de façon déterministe
      final branchSeed = parameters.seed + branch.depth * 1000 + branchCounter + 10000; // Offset pour distinguer des feuilles initiales
      final branchRandom = math.Random(branchSeed);
      
      int addedCount = 0;
      int attempts = 0;
      const maxAttempts = 50; // Limite pour éviter les boucles infinies
      
      while (addedCount < leavesToAdd && attempts < maxAttempts) {
        attempts++;
        
        // Position aléatoire le long de la branche
        final t = 0.2 + branchRandom.nextDouble() * 0.8; // Entre 20% et 100%
        
        // Créer un ID unique pour cette feuille
        final leafId = '${branch.depth}_${branch.start.dx.toStringAsFixed(2)}_${t.toStringAsFixed(3)}_${addedCount}';
        
        // Vérifier si cette feuille existe déjà
        if (existingLeafIds.contains(leafId)) {
          continue; // Cette feuille existe déjà, essayer une autre position
        }
        
        // Calculer la position sur la courbe de Bézier
        final branchPos = _bezierPoint(branch.start, branch.controlPoint, branch.end, t);
        
        // Calculer la tangente pour l'orientation
        final tangent = _bezierTangent(branch.start, branch.controlPoint, branch.end, t);
        final branchAngle = math.atan2(tangent.dy, tangent.dx);
        final perpAngle = branchAngle + math.pi / 2;
        
        // Épaisseur de la branche à ce point
        final thicknessAtPoint = branch.thickness * (1.0 - t * 0.3);
        final branchRadius = thicknessAtPoint / 2; // Rayon de la branche (épaisseur / 2)
        
        // Taille de la feuille
        final leafSeed = branchSeed + addedCount * 100 + existingLeavesOnBranch;
        final leafRandom = math.Random(leafSeed);
        final maxSize = 0.5 + leafRandom.nextDouble() * 1.0;
        
        // Position finale : la feuille s'éloigne du centre de la branche d'une distance égale à l'épaisseur / 2
        final side = leafRandom.nextBool() ? 1 : -1;
        final totalOffset = branchRadius; // Distance du centre = épaisseur / 2
        final leafPos = Offset(
          branchPos.dx + math.cos(perpAngle) * totalOffset * side,
          branchPos.dy + math.sin(perpAngle) * totalOffset * side,
        );
        
        // AppearanceTime : après 100%, les nouvelles feuilles apparaissent progressivement
        // Basé sur le temps depuis la maturité
        final appearanceTime = 1.0 + (addedCount * newLeavesInterval) + (leafRandom.nextDouble() * 0.05);
        
        // Vérifier la distance avec les feuilles existantes
        bool tooClose = false;
        final minDistance = baseLeafSize * 0.5;
        for (final existingLeaf in _leaves) {
          final distance = (leafPos - existingLeaf.position).distance;
          if (distance < minDistance) {
            tooClose = true;
            break;
          }
        }
        
        // Ajouter la feuille si elle n'est pas trop proche
        if (!tooClose) {
          existingLeafIds.add(leafId);
          _leaves.add(LeafInfo(
            position: leafPos,
            branchPosition: branchPos,
            branch: branch,
            tOnBranch: t,
            side: side,
            appearanceTime: appearanceTime,
            maxSize: maxSize,
            currentGrowth: 0.0,
          ));
          addedCount++;
        }
      }
      
      branchCounter++;
    }
  }

  /// Génère les feuilles de façon semi-aléatoire le long des branches
  void _generateLeaves() {
    if (_branches.isEmpty) return;
    
    final baseLeafSize = treeSize * 0.064; // Réduit de 20% (0.08 * 0.8 = 0.064) // Taille de base d'une feuille
    
    // Créer un identifiant unique pour chaque branche basé sur sa position dans l'arbre
    // Cela permet de générer les mêmes feuilles pour les mêmes branches
    final branchIds = <TreeBranch, String>{};
    int branchCounter = 0;
    for (final branch in _branches) {
      branchIds[branch] = 'branch_${branch.depth}_$branchCounter';
      branchCounter++;
    }
    
    // Parcourir toutes les branches (sauf le tronc)
    branchCounter = 0;
    for (final branch in _branches) {
      if (branch.depth == 0) {
        branchCounter++;
        continue; // Ignorer le tronc
      }
      
      // Générer de nouvelles feuilles pour cette branche
      // Nombre de feuilles basé sur la longueur de la branche et la profondeur
      // Réduire drastiquement le nombre de feuilles sur les extrémités (profondeurs élevées)
      final normalizedLength = branch.length / treeSize;
      final depthFactor = (branch.depth - 1) / parameters.maxDepth;
      // Réduction progressive pour les extrémités : beaucoup moins de feuilles sur les branches finales
      final depthReduction = branch.depth >= parameters.maxDepth 
          ? 0.15  // Réduction de 85% pour les branches finales (extrémités)
          : (branch.depth >= parameters.maxDepth - 1 
              ? 0.3  // Réduction de 70% pour les branches proches des extrémités
              : (branch.depth >= parameters.maxDepth - 2
                  ? 0.6  // Réduction de 40% pour les branches moyennes
                  : 1.0)); // Pas de réduction pour les autres branches
      final baseLeafCount = (normalizedLength * 50 * (1 + depthFactor) * depthReduction).round();
      
      // Utiliser un seed déterministe basé sur la branche pour garantir la reproductibilité
      // Le seed est basé sur le seed principal + la profondeur + l'index de la branche
      // Cela garantit que chaque branche génère toujours les mêmes feuilles
      final branchSeed = parameters.seed + branch.depth * 1000 + branchCounter;
      final branchRandom = math.Random(branchSeed);
      // Réduire drastiquement le minimum pour les extrémités
      final minLeaves = branch.depth >= parameters.maxDepth ? 0 : (branch.depth >= parameters.maxDepth - 1 ? 1 : 3);
      final numLeaves = math.max(minLeaves, baseLeafCount + branchRandom.nextInt(5) - 2);
      
      // Espacement le long de la branche
      final leafSpacing = 1.0 / (numLeaves + 1);
      
      for (int j = 0; j < numLeaves; j++) {
        // Position le long de la branche avec espacement régulier
        final t = 0.3 + (j + 1) * leafSpacing * 0.7; // Entre 30% et 100% de la branche
        
        // Calculer la position sur la courbe de Bézier
        final branchPos = _bezierPoint(branch.start, branch.controlPoint, branch.end, t);
        
        // 1. Calculer la position exacte sur la branche
        // 2. Calculer la tangente pour l'orientation (direction de la branche)
        final tangent = _bezierTangent(branch.start, branch.controlPoint, branch.end, t);
        final branchAngle = math.atan2(tangent.dy, tangent.dx);
        final perpAngle = branchAngle + math.pi / 2; // Angle perpendiculaire (90°)
        
        // 3. Calculer l'épaisseur de la branche à ce point
        final thicknessAtPoint = branch.thickness * (1.0 - t * 0.3); // Réduction de 30% à la fin
        final branchRadius = thicknessAtPoint / 2; // Rayon de la branche à ce point (épaisseur / 2)
        
        // 4. Taille maximale aléatoire de la feuille (déterministe basé sur la position)
        final leafSeed = branchSeed + j * 100;
        final leafRandom = math.Random(leafSeed);
        final maxSize = 0.5 + leafRandom.nextDouble() * 1.0;
        
        // 5. Position finale : depuis le centre de la branche, aller vers l'extérieur
        // La feuille doit s'éloigner du centre de la branche d'une distance égale à l'épaisseur de la branche / 2
        // Le point d'ancrage (base de la feuille) touche le bord de la branche
        final totalOffset = branchRadius; // Distance du centre = épaisseur / 2
        
        // Choisir le côté (gauche ou droite) - déterministe
        final side = (j % 2 == 0) ? 1 : -1;
        
        // Position de la feuille (centre de la feuille)
        final leafPos = Offset(
          branchPos.dx + math.cos(perpAngle) * totalOffset * side,
          branchPos.dy + math.sin(perpAngle) * totalOffset * side,
        );
        
        // Calculer le niveau de croissance de base pour cette branche
        // S'assurer que la feuille n'apparaît qu'après que la branche soit visible
        // La branche apparaît quand growthLevel atteint (branch.depth / maxDepth)
        final branchAppearanceLevel = branch.depth / parameters.maxDepth;
        final indexDelay = (j / numLeaves) * 0.3; // Délai basé sur l'index de la feuille
        final randomDelay = leafRandom.nextDouble() * 0.2; // Délai aléatoire
        // L'apparition doit être après que la branche soit visible + délais
        final appearanceTime = (branchAppearanceLevel + indexDelay + randomDelay).clamp(0.0, 1.0);
        
        // Vérifier la distance avec les feuilles existantes
        // On utilise une distance minimale basée sur la taille de base des feuilles
        bool tooClose = false;
        final minDistance = baseLeafSize * 0.5; // Distance minimale entre les centres des points
        for (final existingLeaf in _leaves) {
          final distance = (leafPos - existingLeaf.position).distance;
          if (distance < minDistance) {
            tooClose = true;
            break;
          }
        }
        
        // Ajouter la feuille si elle n'est pas trop proche
        if (!tooClose) {
          _leaves.add(LeafInfo(
            position: leafPos,
            branchPosition: branchPos,
            branch: branch,
            tOnBranch: t,
            side: side,
            appearanceTime: appearanceTime,
            maxSize: maxSize,
            currentGrowth: 0.0,
          ));
        }
      }
      
      // Ne plus ajouter automatiquement une feuille à l'extrémité pour les branches finales
      // car elles doivent avoir beaucoup moins de feuilles
      // (supprimé pour réduire le nombre de feuilles sur les extrémités)
      
      branchCounter++;
    }
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
    );

    // Génération récursive des branches
    _branches.add(trunk);
    // Passer effectiveDepth pour savoir quelles profondeurs sont complètement générées
    _generateBranches(trunk, effectiveDepth, depthFraction, random);
  }

  void _generateBranches(
    TreeBranch parent,
    int effectiveDepth,
    double depthFraction,
    math.Random random,
  ) {
    // Nombre de branches (2 ou 3)
    final numBranches = random.nextBool() ? 2 : 3;

    final newDepth = parent.depth + 1;
    
    // Déterminer la profondeur maximale à générer
    // Si depthFraction > 0, on génère aussi le niveau effectiveDepth + 1 (en cours de croissance)
    final maxDepth = depthFraction > 0.0 ? effectiveDepth + 1 : effectiveDepth;
    
    // Ne pas générer de branches au-delà de la profondeur maximale
    if (newDepth > maxDepth) return;
    
    for (int i = 0; i < numBranches; i++) {
      // Angle de branchement avec variation
      final angleVariationFactor = (random.nextDouble() - 0.5) * parameters.angleVariation;
      final branchAngle = parent.angle +
          parameters.baseBranchAngle * (i % 2 == 0 ? 1 : -1) +
          angleVariationFactor;

      // Longueur avec variation
      final lengthVariation = 0.85 + random.nextDouble() * 0.3; // 0.85 à 1.15
      var branchLength = parent.length * parameters.lengthRatio * lengthVariation;
      
      // Scaler la longueur seulement si cette branche est au niveau en cours de croissance
      // (c'est-à-dire newDepth == effectiveDepth + 1, qui correspond à maxDepth quand depthFraction > 0)
      // Les branches aux profondeurs <= effectiveDepth sont complètement générées (longueur = 1.0)
      if (newDepth == maxDepth && depthFraction > 0.0 && depthFraction < 1.0) {
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

      // Création de la branche (sans feuilles, elles seront générées séparément)
      final branch = TreeBranch(
        start: branchStart,
        end: branchEnd,
        controlPoint: branchControl,
        angle: branchAngle,
        length: branchLength,
        thickness: branchThickness,
        depth: newDepth,
      );

      _branches.add(branch);

      // Récursion pour les branches enfants
      // Continuer la récursion si on n'a pas atteint la profondeur maximale
      if (newDepth < maxDepth) {
        _generateBranches(branch, effectiveDepth, depthFraction, random);
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
    // Dessiner les branches (du plus profond au moins profond pour le z-ordering)
    final sortedBranches = List<TreeBranch>.from(_branches)
      ..sort((a, b) => b.depth.compareTo(a.depth));
    
    for (final branch in sortedBranches) {
      _drawBranch(canvas, branch);
    }

    // Dessiner les feuilles (filtrer celles qui ont commencé à grandir)
    for (final leafInfo in _leaves) {
      if (leafInfo.currentGrowth > 0.0) {
        _drawLeaf(canvas, leafInfo);
      }
    }
    
    // Dessiner la terre par-dessus (en premier plan) pour que l'arbre soit derrière
    _drawGround(canvas, size);
  }

  /// Dessine l'image de terre à la base de l'arbre
  void _drawGround(Canvas canvas, Size size) {
    if (groundImage == null) return;
    
    // Vérifier que l'image n'a pas été disposée
    try {
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
    } catch (e) {
      // L'image a été disposée, ne rien dessiner
      return;
    }
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
    // Ne dessiner que si la feuille a commencé à grandir
    if (leafInfo.currentGrowth <= 0.0) return;
    
    // Taille de base de la feuille
    final baseSize = treeSize * 0.064; // Réduit de 20% (0.08 * 0.8 = 0.064)
    
    // Taille actuelle : baseSize * maxSize * currentGrowth
    final leafSize = baseSize * leafInfo.maxSize * leafInfo.currentGrowth;
    
    // Si la taille est trop petite, ne pas dessiner
    if (leafSize < 0.01) return;
    
    // Utiliser directement tOnBranch pour calculer la tangente
    final tangent = _bezierTangent(
      leafInfo.branch.start,
      leafInfo.branch.controlPoint,
      leafInfo.branch.end,
      leafInfo.tOnBranch,
    );
    
    // Calculer l'angle de base perpendiculaire à la branche (90°)
    final baseAngle = math.atan2(tangent.dy, tangent.dx) + math.pi / 2;
    
    // Ajouter un angle plus doux si à droite, soustraire si à gauche (réduit de 45° à 25°)
    final angleOffset = leafInfo.side == 1 ? math.pi / 7.2 : -math.pi / 7.2; // +25° ou -25° (180/7.2 ≈ 25°)
    final rotation = baseAngle + angleOffset;
    
    // Sauvegarder l'état du canvas
    canvas.save();
    
    // Appliquer la rotation et translation
    canvas.translate(leafInfo.position.dx, leafInfo.position.dy);
    canvas.rotate(rotation);
    
    // Si la feuille est du côté gauche, appliquer un miroir horizontal
    if (leafInfo.side == -1) {
      canvas.scale(-1.0, 1.0); // Miroir horizontal
    }
    
    // Dessiner l'image de la feuille
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
    
    // Vérifier que l'image n'a pas été disposée
    try {
      final imageWidth = leafImage!.width.toDouble();
      final imageHeight = leafImage!.height.toDouble();
      
      // Calculer les dimensions pour garder les proportions
      final aspectRatio = imageWidth / imageHeight;
      final drawWidth = size * 2;
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
        leafImage!,
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
    final width = size * 1.8;
    final height = size * 3.0;
    
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

