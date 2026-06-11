import 'package:flutter/foundation.dart';

import '../animation/citron_engine.dart';
import '../animation/events/motion_events.dart';
import '../animation/poses/citron_moods.dart';

/// Façade publique du moteur d'animation du citron.
///
/// L'ancienne implémentation (9 LayerControllers + lerp à durée fixe +
/// `sin(temps_absolu × vitesse)`) vivait ici ; tout le mouvement est
/// désormais dans [CitronEngine] (springs critiquement amortis + phase
/// intégrée). Cette classe conserve l'API historique pour main.dart et
/// le panneau de debug.
class CitronAnimationController extends ChangeNotifier {
  final CitronEngine engine = CitronEngine();

  // ─── Échelle de temps (slider du debug panel) ─────────────────────────

  double get speedFactor => engine.timeScale;

  void setSpeedFactor(double factor) {
    engine.timeScale = factor.clamp(0.05, 4.0);
    notifyListeners();
  }

  // ─── Humeur des micro-comportements d'idle ────────────────────────────

  String get idleMood => engine.idleMood;
  set idleMood(String mood) => engine.idleMood = mood;

  // ─── États continus ───────────────────────────────────────────────────

  /// Applique une recette { couche → nom de pose }.
  /// Les transitions sont gérées par springs : interruption fluide garantie,
  /// plus de paramètre de durée.
  void setAnimation(Map<String, String> config) {
    engine.applyRecipe(config);
    notifyListeners();
  }

  /// Joue une animation spéciale par nom (tipsy, greeting, secretDance…)
  /// Applique la recette de mouvement ET son style visuel (teinte, flush,
  /// aura, particules).
  bool playSpecialAnimation(String name) {
    final recipe = CitronMoods.specials[name];
    if (recipe == null) {
      debugPrint('⚠️ Special animation not found: $name');
      return false;
    }
    engine.applyRecipe(recipe, tempo: CitronMoods.tempos[name] ?? 1.0);
    engine.applyStyle(CitronMoods.specialStyles[name] ?? MoodStyle.neutral);
    notifyListeners();
    return true;
  }

  /// Applique le preset correspondant à la santé (0-100) :
  /// mouvement + style visuel (le citron pâlit/rayonne avec sa santé)
  void updateHealth(int health) {
    engine.applyHealth(health);
    engine.applyStyle(CitronMoods.healthStyle(health));
    notifyListeners();
  }

  /// Flash d'aura (level-up)
  void kickGlow() => engine.kickGlow();

  // ─── Événements one-shot ──────────────────────────────────────────────

  /// Déclenche un événement one-shot (jump_joy, drink_beer…).
  /// Retourne l'événement si trouvé, null sinon.
  MotionEvent? triggerEvent(String name) => engine.triggerEvent(name);

  bool get hasActiveEvent => engine.hasActiveEvent;

  // ─── Lectures d'état (debug / introspection) ──────────────────────────

  double get blinkAmount => engine.blinkAmount;
  double get eyeLookX => engine.eyeLookX;
}
