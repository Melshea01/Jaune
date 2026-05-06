/// Example usage of the complete animation system
/// 
/// The CitronAnimationController provides 3 main APIs:

import 'controllers/citron_animation_controller.dart';
import 'models/health_animation_map.dart';
import 'models/special_animation_map.dart';
import 'models/animation_events.dart';

void demonstrateAnimationSystem(CitronAnimationController controller) {
  // ========== 1. Health-based animations (automatic) ==========
  // When health changes, these are applied automatically in _updateRiveState():
  
  // HP 100 → superHappy (bouncy, excited)
  controller.updateHealth(100);
  
  // HP 75 → happy (content, playful)
  controller.updateHealth(75);
  
  // HP 50 → neutral (normal, calm)
  controller.updateHealth(50);
  
  // HP 25 → tired (sleepy, sluggish)
  controller.updateHealth(25);
  
  // HP 0 → dead (collapsed, lifeless)
  controller.updateHealth(0);
  

  // ========== 2. Special behavior animations ==========
  // Play a specific animation on top of current health preset:
  
  // User got drunk
  controller.playSpecialAnimation('drunk'); // Returns true if found
  
  // User is now walking
  controller.playSpecialAnimation('walking');
  
  // User triggered panic
  controller.playSpecialAnimation('panicMode');
  
  // User is levitating (easter egg)
  controller.playSpecialAnimation('levitation');
  
  // Check if animation was available
  bool success = controller.playSpecialAnimation('unknownAnimation');
  if (!success) {
    print('Animation not found');
  }
  

  // ========== 3. One-shot event animations ==========
  // Trigger momentary events with specific durations:
  
  // User completed daily goal - jump of joy
  final event = controller.triggerEvent('jump_joy');
  if (event != null) {
    print('Event: ${event.name} → ${event.duration.inMilliseconds}ms');
    // Overlay this event's animation on top of current state
    // The CitronCharacter widget can apply event.update() callbacks
  }
  
  // User got scared
  controller.triggerEvent('scared'); // 350ms startle animation
  
  // User had hiccup
  controller.triggerEvent('hiccup'); // 200ms involuntary twitch
  
  // User is curious
  controller.triggerEvent('curious'); // 2500ms head tilt exploration
  

  // ========== Integration in main app ==========
  // Currently integrated in lib/main.dart:
  // - _updateRiveState() calls: controller.updateHealth() automatically
  // - CitronCharacter receives controller and renders in 60 FPS loop
  // - Special animations and events can be triggered from any state
}

/// Complete catalog of 42+ animations:
/// 
/// Health Presets (6):
/// - superHappy (HP 85-100)
/// - happy (HP 70-84)
/// - neutral (HP 50-69)
/// - tired (HP 30-49)
/// - sick (HP 1-29)
/// - dead (HP 0)
/// 
/// Special Animations (22):
/// Alcohol: tipsy, drunk, wasted, hungover
/// Wellness: recovery, dehydrated, zen, asleep, pulse
/// Events: loading, bored, digest, secretDance, greeting
/// Movement: walking, sprinting, panicMode, workout, freezing, overheating, levitation
/// 
/// One-Shot Events (14):
/// Joy: jump_joy (1s), double_jump (1.2s), mega_jump (1.8s), badge_proud (2s)
/// Alert: shiver (150ms), scared (350ms), craquage (800ms), hiccup (200ms)
/// Emotion: encourage (600ms), curious (2.5s), willpower (1s), craving (2s)
/// Gameplay: coin_spin (800ms), drink_beer (1.4s)
