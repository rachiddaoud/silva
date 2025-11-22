import 'dart:math' as math;
import 'package:flutter/material.dart';


/// État d'une feuille dans le processus de mort
enum LeafState {
  alive,
  dead1,
  dead2,
  dead3,
}

/// Classe représentant une feuille attachée à une branche
class Leaf {
  final String id;
  final double tOnBranch; // Position sur la branche (0.0 à 1.0)
  final int side; // Côté de la branche (-1 ou 1)
  double age; // Âge en jours (peut être fractionnaire)
  final double maxAge; // Âge maximum (dépend de l'épaisseur de la branche)
  final double randomSizeFactor; // Facteur aléatoire de taille (0.8 à 1.2) pour variation individuelle
  double currentGrowth; // Niveau de croissance actuel (0.0 à 1.0)
  LeafState state; // État de la feuille
  int deathAge; // Nombre de jours depuis le début de la mort (0 = pas encore morte)
  Offset position; // Position calculée (mutable)
  Offset branchPosition; // Position sur la branche (mutable)

  Leaf({
    required this.id,
    required this.tOnBranch,
    required this.side,
    this.age = 0.0,
    required this.maxAge,
    required this.randomSizeFactor,
    this.currentGrowth = 0.1,
    this.state = LeafState.alive,
    this.deathAge = 0,
    required this.position,
    required this.branchPosition,
  });
  
  /// Calcule la taille maximale dynamiquement basée sur l'état actuel de la branche
  double calculateMaxSize(Branch branch) {
    // Facteur basé sur la profondeur : impact augmenté pour les branches principales
    // depth 1 = 1.5, depth 2 = 1.2, depth 3 = 0.9, depth 4 = 0.6, depth 5+ = 0.4
    final depthFactor = 1.5 - (branch.depth - 1) * 0.3; // Décroît de 0.3 par niveau (augmenté)
    final clampedDepthFactor = depthFactor.clamp(0.4, 1.5); // Min 0.4, max 1.5 pour les branches principales
    
    // Facteur basé sur l'âge de la branche : plus vieille = plus grande
    final ageFactor = 0.5 + (branch.age / 20.0).clamp(0.0, 0.5); // Entre 0.5 et 1.0
    
    // maxSize : combine depth (impact augmenté), age et le facteur aléatoire individuel de la feuille
    return clampedDepthFactor * ageFactor * randomSizeFactor;
  }

  /// Fait grandir la feuille d'un jour
  /// Appelée par la branche parent lors de la propagation hiérarchique
  /// Évolue automatiquement l'état de mort si la feuille est en train de mourir
  void growOneDay() {
    if (state == LeafState.alive && age < maxAge) {
      // Feuille vivante : croissance normale
      age += 0.05; // Augmente l'âge (fractionnaire pour croissance progressive)
      // Calcul simplifié : currentGrowth = ratio d'âge (linéaire)
      currentGrowth = (age / maxAge).clamp(0.0, 1.0);
    } else if (state != LeafState.alive) {
      // Feuille en train de mourir : évolution automatique de l'état chaque jour
      deathAge++;
      
      // Évolution automatique basée sur le nombre de jours depuis le début de la mort :
      // - Jour 0 (startDeath appelé) : dead_1
      // - Jour 1 (après 1er growOneDay) : reste dead_1
      // - Jour 2 (après 2ème growOneDay) : passe à dead_2
      // - Jour 3 (après 3ème growOneDay) : passe à dead_3
      // - Jour 4+ : reste dead_3 (affichée pendant au moins 1 jour, puis supprimée)
      if (deathAge == 2) {
        state = LeafState.dead2;
      } else if (deathAge >= 3) {
        state = LeafState.dead3;
      }
      // Si deathAge == 1, on reste en dead_1 (déjà défini par startDeath)
    }
  }

  /// Lance le processus de mort de la feuille
  /// La feuille passera automatiquement à dead_1, puis dead_2, puis dead_3 au fil des jours
  void startDeath() {
    if (state == LeafState.alive) {
      state = LeafState.dead1;
      deathAge = 0; // Commence le compteur de mort
    }
  }
  
