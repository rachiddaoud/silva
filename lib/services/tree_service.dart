import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ma_bulle/models/tree_model.dart';

/// Service responsable de la génération de la structure de l'arbre
class TreeGenerator {
  /// Génère la structure Tree avec toutes ses branches de manière procédurale
  static Tree generateTreeStructure({
    required double growthLevel,
    required double treeSize,
    required TreeParameters parameters,
    int treeAge = 0,
  }) {
    final random = math.Random(parameters.seed);
    final fractionalDepth = parameters.maxDepth * growthLevel.clamp(0.0, 1.0);
    final effectiveDepth = fractionalDepth.floor();
    final depthFraction = fractionalDepth - effectiveDepth;
    
    if (effectiveDepth == 0 && depthFraction < 0.01) {
      // Arbre trop jeune, juste créer un tronc vide
      final treeBase = _getTreeBasePositionStatic(treeSize);
      final trunk = Branch(
        id: '0',
        start: treeBase,
        end: treeBase,
        controlPoint: treeBase,
        thickness: 0.01,
        length: 0.01,
        angle: -math.pi / 2,
        depth: 0,
        age: treeAge,
      );
      return Tree(
        age: treeAge,
        trunk: trunk,
        treeSize: treeSize,
        parameters: parameters,
      );
    }
    
    // Position de départ
    final treeBase = _getTreeBasePositionStatic(treeSize);
    final startX = treeBase.dx;
    final startY = treeBase.dy;
    
    // Facteur de croissance
    final growthFactor = growthLevel.clamp(0.0, 1.0);
    
    // Longueur et épaisseur du tronc
    final trunkLength = treeSize * (0.05 + 0.20 * growthFactor);
    final thicknessGrowth = growthFactor * growthFactor;
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
    
    // Création du tronc
    final trunk = Branch(
      id: '0',
      start: Offset(startX, startY),
      end: trunkEnd,
      controlPoint: trunkControl,
      thickness: trunkThickness,
      length: trunkLength,
      angle: trunkAngle,
      depth: 0,
      age: treeAge,
    );
    
    // Génération récursive des branches enfants
    _generateBranchChildren(
      trunk,
      effectiveDepth,
      depthFraction,
      random,
      parameters,
      treeSize,
      treeAge,
    );
    
    return Tree(
      age: treeAge,
      trunk: trunk,
      treeSize: treeSize,
      parameters: parameters,
    );
  }
  
  /// Génère récursivement les branches enfants
  static void _generateBranchChildren(
    Branch parent,
    int effectiveDepth,
    double depthFraction,
    math.Random random,
    TreeParameters parameters,
    double treeSize,
    int treeAge,
  ) {
    // Nombre de branches (2 ou 3)
    final numBranches = random.nextBool() ? 2 : 3;
    
    final newDepth = parent.depth + 1;
    
    // Déterminer la profondeur maximale à générer
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
      if (newDepth == maxDepth && depthFraction > 0.0 && depthFraction < 1.0) {
        branchLength *= depthFraction;
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
      
      // Création de la branche avec ID unique
      final branchId = '${parent.id}_$i';
      final branch = Branch(
        id: branchId,
        start: branchStart,
        end: branchEnd,
        controlPoint: branchControl,
        thickness: branchThickness,
        length: branchLength,
        angle: branchAngle,
        depth: newDepth,
        age: treeAge,
      );
      
      // Ajouter la branche comme enfant du parent
      parent.addChild(branch);
      
      // Récursion pour les branches enfants
      if (newDepth < maxDepth) {
        _generateBranchChildren(
          branch,
          effectiveDepth,
          depthFraction,
          random,
          parameters,
          treeSize,
          treeAge,
        );
      }
    }
  }
  
