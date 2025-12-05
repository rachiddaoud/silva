// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Silva';

  @override
  String get victoriesTitle => 'Victories';

  @override
  String congratulationsMessage(int count, String pluralSuffix) {
    return 'Well done! You completed $count victor$pluralSuffix today.';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get chooseTheme => 'Choose a theme';

  @override
  String get colors => 'Colors';

  @override
  String get seasons => 'Seasons';

  @override
  String get dark => 'Dark';

  @override
  String get notifications => 'Notifications';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Disabled';

  @override
  String get testNotifications => 'Test Notifications';

  @override
  String get sendTest => 'Send a test';

  @override
  String get about => 'About';

  @override
  String get logout => 'Log out';

  @override
  String get logoutConfirmation => 'Do you really want to log out?';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get aboutDescription =>
      'An app to support you in your postpartum journey. Every little step counts.';

  @override
  String get victoryWater => 'I drank a big glass of water';

  @override
  String get victoryShower => 'I took a shower';

  @override
  String get victoryHelp => 'I asked for help';

  @override
  String get victoryMeal => 'I ate a hot meal';

  @override
  String get victoryBreathe => 'I breathed for 1 minute';

  @override
  String get victoryBaby => 'I put the baby down for 5 min';

  @override
  String get victoryNo => 'I said \"No\"';

  @override
  String get victorySmile => 'I smiled';

  @override
  String get victorySun => 'I saw the sun for 5 min';

  @override
  String get victoryReminderWater => 'drink a big glass of water';

  @override
  String get victoryReminderShower => 'take a shower';

  @override
  String get victoryReminderHelp => 'ask for help';

  @override
  String get victoryReminderMeal => 'eat a hot meal';

  @override
  String get victoryReminderBreathe => 'breathe for 1 minute';

  @override
  String get victoryReminderBaby => 'put the baby down for 5 min';

  @override
  String get victoryReminderNo => 'say \"No\"';

  @override
  String get victoryReminderSmile => 'smile';

  @override
  String get victoryReminderSun => 'see the sun for 5 min';

  @override
  String get victoryVitamins => 'I took my vitamins';

  @override
  String get victoryWater2L => 'I drank 2L of water';

  @override
  String get victoryLegs => 'I elevated my legs';

  @override
  String get victoryBelly => 'I moisturized my belly';

  @override
  String get victoryTalkBaby => 'I talked to the baby';

  @override
  String get victoryWalk15 => 'Short walk (15 min)';

  @override
  String get victoryBreastfeed => 'I breastfed/fed the baby peacefully';

  @override
  String get victorySleepBaby => 'I slept when the baby slept';

  @override
  String get victoryScreens => 'Screen break (1h)';

  @override
  String get victoryRead => 'I read 10 pages';

  @override
  String get victoryTidy => 'I tidied a room';

  @override
  String get victoryMeditate => 'I meditated';

  @override
  String get victoryCallFriend => 'I called a friend';

  @override
  String get victoryReminderVitamins => 'take your vitamins';

  @override
  String get victoryReminderWater2L => 'drink 2L of water';

  @override
  String get victoryReminderLegs => 'elevate your legs';

  @override
  String get victoryReminderBelly => 'moisturize your belly';

  @override
  String get victoryReminderTalkBaby => 'talk to the baby';

  @override
  String get victoryReminderWalk15 => 'take a short walk (15 min)';

  @override
  String get victoryReminderBreastfeed => 'breastfeed/feed the baby peacefully';

  @override
  String get victoryReminderSleepBaby => 'sleep when the baby sleeps';

  @override
  String get victoryReminderScreens => 'take a screen break (1h)';

  @override
  String get victoryReminderRead => 'read 10 pages';

  @override
  String get victoryReminderTidy => 'tidy a room';

  @override
  String get victoryReminderMeditate => 'meditate';

  @override
  String get victoryReminderCallFriend => 'call a friend';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get dayNotFilled => 'Day not filled';

  @override
  String get history => 'History';

  @override
  String loginError(String error) {
    return 'Login error: $error';
  }

  @override
  String get welcomeTitle => 'Welcome to\nSilva';

  @override
  String get welcomeSubtitle => 'Your space for serenity and well-being';

  @override
  String get continueWithGoogle => 'Start with Google';

  @override
  String finishDayTitle(String date) {
    return 'Finish $date';
  }

  @override
  String get howDoYouFeel => 'How do you feel today?';

  @override
  String get wordAboutDay => 'A word about your day?';

  @override
  String get share => 'Share';

  @override
  String get validate => 'Validate';

  @override
  String get everyStepCounts => 'Every little step counts 🌱';

  @override
  String get selectMoodError => 'Please select your mood';

  @override
  String get quitWithoutSaving => 'Quit without saving?';

  @override
  String get quitWithoutSavingMessage =>
      'You haven\'t saved your mood yet. Are you sure you want to quit?';

  @override
  String get quit => 'Quit';

  @override
  String shareTitle(String date) {
    return '🌟 My day on $date';
  }

  @override
  String shareVictories(int count, String plural) {
    return '$count victor$plural completed:';
  }

  @override
  String shareMood(String mood) {
    return '💭 How I feel: $mood';
  }

  @override
  String get emotionExhausted => 'Exhausted';

  @override
  String get emotionSad => 'Sad / Overwhelmed';

  @override
  String get emotionAnxious => 'Anxious';

  @override
  String get emotionNeutral => 'Meh / Neutral';

  @override
  String get emotionCalm => 'OK / Calm';

  @override
  String get emotionHappy => 'Proud / Happy';

  @override
  String get language => 'Language';

  @override
  String get systemDefault => 'System default';

  @override
  String get french => 'Français';

  @override
  String get english => 'English';

  @override
  String get notifFinishDay => 'Finish your day';

  @override
  String notifFinishDayBody(String name) {
    return '$name, don\'t forget to finish your day and note your mood!';
  }

  @override
  String get notifFinishNow => 'Finish now';

  @override
  String notifGoodMorning(String name) {
    return 'Good morning $name!';
  }

  @override
  String notifQuoteOfDay(String quote) {
    return 'Your quote of the day: $quote';
  }

  @override
  String get notifReminder => 'Little reminder 💚';

  @override
  String notifReminderBody(String name, String victory) {
    return '$name, don\'t forget to $victory';
  }

  @override
  String get notifActionDone => 'I did this action';

  @override
  String treeRegenerated(int days) {
    return 'Tree regenerated from $days days of history.';
  }

  @override
  String get treeInfo1 => '• Each day filled makes the tree grow 🌱';

  @override
  String get treeInfo2 => '• Positive days make the tree bloom 🌸';

  @override
  String get treeInfo3 => '• Difficult days can cause dead leaves 🍂';

  @override
  String treeAge(int age) {
    return 'Age: $age days';
  }

  @override
  String treeBranches(int count) {
    return 'Branches: $count';
  }

  @override
  String treeLeaves(int count) {
    return 'Leaves: $count';
  }

  @override
  String treeFlowers(int count) {
    return 'Flowers: $count';
  }

  @override
  String get treeInfoTitle => 'My Tree';

  @override
  String get treeInfoSubtitle => 'Growth Information';

  @override
  String get treeInfoDescription =>
      'This tree represents your personal growth. Every day you complete, every victory you accomplish, and every emotion you express contributes to making your unique tree grow.';

  @override
  String get treeInfoHowItWorks => 'How it works';

  @override
  String get treeInfoLeavesTitle => 'Leaves';

  @override
  String get treeInfoLeavesDescription =>
      'Earn leaves by completing your daily victories. Use them to decorate your tree!';

  @override
  String get treeInfoFlowersTitle => 'Flowers';

  @override
  String get treeInfoFlowersDescription =>
      'Add a flower per day to beautify your tree. Flowers are earned through your daily streak!';

  @override
  String get treeInfoSpecialFlowersTitle => 'Special unique flowers';

  @override
  String get treeInfoSpecialFlowersDescription =>
      'Maintain your streak to unlock rare and unique flowers! Special flowers appear at 3 days, 7 days (1 week), and 30 days of consecutive streak. Every milestone of your journey deserves to be celebrated!';

  @override
  String get treeInfoStats => 'Statistics';

  @override
  String treeInfoStreak(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return 'Streak: $days $_temp0';
  }

  @override
  String get treeInfoTip => 'Consistency is the key to growth!';

  @override
  String get sendFeedback => 'Send Feedback';

  @override
  String get sendFeedbackSubtitle => 'Share your ideas and suggestions';

  @override
  String get feedbackEmailSubject => 'Silva Feedback';

  @override
  String get feedbackEmailError => 'Unable to open email client';

  @override
  String get thoughtOfTheDay => 'THOUGHT OF THE DAY';

  @override
  String get victoryAlreadyCompleted =>
      'This victory is already completed. You can delete it from the History tab by swiping left or right.';

  @override
  String get statistics => 'Statistics';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get victoriesChart => 'Daily Victories';

  @override
  String get moodTrend => 'Mood Trend';

  @override
  String get noDataYet => 'No data yet';

  @override
  String get startAddingVictories =>
      'Start adding victories to see your progress';

  @override
  String streakDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return 'Streak: $days $_temp0';
  }

  @override
  String wateredStreakFlower(int streak) {
    String _temp0 = intl.Intl.pluralLogic(
      streak,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return 'Streak updated! Streak: $streak $_temp0. +1 Flower!';
  }

  @override
  String get alreadyAddedFlowerToday =>
      'Already added a flower today! Come back tomorrow.';

  @override
  String get noLeavesAvailable =>
      'No leaves available. Complete victories to earn leaves!';

  @override
  String alreadyFlowerAvailableIn(int hours, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'hours',
      one: 'hour',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'minutes',
      one: 'minute',
    );
    return 'Already added a flower today! Available again in $hours $_temp0 and $minutes $_temp1';
  }

  @override
  String alreadyFlowerAvailableInMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'minutes',
      one: 'minute',
    );
    return 'Already added a flower today! Available again in $minutes $_temp0';
  }

  @override
  String get leafButton => 'Leaf';

  @override
  String get flowerButton => 'Flower';

  @override
  String get waterDone => 'Done';

  @override
  String get resetTreeTitle => 'Reset Tree';

  @override
  String get resetTreeConfirm =>
      'Reset tree to age 10 with no leaves or flowers?';

  @override
  String get reset => 'Reset';

  @override
  String get resetTooltip => 'Reset';

  @override
  String get treeInfoTooltip => 'Tree Info';

  @override
  String get appleSignInComingSoon => 'Apple Sign-In coming soon!';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get termsOfService =>
      'By continuing, you agree to our Terms of Service';

  @override
  String get testNotificationsSent => 'Test notifications sent!';

  @override
  String get soundEffects => 'Sound Effects';

  @override
  String get hapticFeedback => 'Haptic Feedback';

  @override
  String get enabled => 'Enabled';

  @override
  String get specialFlowerUnlocked => 'You\'ve unlocked a special flower! 🌸';

  @override
  String get category => 'Category';

  @override
  String get selectCategory => 'Select a category';

  @override
  String get categoryChanged => 'Category updated';

  @override
  String get categoryChangedMessage =>
      'Today\'s victories have been updated according to your new category.';
}
