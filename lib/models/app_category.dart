import 'package:flutter/material.dart';

enum AppCategory {
  futureMaman,
  nouvelleMaman,
  sereniteQuotidienne;

  String get displayName {
    switch (this) {
      case AppCategory.futureMaman:
        return 'Futur Maman';
      case AppCategory.nouvelleMaman:
        return 'Nouvelle Maman';
      case AppCategory.sereniteQuotidienne:
        return 'Sérénité Quotidienne';
    }
  }

  String get description {
    switch (this) {
      case AppCategory.futureMaman:
        return 'Parcours de bien-être et de sérénité spécifiquement conçu pour accompagner les femmes enceintes tout au long de leur grossesse.';
      case AppCategory.nouvelleMaman:
        return 'Un soutien quotidien pour les nouvelles mamans, axé sur la récupération, le repos et la reconnaissance des petites victoires après l\'accouchement.';
      case AppCategory.sereniteQuotidienne:
        return 'Un guide pour cultiver le calme et l\'équilibre au jour le jour, adapté à toute personne cherchant à améliorer son bien-être général.';
    }
  }

  String get assetPath {
    switch (this) {
      case AppCategory.futureMaman:
        return 'assets/doodles/enceinte.png';
      case AppCategory.nouvelleMaman:
        return 'assets/doodles/maman.png';
      case AppCategory.sereniteQuotidienne:
        return 'assets/doodles/yoga.png';
    }
  }

  Color get color {
    switch (this) {
      case AppCategory.futureMaman:
        return const Color(0xFFFFF5E1); // Pale Yellow
      case AppCategory.nouvelleMaman:
        return const Color(0xFFE1F5FE); // Pale Blue
      case AppCategory.sereniteQuotidienne:
        return const Color(0xFFE8F5E9); // Pale Mint Green
    }
  }
}