  /// Vérifie si la feuille doit être supprimée (en état dead_3 depuis au moins 1 jour)
  bool shouldBeRemoved() {
    return state == LeafState.dead3 && deathAge >= 4;
  }

  /// Met à jour la position de la feuille pour suivre sa branche
  void updatePosition(Branch branch, double treeSize) {
    // Calculer la position exacte sur la branche au paramètre tOnBranch
    final branchPos = _bezierPoint(
      branch.start,
      branch.controlPoint,
      branch.end,
      tOnBranch,
    );

    // Calculer la tangente à la branche à ce point
    final tangent = _bezierTangent(
      branch.start,
      branch.controlPoint,
      branch.end,
      tOnBranch,
    );

    // Calculer l'angle perpendiculaire à la branche
    final branchAngle = math.atan2(tangent.dy, tangent.dx);
    final perpAngle = branchAngle + math.pi / 2;

    // Calculer l'épaisseur de la branche à ce point
    final thicknessAtPoint = branch.thickness * (1.0 - tOnBranch * 0.3);
    final branchRadius = thicknessAtPoint / 2;

    // Position finale: depuis le centre de la branche, aller vers l'extérieur
    position = Offset(
      branchPos.dx + math.cos(perpAngle) * branchRadius * side,
      branchPos.dy + math.sin(perpAngle) * branchRadius * side,
    );
    branchPosition = branchPos;
  }

  /// Calcule un point sur une courbe de Bézier quadratique
  static Offset _bezierPoint(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1 - t;
    final tt = t * t;
    final uu = u * u;

    return Offset(
      uu * p0.dx + 2 * u * t * p1.dx + tt * p2.dx,
      uu * p0.dy + 2 * u * t * p1.dy + tt * p2.dy,
    );
  }

  /// Calcule la tangente à une courbe de Bézier quadratique
  static Offset _bezierTangent(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1 - t;
    return Offset(
      2 * u * (p1.dx - p0.dx) + 2 * t * (p2.dx - p1.dx),
      2 * u * (p1.dy - p0.dy) + 2 * t * (p2.dy - p1.dy),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tOnBranch': tOnBranch,
      'side': side,
      'age': age,
      'maxAge': maxAge,
      'randomSizeFactor': randomSizeFactor,
      'currentGrowth': currentGrowth,
      'state': state.index,
      'deathAge': deathAge,
      'position': {'dx': position.dx, 'dy': position.dy},
      'branchPosition': {'dx': branchPosition.dx, 'dy': branchPosition.dy},
    };
  }

  factory Leaf.fromJson(Map<String, dynamic> json) {
    return Leaf(
      id: json['id'] as String,
      tOnBranch: json['tOnBranch'] as double,
      side: json['side'] as int,
      age: json['age'] as double,
      maxAge: json['maxAge'] as double,
      randomSizeFactor: json['randomSizeFactor'] as double,
      currentGrowth: json['currentGrowth'] as double,
      state: LeafState.values[json['state'] as int],
      deathAge: json['deathAge'] as int,
      position: Offset(
        (json['position'] as Map<String, dynamic>)['dx'] as double,
        (json['position'] as Map<String, dynamic>)['dy'] as double,
      ),
      branchPosition: Offset(
        (json['branchPosition'] as Map<String, dynamic>)['dx'] as double,
        (json['branchPosition'] as Map<String, dynamic>)['dy'] as double,
      ),
    );
  }
}

/// Classe représentant une fleur attachée à une branche
class Flower {
  final String id;
  final double tOnBranch; // Position sur la branche (0.0 à 1.0)
  final int side; // Côté de la branche (-1 ou 1)
  final double sizeFactor; // Facteur de taille basé sur la profondeur de la branche
  final int flowerType; // Type de fleur (0 = flower.png, 1 = jasmin.png)
  Offset position; // Position calculée (mutable)
  Offset branchPosition; // Position sur la branche (mutable)

  Flower({
    required this.id,
    required this.tOnBranch,
    required this.side,
    required this.sizeFactor,
    required this.flowerType,
    required this.position,
    required this.branchPosition,
  });

