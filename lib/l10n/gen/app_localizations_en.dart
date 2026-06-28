// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Jaune';

  @override
  String bejauneScoreMessage(int percent) {
    return 'Lemon score: $percent%';
  }

  @override
  String get notifAperoTitle => '🍋 Happy hour with Jaune!';

  @override
  String get notifAperoBody =>
      'Time to capture your happy-hour moment. Show us your glass!';

  @override
  String get postBejaune => 'Post a JAUNE';

  @override
  String get alreadyPostedToday => '✓ Already posted today';

  @override
  String get availableAtApero => '🔒 Available at happy hour';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get calendarSee => 'View';

  @override
  String get calendarClose => 'Close';

  @override
  String get calendarToday => 'Today';

  @override
  String get calendarMonthEmpty => 'Nothing logged this month';

  @override
  String get calendarLegendSober => 'Sober';

  @override
  String get calendarLegendModerate => 'Moderate';

  @override
  String get calendarLegendRising => 'Heating up';

  @override
  String get calendarLegendHeavy => 'Big night';

  @override
  String get dayDetailSober => 'Sober day';

  @override
  String dayDetailModerate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count drinks · moderate',
      one: '1 drink · moderate',
    );
    return '$_temp0';
  }

  @override
  String dayDetailRising(int count) {
    return '$count drinks · heating up';
  }

  @override
  String dayDetailHeavy(int count) {
    return '$count drinks · big night';
  }

  @override
  String xpToastAmount(int amount) {
    return '+$amount XP';
  }

  @override
  String get xpReasonAppOpen => 'Opened the app';

  @override
  String get xpReasonDailyLog => 'Logged today';

  @override
  String get xpReasonSoberYesterday => 'Sober yesterday';

  @override
  String get xpReasonGreenDay => 'Green day';

  @override
  String get xpReasonPerfectWeek => 'Perfect week';

  @override
  String get xpReasonQuestComplete => 'Quest complete';

  @override
  String get xpReasonWeeklyGoal => 'This week\'s goal';

  @override
  String get dailyQuestsTitle => '🎯 Daily quests';

  @override
  String get questOpenAppTitle => 'Say hi to your lemon';

  @override
  String get questLogTodayTitle => 'Log your day';

  @override
  String get questSoberTodayTitle => 'An alcohol-free day';

  @override
  String get questUnderTwoTitle => 'Stay under 2 drinks';

  @override
  String get questKeepStreakTitle => 'Keep your streak alive';

  @override
  String get weeklyGoalTitle => 'This week\'s goal';

  @override
  String weeklyGoalProgress(int sober, int target) {
    return '$sober / $target sober days';
  }

  @override
  String get levelStatStreak => 'streak';

  @override
  String get levelStatShields => 'shields';

  @override
  String get levelStatBadges => 'badges';

  @override
  String get levelStatSkins => 'outfits';

  @override
  String get streakShieldProtected => '🛡️ Streak protected';

  @override
  String streakShieldsAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shields',
      one: '1 shield',
      zero: 'No shields',
    );
    return '$_temp0';
  }

  @override
  String soberStreakInARow(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days sober days in a row',
      one: '1 sober day in a row',
    );
    return '$_temp0';
  }

  @override
  String get rankApprentice => 'Apprentice 🌱';

  @override
  String get rankExplorer => 'Explorer 🗺️';

  @override
  String get rankMaster => 'Master 🏆';

  @override
  String get rankLegend => 'Legend ⭐';

  @override
  String get phaseDiscovery => '🌱 Discovery';

  @override
  String get phaseEngagement => '⚡ Engagement';

  @override
  String get phaseMastery => '🏆 Mastery';

  @override
  String get levelRingLabel => 'LEVEL';

  @override
  String xpProgress(int xp, int xpToNext) {
    return '⚡ $xp / $xpToNext XP';
  }

  @override
  String get streakKeepGoing => 'Keep going, your lemon is glowing!';

  @override
  String get unlockedAtThisLevel => '✨ Unlocked at this level';

  @override
  String get nextChallenge => '🎯 Next challenge';

  @override
  String levelWithDescription(int level, String description) {
    return 'Level $level · $description';
  }

  @override
  String xpReward(int xp) {
    return '+$xp XP';
  }

  @override
  String get andThen => 'And then…';

  @override
  String get levelScreenTitle => 'Progress';

  @override
  String get newWorldBanner => '✦ NEW WORLD ✦';

  @override
  String get weeklyGoalReached => 'Goal reached! 🛡️ +1 shield';

  @override
  String get levelJourneyTitle => '🗺️ Your journey';

  @override
  String get levelYouAreHere => 'You are here';

  @override
  String chapterTitle(int n) {
    return 'Chapter $n';
  }

  @override
  String levelLockedShort(int level) {
    return 'Lvl $level';
  }

  @override
  String levelUpTitle(int level) {
    return 'LEVEL $level';
  }

  @override
  String get unlockedBanner => '✨ UNLOCKED ✨';

  @override
  String get continueLabel => 'Continue';

  @override
  String get infoTitle => 'How does it work?';

  @override
  String get infoStep1Title => 'Log your drinks';

  @override
  String get infoStep1Text =>
      'Each time you drink, tap the \"🍻\" button. 1 standard drink = 1 tap (e.g. a pint = 2 taps).';

  @override
  String get infoStep2Title => 'Your lemon lives with you';

  @override
  String get infoStep2Text =>
      'Your lemon has health points that rise or fall with your drinking. Take good care of it!';

  @override
  String get infoStep3Title => 'Earn XP';

  @override
  String get infoStep3Text =>
      'Sober days, balanced weeks and consistency level you up and unlock surprises.';

  @override
  String get resetDayTitle => 'Reset today?';

  @override
  String get resetDayMessage =>
      'This will reset today\'s drinks to zero. Are you sure?';

  @override
  String get cancel => 'Cancel';

  @override
  String get resetAction => 'Reset';

  @override
  String dayUnit(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$_temp0';
  }

  @override
  String daysCount(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get captureBackTooltip => 'Back';

  @override
  String get backToCamera => 'Back to camera';

  @override
  String get previewCaption => '📱 Final composition preview';

  @override
  String get debugModeOn => '🐛 Debug mode on';

  @override
  String get debugModeOff => '📸 Normal mode';

  @override
  String get cameraUnavailable => 'Camera unavailable or access denied.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get openSettings => 'Open settings';

  @override
  String get previewUnavailable => 'Preview unavailable';

  @override
  String get retry => 'Retry';

  @override
  String get sayJaune => 'Say JAUNEEE...';

  @override
  String get photoLabel => 'PHOTO';

  @override
  String levelChip(int level) {
    return 'Lvl $level';
  }

  @override
  String get hpLabel => 'HP';

  @override
  String get sharedFromJaune => 'Shared from Jaune!';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsUsername => 'My nickname';

  @override
  String get settingsUsernameSubtitle => 'Visible in the friends leaderboard';

  @override
  String get settingsUsernameEmpty => 'Not set';

  @override
  String get settingsNotifications => 'Reminders';

  @override
  String get settingsNotificationsSubtitle => 'Daily happy-hour notification';

  @override
  String get settingsSound => 'Sounds';

  @override
  String get settingsSoundSubtitle => 'In-app sound effects';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsPrivacy => 'Privacy & health';

  @override
  String get settingsPrivacyBody =>
      'Your drink logs and history stay on your phone only.\n\nIf you use the friends leaderboard, your username, health gauge, sober streak, and equipped skin are synced to our servers (Supabase) via an anonymous identifier, no email or password required. You can delete this data at any time below.\n\nThe health bar is a playful indicator inspired by WHO guidelines, not medical advice. If your drinking worries you, talk to a health professional.';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsRedoTutorial => 'Replay the tutorial';

  @override
  String get settingsRedoTutorialSubtitle =>
      'Go through the intro again from the start';

  @override
  String get settingsDeleteData => 'Delete my data';

  @override
  String get deleteDataTitle => 'Delete everything?';

  @override
  String get deleteDataMessage =>
      'Drinks, progress and settings will be permanently deleted from this device.';

  @override
  String get deleteAction => 'Delete';

  @override
  String get unlockMessagesLvl2Title => 'The lemon speaks';

  @override
  String get unlockMessagesLvl2Desc => 'First personalized messages';

  @override
  String get unlockHistory7dTitle => '7-day history';

  @override
  String get unlockHistory7dDesc => 'Consumption chart unlocked';

  @override
  String get unlockBadgeFirstStepTitle => '\"First step\" badge';

  @override
  String get unlockBadgeFirstStepDesc => 'You started your journey';

  @override
  String get unlockStateHappyTitle => 'Happy lemon';

  @override
  String get unlockStateHappyDesc => 'New visual state · healthy habits';

  @override
  String get unlockWeeklyInsightTitle => 'Weekly insight';

  @override
  String get unlockWeeklyInsightDesc => 'A look at your week';

  @override
  String get unlockStateTiredTitle => 'Tired lemon';

  @override
  String get unlockStateTiredDesc => 'Long-term state made visible';

  @override
  String get unlockStatsAdvancedTitle => 'Advanced stats';

  @override
  String get unlockStatsAdvancedDesc => 'Trends and comparisons';

  @override
  String get unlockBadgeRegularityTitle => '\"Consistency\" badge';

  @override
  String get unlockBadgeRegularityDesc => '30 days of use';

  @override
  String get unlockStateWiseTitle => 'Wise lemon';

  @override
  String get unlockStateWiseDesc => 'Rare expression, long sobriety';

  @override
  String get unlockSkinDarkTitle => 'Dark skin';

  @override
  String get unlockSkinDarkDesc => 'Alternative lemon look';

  @override
  String get unlockMessagesDeepTitle => 'Deep messages';

  @override
  String get unlockMessagesDeepDesc => 'Reflections on your path';

  @override
  String get unlockBadgeMasterTitle => '\"Lemon master\" badge';

  @override
  String get unlockBadgeMasterDesc => 'Rare and shareable';

  @override
  String get unlockSkinSunglassesTitle => 'Sunglasses';

  @override
  String get unlockSkinSunglassesDesc => 'Lemon goes full celebrity';

  @override
  String get unlockSkinPartyHatTitle => 'Party hat';

  @override
  String get unlockSkinPartyHatDesc => 'To celebrate every win';

  @override
  String get unlockSkinCrownTitle => 'Crown';

  @override
  String get unlockSkinCrownDesc => 'Royalty is earned';

  @override
  String get unlockSkinGoldTitle => 'Golden lemon';

  @override
  String get unlockSkinGoldDesc => 'The shine of long journeys';

  @override
  String get badgeEquip => 'Equip';

  @override
  String get badgeEquipped => '✓ Equipped';

  @override
  String get unlockGenericTitle => 'Surprise';

  @override
  String get unlockGenericDesc => 'New unlock';

  @override
  String get onboarding1Title => 'Meet Jaune';

  @override
  String get onboarding1Text =>
      'Your lemon lives to the rhythm of your drinking. Take care of it and it will return the favor.';

  @override
  String get onboarding2Title => 'Your health at a glance';

  @override
  String get onboarding2Text =>
      'Log every drink with one tap. The health bar reacts, and sober days earn you XP and surprises.';

  @override
  String get onboardingDisclaimer =>
      'A playful indicator inspired by WHO guidelines, not medical advice.';

  @override
  String get onboardingDisclaimerAck => 'Got it';

  @override
  String get onboardingScoringTitle => 'How it works';

  @override
  String get onboardingScoringText =>
      'Every drink lowers your lemon\'s HP. Sober days restore HP, earn you XP and grow your streak 🔥.';

  @override
  String get onboardingRankingTitle => 'Challenge your friends';

  @override
  String get onboardingRankingText =>
      'Add friends and compare your gauges and streaks. The healthiest one tops the leaderboard.';

  @override
  String get onboarding3Title => 'The BeJaune';

  @override
  String get onboarding3Text =>
      'Every day at happy hour, a window opens to capture your moment and share it.';

  @override
  String get onboardingRemindersBenefit =>
      'A notification pings you right at happy hour, so you never miss your BeJaune or your streak.';

  @override
  String get onboardingEnableReminders => 'Turn on reminders';

  @override
  String get onboardingRemindersEnabled => '✓ Reminders on';

  @override
  String get onboardingNext => 'Continue';

  @override
  String get onboardingStart => 'Let\'s go!';

  @override
  String get onboardingLater => 'Later';

  @override
  String get calendarEmptyTitle => 'Your first day starts here';

  @override
  String get calendarEmptyText =>
      'Log your drinks and watch your month fill with color.';

  @override
  String a11yAddDrink(int count) {
    return 'Add a drink. $count today';
  }

  @override
  String get a11yResetButton => 'Reset today\'s drinks';

  @override
  String get a11yCalendarButton => 'Open the consumption calendar';

  @override
  String a11yHealthBar(int percent, int level) {
    return '$percent% health, level $level';
  }

  @override
  String a11yStreakBadge(int days) {
    return '$days sober days in a row, open progress';
  }

  @override
  String get a11yCitron => 'Jaune, your lemon. Tap it to say hi';

  @override
  String get a11yCapture => 'Take the BeJaune photo';

  @override
  String notifStreakTitle(int days) {
    return '🔥 $days sober days!';
  }

  @override
  String get notifStreakBody => 'Your lemon is glowing. Come see it shine!';

  @override
  String notifLevelTeaserTitle(int level) {
    return '⚡ Level $level in sight!';
  }

  @override
  String notifLevelTeaserBody(int xp) {
    return 'Only $xp XP left, one sober day and it\'s yours.';
  }

  @override
  String get badgeGalleryTitle => 'Collection';

  @override
  String get badgeGalleryViewAll => 'View the whole collection';

  @override
  String badgeLockedLevel(int level) {
    return 'Level $level';
  }

  @override
  String streakCountdown(int days, int target) {
    return '$days days to the $target-day milestone 🔥';
  }

  @override
  String get statsTitle => 'Statistics';

  @override
  String get statsLast7Days => 'Last 7 days';

  @override
  String get statsThisWeek => 'This week';

  @override
  String get statsLastWeek => 'Last week';

  @override
  String statsDrinksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count drinks',
      one: '1 drink',
      zero: '0 drinks',
    );
    return '$_temp0';
  }

  @override
  String statsTrendDown(int percent) {
    return '−$percent% vs previous period 💪';
  }

  @override
  String statsTrendUp(int percent) {
    return '+$percent% vs previous period';
  }

  @override
  String get statsTrendFlat => 'Steady vs previous period';

  @override
  String get statsHealthTrend => 'Your health trend';

  @override
  String get statsHealthTrendHint => 'Background health over the last 30 days';

  @override
  String get statsRecords => 'Records';

  @override
  String get statsLongestStreak => 'Longest sober streak';

  @override
  String get statsLightestWeek => 'Lightest week';

  @override
  String get statsDrinksAvoided => 'Drinks avoided';

  @override
  String get statsAvoidedHint => 'vs your pace in the first 4 weeks';

  @override
  String get statsShare => 'Share';

  @override
  String get statsHeroStreak => 'sober days in a row';

  @override
  String get statsHpUnit => 'HP';

  @override
  String get statsPeriodWeek => 'Week';

  @override
  String get statsPeriodMonth => 'Month';

  @override
  String get statsPeriodYear => 'Year';

  @override
  String get statsPeriodAll => 'All';

  @override
  String get statsConsumptionTitle => 'Drinks';

  @override
  String get statsDrinksLabel => 'Drinks this period';

  @override
  String get statsSoberUp => 'Improving vs before 📈';

  @override
  String get statsSoberDown => 'Down vs before';

  @override
  String get statsSoberFlat => 'Steady vs before';

  @override
  String get statsGuidelineTitle => 'Lower-risk guidelines';

  @override
  String get statsGuidelineSubtitle => 'This week · French health guidelines';

  @override
  String get statsGuidelineWeekly => '≤ 10 drinks / week';

  @override
  String get statsGuidelinePerDay => '≤ 2 drinks / day (max reached)';

  @override
  String get statsGuidelineSoberDays => 'Alcohol-free days';

  @override
  String get statsClockTitle => 'What time';

  @override
  String get statsClockSubtitle => 'When you drink during the day';

  @override
  String get statsClockEmpty => 'Your hours will show up as you log drinks';

  @override
  String get statsClockPeak => 'peak time';

  @override
  String statsClockInsight(int percent) {
    return '$percent% of your drinks in the evening (9pm–2am)';
  }

  @override
  String get statsUnitPerDay => 'Drinks per day';

  @override
  String get statsUnitPerMonth => 'Drinks per month';

  @override
  String get statsHealthScrubHint => 'Drag across the curve to see each day';

  @override
  String get statsSoberTitle => 'Sober days';

  @override
  String get statsSoberSubtitle => 'Over the selected period';

  @override
  String statsSoberCount(int sober, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      sober,
      locale: localeName,
      other: '$sober sober days out of $total',
      one: '1 sober day out of $total',
    );
    return '$_temp0';
  }

  @override
  String get statsMilestoneTitle => 'Streak goals';

  @override
  String get statsMilestoneReached => 'Top goal reached, you\'re a legend 🔥';

  @override
  String statsMilestoneCaption(int remaining, int target) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: '$remaining more sober days to reach goal $target 🔥',
      one: '1 more sober day to reach goal $target 🔥',
    );
    return '$_temp0';
  }

  @override
  String get statsWeekdayTitle => 'By day of the week';

  @override
  String get statsWeekdaySubtitle =>
      'Average drinks per day, your risky day stands out';

  @override
  String get statsHeatmapTitle => 'Your history';

  @override
  String get statsHeatmapSubtitle =>
      'Each square = a day. Green = sober, red = heavy.';

  @override
  String get statsHeatmapLess => 'Sober';

  @override
  String get statsHeatmapMore => 'Heavy';

  @override
  String get statsAllTimeSection => 'All-time';

  @override
  String get statsTotalSoberDays => 'Total sober days';

  @override
  String statsShareCaption(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sober days in total',
      one: '1 sober day in total',
    );
    return '$_temp0';
  }

  @override
  String statsInsightTrendDown(int percent) {
    return '−$percent% vs the previous period, keep it up 🎉';
  }

  @override
  String statsInsightTrendUp(int percent) {
    return '+$percent% vs the previous period, take back control 💪';
  }

  @override
  String statsInsightBestStreak(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Current record: $days sober days 🔥',
      one: 'Current record: 1 sober day 🔥',
    );
    return '$_temp0';
  }

  @override
  String statsInsightSoberRate(int percent) {
    return '$percent% sober days this period 💧';
  }

  @override
  String statsInsightWorstWeekday(String day) {
    return 'Your heaviest day: $day';
  }

  @override
  String get statsInsightGettingStarted =>
      'Keep logging, your stats will sharpen 🍋';

  @override
  String get a11yStatsButton => 'Open statistics';

  @override
  String get shareAction => 'Share';

  @override
  String get leaderboardTitle => 'Leaderboard';

  @override
  String get leaderboardTabRanking => 'Ranking';

  @override
  String get leaderboardTabRequests => 'Requests';

  @override
  String get leaderboardAddFriend => 'Add a friend';

  @override
  String get leaderboardAccept => 'Accept';

  @override
  String get leaderboardIgnore => 'Ignore';

  @override
  String get leaderboardEmptyTitle => 'No one here yet';

  @override
  String get leaderboardEmptySubtitle =>
      'Add a friend to compare your gauges and streaks.';

  @override
  String get leaderboardNoRequestsTitle => 'No requests';

  @override
  String get leaderboardNoRequestsSubtitle =>
      'Incoming friend requests will show up here.';

  @override
  String get leaderboardManageTitle => 'Friends';

  @override
  String get leaderboardYourFriends => 'Your friends';

  @override
  String get leaderboardRemoveFriend => 'Remove';

  @override
  String get leaderboardRemoveFriendTitle => 'Remove this friend?';

  @override
  String leaderboardRemoveFriendMessage(String name) {
    return '$name will no longer be in your leaderboard. You\'ll need a new request to re-add each other.';
  }

  @override
  String get leaderboardRemoveFriendConfirm => 'Remove';

  @override
  String get a11yLeaderboardButton => 'Open friends leaderboard';

  @override
  String get addFriendTitle => 'Add a friend';

  @override
  String get addFriendSubtitle =>
      'Let a friend scan your QR code, or share your invite link.';

  @override
  String get addFriendShare => 'Share my link';

  @override
  String get addFriendScan => 'Scan a QR code';

  @override
  String get addFriendScanTitle => 'Scan a friend\'s code';

  @override
  String get addFriendScanHint => 'Line up the QR code inside the frame';

  @override
  String get addFriendScanTorch => 'Flashlight';

  @override
  String get addFriendScanError => 'Can\'t open the camera';

  @override
  String get addFriendScanPermission =>
      'Allow camera access in your phone settings to scan a code.';

  @override
  String get addFriendScanRetry => 'Try again';

  @override
  String addFriendShareMessage(String link) {
    return 'Join me on Jaune and let\'s compare our gauges! $link';
  }

  @override
  String get usernamePromptTitle => 'Choose your nickname';

  @override
  String get usernamePromptSubtitle =>
      'This is the name your friends will see in the leaderboard.';

  @override
  String get usernamePromptHint => 'Your nickname';

  @override
  String get usernamePromptSave => 'Confirm';
}
