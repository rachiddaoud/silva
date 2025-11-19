import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ma_bulle/models/tree_model.dart' as tree_model;

// Réexporter LeafState pour compatibilité
typedef LeafState = tree_model.LeafState;

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
  ui.Image? _groundImage;
  late AnimationController _windController;
  late Animation<double> _windAnimation;
  // ValueNotifier pour forcer le rebuild quand l'arbre change
  final ValueNotifier<int> _treeNotifier = ValueNotifier<int>(0);
  // L'arbre avec toutes ses branches et feuilles
  tree_model.Tree? _tree;
  
  // Getter pour accéder à l'arbre depuis l'extérieur
  tree_model.Tree? get tree => _tree;

  @override
  void initState() {
    super.initState();
    _loadLeafImage();
    _loadLeafDead1Image();
    _loadLeafDead2Image();
    _loadLeafDead3Image();
    _loadFlowerImage();
    _loadJasminImage();
    _loadGroundImage();
    
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
    _tree = TreePainter.generateTreeStructure(
      growthLevel: widget.growthLevel,
      treeSize: widget.size,
      parameters: widget.parameters,
      treeAge: 0,
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

  Future<void> _loadGroundImage() async {
    try {
      final ByteData data = await rootBundle.load('assets/tree/terre.png');
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
    _leafDead1Image?.dispose();
    _leafDead2Image?.dispose();
    _leafDead3Image?.dispose();
    _flowerImage?.dispose();
    _jasminImage?.dispose();
    _groundImage?.dispose();
    _windController.dispose();
    _treeNotifier.dispose();
    super.dispose();
  }

  /// Ajoute 1-2 feuilles aléatoirement sur des branches disponibles
  void addRandomLeaves() {
    if (_tree == null) {
      debugPrint('=== AJOUTER FEUILLES ===');
      debugPrint('Arbre non initialisé');
      return;
    }
    
      setState(() {
        final random = math.Random();
        
        // Récupérer toutes les branches (exclure le tronc)
      final branches = _tree!.getAllBranches();
      debugPrint('=== DEBUG BRANCHES ===');
      debugPrint('Total branches: ${branches.length}');
      debugPrint('Branches par profondeur:');
      for (int i = 0; i <= 6; i++) {
        final count = branches.where((b) => b.depth == i).length;
        if (count > 0) debugPrint('  Depth $i: $count branches');
      }
      
      final availableBranches = branches.where((branch) => branch.depth > 0).toList();
      
      if (availableBranches.isEmpty) {
        debugPrint('=== AJOUTER FEUILLES ===');
        debugPrint('Aucune branche disponible (tronc exclu)');
        debugPrint('L\'arbre est trop jeune, faites-le grandir d\'abord !');
        return;
      }
      
      // Filtrer les branches qui ont de l'espace
      final branchesWithSpace = availableBranches.where((branch) => branch.canAddLeaf()).toList();
      
      if (branchesWithSpace.isEmpty) {
        debugPrint('=== AJOUTER FEUILLES ===');
        debugPrint('Aucune branche disponible (toutes pleines)');
        return;
      }
      
      // Calculer le nombre de feuilles à ajouter proportionnellement à la taille de l'arbre
      // Basé sur l'âge de l'arbre : plus l'arbre est grand, plus on ajoute de feuilles
      final treeAge = _tree!.age;
      final totalBranches = branches.length;
      
      // Formule : nombre de feuilles = base (1-2) + bonus basé sur l'âge et le nombre de branches
      // Arbre jeune (0-5 jours) : 1-2 feuilles
      // Arbre moyen (5-15 jours) : 2-4 feuilles  
      // Arbre grand (15+ jours) : 4-8+ feuilles
      final baseCount = 1 + random.nextInt(2); // 1-2 feuilles de base
      final ageBonus = (treeAge / 3.0).floor(); // Bonus de 1 feuille tous les 3 jours
      final branchBonus = (totalBranches / 10.0).floor(); // Bonus de 1 feuille tous les 10 branches
      
      // Nombre total à ajouter (avec limite raisonnable)
      final numToAdd = (baseCount + ageBonus + branchBonus).clamp(1, 15);
      
      // Ne pas dépasser le nombre de branches disponibles
      final actualNumToAdd = math.min(numToAdd, branchesWithSpace.length);
      
      debugPrint('=== CALCUL FEUILLES ===');
      debugPrint('Âge arbre: $treeAge jours');
      debugPrint('Total branches: $totalBranches');
      debugPrint('Base: $baseCount, Age bonus: $ageBonus, Branch bonus: $branchBonus');
      debugPrint('Nombre de feuilles à ajouter: $actualNumToAdd');
      
      final selectedBranches = <tree_model.Branch>[];
      final availableCopy = List<tree_model.Branch>.from(branchesWithSpace);
      
      for (int i = 0; i < actualNumToAdd && availableCopy.isNotEmpty; i++) {
        final index = random.nextInt(availableCopy.length);
        selectedBranches.add(availableCopy[index]);
        availableCopy.removeAt(index);
      }
      
      // Ajouter une feuille sur chaque branche sélectionnée
      int addedCount = 0;
      for (final branch in selectedBranches) {
        // VÉRIFICATION DE SÉCURITÉ : Ne jamais ajouter de feuille sur le tronc
        if (branch.depth == 0) {
          debugPrint('⚠️ ATTENTION: Tentative d\'ajouter une feuille sur le tronc (depth=0) - REFUSÉ');
          continue;
        }
        
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
        
        // Calcul simplifié basé sur depth et age de la branche
        // Plus la branche est proche du tronc (depth petit) et plus elle est vieille (age grand), 
        // plus les feuilles peuvent être grandes
        
        // Facteur basé sur la profondeur : depth 1 = 1.0, depth 6 = 0.3
        final depthFactor = 1.0 - (branch.depth - 1) * 0.12; // Décroît de 0.12 par niveau
        final clampedDepthFactor = depthFactor.clamp(0.3, 1.0);
        
        // Variation aléatoire pour le naturel (stockée dans la feuille pour variation individuelle)
        final randomSizeFactor = 0.8 + random.nextDouble() * 0.4; // Entre 0.8 et 1.2
        
        // maxAge : dépend aussi de la profondeur et de l'âge
        final maxAge = 0.3 + (clampedDepthFactor * 0.3); // Entre 0.3 et 0.6
        
        // Vérifier distance avec les feuilles existantes
        bool tooClose = false;
        for (final existingLeaf in branch.leaves) {
          if ((leafPos - existingLeaf.position).distance < 10.0) {
            tooClose = true;
            break;
          }
        }
        
        if (!tooClose) {
          final leafId = '${branch.id}_${t.toStringAsFixed(3)}_$side';
          // Calculer l'âge initial pour que la feuille soit visible dès l'ajout
          // On veut currentGrowth = 0.2 (20% de la taille max) pour être bien visible
          final initialElapsed = 0.2; // 20% de croissance initiale
          final initialAge = initialElapsed * maxAge;
          
          final newLeaf = tree_model.Leaf(
            id: leafId,
            tOnBranch: t,
            side: side,
            age: initialAge,
            maxAge: maxAge,
            randomSizeFactor: randomSizeFactor,
            currentGrowth: initialElapsed, // Calculé correctement dès le départ
            state: tree_model.LeafState.alive,
            position: leafPos,
            branchPosition: branchPos,
          );
          
          branch.addLeaf(newLeaf);
          debugPrint('  Feuille ajoutée sur branche depth=${branch.depth}, id=${branch.id}');
          addedCount++;
        }
      }
      
      debugPrint('=== AJOUTER FEUILLES ===');
      debugPrint('Feuilles ajoutées: $addedCount');
      debugPrint('Total feuilles: ${_tree!.getAllLeaves().length}');
      
      // Forcer le rebuild
      _treeNotifier.value++;
    });
  }

  /// Ajoute une fleur aléatoirement sur une branche disponible
  void addRandomFlower() {
    if (_tree == null) {
      debugPrint('=== AJOUTER FLEUR ===');
      debugPrint('Arbre non initialisé');
      return;
    }
    
    setState(() {
      final random = math.Random();
      
      // Récupérer toutes les branches (exclure le tronc)
      final branches = _tree!.getAllBranches();
      final availableBranches = branches.where((branch) => branch.depth > 0).toList();
      
      if (availableBranches.isEmpty) {
        debugPrint('=== AJOUTER FLEUR ===');
        debugPrint('Aucune branche disponible (tronc exclu)');
        return;
      }
      
      // Sélectionner une branche avec probabilité pondérée par l'âge
      // Plus la branche est ancienne, plus elle a de chances d'être sélectionnée
      final weights = availableBranches.map((branch) {
        // Poids basé sur l'âge : 1 + age (minimum 1, augmente avec l'âge)
        // Les branches plus anciennes ont beaucoup plus de chances
        return 1.0 + (branch.age * 4.0); // Multiplier par 4 pour accentuer l'effet (doublé)
      }).toList();
      
      // Calculer la somme totale des poids
      final totalWeight = weights.fold(0.0, (sum, weight) => sum + weight);
      
      // Sélectionner une branche selon la distribution pondérée
      final randomValue = random.nextDouble() * totalWeight;
      double cumulativeWeight = 0.0;
      tree_model.Branch? selectedBranch;
      
      for (int i = 0; i < availableBranches.length; i++) {
        cumulativeWeight += weights[i];
        if (randomValue <= cumulativeWeight) {
          selectedBranch = availableBranches[i];
          break;
        }
      }
      
      // Fallback si aucune branche n'a été sélectionnée (ne devrait pas arriver)
      selectedBranch ??= availableBranches[random.nextInt(availableBranches.length)];
      
      // VÉRIFICATION DE SÉCURITÉ : Ne jamais ajouter de fleur sur le tronc
      if (selectedBranch.depth == 0) {
        debugPrint('⚠️ ATTENTION: Tentative d\'ajouter une fleur sur le tronc (depth=0) - REFUSÉ');
        return;
      }
      
      // Position aléatoire sur la branche
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
      
      // Calculer le facteur de taille basé sur la profondeur
      final sizeFactor = tree_model.Flower.calculateSizeFactor(selectedBranch);
      
      // Choisir aléatoirement le type de fleur (0 = flower.png, 1 = jasmin.png)
      final flowerType = random.nextInt(2);
      
      // Vérifier distance avec les fleurs existantes
      bool tooClose = false;
      for (final existingFlower in selectedBranch.flowers) {
        if ((flowerPos - existingFlower.position).distance < 15.0) {
          tooClose = true;
          break;
        }
      }
      
      if (!tooClose) {
        final flowerId = 'flower_${selectedBranch.id}_${t.toStringAsFixed(3)}_$side';
        
        final newFlower = tree_model.Flower(
          id: flowerId,
          tOnBranch: t,
          side: side,
          sizeFactor: sizeFactor,
          flowerType: flowerType,
          position: flowerPos,
          branchPosition: branchPos,
        );
        
        selectedBranch.addFlower(newFlower);
        debugPrint('=== AJOUTER FLEUR ===');
        debugPrint('Fleur ajoutée sur branche depth=${selectedBranch.depth}, id=${selectedBranch.id}');
        debugPrint('Total fleurs: ${_tree!.getAllFlowers().length}');
        
        // Forcer le rebuild
        _treeNotifier.value++;
      }
    });
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

  /// Incrémente l'âge de toutes les feuilles vivantes (fait grandir l'arbre d'un jour)
  void growLeaves() {
    if (_tree == null) return;
    
    setState(() {
      _tree!.growOneDay();
      
      debugPrint('=== FAIRE GRANDIR ===');
      debugPrint('Âge de l\'arbre: ${_tree!.age} jours');
      debugPrint('Total feuilles: ${_tree!.getAllLeaves().length}');
      
      // Forcer le rebuild
      _treeNotifier.value++;
    });
  }

  /// Avance le processus de mort des feuilles
  void advanceLeafDeath() {
    if (_tree == null) return;
    
    setState(() {
      final allLeaves = _tree!.getAllLeaves();
      
      // Sélectionner 1-2 feuilles vivantes aléatoires pour lancer le processus de mort
      // L'évolution (dead_1 → dead_2 → dead_3 → suppression) se fera automatiquement chaque jour
      final aliveLeaves = allLeaves
          .where((l) => l.currentGrowth > 0.0 && l.state == tree_model.LeafState.alive)
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
      
      debugPrint('=== TUER FEUILLE ===');
      debugPrint('Total feuilles: ${_tree!.getAllLeaves().length}');
      debugPrint('Feuilles visibles: ${allLeaves.where((l) => l.currentGrowth > 0.0).length}');
      debugPrint('Feuilles en train de mourir: ${allLeaves.where((l) => l.state != tree_model.LeafState.alive).length}');
      
      // Forcer le rebuild
      _treeNotifier.value++;
    });
  }

  @override
  void didUpdateWidget(ProceduralTreeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Régénérer l'arbre seulement si le growthLevel ou les paramètres changent
    if (oldWidget.growthLevel != widget.growthLevel ||
        oldWidget.size != widget.size ||
        oldWidget.parameters.seed != widget.parameters.seed) {
      
      // Sauvegarder les feuilles et fleurs existantes
      final existingLeaves = _tree?.getAllLeaves() ?? [];
      final existingFlowers = _tree?.getAllFlowers() ?? [];
      
      // Régénérer l'arbre avec la nouvelle structure
      _tree = TreePainter.generateTreeStructure(
        growthLevel: widget.growthLevel,
        treeSize: widget.size,
        parameters: widget.parameters,
        treeAge: _tree?.age ?? 0,
      );
      
      // Réappliquer les feuilles existantes sur les nouvelles branches
      if (existingLeaves.isNotEmpty) {
        _reapplyLeaves(existingLeaves);
      }
      
      // Réappliquer les fleurs existantes sur les nouvelles branches
      if (existingFlowers.isNotEmpty) {
        _reapplyFlowers(existingFlowers);
      }
    }
  }
  
  /// Réapplique les feuilles existantes sur les nouvelles branches de l'arbre
  void _reapplyLeaves(List<tree_model.Leaf> oldLeaves) {
    final newBranches = _tree!.getAllBranches();
    int skippedTrunk = 0;
    
    for (final oldLeaf in oldLeaves) {
      // L'ID de la feuille est formaté comme: '${branch.id}_${t}_$side'
      // Par exemple: '0_1_2_0.523_1' où '0_1_2' est l'ID de la branche
      // Il faut extraire l'ID de la branche (tout sauf les 2 derniers segments)
      final parts = oldLeaf.id.split('_');
      if (parts.length < 3) continue; // ID invalide
      
      // L'ID de la branche est tout sauf les 2 derniers segments (t et side)
      final branchId = parts.sublist(0, parts.length - 2).join('_');
      
      tree_model.Branch? matchingBranch;
      try {
        matchingBranch = newBranches.firstWhere((b) => b.id == branchId);
      } catch (e) {
        continue; // Branche non trouvée, skip cette feuille
      }
      
      // VÉRIFICATION DE SÉCURITÉ : Ne jamais réappliquer une feuille sur le tronc
      if (matchingBranch.depth == 0) {
        skippedTrunk++;
        debugPrint('⚠️ Feuille ignorée : était sur le tronc (depth=0)');
        continue;
      }
      
      // Créer une nouvelle feuille avec les mêmes propriétés
      final newLeaf = tree_model.Leaf(
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
      
      // Mettre à jour la position pour suivre la nouvelle branche
      newLeaf.updatePosition(matchingBranch, widget.size);
      
      // Ajouter la feuille à la nouvelle branche
      matchingBranch.addLeaf(newLeaf);
    }
    
    debugPrint('=== RÉAPPLICATION FEUILLES ===');
    debugPrint('Feuilles réappliquées: ${_tree!.getAllLeaves().length}');
    if (skippedTrunk > 0) {
      debugPrint('⚠️ Feuilles ignorées (sur le tronc): $skippedTrunk');
    }
  }

  /// Réapplique les fleurs existantes sur les nouvelles branches de l'arbre
  void _reapplyFlowers(List<tree_model.Flower> oldFlowers) {
    final newBranches = _tree!.getAllBranches();
    int skippedTrunk = 0;
    
    for (final oldFlower in oldFlowers) {
      // L'ID de la fleur est formaté comme: 'flower_${branch.id}_${t}_$side'
      // Par exemple: 'flower_0_1_2_0.523_1' où '0_1_2' est l'ID de la branche
      // Il faut extraire l'ID de la branche (enlever le préfixe "flower_" et les 2 derniers segments)
      final parts = oldFlower.id.split('_');
      if (parts.length < 4) continue; // ID invalide (doit avoir au moins "flower" + branchId + t + side)
      
      // Enlever le préfixe "flower" et les 2 derniers segments (t et side)
      // L'ID de la branche est tout sauf le premier segment ("flower") et les 2 derniers
      final branchId = parts.sublist(1, parts.length - 2).join('_');
      
      tree_model.Branch? matchingBranch;
      try {
        matchingBranch = newBranches.firstWhere((b) => b.id == branchId);
      } catch (e) {
        continue; // Branche non trouvée, skip cette fleur
      }
      
      // VÉRIFICATION DE SÉCURITÉ : Ne jamais réappliquer une fleur sur le tronc
      if (matchingBranch.depth == 0) {
        skippedTrunk++;
        debugPrint('⚠️ Fleur ignorée : était sur le tronc (depth=0)');
        continue;
      }
      
      // Recalculer le facteur de taille basé sur la nouvelle branche
      final sizeFactor = tree_model.Flower.calculateSizeFactor(matchingBranch);
      
      // Créer une nouvelle fleur avec les mêmes propriétés
      final newFlower = tree_model.Flower(
        id: oldFlower.id,
        tOnBranch: oldFlower.tOnBranch,
        side: oldFlower.side,
        sizeFactor: sizeFactor, // Recalculer pour la nouvelle branche
        flowerType: oldFlower.flowerType, // Conserver le type de fleur
        position: oldFlower.position,
        branchPosition: oldFlower.branchPosition,
      );
      
      // Mettre à jour la position pour suivre la nouvelle branche
      newFlower.updatePosition(matchingBranch, widget.size);
      
      // Ajouter la fleur à la nouvelle branche
      matchingBranch.addFlower(newFlower);
    }
    
    debugPrint('=== RÉAPPLICATION FLEURS ===');
    debugPrint('Fleurs réappliquées: ${_tree!.getAllFlowers().length}');
    if (skippedTrunk > 0) {
      debugPrint('⚠️ Fleurs ignorées (sur le tronc): $skippedTrunk');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_windAnimation, _treeNotifier]),
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: TreePainter(
              tree: _tree!,
              treeSize: widget.size,
              parameters: widget.parameters,
              leafImage: _leafImage,
              leafDead1Image: _leafDead1Image,
              leafDead2Image: _leafDead2Image,
              leafDead3Image: _leafDead3Image,
              flowerImage: _flowerImage,
              jasminImage: _jasminImage,
              groundImage: _groundImage,
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
  final ui.Image? groundImage;
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
    this.groundImage,
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
  
  /// Génère la structure Tree avec toutes ses branches de manière procédurale
  static tree_model.Tree generateTreeStructure({
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
      final trunk = tree_model.Branch(
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
      return tree_model.Tree(
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
    final trunk = tree_model.Branch(
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
    
    return tree_model.Tree(
      age: treeAge,
      trunk: trunk,
      treeSize: treeSize,
      parameters: parameters,
    );
  }
  
  /// Génère récursivement les branches enfants
  static void _generateBranchChildren(
    tree_model.Branch parent,
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
      final branch = tree_model.Branch(
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
      ..color = branchColor
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    // Vérifier si la branche a des enfants (branches qui commencent à son extrémité)
    final tolerance = treeSize * 0.01; // Tolérance relative à la taille de l'arbre
    final allBranches = tree.getAllBranches();
    final hasChildren = allBranches.any((b) => 
      b.depth == branch.depth + 1 && 
      (b.start - branch.end).distance < tolerance // Tolérance pour les erreurs d'arrondi
    );

    // Récupérer les positions déformées (calculées hiérarchiquement)
    final deformedStart = _deformedStarts[branch] ?? branch.start;
    final deformedEnd = _deformedEnds[branch] ?? branch.end;
    
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
        oldDelegate.leafImage != leafImage ||
        oldDelegate.flowerImage != flowerImage ||
        oldDelegate.jasminImage != jasminImage ||
        oldDelegate.groundImage != groundImage ||
        oldDelegate.windPhase != windPhase ||
        oldDelegate.parameters.seed != parameters.seed;
  }
}