  /// Calcule la taille de la fleur basée sur la profondeur de la branche
  /// Plus la branche est proche du tronc (depth petit), plus la fleur est grande
  static double calculateSizeFactor(Branch branch) {
    // Facteur basé sur la profondeur : depth 1 = 1.0, depth 6 = 0.3
    final depthFactor = 1.0 - (branch.depth - 1) * 0.12; // Décroît de 0.12 par niveau
    return depthFactor.clamp(0.3, 1.0);
  }

  /// Met à jour la position de la fleur pour suivre sa branche
  void updatePosition(Branch branch, double treeSize) {
    // Calculer la position exacte sur la branche au paramètre tOnBranch
    final branchPos = _bezierPoint(
      branch.start,
      branch.controlPoint,
      branch.end,
      tOnBranch,
    );

    // Calculer la tangente à la branche à ce point
    final tangent = _bezierTangent(
      branch.start,
      branch.controlPoint,
      branch.end,
      tOnBranch,
    );

    // Calculer l'angle perpendiculaire à la branche
    final branchAngle = math.atan2(tangent.dy, tangent.dx);
    final perpAngle = branchAngle + math.pi / 2;

    // Calculer l'épaisseur de la branche à ce point
    final thicknessAtPoint = branch.thickness * (1.0 - tOnBranch * 0.3);
    final branchRadius = thicknessAtPoint / 2;

    // Position finale: depuis le centre de la branche, aller vers l'extérieur
    position = Offset(
      branchPos.dx + math.cos(perpAngle) * branchRadius * side,
      branchPos.dy + math.sin(perpAngle) * branchRadius * side,
    );
    branchPosition = branchPos;
  }

  /// Calcule un point sur une courbe de Bézier quadratique
  static Offset _bezierPoint(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1 - t;
    final tt = t * t;
    final uu = u * u;

    return Offset(
      uu * p0.dx + 2 * u * t * p1.dx + tt * p2.dx,
      uu * p0.dy + 2 * u * t * p1.dy + tt * p2.dy,
    );
  }

  /// Calcule la tangente à une courbe de Bézier quadratique
  static Offset _bezierTangent(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1 - t;
    return Offset(
      2 * u * (p1.dx - p0.dx) + 2 * t * (p2.dx - p1.dx),
      2 * u * (p1.dy - p0.dy) + 2 * t * (p2.dy - p1.dy),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tOnBranch': tOnBranch,
      'side': side,
      'sizeFactor': sizeFactor,
      'flowerType': flowerType,
      'position': {'dx': position.dx, 'dy': position.dy},
      'branchPosition': {'dx': branchPosition.dx, 'dy': branchPosition.dy},
    };
  }

  factory Flower.fromJson(Map<String, dynamic> json) {
    return Flower(
      id: json['id'] as String,
      tOnBranch: json['tOnBranch'] as double,
      side: json['side'] as int,
      sizeFactor: json['sizeFactor'] as double,
      flowerType: json['flowerType'] as int,
      position: Offset(
        (json['position'] as Map<String, dynamic>)['dx'] as double,
        (json['position'] as Map<String, dynamic>)['dy'] as double,
      ),
      branchPosition: Offset(
        (json['branchPosition'] as Map<String, dynamic>)['dx'] as double,
        (json['branchPosition'] as Map<String, dynamic>)['dy'] as double,
      ),
    );
  }
}

/// Classe représentant une branche de l'arbre
class Branch {
  final String id;
  final List<Branch> children = []; // Branches enfants
  final List<Leaf> leaves = []; // Feuilles attachées à cette branche
  final List<Flower> flowers = []; // Fleurs attachées à cette branche
  int age; // Âge en jours (commence à 0 quand la branche apparaît)

  // Géométrie
  Offset start; // Point de départ (mutable pour la croissance)
  Offset end; // Point d'arrivée (mutable pour la croissance)
  Offset controlPoint; // Point de contrôle Bézier (mutable)
  double thickness; // Épaisseur (mutable)
  double length; // Longueur (mutable)
  final double angle; // Angle par rapport au parent
  final int depth; // Niveau (0=tronc, 1=première génération, etc.)

  Branch({
    required this.id,
    required this.start,
    required this.end,
    required this.controlPoint,
    required this.thickness,
    required this.length,
    required this.angle,
    required this.depth,
    this.age = 0,
  });

