import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'Silva'**
  String get appTitle;

  /// No description provided for @victoriesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Victoires'**
  String get victoriesTitle;

  /// No description provided for @congratulationsMessage.
  ///
  /// In fr, this message translates to:
  /// **'Bravo ! Vous avez terminé {count} victoire{pluralSuffix} aujourd\'hui.'**
  String congratulationsMessage(int count, String pluralSuffix);

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settingsTitle;

  /// No description provided for @chooseTheme.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un thème'**
  String get chooseTheme;

  /// No description provided for @colors.
  ///
  /// In fr, this message translates to:
  /// **'Couleurs'**
  String get colors;

  /// No description provided for @seasons.
  ///
  /// In fr, this message translates to:
  /// **'Saisons'**
  String get seasons;

  /// No description provided for @dark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get dark;

  /// No description provided for @notifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @active.
  ///
  /// In fr, this message translates to:
  /// **'Actives'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In fr, this message translates to:
  /// **'Désactivées'**
  String get inactive;

  /// No description provided for @testNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Test Notifications'**
  String get testNotifications;

  /// No description provided for @sendTest.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer un test'**
  String get sendTest;

  /// No description provided for @about.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get about;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get logout;

  /// No description provided for @logoutConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment vous déconnecter ?'**
  String get logoutConfirmation;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @aboutDescription.
  ///
  /// In fr, this message translates to:
  /// **'Une application pour vous accompagner dans votre parcours post-partum. Chaque petit pas compte.'**
  String get aboutDescription;

  /// No description provided for @victoryWater.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai bu un grand verre d\'eau'**
  String get victoryWater;

  /// No description provided for @victoryShower.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai pris ma douche'**
  String get victoryShower;

  /// No description provided for @victoryHelp.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai demandé de l\'aide'**
  String get victoryHelp;

  /// No description provided for @victoryMeal.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai mangé un repas chaud'**
  String get victoryMeal;

  /// No description provided for @victoryBreathe.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai respiré 1 minute'**
  String get victoryBreathe;

  /// No description provided for @victoryBaby.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai posé le bébé 5 min'**
  String get victoryBaby;

  /// No description provided for @victoryNo.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai dit \"Non\"'**
  String get victoryNo;

  /// No description provided for @victorySmile.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai souri'**
  String get victorySmile;

  /// No description provided for @victorySun.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai vu le soleil 5 min'**
  String get victorySun;

  /// No description provided for @victoryReminderWater.
  ///
  /// In fr, this message translates to:
  /// **'boire un grand verre d\'eau'**
  String get victoryReminderWater;

  /// No description provided for @victoryReminderShower.
  ///
  /// In fr, this message translates to:
  /// **'prendre votre douche'**
  String get victoryReminderShower;

  /// No description provided for @victoryReminderHelp.
  ///
  /// In fr, this message translates to:
  /// **'demander de l\'aide'**
  String get victoryReminderHelp;

  /// No description provided for @victoryReminderMeal.
  ///
  /// In fr, this message translates to:
  /// **'manger un repas chaud'**
  String get victoryReminderMeal;

  /// No description provided for @victoryReminderBreathe.
  ///
  /// In fr, this message translates to:
  /// **'respirer 1 minute'**
  String get victoryReminderBreathe;

  /// No description provided for @victoryReminderBaby.
  ///
  /// In fr, this message translates to:
  /// **'poser le bébé 5 min'**
  String get victoryReminderBaby;

  /// No description provided for @victoryReminderNo.
  ///
  /// In fr, this message translates to:
  /// **'dire \"Non\"'**
  String get victoryReminderNo;

  /// No description provided for @victoryReminderSmile.
  ///
  /// In fr, this message translates to:
  /// **'sourire'**
  String get victoryReminderSmile;

  /// No description provided for @victoryReminderSun.
  ///
  /// In fr, this message translates to:
  /// **'voir le soleil 5 min'**
  String get victoryReminderSun;

  /// No description provided for @today.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get yesterday;

  /// No description provided for @dayNotFilled.
  ///
  /// In fr, this message translates to:
  /// **'Jour non rempli'**
  String get dayNotFilled;

  /// No description provided for @history.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get history;

  /// No description provided for @loginError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de connexion: {error}'**
  String loginError(String error);

  /// No description provided for @welcomeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur\nSilva'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre espace de sérénité'**
  String get welcomeSubtitle;

  /// No description provided for @continueWithGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Commencer avec Google'**
  String get continueWithGoogle;

  /// No description provided for @finishDayTitle.
  ///
  /// In fr, this message translates to:
  /// **'Terminer {date}'**
  String finishDayTitle(String date);

  /// No description provided for @howDoYouFeel.
  ///
  /// In fr, this message translates to:
  /// **'Comment vous sentez-vous aujourd\'hui ?'**
  String get howDoYouFeel;

  /// No description provided for @wordAboutDay.
  ///
  /// In fr, this message translates to:
  /// **'Un mot sur votre journée ?'**
  String get wordAboutDay;

  /// No description provided for @share.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get share;

  /// No description provided for @validate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get validate;

  /// No description provided for @everyStepCounts.
  ///
  /// In fr, this message translates to:
  /// **'Chaque petit pas compte 🌱'**
  String get everyStepCounts;

  /// No description provided for @selectMoodError.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner votre humeur'**
  String get selectMoodError;

  /// No description provided for @quitWithoutSaving.
  ///
  /// In fr, this message translates to:
  /// **'Quitter sans enregistrer ?'**
  String get quitWithoutSaving;

  /// No description provided for @quitWithoutSavingMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez pas encore enregistré votre humeur. Êtes-vous sûr de vouloir quitter ?'**
  String get quitWithoutSavingMessage;

  /// No description provided for @quit.
  ///
  /// In fr, this message translates to:
  /// **'Quitter'**
  String get quit;

  /// No description provided for @shareTitle.
  ///
  /// In fr, this message translates to:
  /// **'🌟 Ma journée du {date}'**
  String shareTitle(String date);

  /// No description provided for @shareVictories.
  ///
  /// In fr, this message translates to:
  /// **'{count} victoire{plural} accomplie{plural} :'**
  String shareVictories(int count, String plural);

  /// No description provided for @shareMood.
  ///
  /// In fr, this message translates to:
  /// **'💭 Comment je me sens : {mood}'**
  String shareMood(String mood);

  /// No description provided for @emotionExhausted.
  ///
  /// In fr, this message translates to:
  /// **'Épuisée'**
  String get emotionExhausted;

  /// No description provided for @emotionSad.
  ///
  /// In fr, this message translates to:
  /// **'Triste / Débordée'**
  String get emotionSad;

  /// No description provided for @emotionAnxious.
  ///
  /// In fr, this message translates to:
  /// **'Anxieuse'**
  String get emotionAnxious;

  /// No description provided for @emotionNeutral.
  ///
  /// In fr, this message translates to:
  /// **'Bof / Neutre'**
  String get emotionNeutral;

  /// No description provided for @emotionCalm.
  ///
  /// In fr, this message translates to:
  /// **'OK / Calme'**
  String get emotionCalm;

  /// No description provided for @emotionHappy.
  ///
  /// In fr, this message translates to:
  /// **'Fière / Joyeuse'**
  String get emotionHappy;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @systemDefault.
  ///
  /// In fr, this message translates to:
  /// **'Système par défaut'**
  String get systemDefault;

  /// No description provided for @french.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @english.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @notifFinishDay.
  ///
  /// In fr, this message translates to:
  /// **'Terminer votre journée'**
  String get notifFinishDay;

  /// No description provided for @notifFinishDayBody.
  ///
  /// In fr, this message translates to:
  /// **'{name}, n\'oubliez pas de terminer votre journée et de noter votre humeur !'**
  String notifFinishDayBody(String name);

  /// No description provided for @notifFinishNow.
  ///
  /// In fr, this message translates to:
  /// **'Terminer maintenant'**
  String get notifFinishNow;

  /// No description provided for @notifGoodMorning.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour {name} !'**
  String notifGoodMorning(String name);

  /// No description provided for @notifQuoteOfDay.
  ///
  /// In fr, this message translates to:
  /// **'Votre citation du jour : {quote}'**
  String notifQuoteOfDay(String quote);

  /// No description provided for @notifReminder.
  ///
  /// In fr, this message translates to:
  /// **'Petit rappel 💚'**
  String get notifReminder;

  /// No description provided for @notifReminderBody.
  ///
  /// In fr, this message translates to:
  /// **'{name}, n\'oubliez pas de {victory}'**
  String notifReminderBody(String name, String victory);

  /// No description provided for @notifActionDone.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai fait cette action'**
  String get notifActionDone;

  /// No description provided for @treeRegenerated.
  ///
  /// In fr, this message translates to:
  /// **'Arbre régénéré à partir de {days} jours d\'historique.'**
  String treeRegenerated(int days);

  /// No description provided for @treeInfo1.
  ///
  /// In fr, this message translates to:
  /// **'• Chaque jour rempli fait pousser l\'arbre 🌱'**
  String get treeInfo1;

  /// No description provided for @treeInfo2.
  ///
  /// In fr, this message translates to:
  /// **'• Les jours positifs font fleurir l\'arbre 🌸'**
  String get treeInfo2;

  /// No description provided for @treeInfo3.
  ///
  /// In fr, this message translates to:
  /// **'• Les jours difficiles peuvent causer des feuilles mortes 🍂'**
  String get treeInfo3;

  /// No description provided for @treeAge.
  ///
  /// In fr, this message translates to:
  /// **'Âge: {age} jours'**
  String treeAge(int age);

  /// No description provided for @treeBranches.
  ///
  /// In fr, this message translates to:
  /// **'Branches: {count}'**
  String treeBranches(int count);

  /// No description provided for @treeLeaves.
  ///
  /// In fr, this message translates to:
  /// **'Feuilles: {count}'**
  String treeLeaves(int count);

  /// No description provided for @treeFlowers.
  ///
  /// In fr, this message translates to:
  /// **'Fleurs: {count}'**
  String treeFlowers(int count);

  /// No description provided for @sendFeedback.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer un feedback'**
  String get sendFeedback;

  /// No description provided for @sendFeedbackSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Partagez vos idées et suggestions'**
  String get sendFeedbackSubtitle;

  /// No description provided for @feedbackEmailSubject.
  ///
  /// In fr, this message translates to:
  /// **'Feedback Silva'**
  String get feedbackEmailSubject;

  /// No description provided for @feedbackEmailError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir le client email'**
  String get feedbackEmailError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
