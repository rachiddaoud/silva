import 'package:flutter/widgets.dart';
import '../l10n/app_localizations.dart';
import '../l10n/app_localizations_en.dart';
import '../l10n/app_localizations_fr.dart';

String getVictoryText(BuildContext context, int victoryId) {
  final l10n = AppLocalizations.of(context)!;
  switch (victoryId) {
    case 0:
      return l10n.victoryWater;
    case 1:
      return l10n.victoryShower;
    case 2:
      return l10n.victoryHelp;
    case 3:
      return l10n.victoryMeal;
    case 4:
      return l10n.victoryBreathe;
    case 5:
      return l10n.victoryBaby;
    case 6:
      return l10n.victoryNo;
    case 7:
      return l10n.victorySmile;
    case 8:
      return l10n.victorySun;
    default:
      return '';
  }
}

String getEmotionName(BuildContext context, int index) {
  final l10n = AppLocalizations.of(context)!;
  switch (index) {
    case 0:
      return l10n.emotionExhausted;
    case 1:
      return l10n.emotionSad;
    case 2:
      return l10n.emotionAnxious;
    case 3:
      return l10n.emotionNeutral;
    case 4:
      return l10n.emotionCalm;
    case 5:
      return l10n.emotionHappy;
    default:
      return '';
  }
}

// Static helper for notifications (without BuildContext)
String getVictoryTextByLocale(String localeCode, int victoryId) {
  final AppLocalizations l10n;
  if (localeCode == 'en') {
    l10n = AppLocalizationsEn();
  } else {
    l10n = AppLocalizationsFr();
  }
  
  switch (victoryId) {
    case 0:
      return l10n.victoryWater;
    case 1:
      return l10n.victoryShower;
    case 2:
      return l10n.victoryHelp;
    case 3:
      return l10n.victoryMeal;
    case 4:
      return l10n.victoryBreathe;
    case 5:
      return l10n.victoryBaby;
    case 6:
      return l10n.victoryNo;
    case 7:
      return l10n.victorySmile;
    case 8:
      return l10n.victorySun;
    default:
      return '';
  }
}