  /// Ajoute une branche enfant
  void addChild(Branch child) {
    children.add(child);
  }

  /// Ajoute une feuille
  void addLeaf(Leaf leaf) {
    leaves.add(leaf);
  }

  /// Supprime une feuille par son ID
  void removeLeaf(String leafId) {
    leaves.removeWhere((leaf) => leaf.id == leafId);
  }

  /// Ajoute une fleur
  void addFlower(Flower flower) {
    flowers.add(flower);
  }

  /// Supprime une fleur par son ID
  void removeFlower(String flowerId) {
    flowers.removeWhere((flower) => flower.id == flowerId);
  }

  /// Fait grandir la branche d'un jour
  /// Propagation hiérarchique : Branch → ses feuilles → ses branches enfants
  void growOneDay() {
    age++;

    // 1. Propager la croissance aux feuilles de cette branche
    //    (et supprimer celles qui sont complètement mortes)
    final leavesToRemove = <Leaf>[];
    for (final leaf in leaves) {
      leaf.growOneDay();
      // Supprimer les feuilles en état dead_3 depuis au moins 1 jour
      if (leaf.shouldBeRemoved()) {
        leavesToRemove.add(leaf);
      }
    }
    // Supprimer les feuilles mortes
    for (final leaf in leavesToRemove) {
      removeLeaf(leaf.id);
    }

    // 2. Propager la croissance aux branches enfants (qui propageront récursivement)
    for (final child in children) {
      child.growOneDay();
    }
  }

  /// Retourne la capacité maximale de feuilles pour cette branche
  /// Basé sur la profondeur (depth) et l'âge de la branche
  int getCapacity() {
    // Base : 1 feuille par 50px de longueur
    final baseCapacity = (length / 50.0).ceil();
    
    // Facteur basé sur la profondeur : branches principales (depth petit) = plus de feuilles
    // depth 1 = 1.5x, depth 6 = 0.8x
    final depthFactor = 1.5 - (depth * 0.12).clamp(0.0, 0.7);
    
    // Facteur basé sur l'âge : branches plus vieilles = plus de feuilles
    final ageFactor = 1.0 + (age / 30.0).clamp(0.0, 0.5); // Entre 1.0 et 1.5
    
    final totalCapacity = (baseCapacity * depthFactor * ageFactor).ceil();
    return totalCapacity.clamp(1, 25); // Min 1, max 25 feuilles
  }

  /// Vérifie si on peut ajouter une feuille
  bool canAddLeaf() {
    return leaves.length < getCapacity();
  }

  /// Retourne toutes les branches (cette branche + tous les enfants récursivement)
  List<Branch> getAllBranches() {
    final branches = <Branch>[this];
    for (final child in children) {
      branches.addAll(child.getAllBranches());
    }
    return branches;
  }

  /// Retourne toutes les feuilles (de cette branche + tous les enfants récursivement)
  List<Leaf> getAllLeaves() {
    final allLeaves = <Leaf>[...leaves];
    for (final child in children) {
      allLeaves.addAll(child.getAllLeaves());
    }
    return allLeaves;
  }

