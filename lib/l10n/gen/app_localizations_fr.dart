// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Jaune';

  @override
  String bejauneScoreMessage(int percent) {
    return 'Score citron : $percent%';
  }

  @override
  String get notifAperoTitle => '🍋 Moment apéro avec Jaune !';

  @override
  String get notifAperoBody =>
      'C\'est l\'heure de capturer ton moment à l\'apéro. Montre-nous ton verre !';

  @override
  String get postBejaune => 'Poste un JAUNE';

  @override
  String get alreadyPostedToday => '✓ Déjà posté aujourd\'hui';

  @override
  String get availableAtApero => '🔒 Disponible à l\'apéro';

  @override
  String get calendarTitle => 'Calendrier';

  @override
  String get calendarSee => 'Voir';

  @override
  String get calendarClose => 'Fermer';

  @override
  String get calendarToday => 'Aujourd\'hui';

  @override
  String get calendarMonthEmpty => 'Rien de loggé ce mois-ci';

  @override
  String get calendarLegendSober => 'Sobre';

  @override
  String get calendarLegendModerate => 'Modéré';

  @override
  String get calendarLegendRising => 'Ça monte';

  @override
  String get calendarLegendHeavy => 'Grosse soirée';

  @override
  String get dayDetailSober => 'Journée sobre';

  @override
  String dayDetailModerate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count verres · modéré',
      one: '1 verre · modéré',
    );
    return '$_temp0';
  }

  @override
  String dayDetailRising(int count) {
    return '$count verres · ça monte';
  }

  @override
  String dayDetailHeavy(int count) {
    return '$count verres · grosse soirée';
  }

  @override
  String xpToastAmount(int amount) {
    return '+$amount XP';
  }

  @override
  String get xpReasonAppOpen => 'Ouverture de l\'app';

  @override
  String get xpReasonDailyLog => 'Enregistrement du jour';

  @override
  String get xpReasonSoberYesterday => 'Journée d\'hier sobre';

  @override
  String get xpReasonGreenDay => 'Journée verte';

  @override
  String get xpReasonPerfectWeek => 'Semaine parfaite';

  @override
  String get xpReasonQuestComplete => 'Quête accomplie';

  @override
  String get xpReasonWeeklyGoal => 'Objectif de la semaine';

  @override
  String get dailyQuestsTitle => '🎯 Quêtes du jour';

  @override
  String get questOpenAppTitle => 'Passer dire bonjour au citron';

  @override
  String get questLogTodayTitle => 'Noter sa journée';

  @override
  String get questSoberTodayTitle => 'Une journée sans alcool';

  @override
  String get questUnderTwoTitle => 'Rester sous 2 verres';

  @override
  String get questKeepStreakTitle => 'Garder sa série en vie';

  @override
  String get weeklyGoalTitle => 'Objectif de la semaine';

  @override
  String weeklyGoalProgress(int sober, int target) {
    return '$sober / $target jours sobres';
  }

  @override
  String get levelStatStreak => 'série';

  @override
  String get levelStatShields => 'boucliers';

  @override
  String get levelStatBadges => 'badges';

  @override
  String get levelStatSkins => 'tenues';

  @override
  String get streakShieldProtected => '🛡️ Série protégée';

  @override
  String streakShieldsAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count boucliers',
      one: '1 bouclier',
      zero: 'Aucun bouclier',
    );
    return '$_temp0';
  }

  @override
  String soberStreakInARow(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours sobres d\'affilée',
      one: '1 jour sobre d\'affilée',
    );
    return '$_temp0';
  }

  @override
  String get rankApprentice => 'Apprenti 🌱';

  @override
  String get rankExplorer => 'Explorateur 🗺️';

  @override
  String get rankMaster => 'Maître 🏆';

  @override
  String get rankLegend => 'Légende ⭐';

  @override
  String get phaseDiscovery => '🌱 Découverte';

  @override
  String get phaseEngagement => '⚡ Engagement';

  @override
  String get phaseMastery => '🏆 Maîtrise';

  @override
  String get levelRingLabel => 'NIVEAU';

  @override
  String xpProgress(int xp, int xpToNext) {
    return '⚡ $xp / $xpToNext XP';
  }

  @override
  String get streakKeepGoing => 'Continue, ton citron rayonne !';

  @override
  String get unlockedAtThisLevel => '✨ Débloqué à ce niveau';

  @override
  String get nextChallenge => '🎯 Prochain défi';

  @override
  String levelWithDescription(int level, String description) {
    return 'Niveau $level · $description';
  }

  @override
  String xpReward(int xp) {
    return '+$xp XP';
  }

  @override
  String get andThen => 'Et ensuite…';

  @override
  String get levelScreenTitle => 'Progression';

  @override
  String get streakScreenTitle => 'Série';

  @override
  String get streakMilestonesTitle => 'Paliers';

  @override
  String get newWorldBanner => '✦ NOUVEAU MONDE ✦';

  @override
  String get weeklyGoalReached => 'Objectif atteint ! 🛡️ +1 bouclier';

  @override
  String get levelJourneyTitle => '🗺️ Ton parcours';

  @override
  String get levelYouAreHere => 'Tu es ici';

  @override
  String chapterTitle(int n) {
    return 'Chapitre $n';
  }

  @override
  String levelLockedShort(int level) {
    return 'Niv. $level';
  }

  @override
  String levelUpTitle(int level) {
    return 'NIVEAU $level';
  }

  @override
  String get unlockedBanner => '✨ DÉBLOQUÉ ✨';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get infoTitle => 'Comment ça marche ?';

  @override
  String get infoStep1Title => 'Loggue tes verres';

  @override
  String get infoStep1Text =>
      'Chaque fois que tu bois, appuie sur le bouton « 🍻 ». 1 verre standard = 1 clic (ex : une pinte = 2 clics).';

  @override
  String get infoStep2Title => 'Ton citron vit avec toi';

  @override
  String get infoStep2Text =>
      'Ton citron a des points de vie qui montent ou descendent selon ta consommation. Prends soin de lui !';

  @override
  String get infoStep3Title => 'Gagne de l\'XP';

  @override
  String get infoStep3Text =>
      'Journées sobres, semaines équilibrées et régularité te font monter de niveau et débloquer des surprises.';

  @override
  String get resetDayTitle => 'Réinitialiser la journée ?';

  @override
  String get resetDayMessage =>
      'Cela remettra à zéro tes consommations d\'aujourd\'hui. Tu confirmes ?';

  @override
  String get cancel => 'Annuler';

  @override
  String get resetAction => 'Réinitialiser';

  @override
  String dayUnit(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'jours',
      one: 'jour',
    );
    return '$_temp0';
  }

  @override
  String daysCount(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String get captureBackTooltip => 'Retour';

  @override
  String get backToCamera => 'Retour à la caméra';

  @override
  String get previewCaption => '📱 Aperçu du montage final';

  @override
  String get debugModeOn => '🐛 Mode debug activé';

  @override
  String get debugModeOff => '📸 Mode normal';

  @override
  String get cameraUnavailable => 'Accès caméra indisponible ou refusé.';

  @override
  String get tryAgain => 'Essayer à nouveau';

  @override
  String get openSettings => 'Ouvrir les réglages';

  @override
  String get previewUnavailable => 'Aperçu indisponible';

  @override
  String get retry => 'Réessayer';

  @override
  String get sayJaune => 'Dites JAUNEEE...';

  @override
  String get photoLabel => 'PHOTO';

  @override
  String levelChip(int level) {
    return 'Niv. $level';
  }

  @override
  String get hpLabel => 'PV';

  @override
  String get sharedFromJaune => 'Partagé depuis Jaune !';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsUsername => 'Mon pseudo';

  @override
  String get settingsUsernameSubtitle =>
      'Visible dans le classement entre amis';

  @override
  String get settingsUsernameEmpty => 'Non défini';

  @override
  String get settingsNotifications => 'Rappels';

  @override
  String get settingsNotificationsSubtitle =>
      'Notification quotidienne à l\'apéro';

  @override
  String get settingsSound => 'Sons';

  @override
  String get settingsSoundSubtitle => 'Effets sonores de l\'app';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageSystem => 'Système';

  @override
  String get settingsPrivacy => 'Confidentialité & santé';

  @override
  String get settingsPrivacyBody =>
      'Tes consommations et ton historique restent uniquement sur ton téléphone.\n\nSi tu utilises le classement entre amis, ton pseudo, ta jauge de santé, ta série sobre et ton skin sont synchronisés sur nos serveurs (Supabase) via un identifiant anonyme, sans email ni mot de passe. Tu peux effacer ces données à tout moment ci-dessous.\n\nLa barre de vie est un indicateur ludique inspiré des repères de l\'OMS, pas un avis médical. Si ta consommation t\'inquiète, parles-en à un professionnel de santé.';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsRedoTutorial => 'Revoir le tutoriel';

  @override
  String get settingsRedoTutorialSubtitle =>
      'Reprends la présentation depuis le début';

  @override
  String get settingsDeleteData => 'Effacer mes données';

  @override
  String get deleteDataTitle => 'Tout effacer ?';

  @override
  String get deleteDataMessage =>
      'Consommations, progression et réglages seront définitivement supprimés de cet appareil.';

  @override
  String get deleteAction => 'Effacer';

  @override
  String get unlockMessagesLvl2Title => 'Le citron parle';

  @override
  String get unlockMessagesLvl2Desc => 'Premiers messages personnalisés';

  @override
  String get unlockHistory7dTitle => 'Historique 7 jours';

  @override
  String get unlockHistory7dDesc => 'Graphique de consommation débloqué';

  @override
  String get unlockBadgeFirstStepTitle => 'Badge « Premier pas »';

  @override
  String get unlockBadgeFirstStepDesc => 'Tu as commencé ton parcours';

  @override
  String get unlockStateHappyTitle => 'Citron heureux';

  @override
  String get unlockStateHappyDesc => 'Nouvel état visuel · bonne conso';

  @override
  String get unlockWeeklyInsightTitle => 'Insight hebdomadaire';

  @override
  String get unlockWeeklyInsightDesc => 'Analyse de ta semaine';

  @override
  String get unlockStateTiredTitle => 'Citron fatigué';

  @override
  String get unlockStateTiredDesc => 'État long terme visible';

  @override
  String get unlockStatsAdvancedTitle => 'Stats avancées';

  @override
  String get unlockStatsAdvancedDesc => 'Tendances et comparaisons';

  @override
  String get unlockBadgeRegularityTitle => 'Badge « Régularité »';

  @override
  String get unlockBadgeRegularityDesc => '30 jours d\'utilisation';

  @override
  String get unlockStateWiseTitle => 'Citron sage';

  @override
  String get unlockStateWiseDesc => 'Expression rare, longue sobriété';

  @override
  String get unlockSkinDarkTitle => 'Skin sombre';

  @override
  String get unlockSkinDarkDesc => 'Apparence alternative du citron';

  @override
  String get unlockMessagesDeepTitle => 'Messages profonds';

  @override
  String get unlockMessagesDeepDesc => 'Réflexions sur ton chemin';

  @override
  String get unlockBadgeMasterTitle => 'Badge « Maître citron »';

  @override
  String get unlockBadgeMasterDesc => 'Rare et partageable';

  @override
  String get unlockSkinSunglassesTitle => 'Lunettes de soleil';

  @override
  String get unlockSkinSunglassesDesc => 'Le citron passe en mode star';

  @override
  String get unlockSkinPartyHatTitle => 'Chapeau de fête';

  @override
  String get unlockSkinPartyHatDesc => 'Pour célébrer chaque victoire';

  @override
  String get unlockSkinCrownTitle => 'Couronne';

  @override
  String get unlockSkinCrownDesc => 'La royauté se mérite';

  @override
  String get unlockSkinGoldTitle => 'Citron doré';

  @override
  String get unlockSkinGoldDesc => 'L\'éclat des grands parcours';

  @override
  String get badgeEquip => 'Équiper';

  @override
  String get badgeEquipped => '✓ Équipé';

  @override
  String get unlockGenericTitle => 'Surprise';

  @override
  String get unlockGenericDesc => 'Nouveau déblocage';

  @override
  String get onboarding1Title => 'Voici Jaune';

  @override
  String get onboarding1Text =>
      'Ton citron vit au rythme de ta consommation d\'alcool. Prends soin de lui, il te le rendra.';

  @override
  String get onboarding2Title => 'Ta santé en un coup d\'œil';

  @override
  String get onboarding2Text =>
      'Loggue chaque verre d\'un tap. La barre de vie réagit, et les journées sobres te font gagner de l\'XP et des surprises.';

  @override
  String get onboardingDisclaimer =>
      'Indicateur ludique inspiré des repères de l\'OMS, pas un avis médical.';

  @override
  String get onboardingDisclaimerAck => 'J\'ai compris';

  @override
  String get onboardingScoringTitle => 'Comment ça marche';

  @override
  String get onboardingScoringText =>
      'Chaque verre fait baisser les PV de ton citron. Les journées sobres lui rendent des PV, te font gagner de l\'XP et allongent ta série 🔥.';

  @override
  String get onboardingRankingTitle => 'Défie tes amis';

  @override
  String get onboardingRankingText =>
      'Ajoute tes amis et comparez vos jauges et vos séries. Le plus en forme prend la tête du classement.';

  @override
  String get onboarding3Title => 'Le BeJaune';

  @override
  String get onboarding3Text =>
      'Chaque jour à l\'apéro, une fenêtre s\'ouvre pour capturer ton moment et le partager.';

  @override
  String get onboardingRemindersBenefit =>
      'Une notif te prévient pile à l\'apéro : tu ne rates jamais ton BeJaune ni ta série.';

  @override
  String get onboardingEnableReminders => 'Activer les rappels';

  @override
  String get onboardingRemindersEnabled => '✓ Rappels activés';

  @override
  String get onboardingNext => 'Continuer';

  @override
  String get onboardingStart => 'C\'est parti !';

  @override
  String get onboardingLater => 'Plus tard';

  @override
  String get calendarEmptyTitle => 'Ton premier jour commence ici';

  @override
  String get calendarEmptyText =>
      'Loggue tes verres et reviens voir ton mois prendre des couleurs.';

  @override
  String a11yAddDrink(int count) {
    return 'Ajouter un verre. $count aujourd\'hui';
  }

  @override
  String get a11yResetButton => 'Réinitialiser les verres d\'aujourd\'hui';

  @override
  String get a11yCalendarButton => 'Ouvrir le calendrier de consommation';

  @override
  String a11yHealthBar(int percent, int level) {
    return '$percent% de santé, niveau $level';
  }

  @override
  String a11yStreakBadge(int days) {
    return '$days jours sobres d\'affilée, ouvrir la progression';
  }

  @override
  String get a11yCitron => 'Jaune, ton citron. Touche-le pour le saluer';

  @override
  String get a11yCapture => 'Prendre la photo BeJaune';

  @override
  String notifStreakTitle(int days) {
    return '🔥 $days jours sobres !';
  }

  @override
  String get notifStreakBody => 'Ton citron rayonne. Viens le voir briller !';

  @override
  String notifLevelTeaserTitle(int level) {
    return '⚡ Niveau $level en vue !';
  }

  @override
  String notifLevelTeaserBody(int xp) {
    return 'Plus que $xp XP, une journée sobre et c\'est dans la poche.';
  }

  @override
  String get badgeGalleryTitle => 'Collection';

  @override
  String get badgeGalleryViewAll => 'Voir toute la collection';

  @override
  String badgeLockedLevel(int level) {
    return 'Niveau $level';
  }

  @override
  String streakCountdown(int days, int target) {
    return 'J-$days avant le palier $target 🔥';
  }

  @override
  String get statsTitle => 'Statistiques';

  @override
  String get statsLast7Days => '7 derniers jours';

  @override
  String get statsThisWeek => 'Cette semaine';

  @override
  String get statsLastWeek => 'Semaine dernière';

  @override
  String statsDrinksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count verres',
      one: '1 verre',
      zero: '0 verre',
    );
    return '$_temp0';
  }

  @override
  String statsTrendDown(int percent) {
    return '−$percent% vs période précédente 💪';
  }

  @override
  String statsTrendUp(int percent) {
    return '+$percent% vs période précédente';
  }

  @override
  String get statsTrendFlat => 'Stable vs période précédente';

  @override
  String get statsHealthTrend => 'Évolution de ta santé';

  @override
  String get statsHealthTrendHint => 'Santé de fond sur les 30 derniers jours';

  @override
  String get statsRecords => 'Records';

  @override
  String get statsLongestStreak => 'Plus longue série sobre';

  @override
  String get statsLightestWeek => 'Semaine la plus légère';

  @override
  String get statsDrinksAvoided => 'Verres évités';

  @override
  String get statsAvoidedHint => 'vs ton rythme des 4 premières semaines';

  @override
  String get statsShare => 'Partager';

  @override
  String get statsHeroStreak => 'jours sobres d\'affilée';

  @override
  String get statsHpUnit => 'PV';

  @override
  String get statsPeriodWeek => 'Semaine';

  @override
  String get statsPeriodMonth => 'Mois';

  @override
  String get statsPeriodYear => 'Année';

  @override
  String get statsPeriodAll => 'Tout';

  @override
  String get statsConsumptionTitle => 'Consommation';

  @override
  String get statsDrinksLabel => 'Verres sur la période';

  @override
  String get statsSoberUp => 'En progrès vs avant 📈';

  @override
  String get statsSoberDown => 'En recul vs avant';

  @override
  String get statsSoberFlat => 'Stable vs avant';

  @override
  String get statsGuidelineTitle => 'Repères à moindre risque';

  @override
  String get statsGuidelineSubtitle =>
      'Cette semaine · repères Santé publique France';

  @override
  String get statsGuidelineWeekly => '≤ 10 verres / semaine';

  @override
  String get statsGuidelinePerDay => '≤ 2 verres / jour (max atteint)';

  @override
  String get statsGuidelineSoberDays => 'Des jours sans alcool';

  @override
  String get statsClockTitle => 'À quelle heure';

  @override
  String get statsClockSubtitle => 'Répartition de tes verres dans la journée';

  @override
  String get statsClockEmpty =>
      'Tes heures s\'afficheront à mesure que tu logues tes verres';

  @override
  String get statsClockPeak => 'heure de pointe';

  @override
  String statsClockInsight(int percent) {
    return '$percent% de tes verres en soirée (21 h–2 h)';
  }

  @override
  String get statsUnitPerDay => 'Verres par jour';

  @override
  String get statsUnitPerMonth => 'Verres par mois';

  @override
  String get statsHealthScrubHint =>
      'Glisse ton doigt sur la courbe pour voir chaque jour';

  @override
  String get statsSoberTitle => 'Jours sobres';

  @override
  String get statsSoberSubtitle => 'Sur la période sélectionnée';

  @override
  String statsSoberCount(int sober, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      sober,
      locale: localeName,
      other: '$sober jours sobres sur $total',
      one: '1 jour sobre sur $total',
    );
    return '$_temp0';
  }

  @override
  String get statsMilestoneTitle => 'Objectifs de série';

  @override
  String get statsMilestoneReached =>
      'Objectif maximum atteint, tu es une légende 🔥';

  @override
  String statsMilestoneCaption(int remaining, int target) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other:
          'Plus que $remaining jours sobres pour atteindre l\'objectif $target 🔥',
      one: 'Plus qu\'un jour sobre pour atteindre l\'objectif $target 🔥',
    );
    return '$_temp0';
  }

  @override
  String get statsWeekdayTitle => 'Par jour de la semaine';

  @override
  String get statsWeekdaySubtitle =>
      'Moyenne de verres par jour, ton jour à risque ressort';

  @override
  String get statsHeatmapTitle => 'Ton historique';

  @override
  String get statsHeatmapSubtitle =>
      'Chaque carré = un jour. Vert = sobre, rouge = chargé.';

  @override
  String get statsHeatmapLess => 'Sobre';

  @override
  String get statsHeatmapMore => 'Chargé';

  @override
  String get statsAllTimeSection => 'Depuis le début';

  @override
  String get statsTotalSoberDays => 'Total de jours sobres';

  @override
  String statsShareCaption(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours sobres au total',
      one: '1 jour sobre au total',
    );
    return '$_temp0';
  }

  @override
  String statsInsightTrendDown(int percent) {
    return '−$percent% vs la période précédente, continue comme ça 🎉';
  }

  @override
  String statsInsightTrendUp(int percent) {
    return '+$percent% vs la période précédente, reprends la main 💪';
  }

  @override
  String statsInsightBestStreak(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Record en cours : $days jours sobres 🔥',
      one: 'Record en cours : 1 jour sobre 🔥',
    );
    return '$_temp0';
  }

  @override
  String statsInsightSoberRate(int percent) {
    return '$percent% de jours sobres sur la période 💧';
  }

  @override
  String statsInsightWorstWeekday(String day) {
    return 'Ton jour le plus chargé : $day';
  }

  @override
  String get statsInsightGettingStarted =>
      'Continue à logguer, tes stats vont s\'affiner 🍋';

  @override
  String get a11yStatsButton => 'Ouvrir les statistiques';

  @override
  String get shareAction => 'Partager';

  @override
  String get leaderboardTitle => 'Classement';

  @override
  String get leaderboardTabRanking => 'Classement';

  @override
  String get leaderboardTabRequests => 'Demandes';

  @override
  String get leaderboardAddFriend => 'Ajouter un ami';

  @override
  String get leaderboardAccept => 'Accepter';

  @override
  String get leaderboardIgnore => 'Ignorer';

  @override
  String get leaderboardEmptyTitle => 'Personne au classement';

  @override
  String get leaderboardEmptySubtitle =>
      'Ajoute un ami pour comparer vos jauges et vos séries.';

  @override
  String get leaderboardNoRequestsTitle => 'Aucune demande';

  @override
  String get leaderboardNoRequestsSubtitle =>
      'Les demandes d\'amitié reçues apparaîtront ici.';

  @override
  String get leaderboardManageTitle => 'Amis';

  @override
  String get leaderboardYourFriends => 'Mes amis';

  @override
  String get leaderboardRemoveFriend => 'Retirer';

  @override
  String get leaderboardRemoveFriendTitle => 'Retirer cet ami ?';

  @override
  String leaderboardRemoveFriendMessage(String name) {
    return '$name ne sera plus dans ton classement. Il faudra une nouvelle demande pour vous réajouter.';
  }

  @override
  String get leaderboardRemoveFriendConfirm => 'Retirer';

  @override
  String get a11yLeaderboardButton => 'Ouvrir le classement entre amis';

  @override
  String get addFriendTitle => 'Ajoute un ami';

  @override
  String get addFriendSubtitle =>
      'Fais scanner ton QR code, ou partage ton lien d\'invitation.';

  @override
  String get addFriendShare => 'Partager mon lien';

  @override
  String get addFriendScan => 'Scanner un QR code';

  @override
  String get addFriendScanTitle => 'Scanne le code d\'un ami';

  @override
  String get addFriendScanHint => 'Aligne le QR code dans le cadre';

  @override
  String get addFriendScanTorch => 'Lampe torche';

  @override
  String get addFriendScanError => 'Impossible d\'ouvrir la caméra';

  @override
  String get addFriendScanPermission =>
      'Autorise l\'accès à la caméra dans les réglages de ton téléphone pour scanner un code.';

  @override
  String get addFriendScanRetry => 'Réessayer';

  @override
  String addFriendShareMessage(String link) {
    return 'Rejoins-moi sur Jaune et comparons nos jauges ! $link';
  }

  @override
  String get usernamePromptTitle => 'Choisis ton pseudo';

  @override
  String get usernamePromptSubtitle =>
      'C\'est le nom que verront tes amis dans le classement.';

  @override
  String get usernamePromptHint => 'Ton pseudo';

  @override
  String get usernamePromptSave => 'Valider';
}