  /// Calcule la position de base de l'arbre (version statique)
  static Offset _getTreeBasePositionStatic(double treeSize) {
    // Position de la terre (similaire à _drawGround)
    final groundWidth = treeSize * 0.4;
    final aspectRatio = 1.0; // Ratio par défaut
    final groundHeight = groundWidth / aspectRatio;
    
    final groundX = (treeSize - groundWidth) / 2;
    final treeBaseY = treeSize * 0.75;
    final groundY = treeBaseY - groundHeight / 2;
    
    final groundCenterX = groundX + groundWidth / 2;
    final groundCenterY = groundY + groundHeight / 2;
    
    return Offset(groundCenterX, groundCenterY);
  }
}

/// Contrôleur pour gérer l'état et les interactions de l'arbre
class TreeController extends ChangeNotifier {
  Tree? _tree;
  Tree? get tree => _tree;

  /// Initialise ou met à jour l'arbre
  void updateTree({
    required double growthLevel,
    required double size,
    required TreeParameters parameters,
  }) {
    // Sauvegarder les feuilles et fleurs existantes
    final existingLeaves = _tree?.getAllLeaves() ?? [];
    final existingFlowers = _tree?.getAllFlowers() ?? [];
    
    // Régénérer l'arbre avec la nouvelle structure
    _tree = TreeGenerator.generateTreeStructure(
      growthLevel: growthLevel,
      treeSize: size,
      parameters: parameters,
      treeAge: _tree?.age ?? 0,
    );
    
    // Réappliquer les feuilles existantes sur les nouvelles branches
    if (existingLeaves.isNotEmpty) {
      _reapplyLeaves(existingLeaves, size);
    }
    
    // Réappliquer les fleurs existantes sur les nouvelles branches
    if (existingFlowers.isNotEmpty) {
      _reapplyFlowers(existingFlowers, size);
    }
    
    notifyListeners();
  }

  /// Incrémente l'âge de toutes les feuilles vivantes (fait grandir l'arbre d'un jour)
  void growLeaves() {
    if (_tree == null) return;
    
    _tree!.growOneDay();
    notifyListeners();
  }

  /// Avance le processus de mort des feuilles
  void advanceLeafDeath() {
    if (_tree == null) return;
    
    final allLeaves = _tree!.getAllLeaves();
    
    // Sélectionner 1-2 feuilles vivantes aléatoires pour lancer le processus de mort
    final aliveLeaves = allLeaves
        .where((l) => l.currentGrowth > 0.0 && l.state == LeafState.alive)
        .toList();
    
    if (aliveLeaves.isNotEmpty) {
      final random = math.Random();
      final numToKill = aliveLeaves.length > 1 ? (1 + random.nextInt(2)) : 1;
      
      for (int i = 0; i < numToKill && aliveLeaves.isNotEmpty; i++) {
        final index = random.nextInt(aliveLeaves.length);
        final leaf = aliveLeaves[index];
        leaf.startDeath(); // Lance le processus de mort (passe à dead_1)
        aliveLeaves.removeAt(index);
      }
    }
    
    notifyListeners();
  }

