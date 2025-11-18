import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Information sur une feuille avec sa position et celle de sa branche
class LeafInfo {
  final String leafId; // Identifiant unique
  final double tOnBranch; // Position fixe sur la branche (0.0 à 1.0)
  final int side; // Côté de la branche (-1 ou 1)
  final Offset branchStart; // Début de la branche
  final Offset branchEnd; // Fin de la branche
  final Offset branchControl; // Point de contrôle de la branche (pour courbe Bézier)
  final double branchLength; // Longueur de la branche pour calculer l'offset
  final double appearanceTime; // Niveau de growthLevel où la feuille apparaît
  final double maxSize; // Taille maximale (variation aléatoire)
  double currentGrowth; // Niveau de croissance actuel (0.0 à 1.0)

  LeafInfo({
    required this.leafId,
    required this.tOnBranch,
    required this.side,
    required this.branchStart,
    required this.branchEnd,
    required this.branchControl,
    required this.branchLength,
    required this.appearanceTime,
    required this.maxSize,
    this.currentGrowth = 0.0,
  });

  /// Calcule la position actuelle de la feuille sur la branche
  Offset calculatePosition() {
    // Calculer la position sur la courbe de Bézier
    final branchPos = _bezierPoint(branchStart, branchControl, branchEnd, tOnBranch);
    
    // Calculer la tangente à la branche à ce point
    final tangent = _bezierTangent(branchStart, branchControl, branchEnd, tOnBranch);
    final perpAngle = math.atan2(tangent.dy, tangent.dx) + math.pi / 2;
    
    // Distance entre la branche et la feuille
    final offset = branchLength * 0.25;
    
    // Position de la feuille (décalée perpendiculairement à la branche)
    return Offset(
      branchPos.dx + math.cos(perpAngle) * offset * side,
      branchPos.dy + math.sin(perpAngle) * offset * side,
    );
  }

