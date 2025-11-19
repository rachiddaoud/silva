import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ma_bulle/widgets/procedural_tree_widget.dart';

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
  final double maxSize; // Taille maximale (variation aléatoire)
  double currentGrowth; // Niveau de croissance actuel (0.0 à 1.0)
  LeafState state; // État de la feuille
  Offset position; // Position calculée (mutable)
  Offset branchPosition; // Position sur la branche (mutable)

  Leaf({
    required this.id,
    required this.tOnBranch,
    required this.side,
    this.age = 0.0,
    required this.maxAge,
    required this.maxSize,
    this.currentGrowth = 0.1,
    this.state = LeafState.alive,
    required this.position,
    required this.branchPosition,
  });

  /// Fait grandir la feuille d'un jour
  void growOneDay() {
    if (age < maxAge) {
      age += 0.05; // Augmente l'âge
      // Recalculer currentGrowth avec une courbe d'easing cubic
      final elapsed = (age / maxAge).clamp(0.0, 1.0);
      final t = elapsed;
      currentGrowth = (1.0 - (1.0 - t) * (1.0 - t) * (1.0 - t)).clamp(0.0, 1.0);
    }
  }

  /// Fait avancer l'état de mort de la feuille
  void advanceDeathState() {
    switch (state) {
      case LeafState.alive:
        state = LeafState.dead1;
        break;
      case LeafState.dead1:
        state = LeafState.dead2;
        break;
      case LeafState.dead2:
        state = LeafState.dead3;
        break;
      case LeafState.dead3:
        // Reste en dead3, sera supprimée par la branche
        break;
    }
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
}

/// Classe représentant une branche de l'arbre
class Branch {
  final String id;
  final List<Branch> children = []; // Branches enfants
  final List<Leaf> leaves = []; // Feuilles attachées à cette branche
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

  /// Fait grandir la branche d'un jour (et propage aux enfants et feuilles)
  void growOneDay() {
    age++;

    // Faire grandir toutes les feuilles de cette branche
    for (final leaf in leaves) {
      leaf.growOneDay();
    }

    // Propager la croissance aux branches enfants
    for (final child in children) {
      child.growOneDay();
    }
  }

  /// Retourne la capacité maximale de feuilles pour cette branche
  int getCapacity() {
    return (length / 50.0).ceil();
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
  void growOneDay() {
    age++;
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

  /// Retourne le niveau de croissance actuel (0.0 à 1.0) basé sur l'âge
  double getGrowthLevel() {
    // Adapter selon les besoins: par exemple, 1 jour = 0.05 de croissance
    // jusqu'à atteindre 1.0 (arbre mature)
    return (age * 0.05).clamp(0.0, 1.0);
  }
}

