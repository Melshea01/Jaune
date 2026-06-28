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
      XpReason.questComplete => l10n.xpReasonQuestComplete,
      XpReason.weeklyGoal => l10n.xpReasonWeeklyGoal,
    };

String questTitle(AppLocalizations l10n, DailyQuest quest) =>
    switch (quest.type) {
      QuestType.openApp => l10n.questOpenAppTitle,
      QuestType.logToday => l10n.questLogTodayTitle,
      QuestType.soberToday => l10n.questSoberTodayTitle,
      QuestType.underTwoToday => l10n.questUnderTwoTitle,
      QuestType.keepStreak => l10n.questKeepStreakTitle,
    };

/// Titre/description du déblocable — contenu bilingue porté par la donnée
/// (cf. journey_data.dart), résolu selon la langue active.
String unlockTitle(LevelUnlock unlock, bool fr) =>
    fr ? unlock.titleFr : unlock.titleEn;

String unlockDescription(LevelUnlock unlock, bool fr) =>
    fr ? unlock.descFr : unlock.descEn;

/// Nom localisé d'un chapitre/monde du voyage.
String chapterName(JourneyChapter chapter, bool fr) => chapter.name(fr);
