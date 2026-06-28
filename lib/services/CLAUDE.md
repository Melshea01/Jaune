# Services — gamification, données, santé

## Gamification : « Le Voyage du Citron »

Cœur dans `character_service.dart` + `journey_data.dart`.

### `journey_data.dart` — les 100 niveaux (source de vérité)
- **5 mondes / arènes** (`kChapters`) : Le Verger (1-20), La Côte (21-40), Les Sommets (41-60), La Ville (61-80), Les Étoiles (81-100). Chacun a couleur + emoji.
- **`kLevelUnlocks`** : 100 `LevelUnlock`, un par niveau. Chaque entrée porte `type` (`lore` / `collectible` / `citronState` / `feature` / `badge`), `key`, `icon` (emoji), et **titre/description bilingues en dur** (`titleFr/En`, `descFr/En`). Pas de clés l10n pour ce contenu — il vit dans la donnée (ça scale à 100+).
- Résolution d'affichage : `l10n_helpers.unlockTitle(unlock, fr)` / `unlockDescription(unlock, fr)`.
- **Contrainte** : un `LevelUnlock` de type `citronState` doit avoir une `key` qui existe dans `citron_skins.dart` (sinon l'équipement casse). Le test `test/journey_data_test.dart` blinde ça (1..100 sans trou, chapitres contigus, skins valides).
- `character_service.dart` fait `export 'journey_data.dart'` → les imports existants de `character_service.dart` voient `LevelUnlock`, `kLevelUnlocks`, `kChapters`, `chapterOfLevel`, `chapterColorOf`.

### `character_service.dart` — XP, progression, mécaniques
- `CharacterProfile` (POJO sérialisé JSON via SharedPreferences, clé `character_profile`). Champs : xp, level, PV, série sobre, **boucliers** (`streakShields` + `frozenDays`), **quêtes** (`lastQuestDate`, `completedQuestIds`), `lastWeeklyGoalDate`, `hasOpenedJourney`, skin équipé… **Tout nouveau champ → défaut dans `fromJson`** (rétrocompat).
- `xpRequiredForLevel(level)` : courbe par paliers (premiers niveaux peu chers = accroche ; niv. 100 = long terme).
- **Série sobre** : `computeSoberStreak(dailyMap)` **dérivée du calendrier** (idempotente). Un **bouclier** (`_maybeConsumeShield`) ponte un écart *isolé* d'hier pour ne pas casser la série (anti « tout ou rien »). Boucliers gagnés via semaine parfaite / objectif hebdo, plafonnés (`kMaxShields`).
- **Quêtes du jour** : `kDailyQuests`, sélection déterministe par date, évaluées dans `awardDailyLogXp` / `awardAppOpenXp`.
- **Objectif hebdo** : `weeklyGoal(dailyMap)` → anneau ; récompense XP + bouclier 1×/sem.
- **XP variable** : `_award(base)` applique une variance haussière bornée (0..+20 %, jamais punitif).
- Les gains sont émis en `XpEvent` (toasts via `../widgets/xp_toast.dart`) ; `main.dart` boucle dessus (haptique/son/animation citron) et déclenche la célébration (`../widgets/level_up_celebration.dart`).

UI associée : `../widgets/level_sheet.dart` (**`LevelScreen.open()`**, page plein écran « parcours »), `badge_gallery_sheet.dart` (collection par mondes), `streak_badge.dart`, `xp_toast.dart`.

## Autres services

- `storage_service.dart` — `dailyMap` (date→verres) + `drinkTimes`. **La** source des données de conso.
- `jaune_health_model.dart` — PV depuis l'historique (calibré OMS). Indicateur ludique, pas médical.
- `citron_skins.dart` — registre des skins (cf. `lib/animation/CLAUDE.md`).
- `stats_service.dart` — agrégats (7 jours, comparaison semaine, plus longue série…).
- `friends_service.dart` (+ `mock_` / `supabase_`) — classement entre amis, identifiant anonyme.
- `notification_service.dart` / `milestone_scheduler.dart` / `deterministic_scheduler.dart` — rappels & rétention.
- `home_widget_service.dart` — sync widget iOS. `audio_service.dart` — sons. `settings_service.dart` — réglages.

## Règles

- Dates : toujours `utils/date_keys.dart` (`dateKey`).
- Ne jamais réintroduire un compteur de série incrémental : tout se **dérive** du calendrier.
- Logique pure testable → ajouter au besoin dans `test/` (mock SharedPreferences).
