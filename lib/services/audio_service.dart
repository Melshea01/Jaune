import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import 'settings_service.dart';

/// Sons de l'app. Singleton : accessible depuis les célébrations et les
/// sheets sans faire circuler d'instance. Tous les sons respectent le
/// toggle des réglages, et un asset manquant dégrade silencieusement
/// (les fichiers de assets/sounds/ sont des slots à remplir).
class AudioService {
  AudioService._() : _audioPlayer = AudioPlayer();
  static final AudioService instance = AudioService._();

  final AudioPlayer _audioPlayer;
  Timer? _volumeFadeTimer;

  Future<void> _playSound(String asset) async {
    if (!SettingsService.instance.soundEnabled.value) return;
    try {
      _volumeFadeTimer?.cancel();
      await _audioPlayer.stop();
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setSource(AssetSource(asset));
      await _audioPlayer.resume();
    } catch (e) {
      debugPrint('Error playing sound $asset: $e');
    }
  }

  Future<void> playConsumptionSound() async {
    await _playSound('beer_sound.mp3');
  }

  Future<void> playJauneSound() async {
    await _playSound('jaune_sound.mp3');
  }

  /// Fanfare de level-up (slot : assets/sounds/level_up.mp3)
  Future<void> playLevelUpSound() async {
    await _playSound('sounds/level_up.mp3');
  }

  /// Pop discret à l'ouverture des sheets (slot : assets/sounds/ui_pop.mp3)
  Future<void> playUiPop() async {
    await _playSound('sounds/ui_pop.mp3');
  }

  /// Carillon de palier de streak (slot : assets/sounds/streak_chime.mp3)
  Future<void> playStreakChime() async {
    await _playSound('sounds/streak_chime.mp3');
  }

  void fadeOutAudio(Duration fadeDuration) {
    _volumeFadeTimer?.cancel();

    final int stepMs = 60;
    final int steps = (fadeDuration.inMilliseconds / stepMs).ceil();

    if (steps <= 0) {
      _stopAudio();
      return;
    }

    int currentStep = 0;
    _volumeFadeTimer = Timer.periodic(Duration(milliseconds: stepMs), (
      timer,
    ) async {
      currentStep += 1;
      final double remaining = (steps - currentStep) / steps;
      final double vol = remaining.clamp(0.0, 1.0);

      try {
        await _audioPlayer.setVolume(vol);
      } catch (e) {
        debugPrint('Error while fading audio volume: $e');
      }

      if (currentStep >= steps) {
        _stopAudio();
        timer.cancel();
      }
    });
  }

  Future<void> _stopAudio() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }
}
