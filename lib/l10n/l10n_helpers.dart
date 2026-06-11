import '../services/character_service.dart';
import 'gen/app_localizations.dart';

/// Localisation des données de gamification : les services restent en pure
/// data (clés stables), l'UI résout les libellés ici.

String xpReasonLabel(AppLocalizations l10n, XpEvent event) =>
    switch (event.reason) {
      XpReason.appOpen => l10n.xpReasonAppOpen,
      XpReason.dailyLog => l10n.xpReasonDailyLog,
      XpReason.soberYesterday => l10n.xpReasonSoberYesterday,
      XpReason.greenDay => l10n.xpReasonGreenDay,
      XpReason.soberStreak => l10n.soberStreakInARow(event.value ?? 0),
      XpReason.perfectWeek => l10n.xpReasonPerfectWeek,
    };

String rankTitle(AppLocalizations l10n, int level) => switch (level) {
  <= 5 => l10n.rankApprentice,
  <= 15 => l10n.rankExplorer,
  <= 30 => l10n.rankMaster,
  _ => l10n.rankLegend,
};

String phaseLabel(AppLocalizations l10n, String phase) => switch (phase) {
  'discovery' => l10n.phaseDiscovery,
  'engagement' => l10n.phaseEngagement,
  _ => l10n.phaseMastery,
};

String unlockTitle(AppLocalizations l10n, LevelUnlock unlock) =>
    switch (unlock.key) {
      'messages_lvl2' => l10n.unlockMessagesLvl2Title,
      'history_7d' => l10n.unlockHistory7dTitle,
      'badge_first_step' => l10n.unlockBadgeFirstStepTitle,
      'state_happy' => l10n.unlockStateHappyTitle,
      'weekly_insight' => l10n.unlockWeeklyInsightTitle,
      'state_tired' => l10n.unlockStateTiredTitle,
      'stats_advanced' => l10n.unlockStatsAdvancedTitle,
      'badge_regularity' => l10n.unlockBadgeRegularityTitle,
      'state_wise' => l10n.unlockStateWiseTitle,
      'skin_sunglasses' => l10n.unlockSkinSunglassesTitle,
      'skin_party_hat' => l10n.unlockSkinPartyHatTitle,
      'skin_crown' => l10n.unlockSkinCrownTitle,
      'skin_gold' => l10n.unlockSkinGoldTitle,
      'skin_dark' => l10n.unlockSkinDarkTitle,
      'messages_deep' => l10n.unlockMessagesDeepTitle,
      'badge_master' => l10n.unlockBadgeMasterTitle,
      _ => l10n.unlockGenericTitle,
    };

String unlockDescription(AppLocalizations l10n, LevelUnlock unlock) =>
    switch (unlock.key) {
      'messages_lvl2' => l10n.unlockMessagesLvl2Desc,
      'history_7d' => l10n.unlockHistory7dDesc,
      'badge_first_step' => l10n.unlockBadgeFirstStepDesc,
      'state_happy' => l10n.unlockStateHappyDesc,
      'weekly_insight' => l10n.unlockWeeklyInsightDesc,
      'state_tired' => l10n.unlockStateTiredDesc,
      'stats_advanced' => l10n.unlockStatsAdvancedDesc,
      'badge_regularity' => l10n.unlockBadgeRegularityDesc,
      'state_wise' => l10n.unlockStateWiseDesc,
      'skin_sunglasses' => l10n.unlockSkinSunglassesDesc,
      'skin_party_hat' => l10n.unlockSkinPartyHatDesc,
      'skin_crown' => l10n.unlockSkinCrownDesc,
      'skin_gold' => l10n.unlockSkinGoldDesc,
      'skin_dark' => l10n.unlockSkinDarkDesc,
      'messages_deep' => l10n.unlockMessagesDeepDesc,
      'badge_master' => l10n.unlockBadgeMasterDesc,
      _ => l10n.unlockGenericDesc,
    };