  /// Retourne toutes les fleurs (de cette branche + tous les enfants récursivement)
  List<Flower> getAllFlowers() {
    final allFlowers = <Flower>[...flowers];
    for (final child in children) {
      allFlowers.addAll(child.getAllFlowers());
    }
    return allFlowers;
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'children': children.map((c) => c.toJson()).toList(),
      'leaves': leaves.map((l) => l.toJson()).toList(),
      'flowers': flowers.map((f) => f.toJson()).toList(),
      'age': age,
      'start': {'dx': start.dx, 'dy': start.dy},
      'end': {'dx': end.dx, 'dy': end.dy},
      'controlPoint': {'dx': controlPoint.dx, 'dy': controlPoint.dy},
      'thickness': thickness,
      'length': length,
      'angle': angle,
      'depth': depth,
    };
  }

  factory Branch.fromJson(Map<String, dynamic> json) {
    final branch = Branch(
      id: json['id'] as String,
      start: Offset(
        (json['start'] as Map<String, dynamic>)['dx'] as double,
        (json['start'] as Map<String, dynamic>)['dy'] as double,
      ),
      end: Offset(
        (json['end'] as Map<String, dynamic>)['dx'] as double,
        (json['end'] as Map<String, dynamic>)['dy'] as double,
      ),
      controlPoint: Offset(
        (json['controlPoint'] as Map<String, dynamic>)['dx'] as double,
        (json['controlPoint'] as Map<String, dynamic>)['dy'] as double,
      ),
      thickness: json['thickness'] as double,
      length: json['length'] as double,
      angle: json['angle'] as double,
      depth: json['depth'] as int,
      age: json['age'] as int,
    );

    if (json['children'] != null) {
      final childrenList = (json['children'] as List).map((c) => Branch.fromJson(c as Map<String, dynamic>)).toList();
      branch.children.addAll(childrenList);
    }

    if (json['leaves'] != null) {
      final leavesList = (json['leaves'] as List).map((l) => Leaf.fromJson(l as Map<String, dynamic>)).toList();
      branch.leaves.addAll(leavesList);
    }

    if (json['flowers'] != null) {
      final flowersList = (json['flowers'] as List).map((f) => Flower.fromJson(f as Map<String, dynamic>)).toList();
      branch.flowers.addAll(flowersList);
    }

    return branch;
  }
}

/// Classe représentant l'arbre complet
class Tree {
  int age; // Âge total de l'arbre en jours
  final Branch trunk; // Branche racine (tronc)
  final double treeSize; // Taille du canvas
  final TreeParameters parameters; // Paramètres de génération

  Tree({
    required this.age,
    required this.trunk,
    required this.treeSize,
    required this.parameters,
  });

  /// Fait grandir l'arbre d'un jour
  /// Propagation hiérarchique : Tree → Branch → Leaf
  void growOneDay() {
    age++;
    // Propager la croissance au tronc (qui propagera récursivement à toutes les branches et feuilles)
    trunk.growOneDay();
  }

  /// Retourne toutes les branches de l'arbre (parcours récursif depuis le tronc)
  List<Branch> getAllBranches() {
    return trunk.getAllBranches();
  }

  /// Retourne toutes les feuilles de l'arbre (parcours récursif depuis le tronc)
  List<Leaf> getAllLeaves() {
    return trunk.getAllLeaves();
  }

  /// Retourne toutes les fleurs de l'arbre (parcours récursif depuis le tronc)
  List<Flower> getAllFlowers() {
    return trunk.getAllFlowers();
  }

  /// Retourne le niveau de croissance actuel (0.0 à 1.0) basé sur l'âge
  double getGrowthLevel() {
    // Adapter selon les besoins: par exemple, 1 jour = 0.05 de croissance
    // jusqu'à atteindre 1.0 (arbre mature)
    return (age * 0.05).clamp(0.0, 1.0);
  }
  Map<String, dynamic> toJson() {
    return {
      'age': age,
      'trunk': trunk.toJson(),
      'treeSize': treeSize,
      'parameters': parameters.toJson(),
    };
  }

  factory Tree.fromJson(Map<String, dynamic> json) {
    return Tree(
      age: json['age'] as int,
      trunk: Branch.fromJson(json['trunk'] as Map<String, dynamic>),
      treeSize: json['treeSize'] as double,
      parameters: TreeParameters.fromJson(json['parameters'] as Map<String, dynamic>),
    );
  }
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
  Map<String, dynamic> toJson() {
    return {
      'maxDepth': maxDepth,
      'baseBranchAngle': baseBranchAngle,
      'lengthRatio': lengthRatio,
      'thicknessRatio': thicknessRatio,
      'angleVariation': angleVariation,
      'curveIntensity': curveIntensity,
      'seed': seed,
    };
  }

  factory TreeParameters.fromJson(Map<String, dynamic> json) {
    return TreeParameters(
      maxDepth: json['maxDepth'] as int,
      baseBranchAngle: json['baseBranchAngle'] as double,
      lengthRatio: json['lengthRatio'] as double,
      thicknessRatio: json['thicknessRatio'] as double,
      angleVariation: json['angleVariation'] as double,
      curveIntensity: json['curveIntensity'] as double,
      seed: json['seed'] as int,
    );
  }
}

