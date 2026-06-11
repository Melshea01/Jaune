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
  String get dayDetailSober => 'Journée sobre';

  @override
  String dayDetailModerate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count verres — modéré',
      one: '1 verre — modéré',
    );
    return '$_temp0';
  }

  @override
  String dayDetailRising(int count) {
    return '$count verres — ça monte';
  }

  @override
  String dayDetailHeavy(int count) {
    return '$count verres — grosse soirée';
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
    return 'Niveau $level — $description';
  }

  @override
  String xpReward(int xp) {
    return '+$xp XP';
  }

  @override
  String get andThen => 'Et ensuite…';

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
      'Tes données restent sur ton téléphone : rien n\'est envoyé sur Internet, aucun compte, aucun tracking.\n\nLa barre de vie est un indicateur ludique inspiré des repères de l\'OMS — ce n\'est pas un avis médical. Si ta consommation t\'inquiète, parles-en à un professionnel de santé.';

  @override
  String get settingsVersion => 'Version';

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
  String get unlockStateHappyDesc => 'Nouvel état visuel — bonne conso';

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
      'Ton citron vit au rythme de ta consommation d\'alcool. Prends soin de lui — il te le rendra.';

  @override
  String get onboarding2Title => 'Ta santé en un coup d\'œil';

  @override
  String get onboarding2Text =>
      'Loggue chaque verre d\'un tap. La barre de vie réagit, et les journées sobres te font gagner de l\'XP et des surprises.';

  @override
  String get onboardingDisclaimer =>
      'Indicateur ludique inspiré des repères de l\'OMS — pas un avis médical.';

  @override
  String get onboardingDisclaimerAck => 'J\'ai compris';

  @override
  String get onboarding3Title => 'Le BeJaune';

  @override
  String get onboarding3Text =>
      'Chaque jour à l\'apéro, une fenêtre s\'ouvre pour capturer ton moment et le partager. Active les rappels pour ne jamais la rater.';

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
    return 'Plus que $xp XP — une journée sobre et c\'est dans la poche.';
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
    return '−$percent% vs semaine dernière 💪';
  }

  @override
  String statsTrendUp(int percent) {
    return '+$percent% vs semaine dernière';
  }

  @override
  String get statsTrendFlat => 'Stable vs semaine dernière';

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
  String get a11yStatsButton => 'Ouvrir les statistiques';

  @override
  String get shareAction => 'Partager';
}
