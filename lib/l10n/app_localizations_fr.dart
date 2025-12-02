// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Silva';

  @override
  String get victoriesTitle => 'Victoires';

  @override
  String congratulationsMessage(int count, String pluralSuffix) {
    return 'Bravo ! Vous avez terminé $count victoire$pluralSuffix aujourd\'hui.';
  }

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get chooseTheme => 'Choisir un thème';

  @override
  String get colors => 'Couleurs';

  @override
  String get seasons => 'Saisons';

  @override
  String get dark => 'Sombre';

  @override
  String get notifications => 'Notifications';

  @override
  String get active => 'Actives';

  @override
  String get inactive => 'Désactivées';

  @override
  String get testNotifications => 'Test Notifications';

  @override
  String get sendTest => 'Envoyer un test';

  @override
  String get about => 'À propos';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get logoutConfirmation => 'Voulez-vous vraiment vous déconnecter ?';

  @override
  String get cancel => 'Annuler';

  @override
  String get close => 'Fermer';

  @override
  String get aboutDescription =>
      'Une application pour vous accompagner dans votre parcours post-partum. Chaque petit pas compte.';

  @override
  String get victoryWater => 'J\'ai bu un grand verre d\'eau';

  @override
  String get victoryShower => 'J\'ai pris ma douche';

  @override
  String get victoryHelp => 'J\'ai demandé de l\'aide';

  @override
  String get victoryMeal => 'J\'ai mangé un repas chaud';

  @override
  String get victoryBreathe => 'J\'ai respiré 1 minute';

  @override
  String get victoryBaby => 'J\'ai posé le bébé 5 min';

  @override
  String get victoryNo => 'J\'ai dit \"Non\"';

  @override
  String get victorySmile => 'J\'ai souri';

  @override
  String get victorySun => 'J\'ai vu le soleil 5 min';

  @override
  String get victoryReminderWater => 'boire un grand verre d\'eau';

  @override
  String get victoryReminderShower => 'prendre votre douche';

  @override
  String get victoryReminderHelp => 'demander de l\'aide';

  @override
  String get victoryReminderMeal => 'manger un repas chaud';

  @override
  String get victoryReminderBreathe => 'respirer 1 minute';

  @override
  String get victoryReminderBaby => 'poser le bébé 5 min';

  @override
  String get victoryReminderNo => 'dire \"Non\"';

  @override
  String get victoryReminderSmile => 'sourire';

  @override
  String get victoryReminderSun => 'voir le soleil 5 min';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String get dayNotFilled => 'Jour non rempli';

  @override
  String get history => 'Historique';

  @override
  String loginError(String error) {
    return 'Erreur de connexion: $error';
  }

  @override
  String get welcomeTitle => 'Bienvenue sur\nSilva';

  @override
  String get welcomeSubtitle => 'Votre espace de sérénité';

  @override
  String get continueWithGoogle => 'Commencer avec Google';

  @override
  String finishDayTitle(String date) {
    return 'Terminer $date';
  }

  @override
  String get howDoYouFeel => 'Comment vous sentez-vous aujourd\'hui ?';

  @override
  String get wordAboutDay => 'Un mot sur votre journée ?';

  @override
  String get share => 'Partager';

  @override
  String get validate => 'Valider';

  @override
  String get everyStepCounts => 'Chaque petit pas compte 🌱';

  @override
  String get selectMoodError => 'Veuillez sélectionner votre humeur';

  @override
  String get quitWithoutSaving => 'Quitter sans enregistrer ?';

  @override
  String get quitWithoutSavingMessage =>
      'Vous n\'avez pas encore enregistré votre humeur. Êtes-vous sûr de vouloir quitter ?';

  @override
  String get quit => 'Quitter';

  @override
  String shareTitle(String date) {
    return '🌟 Ma journée du $date';
  }

  @override
  String shareVictories(int count, String plural) {
    return '$count victoire$plural accomplie$plural :';
  }

  @override
  String shareMood(String mood) {
    return '💭 Comment je me sens : $mood';
  }

  @override
  String get emotionExhausted => 'Épuisée';

  @override
  String get emotionSad => 'Triste / Débordée';

  @override
  String get emotionAnxious => 'Anxieuse';

  @override
  String get emotionNeutral => 'Bof / Neutre';

  @override
  String get emotionCalm => 'OK / Calme';

  @override
  String get emotionHappy => 'Fière / Joyeuse';

  @override
  String get language => 'Langue';

  @override
  String get systemDefault => 'Système par défaut';

  @override
  String get french => 'Français';

  @override
  String get english => 'English';

  @override
  String get notifFinishDay => 'Terminer votre journée';

  @override
  String notifFinishDayBody(String name) {
    return '$name, n\'oubliez pas de terminer votre journée et de noter votre humeur !';
  }

  @override
  String get notifFinishNow => 'Terminer maintenant';

  @override
  String notifGoodMorning(String name) {
    return 'Bonjour $name !';
  }

  @override
  String notifQuoteOfDay(String quote) {
    return 'Votre citation du jour : $quote';
  }

  @override
  String get notifReminder => 'Petit rappel 💚';

  @override
  String notifReminderBody(String name, String victory) {
    return '$name, n\'oubliez pas de $victory';
  }

  @override
  String get notifActionDone => 'J\'ai fait cette action';

  @override
  String treeRegenerated(int days) {
    return 'Arbre régénéré à partir de $days jours d\'historique.';
  }

  @override
  String get treeInfo1 => '• Chaque jour rempli fait pousser l\'arbre 🌱';

  @override
  String get treeInfo2 => '• Les jours positifs font fleurir l\'arbre 🌸';

  @override
  String get treeInfo3 =>
      '• Les jours difficiles peuvent causer des feuilles mortes 🍂';

  @override
  String treeAge(int age) {
    return 'Âge: $age jours';
  }

  @override
  String treeBranches(int count) {
    return 'Branches: $count';
  }

  @override
  String treeLeaves(int count) {
    return 'Feuilles: $count';
  }

  @override
  String treeFlowers(int count) {
    return 'Fleurs: $count';
  }

  @override
  String get treeInfoTitle => 'Mon Arbre';

  @override
  String get treeInfoSubtitle => 'Informations de croissance';

  @override
  String get treeInfoDescription =>
      'Cet arbre représente votre croissance personnelle. Chaque jour que vous complétez, chaque victoire que vous accomplissez, et chaque émotion que vous exprimez contribuent à faire grandir votre arbre unique.';

  @override
  String get treeInfoHowItWorks => 'Comment ça fonctionne';

  @override
  String get treeInfoWateringTitle => 'Arrosage';

  @override
  String get treeInfoWateringDescription =>
      'Arrosez votre arbre une fois par jour après avoir complété 3 victoires. Cela fait grandir votre arbre et maintient votre streak !';

  @override
  String get treeInfoLeavesTitle => 'Feuilles';

  @override
  String get treeInfoLeavesDescription =>
      'Gagnez des feuilles en complétant vos victoires quotidiennes. Utilisez-les pour décorer votre arbre !';

  @override
  String get treeInfoFlowersTitle => 'Fleurs';

  @override
  String get treeInfoFlowersDescription =>
      'Ajoutez une fleur par jour pour embellir votre arbre. Les fleurs sont gagnées grâce à votre streak quotidien !';

  @override
  String get treeInfoSpecialFlowersTitle => 'Fleurs uniques spéciales';

  @override
  String get treeInfoSpecialFlowersDescription =>
      'Maintenez votre streak pour débloquer des fleurs rares et uniques ! Des fleurs spéciales apparaissent à 3 jours, 7 jours (1 semaine) et 30 jours de streak consécutifs. Chaque étape de votre parcours mérite d\'être célébrée !';

  @override
  String get treeInfoStats => 'Statistiques';

  @override
  String treeInfoStreak(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'jours',
      one: 'jour',
    );
    return 'Streak: $days $_temp0';
  }

  @override
  String get treeInfoTip => 'La régularité est la clé de la croissance !';

  @override
  String get sendFeedback => 'Envoyer un feedback';

  @override
  String get sendFeedbackSubtitle => 'Partagez vos idées et suggestions';

  @override
  String get feedbackEmailSubject => 'Feedback Silva';

  @override
  String get feedbackEmailError => 'Impossible d\'ouvrir le client email';
}
