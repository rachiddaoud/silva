import 'package:flutter/widgets.dart';
import '../l10n/app_localizations.dart';
import '../l10n/app_localizations_en.dart';
import '../l10n/app_localizations_fr.dart';

String getVictoryText(BuildContext context, int victoryId) {
  final l10n = AppLocalizations.of(context)!;
  return _getVictoryTextFromL10n(l10n, victoryId);
}

String _getVictoryTextFromL10n(AppLocalizations l10n, int victoryId) {
  switch (victoryId) {
    // futureMaman (100-105)
    case 100:
      return l10n.victoryVitamins;
    case 101:
      return l10n.victoryWater2L;
    case 102:
      return l10n.victoryLegs;
    case 103:
      return l10n.victoryBelly;
    case 104:
      return l10n.victoryTalkBaby;
    case 105:
      return l10n.victoryWalk15;
    
    // nouvelleMaman (200-210)
    case 200:
      return l10n.victoryWater;
    case 201:
      return l10n.victoryShower;
    case 202:
      return l10n.victoryHelp;
    case 203:
      return l10n.victoryMeal;
    case 204:
      return l10n.victoryBreathe;
    case 205:
      return l10n.victoryBaby;
    case 206:
      return l10n.victoryNo;
    case 207:
      return l10n.victorySmile;
    case 208:
      return l10n.victorySun;
    case 209:
      return l10n.victoryBreastfeed;
    case 210:
      return l10n.victorySleepBaby;
    
    // sereniteQuotidienne (300-305)
    case 300:
      return l10n.victoryWater;
    case 301:
      return l10n.victoryScreens;
    case 302:
      return l10n.victoryRead;
    case 303:
      return l10n.victoryTidy;
    case 304:
      return l10n.victoryMeditate;
    case 305:
      return l10n.victoryCallFriend;
    
    // Legacy IDs (0-8) - for backwards compatibility
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
  
  return _getVictoryTextFromL10n(l10n, victoryId);
}

String _getVictoryReminderTextFromL10n(AppLocalizations l10n, int victoryId) {
  switch (victoryId) {
    // futureMaman (100-105)
    case 100:
      return l10n.victoryReminderVitamins;
    case 101:
      return l10n.victoryReminderWater2L;
    case 102:
      return l10n.victoryReminderLegs;
    case 103:
      return l10n.victoryReminderBelly;
    case 104:
      return l10n.victoryReminderTalkBaby;
    case 105:
      return l10n.victoryReminderWalk15;
    
    // nouvelleMaman (200-210)
    case 200:
      return l10n.victoryReminderWater;
    case 201:
      return l10n.victoryReminderShower;
    case 202:
      return l10n.victoryReminderHelp;
    case 203:
      return l10n.victoryReminderMeal;
    case 204:
      return l10n.victoryReminderBreathe;
    case 205:
      return l10n.victoryReminderBaby;
    case 206:
      return l10n.victoryReminderNo;
    case 207:
      return l10n.victoryReminderSmile;
    case 208:
      return l10n.victoryReminderSun;
    case 209:
      return l10n.victoryReminderBreastfeed;
    case 210:
      return l10n.victoryReminderSleepBaby;
    
    // sereniteQuotidienne (300-305)
    case 300:
      return l10n.victoryReminderWater;
    case 301:
      return l10n.victoryReminderScreens;
    case 302:
      return l10n.victoryReminderRead;
    case 303:
      return l10n.victoryReminderTidy;
    case 304:
      return l10n.victoryReminderMeditate;
    case 305:
      return l10n.victoryReminderCallFriend;
    
    // Legacy IDs (0-8) - for backwards compatibility
    case 0:
      return l10n.victoryReminderWater;
    case 1:
      return l10n.victoryReminderShower;
    case 2:
      return l10n.victoryReminderHelp;
    case 3:
      return l10n.victoryReminderMeal;
    case 4:
      return l10n.victoryReminderBreathe;
    case 5:
      return l10n.victoryReminderBaby;
    case 6:
      return l10n.victoryReminderNo;
    case 7:
      return l10n.victoryReminderSmile;
    case 8:
      return l10n.victoryReminderSun;
    
    default:
      return '';
  }
}

// Static helper for reminder notifications (without BuildContext)
// Returns the infinitive form of the victory text (e.g., "boire de l'eau" instead of "J'ai bu de l'eau")
String getVictoryReminderTextByLocale(String localeCode, int victoryId) {
  final AppLocalizations l10n;
  if (localeCode == 'en') {
    l10n = AppLocalizationsEn();
  } else {
    l10n = AppLocalizationsFr();
  }
  
  return _getVictoryReminderTextFromL10n(l10n, victoryId);
}
