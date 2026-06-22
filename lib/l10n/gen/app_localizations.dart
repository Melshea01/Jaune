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
/// import 'gen/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
  /// **'Jaune'**
  String get appTitle;

  /// No description provided for @bejauneScoreMessage.
  ///
  /// In fr, this message translates to:
  /// **'Score citron : {percent}%'**
  String bejauneScoreMessage(int percent);

  /// No description provided for @notifAperoTitle.
  ///
  /// In fr, this message translates to:
  /// **'🍋 Moment apéro avec Jaune !'**
  String get notifAperoTitle;

  /// No description provided for @notifAperoBody.
  ///
  /// In fr, this message translates to:
  /// **'C\'est l\'heure de capturer ton moment à l\'apéro. Montre-nous ton verre !'**
  String get notifAperoBody;

  /// No description provided for @postBejaune.
  ///
  /// In fr, this message translates to:
  /// **'Poste un JAUNE'**
  String get postBejaune;

  /// No description provided for @alreadyPostedToday.
  ///
  /// In fr, this message translates to:
  /// **'✓ Déjà posté aujourd\'hui'**
  String get alreadyPostedToday;

  /// No description provided for @availableAtApero.
  ///
  /// In fr, this message translates to:
  /// **'🔒 Disponible à l\'apéro'**
  String get availableAtApero;

  /// No description provided for @calendarTitle.
  ///
  /// In fr, this message translates to:
  /// **'Calendrier'**
  String get calendarTitle;

  /// No description provided for @calendarSee.
  ///
  /// In fr, this message translates to:
  /// **'Voir'**
  String get calendarSee;

  /// No description provided for @calendarClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get calendarClose;

  /// No description provided for @dayDetailSober.
  ///
  /// In fr, this message translates to:
  /// **'Journée sobre'**
  String get dayDetailSober;

  /// No description provided for @dayDetailModerate.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 verre · modéré} other{{count} verres · modéré}}'**
  String dayDetailModerate(int count);

  /// No description provided for @dayDetailRising.
  ///
  /// In fr, this message translates to:
  /// **'{count} verres · ça monte'**
  String dayDetailRising(int count);

  /// No description provided for @dayDetailHeavy.
  ///
  /// In fr, this message translates to:
  /// **'{count} verres · grosse soirée'**
  String dayDetailHeavy(int count);

  /// No description provided for @xpToastAmount.
  ///
  /// In fr, this message translates to:
  /// **'+{amount} XP'**
  String xpToastAmount(int amount);

  /// No description provided for @xpReasonAppOpen.
  ///
  /// In fr, this message translates to:
  /// **'Ouverture de l\'app'**
  String get xpReasonAppOpen;

  /// No description provided for @xpReasonDailyLog.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement du jour'**
  String get xpReasonDailyLog;

  /// No description provided for @xpReasonSoberYesterday.
  ///
  /// In fr, this message translates to:
  /// **'Journée d\'hier sobre'**
  String get xpReasonSoberYesterday;

  /// No description provided for @xpReasonGreenDay.
  ///
  /// In fr, this message translates to:
  /// **'Journée verte'**
  String get xpReasonGreenDay;

  /// No description provided for @xpReasonPerfectWeek.
  ///
  /// In fr, this message translates to:
  /// **'Semaine parfaite'**
  String get xpReasonPerfectWeek;

  /// No description provided for @soberStreakInARow.
  ///
  /// In fr, this message translates to:
  /// **'{days, plural, =1{1 jour sobre d\'affilée} other{{days} jours sobres d\'affilée}}'**
  String soberStreakInARow(int days);

  /// No description provided for @rankApprentice.
  ///
  /// In fr, this message translates to:
  /// **'Apprenti 🌱'**
  String get rankApprentice;

  /// No description provided for @rankExplorer.
  ///
  /// In fr, this message translates to:
  /// **'Explorateur 🗺️'**
  String get rankExplorer;

  /// No description provided for @rankMaster.
  ///
  /// In fr, this message translates to:
  /// **'Maître 🏆'**
  String get rankMaster;

  /// No description provided for @rankLegend.
  ///
  /// In fr, this message translates to:
  /// **'Légende ⭐'**
  String get rankLegend;

  /// No description provided for @phaseDiscovery.
  ///
  /// In fr, this message translates to:
  /// **'🌱 Découverte'**
  String get phaseDiscovery;

  /// No description provided for @phaseEngagement.
  ///
  /// In fr, this message translates to:
  /// **'⚡ Engagement'**
  String get phaseEngagement;

  /// No description provided for @phaseMastery.
  ///
  /// In fr, this message translates to:
  /// **'🏆 Maîtrise'**
  String get phaseMastery;

  /// No description provided for @levelRingLabel.
  ///
  /// In fr, this message translates to:
  /// **'NIVEAU'**
  String get levelRingLabel;

  /// No description provided for @xpProgress.
  ///
  /// In fr, this message translates to:
  /// **'⚡ {xp} / {xpToNext} XP'**
  String xpProgress(int xp, int xpToNext);

  /// No description provided for @streakKeepGoing.
  ///
  /// In fr, this message translates to:
  /// **'Continue, ton citron rayonne !'**
  String get streakKeepGoing;

  /// No description provided for @unlockedAtThisLevel.
  ///
  /// In fr, this message translates to:
  /// **'✨ Débloqué à ce niveau'**
  String get unlockedAtThisLevel;

  /// No description provided for @nextChallenge.
  ///
  /// In fr, this message translates to:
  /// **'🎯 Prochain défi'**
  String get nextChallenge;

  /// No description provided for @levelWithDescription.
  ///
  /// In fr, this message translates to:
  /// **'Niveau {level} · {description}'**
  String levelWithDescription(int level, String description);

  /// No description provided for @xpReward.
  ///
  /// In fr, this message translates to:
  /// **'+{xp} XP'**
  String xpReward(int xp);

  /// No description provided for @andThen.
  ///
  /// In fr, this message translates to:
  /// **'Et ensuite…'**
  String get andThen;

  /// No description provided for @levelUpTitle.
  ///
  /// In fr, this message translates to:
  /// **'NIVEAU {level}'**
  String levelUpTitle(int level);

  /// No description provided for @unlockedBanner.
  ///
  /// In fr, this message translates to:
  /// **'✨ DÉBLOQUÉ ✨'**
  String get unlockedBanner;

  /// No description provided for @continueLabel.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continueLabel;

  /// No description provided for @infoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comment ça marche ?'**
  String get infoTitle;

  /// No description provided for @infoStep1Title.
  ///
  /// In fr, this message translates to:
  /// **'Loggue tes verres'**
  String get infoStep1Title;

  /// No description provided for @infoStep1Text.
  ///
  /// In fr, this message translates to:
  /// **'Chaque fois que tu bois, appuie sur le bouton « 🍻 ». 1 verre standard = 1 clic (ex : une pinte = 2 clics).'**
  String get infoStep1Text;

  /// No description provided for @infoStep2Title.
  ///
  /// In fr, this message translates to:
  /// **'Ton citron vit avec toi'**
  String get infoStep2Title;

  /// No description provided for @infoStep2Text.
  ///
  /// In fr, this message translates to:
  /// **'Ton citron a des points de vie qui montent ou descendent selon ta consommation. Prends soin de lui !'**
  String get infoStep2Text;

  /// No description provided for @infoStep3Title.
  ///
  /// In fr, this message translates to:
  /// **'Gagne de l\'XP'**
  String get infoStep3Title;

  /// No description provided for @infoStep3Text.
  ///
  /// In fr, this message translates to:
  /// **'Journées sobres, semaines équilibrées et régularité te font monter de niveau et débloquer des surprises.'**
  String get infoStep3Text;

  /// No description provided for @resetDayTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser la journée ?'**
  String get resetDayTitle;

  /// No description provided for @resetDayMessage.
  ///
  /// In fr, this message translates to:
  /// **'Cela remettra à zéro tes consommations d\'aujourd\'hui. Tu confirmes ?'**
  String get resetDayMessage;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @resetAction.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get resetAction;

  /// No description provided for @dayUnit.
  ///
  /// In fr, this message translates to:
  /// **'{days, plural, =1{jour} other{jours}}'**
  String dayUnit(int days);

  /// No description provided for @daysCount.
  ///
  /// In fr, this message translates to:
  /// **'{days, plural, =1{1 jour} other{{days} jours}}'**
  String daysCount(int days);

  /// No description provided for @captureBackTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get captureBackTooltip;

  /// No description provided for @backToCamera.
  ///
  /// In fr, this message translates to:
  /// **'Retour à la caméra'**
  String get backToCamera;

  /// No description provided for @previewCaption.
  ///
  /// In fr, this message translates to:
  /// **'📱 Aperçu du montage final'**
  String get previewCaption;

  /// No description provided for @debugModeOn.
  ///
  /// In fr, this message translates to:
  /// **'🐛 Mode debug activé'**
  String get debugModeOn;

  /// No description provided for @debugModeOff.
  ///
  /// In fr, this message translates to:
  /// **'📸 Mode normal'**
  String get debugModeOff;

  /// No description provided for @cameraUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Accès caméra indisponible ou refusé.'**
  String get cameraUnavailable;

  /// No description provided for @tryAgain.
  ///
  /// In fr, this message translates to:
  /// **'Essayer à nouveau'**
  String get tryAgain;

  /// No description provided for @openSettings.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir les réglages'**
  String get openSettings;

  /// No description provided for @previewUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu indisponible'**
  String get previewUnavailable;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @sayJaune.
  ///
  /// In fr, this message translates to:
  /// **'Dites JAUNEEE...'**
  String get sayJaune;

  /// No description provided for @photoLabel.
  ///
  /// In fr, this message translates to:
  /// **'PHOTO'**
  String get photoLabel;

  /// No description provided for @levelChip.
  ///
  /// In fr, this message translates to:
  /// **'Niv. {level}'**
  String levelChip(int level);

  /// No description provided for @hpLabel.
  ///
  /// In fr, this message translates to:
  /// **'PV'**
  String get hpLabel;

  /// No description provided for @sharedFromJaune.
  ///
  /// In fr, this message translates to:
  /// **'Partagé depuis Jaune !'**
  String get sharedFromJaune;

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get settingsTitle;

  /// No description provided for @settingsUsername.
  ///
  /// In fr, this message translates to:
  /// **'Mon pseudo'**
  String get settingsUsername;

  /// No description provided for @settingsUsernameSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Visible dans le classement entre amis'**
  String get settingsUsernameSubtitle;

  /// No description provided for @settingsUsernameEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Non défini'**
  String get settingsUsernameEmpty;

  /// No description provided for @settingsNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Rappels'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Notification quotidienne à l\'apéro'**
  String get settingsNotificationsSubtitle;

  /// No description provided for @settingsSound.
  ///
  /// In fr, this message translates to:
  /// **'Sons'**
  String get settingsSound;

  /// No description provided for @settingsSoundSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Effets sonores de l\'app'**
  String get settingsSoundSubtitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'Confidentialité & santé'**
  String get settingsPrivacy;

  /// No description provided for @settingsPrivacyBody.
  ///
  /// In fr, this message translates to:
  /// **'Tes consommations et ton historique restent uniquement sur ton téléphone.\n\nSi tu utilises le classement entre amis, ton pseudo, ta jauge de santé, ta série sobre et ton skin sont synchronisés sur nos serveurs (Supabase) via un identifiant anonyme, sans email ni mot de passe. Tu peux effacer ces données à tout moment ci-dessous.\n\nLa barre de vie est un indicateur ludique inspiré des repères de l\'OMS, pas un avis médical. Si ta consommation t\'inquiète, parles-en à un professionnel de santé.'**
  String get settingsPrivacyBody;

  /// No description provided for @settingsVersion.
  ///
  /// In fr, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsRedoTutorial.
  ///
  /// In fr, this message translates to:
  /// **'Revoir le tutoriel'**
  String get settingsRedoTutorial;

  /// No description provided for @settingsRedoTutorialSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Reprends la présentation depuis le début'**
  String get settingsRedoTutorialSubtitle;

  /// No description provided for @settingsDeleteData.
  ///
  /// In fr, this message translates to:
  /// **'Effacer mes données'**
  String get settingsDeleteData;

  /// No description provided for @deleteDataTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tout effacer ?'**
  String get deleteDataTitle;

  /// No description provided for @deleteDataMessage.
  ///
  /// In fr, this message translates to:
  /// **'Consommations, progression et réglages seront définitivement supprimés de cet appareil.'**
  String get deleteDataMessage;

  /// No description provided for @deleteAction.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get deleteAction;

  /// No description provided for @unlockMessagesLvl2Title.
  ///
  /// In fr, this message translates to:
  /// **'Le citron parle'**
  String get unlockMessagesLvl2Title;

  /// No description provided for @unlockMessagesLvl2Desc.
  ///
  /// In fr, this message translates to:
  /// **'Premiers messages personnalisés'**
  String get unlockMessagesLvl2Desc;

  /// No description provided for @unlockHistory7dTitle.
  ///
  /// In fr, this message translates to:
  /// **'Historique 7 jours'**
  String get unlockHistory7dTitle;

  /// No description provided for @unlockHistory7dDesc.
  ///
  /// In fr, this message translates to:
  /// **'Graphique de consommation débloqué'**
  String get unlockHistory7dDesc;

  /// No description provided for @unlockBadgeFirstStepTitle.
  ///
  /// In fr, this message translates to:
  /// **'Badge « Premier pas »'**
  String get unlockBadgeFirstStepTitle;

  /// No description provided for @unlockBadgeFirstStepDesc.
  ///
  /// In fr, this message translates to:
  /// **'Tu as commencé ton parcours'**
  String get unlockBadgeFirstStepDesc;

  /// No description provided for @unlockStateHappyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Citron heureux'**
  String get unlockStateHappyTitle;

  /// No description provided for @unlockStateHappyDesc.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel état visuel · bonne conso'**
  String get unlockStateHappyDesc;

  /// No description provided for @unlockWeeklyInsightTitle.
  ///
  /// In fr, this message translates to:
  /// **'Insight hebdomadaire'**
  String get unlockWeeklyInsightTitle;

  /// No description provided for @unlockWeeklyInsightDesc.
  ///
  /// In fr, this message translates to:
  /// **'Analyse de ta semaine'**
  String get unlockWeeklyInsightDesc;

  /// No description provided for @unlockStateTiredTitle.
  ///
  /// In fr, this message translates to:
  /// **'Citron fatigué'**
  String get unlockStateTiredTitle;

  /// No description provided for @unlockStateTiredDesc.
  ///
  /// In fr, this message translates to:
  /// **'État long terme visible'**
  String get unlockStateTiredDesc;

  /// No description provided for @unlockStatsAdvancedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Stats avancées'**
  String get unlockStatsAdvancedTitle;

  /// No description provided for @unlockStatsAdvancedDesc.
  ///
  /// In fr, this message translates to:
  /// **'Tendances et comparaisons'**
  String get unlockStatsAdvancedDesc;

  /// No description provided for @unlockBadgeRegularityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Badge « Régularité »'**
  String get unlockBadgeRegularityTitle;

  /// No description provided for @unlockBadgeRegularityDesc.
  ///
  /// In fr, this message translates to:
  /// **'30 jours d\'utilisation'**
  String get unlockBadgeRegularityDesc;

  /// No description provided for @unlockStateWiseTitle.
  ///
  /// In fr, this message translates to:
  /// **'Citron sage'**
  String get unlockStateWiseTitle;

  /// No description provided for @unlockStateWiseDesc.
  ///
  /// In fr, this message translates to:
  /// **'Expression rare, longue sobriété'**
  String get unlockStateWiseDesc;

  /// No description provided for @unlockSkinDarkTitle.
  ///
  /// In fr, this message translates to:
  /// **'Skin sombre'**
  String get unlockSkinDarkTitle;

  /// No description provided for @unlockSkinDarkDesc.
  ///
  /// In fr, this message translates to:
  /// **'Apparence alternative du citron'**
  String get unlockSkinDarkDesc;

  /// No description provided for @unlockMessagesDeepTitle.
  ///
  /// In fr, this message translates to:
  /// **'Messages profonds'**
  String get unlockMessagesDeepTitle;

  /// No description provided for @unlockMessagesDeepDesc.
  ///
  /// In fr, this message translates to:
  /// **'Réflexions sur ton chemin'**
  String get unlockMessagesDeepDesc;

  /// No description provided for @unlockBadgeMasterTitle.
  ///
  /// In fr, this message translates to:
  /// **'Badge « Maître citron »'**
  String get unlockBadgeMasterTitle;

  /// No description provided for @unlockBadgeMasterDesc.
  ///
  /// In fr, this message translates to:
  /// **'Rare et partageable'**
  String get unlockBadgeMasterDesc;

  /// No description provided for @unlockSkinSunglassesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Lunettes de soleil'**
  String get unlockSkinSunglassesTitle;

  /// No description provided for @unlockSkinSunglassesDesc.
  ///
  /// In fr, this message translates to:
  /// **'Le citron passe en mode star'**
  String get unlockSkinSunglassesDesc;

  /// No description provided for @unlockSkinPartyHatTitle.
  ///
  /// In fr, this message translates to:
  /// **'Chapeau de fête'**
  String get unlockSkinPartyHatTitle;

  /// No description provided for @unlockSkinPartyHatDesc.
  ///
  /// In fr, this message translates to:
  /// **'Pour célébrer chaque victoire'**
  String get unlockSkinPartyHatDesc;

  /// No description provided for @unlockSkinCrownTitle.
  ///
  /// In fr, this message translates to:
  /// **'Couronne'**
  String get unlockSkinCrownTitle;

  /// No description provided for @unlockSkinCrownDesc.
  ///
  /// In fr, this message translates to:
  /// **'La royauté se mérite'**
  String get unlockSkinCrownDesc;

  /// No description provided for @unlockSkinGoldTitle.
  ///
  /// In fr, this message translates to:
  /// **'Citron doré'**
  String get unlockSkinGoldTitle;

  /// No description provided for @unlockSkinGoldDesc.
  ///
  /// In fr, this message translates to:
  /// **'L\'éclat des grands parcours'**
  String get unlockSkinGoldDesc;

  /// No description provided for @badgeEquip.
  ///
  /// In fr, this message translates to:
  /// **'Équiper'**
  String get badgeEquip;

  /// No description provided for @badgeEquipped.
  ///
  /// In fr, this message translates to:
  /// **'✓ Équipé'**
  String get badgeEquipped;

  /// No description provided for @unlockGenericTitle.
  ///
  /// In fr, this message translates to:
  /// **'Surprise'**
  String get unlockGenericTitle;

  /// No description provided for @unlockGenericDesc.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau déblocage'**
  String get unlockGenericDesc;

  /// No description provided for @onboarding1Title.
  ///
  /// In fr, this message translates to:
  /// **'Voici Jaune'**
  String get onboarding1Title;

  /// No description provided for @onboarding1Text.
  ///
  /// In fr, this message translates to:
  /// **'Ton citron vit au rythme de ta consommation d\'alcool. Prends soin de lui, il te le rendra.'**
  String get onboarding1Text;

  /// No description provided for @onboarding2Title.
  ///
  /// In fr, this message translates to:
  /// **'Ta santé en un coup d\'œil'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Text.
  ///
  /// In fr, this message translates to:
  /// **'Loggue chaque verre d\'un tap. La barre de vie réagit, et les journées sobres te font gagner de l\'XP et des surprises.'**
  String get onboarding2Text;

  /// No description provided for @onboardingDisclaimer.
  ///
  /// In fr, this message translates to:
  /// **'Indicateur ludique inspiré des repères de l\'OMS, pas un avis médical.'**
  String get onboardingDisclaimer;

  /// No description provided for @onboardingDisclaimerAck.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai compris'**
  String get onboardingDisclaimerAck;

  /// No description provided for @onboardingScoringTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comment ça marche'**
  String get onboardingScoringTitle;

  /// No description provided for @onboardingScoringText.
  ///
  /// In fr, this message translates to:
  /// **'Chaque verre fait baisser les PV de ton citron. Les journées sobres lui rendent des PV, te font gagner de l\'XP et allongent ta série 🔥.'**
  String get onboardingScoringText;

  /// No description provided for @onboardingRankingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Défie tes amis'**
  String get onboardingRankingTitle;

  /// No description provided for @onboardingRankingText.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute tes amis et comparez vos jauges et vos séries. Le plus en forme prend la tête du classement.'**
  String get onboardingRankingText;

  /// No description provided for @onboarding3Title.
  ///
  /// In fr, this message translates to:
  /// **'Le BeJaune'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Text.
  ///
  /// In fr, this message translates to:
  /// **'Chaque jour à l\'apéro, une fenêtre s\'ouvre pour capturer ton moment et le partager.'**
  String get onboarding3Text;

  /// No description provided for @onboardingRemindersBenefit.
  ///
  /// In fr, this message translates to:
  /// **'Une notif te prévient pile à l\'apéro : tu ne rates jamais ton BeJaune ni ta série.'**
  String get onboardingRemindersBenefit;

  /// No description provided for @onboardingEnableReminders.
  ///
  /// In fr, this message translates to:
  /// **'Activer les rappels'**
  String get onboardingEnableReminders;

  /// No description provided for @onboardingRemindersEnabled.
  ///
  /// In fr, this message translates to:
  /// **'✓ Rappels activés'**
  String get onboardingRemindersEnabled;

  /// No description provided for @onboardingNext.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In fr, this message translates to:
  /// **'C\'est parti !'**
  String get onboardingStart;

  /// No description provided for @onboardingLater.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get onboardingLater;

  /// No description provided for @calendarEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ton premier jour commence ici'**
  String get calendarEmptyTitle;

  /// No description provided for @calendarEmptyText.
  ///
  /// In fr, this message translates to:
  /// **'Loggue tes verres et reviens voir ton mois prendre des couleurs.'**
  String get calendarEmptyText;

  /// No description provided for @a11yAddDrink.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un verre. {count} aujourd\'hui'**
  String a11yAddDrink(int count);

  /// No description provided for @a11yResetButton.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser les verres d\'aujourd\'hui'**
  String get a11yResetButton;

  /// No description provided for @a11yCalendarButton.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir le calendrier de consommation'**
  String get a11yCalendarButton;

  /// No description provided for @a11yHealthBar.
  ///
  /// In fr, this message translates to:
  /// **'{percent}% de santé, niveau {level}'**
  String a11yHealthBar(int percent, int level);

  /// No description provided for @a11yStreakBadge.
  ///
  /// In fr, this message translates to:
  /// **'{days} jours sobres d\'affilée, ouvrir la progression'**
  String a11yStreakBadge(int days);

  /// No description provided for @a11yCitron.
  ///
  /// In fr, this message translates to:
  /// **'Jaune, ton citron. Touche-le pour le saluer'**
  String get a11yCitron;

  /// No description provided for @a11yCapture.
  ///
  /// In fr, this message translates to:
  /// **'Prendre la photo BeJaune'**
  String get a11yCapture;

  /// No description provided for @notifStreakTitle.
  ///
  /// In fr, this message translates to:
  /// **'🔥 {days} jours sobres !'**
  String notifStreakTitle(int days);

  /// No description provided for @notifStreakBody.
  ///
  /// In fr, this message translates to:
  /// **'Ton citron rayonne. Viens le voir briller !'**
  String get notifStreakBody;

  /// No description provided for @notifLevelTeaserTitle.
  ///
  /// In fr, this message translates to:
  /// **'⚡ Niveau {level} en vue !'**
  String notifLevelTeaserTitle(int level);

  /// No description provided for @notifLevelTeaserBody.
  ///
  /// In fr, this message translates to:
  /// **'Plus que {xp} XP, une journée sobre et c\'est dans la poche.'**
  String notifLevelTeaserBody(int xp);

  /// No description provided for @badgeGalleryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Collection'**
  String get badgeGalleryTitle;

  /// No description provided for @badgeGalleryViewAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir toute la collection'**
  String get badgeGalleryViewAll;

  /// No description provided for @badgeLockedLevel.
  ///
  /// In fr, this message translates to:
  /// **'Niveau {level}'**
  String badgeLockedLevel(int level);

  /// No description provided for @streakCountdown.
  ///
  /// In fr, this message translates to:
  /// **'J-{days} avant le palier {target} 🔥'**
  String streakCountdown(int days, int target);

  /// No description provided for @statsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques'**
  String get statsTitle;

  /// No description provided for @statsLast7Days.
  ///
  /// In fr, this message translates to:
  /// **'7 derniers jours'**
  String get statsLast7Days;

  /// No description provided for @statsThisWeek.
  ///
  /// In fr, this message translates to:
  /// **'Cette semaine'**
  String get statsThisWeek;

  /// No description provided for @statsLastWeek.
  ///
  /// In fr, this message translates to:
  /// **'Semaine dernière'**
  String get statsLastWeek;

  /// No description provided for @statsDrinksCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 verre} =1{1 verre} other{{count} verres}}'**
  String statsDrinksCount(int count);

  /// No description provided for @statsTrendDown.
  ///
  /// In fr, this message translates to:
  /// **'−{percent}% vs période précédente 💪'**
  String statsTrendDown(int percent);

  /// No description provided for @statsTrendUp.
  ///
  /// In fr, this message translates to:
  /// **'+{percent}% vs période précédente'**
  String statsTrendUp(int percent);

  /// No description provided for @statsTrendFlat.
  ///
  /// In fr, this message translates to:
  /// **'Stable vs période précédente'**
  String get statsTrendFlat;

  /// No description provided for @statsHealthTrend.
  ///
  /// In fr, this message translates to:
  /// **'Évolution de ta santé'**
  String get statsHealthTrend;

  /// No description provided for @statsHealthTrendHint.
  ///
  /// In fr, this message translates to:
  /// **'Santé de fond sur les 30 derniers jours'**
  String get statsHealthTrendHint;

  /// No description provided for @statsRecords.
  ///
  /// In fr, this message translates to:
  /// **'Records'**
  String get statsRecords;

  /// No description provided for @statsLongestStreak.
  ///
  /// In fr, this message translates to:
  /// **'Plus longue série sobre'**
  String get statsLongestStreak;

  /// No description provided for @statsLightestWeek.
  ///
  /// In fr, this message translates to:
  /// **'Semaine la plus légère'**
  String get statsLightestWeek;

  /// No description provided for @statsDrinksAvoided.
  ///
  /// In fr, this message translates to:
  /// **'Verres évités'**
  String get statsDrinksAvoided;

  /// No description provided for @statsAvoidedHint.
  ///
  /// In fr, this message translates to:
  /// **'vs ton rythme des 4 premières semaines'**
  String get statsAvoidedHint;

  /// No description provided for @statsShare.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get statsShare;

  /// No description provided for @statsHeroStreak.
  ///
  /// In fr, this message translates to:
  /// **'jours sobres d\'affilée'**
  String get statsHeroStreak;

  /// No description provided for @statsHpUnit.
  ///
  /// In fr, this message translates to:
  /// **'PV'**
  String get statsHpUnit;

  /// No description provided for @statsPeriodWeek.
  ///
  /// In fr, this message translates to:
  /// **'Semaine'**
  String get statsPeriodWeek;

  /// No description provided for @statsPeriodMonth.
  ///
  /// In fr, this message translates to:
  /// **'Mois'**
  String get statsPeriodMonth;

  /// No description provided for @statsPeriodYear.
  ///
  /// In fr, this message translates to:
  /// **'Année'**
  String get statsPeriodYear;

  /// No description provided for @statsPeriodAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get statsPeriodAll;

  /// No description provided for @statsConsumptionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Consommation'**
  String get statsConsumptionTitle;

  /// No description provided for @statsUnitPerDay.
  ///
  /// In fr, this message translates to:
  /// **'Verres par jour'**
  String get statsUnitPerDay;

  /// No description provided for @statsUnitPerMonth.
  ///
  /// In fr, this message translates to:
  /// **'Verres par mois'**
  String get statsUnitPerMonth;

  /// No description provided for @statsHealthScrubHint.
  ///
  /// In fr, this message translates to:
  /// **'Glisse ton doigt sur la courbe pour voir chaque jour'**
  String get statsHealthScrubHint;

  /// No description provided for @statsSoberTitle.
  ///
  /// In fr, this message translates to:
  /// **'Jours sobres'**
  String get statsSoberTitle;

  /// No description provided for @statsSoberSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Sur la période sélectionnée'**
  String get statsSoberSubtitle;

  /// No description provided for @statsSoberCount.
  ///
  /// In fr, this message translates to:
  /// **'{sober, plural, =1{1 jour sobre sur {total}} other{{sober} jours sobres sur {total}}}'**
  String statsSoberCount(int sober, int total);

  /// No description provided for @statsMilestoneTitle.
  ///
  /// In fr, this message translates to:
  /// **'Objectifs de série'**
  String get statsMilestoneTitle;

  /// No description provided for @statsMilestoneReached.
  ///
  /// In fr, this message translates to:
  /// **'Objectif maximum atteint, tu es une légende 🔥'**
  String get statsMilestoneReached;

  /// No description provided for @statsMilestoneCaption.
  ///
  /// In fr, this message translates to:
  /// **'{remaining, plural, =1{Plus qu\'un jour sobre pour atteindre l\'objectif {target} 🔥} other{Plus que {remaining} jours sobres pour atteindre l\'objectif {target} 🔥}}'**
  String statsMilestoneCaption(int remaining, int target);

  /// No description provided for @statsWeekdayTitle.
  ///
  /// In fr, this message translates to:
  /// **'Par jour de la semaine'**
  String get statsWeekdayTitle;

  /// No description provided for @statsWeekdaySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Moyenne de verres par jour, ton jour à risque ressort'**
  String get statsWeekdaySubtitle;

  /// No description provided for @statsHeatmapTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ton historique'**
  String get statsHeatmapTitle;

  /// No description provided for @statsHeatmapSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Chaque carré = un jour. Vert = sobre, rouge = chargé.'**
  String get statsHeatmapSubtitle;

  /// No description provided for @statsHeatmapLess.
  ///
  /// In fr, this message translates to:
  /// **'Sobre'**
  String get statsHeatmapLess;

  /// No description provided for @statsHeatmapMore.
  ///
  /// In fr, this message translates to:
  /// **'Chargé'**
  String get statsHeatmapMore;

  /// No description provided for @statsAllTimeSection.
  ///
  /// In fr, this message translates to:
  /// **'Depuis le début'**
  String get statsAllTimeSection;

  /// No description provided for @statsTotalSoberDays.
  ///
  /// In fr, this message translates to:
  /// **'Total de jours sobres'**
  String get statsTotalSoberDays;

  /// No description provided for @statsShareCaption.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 jour sobre au total} other{{count} jours sobres au total}}'**
  String statsShareCaption(int count);

  /// No description provided for @statsInsightTrendDown.
  ///
  /// In fr, this message translates to:
  /// **'−{percent}% vs la période précédente, continue comme ça 🎉'**
  String statsInsightTrendDown(int percent);

  /// No description provided for @statsInsightTrendUp.
  ///
  /// In fr, this message translates to:
  /// **'+{percent}% vs la période précédente, reprends la main 💪'**
  String statsInsightTrendUp(int percent);

  /// No description provided for @statsInsightBestStreak.
  ///
  /// In fr, this message translates to:
  /// **'{days, plural, =1{Record en cours : 1 jour sobre 🔥} other{Record en cours : {days} jours sobres 🔥}}'**
  String statsInsightBestStreak(int days);

  /// No description provided for @statsInsightSoberRate.
  ///
  /// In fr, this message translates to:
  /// **'{percent}% de jours sobres sur la période 💧'**
  String statsInsightSoberRate(int percent);

  /// No description provided for @statsInsightWorstWeekday.
  ///
  /// In fr, this message translates to:
  /// **'Ton jour le plus chargé : {day}'**
  String statsInsightWorstWeekday(String day);

  /// No description provided for @statsInsightGettingStarted.
  ///
  /// In fr, this message translates to:
  /// **'Continue à logguer, tes stats vont s\'affiner 🍋'**
  String get statsInsightGettingStarted;

  /// No description provided for @a11yStatsButton.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir les statistiques'**
  String get a11yStatsButton;

  /// No description provided for @shareAction.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get shareAction;

  /// No description provided for @leaderboardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Classement'**
  String get leaderboardTitle;

  /// No description provided for @leaderboardTabRanking.
  ///
  /// In fr, this message translates to:
  /// **'Classement'**
  String get leaderboardTabRanking;

  /// No description provided for @leaderboardTabRequests.
  ///
  /// In fr, this message translates to:
  /// **'Demandes'**
  String get leaderboardTabRequests;

  /// No description provided for @leaderboardAddFriend.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un ami'**
  String get leaderboardAddFriend;

  /// No description provided for @leaderboardAccept.
  ///
  /// In fr, this message translates to:
  /// **'Accepter'**
  String get leaderboardAccept;

  /// No description provided for @leaderboardIgnore.
  ///
  /// In fr, this message translates to:
  /// **'Ignorer'**
  String get leaderboardIgnore;

  /// No description provided for @leaderboardEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Personne au classement'**
  String get leaderboardEmptyTitle;

  /// No description provided for @leaderboardEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute un ami pour comparer vos jauges et vos séries.'**
  String get leaderboardEmptySubtitle;

  /// No description provided for @leaderboardNoRequestsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune demande'**
  String get leaderboardNoRequestsTitle;

  /// No description provided for @leaderboardNoRequestsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Les demandes d\'amitié reçues apparaîtront ici.'**
  String get leaderboardNoRequestsSubtitle;

  /// No description provided for @leaderboardManageTitle.
  ///
  /// In fr, this message translates to:
  /// **'Amis'**
  String get leaderboardManageTitle;

  /// No description provided for @leaderboardYourFriends.
  ///
  /// In fr, this message translates to:
  /// **'Mes amis'**
  String get leaderboardYourFriends;

  /// No description provided for @leaderboardRemoveFriend.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get leaderboardRemoveFriend;

  /// No description provided for @leaderboardRemoveFriendTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retirer cet ami ?'**
  String get leaderboardRemoveFriendTitle;

  /// No description provided for @leaderboardRemoveFriendMessage.
  ///
  /// In fr, this message translates to:
  /// **'{name} ne sera plus dans ton classement. Il faudra une nouvelle demande pour vous réajouter.'**
  String leaderboardRemoveFriendMessage(String name);

  /// No description provided for @leaderboardRemoveFriendConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get leaderboardRemoveFriendConfirm;

  /// No description provided for @a11yLeaderboardButton.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir le classement entre amis'**
  String get a11yLeaderboardButton;

  /// No description provided for @addFriendTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute un ami'**
  String get addFriendTitle;

  /// No description provided for @addFriendSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Fais scanner ton QR code, ou partage ton lien d\'invitation.'**
  String get addFriendSubtitle;

  /// No description provided for @addFriendShare.
  ///
  /// In fr, this message translates to:
  /// **'Partager mon lien'**
  String get addFriendShare;

  /// No description provided for @addFriendScan.
  ///
  /// In fr, this message translates to:
  /// **'Scanner un QR code'**
  String get addFriendScan;

  /// No description provided for @addFriendScanTitle.
  ///
  /// In fr, this message translates to:
  /// **'Scanne le code d\'un ami'**
  String get addFriendScanTitle;

  /// No description provided for @addFriendScanHint.
  ///
  /// In fr, this message translates to:
  /// **'Aligne le QR code dans le cadre'**
  String get addFriendScanHint;

  /// No description provided for @addFriendScanTorch.
  ///
  /// In fr, this message translates to:
  /// **'Lampe torche'**
  String get addFriendScanTorch;

  /// No description provided for @addFriendScanError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir la caméra'**
  String get addFriendScanError;

  /// No description provided for @addFriendScanPermission.
  ///
  /// In fr, this message translates to:
  /// **'Autorise l\'accès à la caméra dans les réglages de ton téléphone pour scanner un code.'**
  String get addFriendScanPermission;

  /// No description provided for @addFriendScanRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get addFriendScanRetry;

  /// No description provided for @addFriendShareMessage.
  ///
  /// In fr, this message translates to:
  /// **'Rejoins-moi sur Jaune et comparons nos jauges ! {link}'**
  String addFriendShareMessage(String link);

  /// No description provided for @usernamePromptTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisis ton pseudo'**
  String get usernamePromptTitle;

  /// No description provided for @usernamePromptSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'C\'est le nom que verront tes amis dans le classement.'**
  String get usernamePromptSubtitle;

  /// No description provided for @usernamePromptHint.
  ///
  /// In fr, this message translates to:
  /// **'Ton pseudo'**
  String get usernamePromptHint;

  /// No description provided for @usernamePromptSave.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get usernamePromptSave;
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