  /// Fonctions helper pour calculer les points Bézier (nécessaires pour calculatePosition)
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
    // Ajouter des feuilles supplémentaires sur les branches matures (sauf le tronc)
    _addLeavesToMatureBranches();
    // Mettre à jour la croissance des feuilles
    _updateLeaves();
  }

  /// Ajoute des feuilles supplémentaires sur les branches matures (sauf le tronc)
  void _addLeavesToMatureBranches() {
    // Utiliser un Set pour éviter les doublons de feuilles basé sur leafId
    final existingLeafIds = <String>{};
    for (final leaf in _leaves) {
      existingLeafIds.add(leaf.leafId);
    }
    
    // Parcourir toutes les branches sauf le tronc (depth > 0)
    for (final branch in _branches) {
      if (branch.depth == 0) continue; // Ignorer le tronc
      
      // Vérifier si la branche est mature (elle existe depuis un certain temps)
      // Une branche est mature si elle a été créée avant le niveau de croissance actuel
      final branchMaturityLevel = branch.depth / parameters.maxDepth;
      if (growthLevel > branchMaturityLevel + 0.1) {
        // La branche est mature, on peut ajouter des feuilles supplémentaires
        
        // Collecter les feuilles existantes pour vérifier les collisions
        final existingLeaves = <LeafInfo>[];
        for (final b in _branches) {
          existingLeaves.addAll(b.leaves);
        }
        existingLeaves.addAll(_leaves);
        
        // Nombre de feuilles supplémentaires à ajouter (basé sur la longueur de la branche)
        final normalizedLength = branch.length / treeSize;
        final additionalLeafCount = (normalizedLength * 8).round(); // 8 feuilles supplémentaires par unité
        
        // Distance minimale entre feuilles
        final minLeafDistance = treeSize * 0.08 * 1.5;
        
        for (int i = 0; i < additionalLeafCount; i++) {
          // Créer un identifiant unique pour cette feuille mature
          final leafId = 'branch_${branch.depth}_mature_leaf_$i';
          
          // Vérifier si cette feuille existe déjà (éviter les doublons)
          if (existingLeafIds.contains(leafId)) continue;
          
          // Position aléatoire le long de la branche (déterministe basé sur le seed et l'index)
          final leafRandom = math.Random(parameters.seed + branch.depth * 1000 + i);
          final t = 0.2 + leafRandom.nextDouble() * 0.8; // Entre 20% et 100% de la branche
          
          // Calculer la position potentielle
          final potentialBranchPos = _bezierPoint(branch.start, branch.controlPoint, branch.end, t);
          final potentialTangent = _bezierTangent(branch.start, branch.controlPoint, branch.end, t);
          final potentialPerpAngle = math.atan2(potentialTangent.dy, potentialTangent.dx) + math.pi / 2;
          final potentialOffset = branch.length * 0.25;
          
          // Essayer les deux côtés
          int bestSide = leafRandom.nextBool() ? 1 : -1;
          double bestDistance = 0.0;
          
          for (final side in [1, -1]) {
            final potentialPos = Offset(
              potentialBranchPos.dx + math.cos(potentialPerpAngle) * potentialOffset * side,
              potentialBranchPos.dy + math.sin(potentialPerpAngle) * potentialOffset * side,
            );
            
            // Vérifier la distance avec toutes les feuilles existantes
            double minDistance = double.infinity;
            for (final existingLeaf in existingLeaves) {
              final existingPos = existingLeaf.calculatePosition();
              final distance = (potentialPos - existingPos).distance;
              if (distance < minDistance) {
                minDistance = distance;
              }
            }
            
            if (minDistance > bestDistance) {
              bestDistance = minDistance;
              bestSide = side;
            }
          }
          
          // Ajouter la feuille si elle est assez éloignée
          if (bestDistance >= minLeafDistance) {
            final appearanceTime = (branchMaturityLevel + leafRandom.nextDouble() * 0.3).clamp(0.0, 1.0);
            final maxSize = 0.5 + leafRandom.nextDouble() * 1.0;
            
            final newLeaf = LeafInfo(
              leafId: leafId,
              tOnBranch: t,
              side: bestSide,
              branchStart: branch.start,
              branchEnd: branch.end,
              branchControl: branch.controlPoint,
              branchLength: branch.length,
              appearanceTime: appearanceTime,
              maxSize: maxSize,
              currentGrowth: 0.0,
            );
            
            _leaves.add(newLeaf);
            existingLeaves.add(newLeaf);
            existingLeafIds.add(leafId);
          }
        }
      }
    }
  }

  /// Met à jour la croissance de toutes les feuilles selon le niveau de croissance actuel
  void _updateLeaves() {
    for (final leaf in _leaves) {
      if (growthLevel >= leaf.appearanceTime) {
        // Temps écoulé depuis l'apparition (normalisé entre 0.0 et 1.0)
        // On suppose qu'une feuille met environ 0.3 unités de growthLevel pour grandir complètement
        final growthDuration = 0.3;
        final elapsed = (growthLevel - leaf.appearanceTime) / growthDuration;
        
        // Courbe ease-out cubique : croissance rapide au début, ralentit à la fin
        // Formule : 1 - (1 - t)³
        final clampedElapsed = elapsed.clamp(0.0, 1.0);
        final growth = 1 - math.pow(1 - clampedElapsed, 3).toDouble();
        leaf.currentGrowth = growth.clamp(0.0, 1.0);
      } else {
        // La feuille n'est pas encore apparue
        leaf.currentGrowth = 0.0;
      }
    }
  }


  void _generateTree() {
    final random = math.Random(parameters.seed);
    
    // TOUJOURS générer l'arbre complet avec les dimensions finales
    // La croissance sera appliquée visuellement lors du dessin
    final effectiveDepth = parameters.maxDepth; // Toujours générer jusqu'à maxDepth
    final depthFraction = 1.0; // Toujours complet pour la structure
    
    // Position de départ : centre vertical de la terre (où l'arbre sort de la terre)
    final treeBase = _getTreeBasePosition();
    final startX = treeBase.dx;
    final startY = treeBase.dy;
    
    // Longueur FINALE du tronc (structure complète)
    // L'épaisseur sera calculée lors du dessin selon le growthLevel
    final trunkLength = treeSize * 0.25; // Longueur finale
    final trunkThickness = treeSize * 0.06; // Épaisseur finale (utilisée comme référence)

    // Calcul de l'extrémité du tronc
    final trunkAngle = -math.pi / 2; // Vers le haut
    final trunkEnd = Offset(
      startX + math.cos(trunkAngle) * trunkLength,
      startY + math.sin(trunkAngle) * trunkLength,
    );

    // Point de contrôle pour courber légèrement le tronc (fixe, déterministe)
    final trunkControl = Offset(
      startX + math.cos(trunkAngle) * trunkLength * 0.5 + (random.nextDouble() - 0.5) * treeSize * 0.05,
      startY + math.sin(trunkAngle) * trunkLength * 0.5,
    );

    // Création du tronc principal (structure complète)
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

    // Génération récursive des branches (structure complète)
    _branches.add(trunk);
    _generateBranches(trunk, effectiveDepth, depthFraction, random);
  }

  void _generateBranches(
    TreeBranch parent,
    int maxDepth,
    double depthFraction,
    math.Random random,
  ) {
    // Collecter toutes les feuilles existantes pour vérifier les collisions
    // Utiliser un Set pour éviter les doublons basé sur leafId
    final existingLeafIds = <String>{};
    final existingLeaves = <LeafInfo>[];
    for (final branch in _branches) {
      for (final leaf in branch.leaves) {
        if (!existingLeafIds.contains(leaf.leafId)) {
          existingLeaves.add(leaf);
          existingLeafIds.add(leaf.leafId);
        }
      }
    }
    for (final leaf in _leaves) {
      if (!existingLeafIds.contains(leaf.leafId)) {
        existingLeaves.add(leaf);
        existingLeafIds.add(leaf.leafId);
      }
    }
    
    // Nombre de branches (2 ou 3)
    final numBranches = random.nextBool() ? 2 : 3;

    final newDepth = parent.depth + 1;
    
    // Arrêter la récursion si on atteint la profondeur maximale
    if (newDepth > maxDepth) return;
    
    for (int i = 0; i < numBranches; i++) {
      // Angle de branchement avec variation
      final angleVariationFactor = (random.nextDouble() - 0.5) * parameters.angleVariation;
      final branchAngle = parent.angle +
          parameters.baseBranchAngle * (i % 2 == 0 ? 1 : -1) +
          angleVariationFactor;

      // Longueur avec variation (toujours la longueur complète)
      final lengthVariation = 0.85 + random.nextDouble() * 0.3; // 0.85 à 1.15
      final branchLength = parent.length * parameters.lengthRatio * lengthVariation;

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
        // Plus on avance (profondeur élevée), moins il y a de feuilles pour éviter qu'elles soient collées
        final normalizedLength = branchLength / treeSize; // Normaliser par rapport à la taille de l'arbre
        final depthFactor = (newDepth - 1) / parameters.maxDepth; // Facteur basé sur la profondeur
        
        // Réduire le nombre de feuilles quand la profondeur augmente
        // Les branches profondes (extrémités) auront moins de feuilles
        final depthReduction = 1.0 - (depthFactor * 0.4); // Réduction jusqu'à 40% pour les branches profondes (moins de réduction)
        final baseLeafCount = (normalizedLength * 25 * depthReduction).round(); // 25 feuilles par unité (augmenté de 15)
        final numLeaves = math.max(2, baseLeafCount + random.nextInt(3) - 1); // Variation de ±1, minimum 2
        
        // Espacement le long de la branche pour éviter les chevauchements
        final leafSpacing = 1.0 / (numLeaves + 1); // Espacement uniforme
        
        // Calculer le niveau de croissance de base pour cette branche
        // Plus la branche est profonde, plus les feuilles apparaissent tôt
        final baseAppearanceLevel = (newDepth - 1) / parameters.maxDepth;
        
        // Distance minimale entre feuilles (basée sur la taille maximale d'une feuille)
        final minLeafDistance = treeSize * 0.08 * 1.5; // 1.5x la taille de base d'une feuille
        
        for (int j = 0; j < numLeaves; j++) {
          // Position le long de la branche avec espacement régulier
          final t = 0.3 + (j + 1) * leafSpacing * 0.7; // Entre 30% et 100% de la branche
          
          // Calculer la position potentielle de la feuille
          final potentialBranchPos = _bezierPoint(branchStart, branchControl, branchEnd, t);
          final potentialTangent = _bezierTangent(branchStart, branchControl, branchEnd, t);
          final potentialPerpAngle = math.atan2(potentialTangent.dy, potentialTangent.dx) + math.pi / 2;
          final potentialOffset = branchLength * 0.25;
          
          // Essayer les deux côtés pour trouver le meilleur emplacement
          int bestSide = (j % 2 == 0) ? 1 : -1;
          double bestDistance = 0.0;
          
          for (final side in [1, -1]) {
            final potentialPos = Offset(
              potentialBranchPos.dx + math.cos(potentialPerpAngle) * potentialOffset * side,
              potentialBranchPos.dy + math.sin(potentialPerpAngle) * potentialOffset * side,
            );
            
            // Vérifier la distance avec toutes les feuilles existantes
            double minDistance = double.infinity;
            for (final existingLeaf in existingLeaves) {
              final existingPos = existingLeaf.calculatePosition();
              final distance = (potentialPos - existingPos).distance;
              if (distance < minDistance) {
                minDistance = distance;
              }
            }
            
            // Vérifier aussi avec les feuilles déjà créées sur cette branche
            for (final leaf in leaves) {
              final leafPos = leaf.calculatePosition();
              final distance = (potentialPos - leafPos).distance;
              if (distance < minDistance) {
                minDistance = distance;
              }
            }
            
            // Choisir le côté avec la plus grande distance
            if (minDistance > bestDistance) {
              bestDistance = minDistance;
              bestSide = side;
            }
          }
          
          // Ne générer la feuille que si elle est assez éloignée des autres
          if (bestDistance >= minLeafDistance) {
            // Délai d'apparition aléatoire : chaque feuille apparaît progressivement
            // Plus la branche est profonde, plus les feuilles apparaissent tôt
            // Ajouter un délai basé sur l'index pour apparition progressive
            final indexDelay = (j / numLeaves) * 0.3; // Délai de 0 à 30% entre les feuilles
            final randomDelay = random.nextDouble() * 0.2; // Délai aléatoire supplémentaire (0 à 20%)
            final appearanceTime = (baseAppearanceLevel + indexDelay + randomDelay).clamp(0.0, 1.0);
            
            // Taille maximale aléatoire (0.5 à 1.5x la taille de base) - variation plus importante
            final maxSize = 0.5 + random.nextDouble() * 1.0;
            
            // Identifiant unique pour la feuille
            final leafId = 'branch_${newDepth}_${i}_leaf_$j';
            
            final newLeaf = LeafInfo(
              leafId: leafId,
              tOnBranch: t,
              side: bestSide,
              branchStart: branchStart,
              branchEnd: branchEnd,
              branchControl: branchControl,
              branchLength: branchLength,
              appearanceTime: appearanceTime,
              maxSize: maxSize,
              currentGrowth: 0.0,
            );
            
            leaves.add(newLeaf);
            existingLeaves.add(newLeaf); // Ajouter à la liste pour les vérifications suivantes
            existingLeafIds.add(leafId); // Ajouter l'ID pour éviter les doublons
          }
        }
      }

      // Ajouter une feuille à l'extrémité si c'est la dernière profondeur
      if (newDepth >= maxDepth) {
        final endAppearanceTime = (newDepth / parameters.maxDepth).clamp(0.0, 1.0);
        final endMaxSize = 0.5 + random.nextDouble() * 1.0; // Variation plus importante
        final endLeafId = 'branch_${newDepth}_${i}_leaf_end';
        
        leaves.add(LeafInfo(
          leafId: endLeafId,
          tOnBranch: 1.0, // À l'extrémité
          side: 1, // Côté par défaut
          branchStart: branchStart,
          branchEnd: branchEnd,
          branchControl: branchControl,
          branchLength: branchLength,
          appearanceTime: endAppearanceTime,
          maxSize: endMaxSize,
          currentGrowth: 0.0,
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

      // Récursion pour les branches enfants (toujours jusqu'à maxDepth)
      _generateBranches(branch, maxDepth, depthFraction, random);
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
    // Calculer la profondeur effective selon le niveau de croissance
    final effectiveDepth = _fractionalDepth.floor();
    final depthFraction = _fractionalDepth - effectiveDepth;
    
    // Calculer l'extrémité visible du tronc pour connecter les branches
    Offset? trunkVisibleEnd;
    double trunkLengthFactor = 0.0;
    
    // Dessiner l'arbre en premier (en arrière-plan)
    // Dessiner les branches (du plus profond au moins profond pour le z-ordering)
    // Filtrer les branches selon le niveau de croissance
    final sortedBranches = List<TreeBranch>.from(_branches)
      ..sort((a, b) => b.depth.compareTo(a.depth));
    
    for (final branch in sortedBranches) {
      // Ne dessiner que les branches qui devraient être visibles
      if (branch.depth == 0) {
        // Tronc : grandit depuis la base vers le haut
        // Le tronc commence très petit et grandit progressivement
        final growthFactor = growthLevel.clamp(0.0, 1.0);
        
        // Calculer la longueur et l'épaisseur du tronc selon le niveau de croissance
        // Longueur : commence à 0% (très petit) et grandit jusqu'à 100% de la longueur finale
        trunkLengthFactor = growthFactor.clamp(0.0, 1.0);
        
        // Calculer l'extrémité visible du tronc
        trunkVisibleEnd = trunkLengthFactor < 1.0
            ? Offset(
                branch.start.dx + (branch.end.dx - branch.start.dx) * trunkLengthFactor,
                branch.start.dy + (branch.end.dy - branch.start.dy) * trunkLengthFactor,
              )
            : branch.end;
        
        // Épaisseur : commence très fine (1%) et s'élargit jusqu'à 100% de l'épaisseur finale
        // Utiliser une courbe quadratique pour un élargissement plus visible au début
        final thicknessGrowth = growthFactor * growthFactor;
        final trunkThicknessFactor = (0.01 / 0.06 + (1.0 - 0.01 / 0.06) * thicknessGrowth).clamp(0.0, 1.0);
        
        _drawBranch(canvas, branch, trunkLengthFactor, trunkThicknessFactor);
      } else if (branch.depth == 1 && trunkVisibleEnd != null) {
        // Branches de profondeur 1 : doivent partir de l'extrémité visible du tronc
        // Ajuster le point de départ pour qu'elles soient connectées
        if (branch.depth < effectiveDepth) {
          // Branche complètement visible, mais épaisseur qui grandit progressivement
          final branchMaturityLevel = branch.depth / parameters.maxDepth;
          final timeSinceAppearance = ((growthLevel - branchMaturityLevel) / 0.3).clamp(0.0, 1.0);
          final branchThicknessFactor = timeSinceAppearance * timeSinceAppearance;
          if (branchThicknessFactor > 0.0) {
            // Créer une branche temporaire avec le point de départ ajusté
            final adjustedBranch = TreeBranch(
              start: trunkVisibleEnd,
              end: branch.end,
              controlPoint: branch.controlPoint,
              angle: branch.angle,
              length: branch.length,
              thickness: branch.thickness,
              depth: branch.depth,
              leaves: branch.leaves,
            );
            _drawBranch(canvas, adjustedBranch, 1.0, branchThicknessFactor);
          }
        } else if (branch.depth == effectiveDepth && depthFraction > 0.01) {
          // Branche partiellement visible
          final branchThicknessFactor = depthFraction;
          final adjustedBranch = TreeBranch(
            start: trunkVisibleEnd,
            end: branch.end,
            controlPoint: branch.controlPoint,
            angle: branch.angle,
            length: branch.length,
            thickness: branch.thickness,
            depth: branch.depth,
            leaves: branch.leaves,
          );
          _drawBranch(canvas, adjustedBranch, depthFraction, branchThicknessFactor);
        }
      } else if (branch.depth < effectiveDepth) {
        // Branche complètement visible, mais épaisseur qui grandit progressivement
        // Les branches commencent étroites et s'élargissent avec le temps
        final branchMaturityLevel = branch.depth / parameters.maxDepth;
        // La branche commence à apparaître à branchMaturityLevel et s'élargit progressivement
        final timeSinceAppearance = ((growthLevel - branchMaturityLevel) / 0.3).clamp(0.0, 1.0);
        // Utiliser une courbe quadratique pour que l'élargissement soit plus visible
        final branchThicknessFactor = timeSinceAppearance * timeSinceAppearance;
        if (branchThicknessFactor > 0.0) {
          _drawBranch(canvas, branch, 1.0, branchThicknessFactor);
        }
      } else if (branch.depth == effectiveDepth && depthFraction > 0.01) {
        // Branche partiellement visible
        final branchThicknessFactor = depthFraction;
        _drawBranch(canvas, branch, depthFraction, branchThicknessFactor);
      }
      // Sinon, ne pas dessiner (branche pas encore créée)
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

  void _drawBranch(Canvas canvas, TreeBranch branch, double lengthFactor, double thicknessFactor) {
    // lengthFactor : 0.0 à 1.0, contrôle la portion de la branche à dessiner
    // thicknessFactor : 0.0 à 1.0, contrôle l'épaisseur de la branche
    if (lengthFactor <= 0.0 || thicknessFactor <= 0.0) return;
    
    // Si la branche n'est pas complètement visible, ajuster le point final
    final effectiveEnd = lengthFactor < 1.0
        ? Offset(
            branch.start.dx + (branch.end.dx - branch.start.dx) * lengthFactor,
            branch.start.dy + (branch.end.dy - branch.start.dy) * lengthFactor,
          )
        : branch.end;
    
    // Ajuster le point de contrôle proportionnellement
    final effectiveControl = lengthFactor < 1.0
        ? Offset(
            branch.start.dx + (branch.controlPoint.dx - branch.start.dx) * lengthFactor,
            branch.start.dy + (branch.controlPoint.dy - branch.start.dy) * lengthFactor,
          )
        : branch.controlPoint;
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
    
    // Calculer l'épaisseur effective selon le facteur d'épaisseur
    final effectiveThickness = branch.thickness * thicknessFactor;
    
    // Épaisseur au début : si c'est le tronc (depth 0), commencer très fin
    // Sinon, utiliser l'épaisseur du parent ajustée
    final halfThicknessStart = branch.depth == 0
        ? (effectiveThickness / parameters.thicknessRatio) / 2 // Tronc : commence fin
        : (effectiveThickness / parameters.thicknessRatio) / 2; // Branches : épaisseur réduite au début
    
    // Si la branche n'a pas d'enfants, elle se termine en pointe (épaisseur proche de zéro)
    // Sinon, elle garde une épaisseur minimale pour se connecter aux branches enfants
    final effectiveThicknessEnd = hasChildren 
      ? effectiveThickness / 2 // Épaisseur normale si elle a des enfants
      : effectiveThickness * 0.05; // Presque zéro pour terminer en pointe
    final halfThicknessEnd = effectiveThicknessEnd;
    
    // Points le long de la courbe pour créer le contour
    final topPoints = <Offset>[];
    final bottomPoints = <Offset>[];
    
    for (int i = 0; i <= numSegments; i++) {
      final t = i / numSegments;
      final point = _bezierPoint(branch.start, effectiveControl, effectiveEnd, t);
      
      // Calculer l'angle tangent à la courbe à ce point
      final tangent = _bezierTangent(branch.start, effectiveControl, effectiveEnd, t);
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
    
    // Calculer la position actuelle de la feuille (dynamique)
    final leafPosition = leafInfo.calculatePosition();
    
    // Taille de base de la feuille
    final baseSize = treeSize * 0.08; // 2x plus grand (0.04 * 2 = 0.08)
    
    // Taille actuelle : baseSize * maxSize * currentGrowth
    final leafSize = baseSize * leafInfo.maxSize * leafInfo.currentGrowth;
    
    // Si la taille est trop petite, ne pas dessiner
    if (leafSize < 0.01) return;
    
    // Calculer l'angle perpendiculaire à la branche au point tOnBranch
    final tangent = _bezierTangent(
      leafInfo.branchStart,
      leafInfo.branchControl,
      leafInfo.branchEnd,
      leafInfo.tOnBranch,
    );
    
    // Angle de la branche (direction de la tangente)
    final branchAngle = math.atan2(tangent.dy, tangent.dx);
    
    // Angle perpendiculaire à la branche (90° exactement)
    // L'image de la feuille pointe vers le haut par défaut, donc on la tourne pour être perpendiculaire
    // Perpendiculaire à la branche = angle de la branche + π/2
    final rotation = branchAngle + math.pi / 2;
    
    // Sauvegarder l'état du canvas
    canvas.save();
    
    // Appliquer la rotation et translation
    canvas.translate(leafPosition.dx, leafPosition.dy);
    canvas.rotate(rotation);
    
    // Si la feuille est du côté gauche, appliquer un miroir horizontal
    if (leafInfo.side == -1) {
      canvas.scale(-1.0, 1.0); // Miroir horizontal
    }
    
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

