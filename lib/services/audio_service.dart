import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _audioPlayer;
  Timer? _volumeFadeTimer;

  AudioService() : _audioPlayer = AudioPlayer();

  Future<void> _playSound(String asset) async {
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

  void dispose() {
    try {
      _volumeFadeTimer?.cancel();
      _audioPlayer.stop();
      _audioPlayer.dispose();
    } catch (e) {
      debugPrint('Error disposing audio service: $e');
    }
  }
}
