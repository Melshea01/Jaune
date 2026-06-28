# Jaune — guide projet

App Flutter (mobile) qui aide à **suivre et réduire sa consommation d'alcool**, gamifiée autour d'une mascotte citron (« le Citron »). Chaque verre se logge en un tap ; une **barre de vie** (inspirée des repères OMS, pas un avis médical) reflète la conso, et des **journées sobres** font gagner de l'XP, monter de niveau et débloquer des récompenses.

- **Nom / version** : `jaune`, voir `pubspec.yaml` (`version:`). SDK Dart `^3.7.0`, Flutter.
- **Langue du code** : **français** (commentaires, messages de commit, libellés). Garde ce ton.
- **Vision produit** (voir aussi la mémoire `niveau-redesign.md`) : qualité « Apple Design Award », gamification addictive mais saine, **MVP strict**, **ne rien supprimer** sans raison.

## Lancer / vérifier

Flutter n'est **pas** dans le PATH par défaut. SDK : `~/Development/flutter/bin`.

```bash
export PATH="$HOME/Development/flutter/bin:$PATH"
flutter run                 # lancer sur simulateur/appareil
dart analyze lib/ test/     # lint (doit être « No issues found! »)
flutter test                # suite de tests (package:flutter_test)
flutter gen-l10n            # régénérer les localisations après édition des .arb
```

## Localisation (l10n)

- Config : `l10n.yaml` → sortie dans `lib/l10n/gen/`. `nullable-getter: false`.
- **Template = `lib/l10n/app_fr.arb`**, traduction = `lib/l10n/app_en.arb`.
- Ajouter une clé : l'écrire dans **les deux** `.arb`, puis `flutter gen-l10n`. Les placeholders nécessitent un bloc `@maClé` (cf. exemples existants).
- Les libellés de gamification (rangs, déblocables…) sont résolus par helpers dans `lib/l10n/l10n_helpers.dart`.

## Architecture

Pas de framework de state management externe. Une grosse page `StatefulWidget` (`MyHomePage` dans `lib/main.dart`) orchestre des **services** (proches du singleton). Persistance via **SharedPreferences**.

- **Données de conso** — `lib/services/storage_service.dart` : `dailyMap` (clé date `yyyy-MM-dd` → nombre de verres) + `drinkTimes`. Source pour la santé, les stats, les séries.
- **Profil joueur** — `lib/services/character_service.dart` : `CharacterProfile` (xp, level, PV, série sobre, boucliers, quêtes…) sérialisé en JSON. **Tout est dérivé du calendrier** (série, santé) → recalcul idempotent, pas de compteur incrémental fragile.
- **Santé** — `lib/services/jaune_health_model.dart` : PV calculés depuis l'historique (calibré OMS).
- **Gamification « Le Voyage du Citron »** — voir `lib/services/CLAUDE.md`.
- **Mascotte (animation)** — moteur procédural maison, **pas du Rive**. Voir `lib/animation/CLAUDE.md`.
- **Social** — classement entre amis (Supabase, identifiant anonyme) : `friends_service.dart` + `mock_friends_service.dart` / `supabase_friends_service.dart`.
- **Notifications / rétention** — `notification_service.dart`, `milestone_scheduler.dart`, `deterministic_scheduler.dart`.
- **Widget écran d'accueil iOS** — `home_widget_service.dart`.
- **Clés de date** — toujours via `lib/utils/date_keys.dart` (`dateKey`), jamais d'autre format.

## Design system

Source unique : `lib/theme/jaune_design.dart` — `JauneColors`, `JauneMotion` (durées/courbes), `JauneRadii`. **Toute nouvelle UI doit y piocher** plutôt que de redéfinir couleurs/durées. Identité : ciel bleu + citron jaune.

## Conventions

- Réutilise l'existant (widgets `pressable.dart`, `draggable_sheet.dart`, helpers, tokens) avant d'écrire du neuf.
- Tests sur la logique pure (`SharedPreferences.setMockInitialValues({})` en `setUp`). Exemples : `test/character_progression_test.dart`, `test/journey_data_test.dart`.
- Rétrocompat de persistance : tout nouveau champ de profil doit avoir un défaut (`?? 0` / `?? ''` / `?? []`) dans `fromJson`.
- Travaille sur une branche de feature (actuelle : `feat/mvp`), pas sur `main`. Commits en français, terminés par la ligne `Co-Authored-By` Claude.

## Mémoire persistante

Des notes de contexte vivent dans `~/.claude/projects/-Users-sachamontel-Development-Jaune/memory/` (index `MEMORY.md`). Notamment `niveau-redesign.md` (refonte de la section niveau) et `jaune-product-vision.md`.