  /// Ajoute 1-2 feuilles aléatoirement sur des branches disponibles
  void addRandomLeaves() {
    if (_tree == null) return;
    
    final random = math.Random();
    
    // Récupérer toutes les branches (exclure le tronc)
    final branches = _tree!.getAllBranches();
    final availableBranches = branches.where((branch) => branch.depth > 0).toList();
    
    if (availableBranches.isEmpty) return;
    
    // Filtrer les branches qui ont de l'espace
    final branchesWithSpace = availableBranches.where((branch) => branch.canAddLeaf()).toList();
    
    if (branchesWithSpace.isEmpty) return;
    
    // Calculer le nombre de feuilles à ajouter
    final treeAge = _tree!.age;
    final totalBranches = branches.length;
    
    final baseCount = 1 + random.nextInt(2);
    final ageBonus = (treeAge / 3.0).floor();
    final branchBonus = (totalBranches / 10.0).floor();
    
    final numToAdd = (baseCount + ageBonus + branchBonus).clamp(1, 15);
    final actualNumToAdd = math.min(numToAdd, branchesWithSpace.length);
    
    final selectedBranches = <Branch>[];
    final availableCopy = List<Branch>.from(branchesWithSpace);
    
    for (int i = 0; i < actualNumToAdd && availableCopy.isNotEmpty; i++) {
      final index = random.nextInt(availableCopy.length);
      selectedBranches.add(availableCopy[index]);
      availableCopy.removeAt(index);
    }
    
    int addedCount = 0;
    for (final branch in selectedBranches) {
      if (branch.depth == 0) continue;
      
      final t = 0.2 + random.nextDouble() * 0.8;
      final branchPos = _bezierPoint(branch.start, branch.controlPoint, branch.end, t);
      final tangent = _bezierTangent(branch.start, branch.controlPoint, branch.end, t);
      final branchAngle = math.atan2(tangent.dy, tangent.dx);
      final perpAngle = branchAngle + math.pi / 2;
      final thicknessAtPoint = branch.thickness * (1.0 - t * 0.3);
      final branchRadius = thicknessAtPoint / 2;
      final side = random.nextBool() ? 1 : -1;
      final leafPos = Offset(
        branchPos.dx + math.cos(perpAngle) * branchRadius * side,
        branchPos.dy + math.sin(perpAngle) * branchRadius * side,
      );
      
      final depthFactor = 1.0 - (branch.depth - 1) * 0.12;
      final clampedDepthFactor = depthFactor.clamp(0.3, 1.0);
      final randomSizeFactor = 0.8 + random.nextDouble() * 0.4;
      final maxAge = 0.3 + (clampedDepthFactor * 0.3);
      
      bool tooClose = false;
      for (final existingLeaf in branch.leaves) {
        if ((leafPos - existingLeaf.position).distance < 10.0) {
          tooClose = true;
          break;
        }
      }
      
      if (!tooClose) {
        final leafId = '${branch.id}_${t.toStringAsFixed(3)}_$side';
        final initialElapsed = 0.2;
        final initialAge = initialElapsed * maxAge;
        
        final newLeaf = Leaf(
          id: leafId,
          tOnBranch: t,
          side: side,
          age: initialAge,
          maxAge: maxAge,
          randomSizeFactor: randomSizeFactor,
          currentGrowth: initialElapsed,
          state: LeafState.alive,
          position: leafPos,
          branchPosition: branchPos,
        );
        
        branch.addLeaf(newLeaf);
        addedCount++;
      }
    }
    
    if (addedCount > 0) {
      notifyListeners();
    }
  }

