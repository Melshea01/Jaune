# Animation du Citron — moteur procédural maison

⚠️ **Le Citron n'est PAS du Rive ni un GIF.** C'est un personnage **animé par code**, en temps réel, via un moteur de ressorts + poses + événements. Pour « créer une nouvelle animation », on écrit du **Dart**, pas de l'art externe.

## Pièces

- `events/motion_events.dart` — **catalogue des `MotionEvent`** (animations one-shot). Un `MotionEvent` = `name`, `duration`, et `sample(double progress)` qui renvoie une map de transformations **additives** :
  - `hopY` (px, **+ = vers le bas**), `scaleX`, `scaleY`, `swayRad` (rotation, radians).
  - Le moteur applique une enveloppe de blend-in/out (~80 ms) et crossfade au retrigger ; on garde l'identité aux bornes par hygiène (anticipation → action → retombée).
- `citron_engine.dart` — le moteur : ressorts scalaires par membre, composition de frame, **idle** (`_idlePools` par humeur → events spontanés), `triggerEvent(name)`.
- `poses/` — `citron_pose.dart`, `citron_moods.dart` (expressions/humeurs, glow…), `pose_catalog.dart`.
- `core/` — `spring_value.dart` (ressort amorti), `oscillator.dart`.
- `../controllers/citron_animation_controller.dart` — façade UI (`triggerEvent`, `hasActiveEvent`, glow…). C'est ce que `main.dart` appelle (`_citronController`).
- Rendu : `../widgets/citron_character.dart` / `citron_avatar.dart` / `citron_aura.dart` / `citron_particles.dart`.

## Ajouter une animation

1. Définir un `MotionEvent` dans `MotionEvents` (suivre les patrons existants : `jumpJoy`, `wave`, `pirouette`…). `hopY +` descend ; un tour complet = `swayRad` qui va de `0` à `2*pi`.
2. L'**enregistrer dans la liste `_byName`** (sinon `triggerEvent` le logge comme « inconnu » et l'ignore — sans planter).
3. Le **déclencher** : `_citronController.triggerEvent('mon_event')` depuis `main.dart` (tap, récompense…), et/ou l'ajouter aux `_idlePools` de `citron_engine.dart` pour qu'il survienne spontanément.

Animations existantes notables : `jump_joy`, `mega_jump` (level-up), `double_jump`, `badge_proud`, `drink_beer`, `shiver`, `curious`, `wave`, `dance`, `pirouette`, `nod`, `wiggle`, `backflip`, `sleepy`.

## Skins

`../services/citron_skins.dart` : un skin est soit un **accessoire SVG** (`SkinKind.accessory`, asset dans `../../assets/skins/`, ancré `body` ou `face`), soit une **variante de couleur** (`SkinKind.colorVariant`, matrice 4×5). Le **canvas SVG** est en `viewBox="-10 -20 420 440"` ; repères visage : yeux ≈ (186, 180) et (237, 180). La **clé** d'un skin doit correspondre à la clé du déblocable dans `journey_data.dart`.

## Panneau de debug

`../widgets/citron_debug_panel.dart` liste les events pour les tester un à un.