  /// Ajoute une fleur aléatoirement sur une branche disponible
  void addRandomFlower() {
    if (_tree == null) return;
    
    final random = math.Random();
    
    final branches = _tree!.getAllBranches();
    final availableBranches = branches.where((branch) => branch.depth > 0).toList();
    
    if (availableBranches.isEmpty) return;
    
    final weights = availableBranches.map((branch) {
      return 1.0 + (branch.age * 4.0);
    }).toList();
    
    final totalWeight = weights.fold(0.0, (sum, weight) => sum + weight);
    final randomValue = random.nextDouble() * totalWeight;
    double cumulativeWeight = 0.0;
    Branch? selectedBranch;
    
    for (int i = 0; i < availableBranches.length; i++) {
      cumulativeWeight += weights[i];
      if (randomValue <= cumulativeWeight) {
        selectedBranch = availableBranches[i];
        break;
      }
    }
    
    selectedBranch ??= availableBranches[random.nextInt(availableBranches.length)];
    
    if (selectedBranch.depth == 0) return;
    
    final t = 0.2 + random.nextDouble() * 0.8;
    final branchPos = _bezierPoint(selectedBranch.start, selectedBranch.controlPoint, selectedBranch.end, t);
    final tangent = _bezierTangent(selectedBranch.start, selectedBranch.controlPoint, selectedBranch.end, t);
    final branchAngle = math.atan2(tangent.dy, tangent.dx);
    final perpAngle = branchAngle + math.pi / 2;
    final thicknessAtPoint = selectedBranch.thickness * (1.0 - t * 0.3);
    final branchRadius = thicknessAtPoint / 2;
    final side = random.nextBool() ? 1 : -1;
    final flowerPos = Offset(
      branchPos.dx + math.cos(perpAngle) * branchRadius * side,
      branchPos.dy + math.sin(perpAngle) * branchRadius * side,
    );
    
    final sizeFactor = Flower.calculateSizeFactor(selectedBranch);
    final flowerType = random.nextInt(2);
    
    bool tooClose = false;
    for (final existingFlower in selectedBranch.flowers) {
      if ((flowerPos - existingFlower.position).distance < 15.0) {
        tooClose = true;
        break;
      }
    }
    
    if (!tooClose) {
      final flowerId = 'flower_${selectedBranch.id}_${t.toStringAsFixed(3)}_$side';
      
      final newFlower = Flower(
        id: flowerId,
        tOnBranch: t,
        side: side,
        sizeFactor: sizeFactor,
        flowerType: flowerType,
        position: flowerPos,
        branchPosition: branchPos,
      );
      
      selectedBranch.addFlower(newFlower);
      notifyListeners();
    }
  }

  /// Réapplique les feuilles existantes sur les nouvelles branches de l'arbre
  void _reapplyLeaves(List<Leaf> oldLeaves, double treeSize) {
    final newBranches = _tree!.getAllBranches();
    
    for (final oldLeaf in oldLeaves) {
      final parts = oldLeaf.id.split('_');
      if (parts.length < 3) continue;
      
      final branchId = parts.sublist(0, parts.length - 2).join('_');
      
      Branch? matchingBranch;
      try {
        matchingBranch = newBranches.firstWhere((b) => b.id == branchId);
      } catch (e) {
        continue;
      }
      
      if (matchingBranch.depth == 0) continue;
      
      final newLeaf = Leaf(
        id: oldLeaf.id,
        tOnBranch: oldLeaf.tOnBranch,
        side: oldLeaf.side,
        age: oldLeaf.age,
        maxAge: oldLeaf.maxAge,
        randomSizeFactor: oldLeaf.randomSizeFactor,
        currentGrowth: oldLeaf.currentGrowth,
        state: oldLeaf.state,
        deathAge: oldLeaf.deathAge,
        position: oldLeaf.position,
        branchPosition: oldLeaf.branchPosition,
      );
      
      newLeaf.updatePosition(matchingBranch, treeSize);
      matchingBranch.addLeaf(newLeaf);
    }
  }

  /// Réapplique les fleurs existantes sur les nouvelles branches de l'arbre
  void _reapplyFlowers(List<Flower> oldFlowers, double treeSize) {
    final newBranches = _tree!.getAllBranches();
    
    for (final oldFlower in oldFlowers) {
      final parts = oldFlower.id.split('_');
      if (parts.length < 4) continue;
      
      final branchId = parts.sublist(1, parts.length - 2).join('_');
      
      Branch? matchingBranch;
      try {
        matchingBranch = newBranches.firstWhere((b) => b.id == branchId);
      } catch (e) {
        continue;
      }
      
      if (matchingBranch.depth == 0) continue;
      
      final sizeFactor = Flower.calculateSizeFactor(matchingBranch);
      
      final newFlower = Flower(
        id: oldFlower.id,
        tOnBranch: oldFlower.tOnBranch,
        side: oldFlower.side,
        sizeFactor: sizeFactor,
        flowerType: oldFlower.flowerType,
        position: oldFlower.position,
        branchPosition: oldFlower.branchPosition,
      );
      
      newFlower.updatePosition(matchingBranch, treeSize);
      matchingBranch.addFlower(newFlower);
    }
  }
  
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
