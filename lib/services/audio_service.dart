import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:floating_bubbles/floating_bubbles.dart';

class AudioService {
  AudioPlayer? _audioPlayer;
  Timer? _volumeFadeTimer;

  AudioService() {
    _audioPlayer = AudioPlayer();
  }

  Future<void> playConsumptionSound() async {
    try {
      // Cancel any previous fade timer
      _volumeFadeTimer?.cancel();

      // Stop current playback and reset
      await _audioPlayer?.stop();
      await _audioPlayer?.setVolume(1.0);
      await _audioPlayer?.setSource(AssetSource('beer_sound.mp3'));
      await _audioPlayer?.resume();
    } catch (e) {
      debugPrint('Error playing beer sound: $e');
    }
  }

  void fadeOutAudio(Duration fadeDuration) {
    // Cancel any existing fade
    _volumeFadeTimer?.cancel();

    final int stepMs = 60; // fade step interval in ms
    final int steps = (fadeDuration.inMilliseconds / stepMs).ceil();

    if (steps <= 0) {
      _stopAudio();
      return;
    }

    int currentStep = 0;
    _volumeFadeTimer = Timer.periodic(Duration(milliseconds: stepMs), (timer) async {
      currentStep += 1;
      final double remaining = (steps - currentStep) / steps;
      final double vol = remaining.clamp(0.0, 1.0);

      try {
        await _audioPlayer?.setVolume(vol);
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
      await _audioPlayer?.stop();
      await _audioPlayer?.setReleaseMode(ReleaseMode.stop);
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  Widget buildBubbleAnimation(AnimationController bubbleController) {
    return Container(
      height: 64,
      width: 64,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: ClipOval(
        child: AnimatedBuilder(
          animation: bubbleController,
          builder: (context, child) {
            final t = bubbleController.value.clamp(0.0, 1.0);
            const int baseOpacity = 40;
            final int currOpacity = (baseOpacity * (1.0 - t)).round();

            if (currOpacity <= 2 ||
                bubbleController.status == AnimationStatus.dismissed) {
              return const SizedBox.shrink();
            }

            return FloatingBubbles(
              noOfBubbles: 16,
              colorsOfBubbles: const [
                Colors.white,
                Colors.blueAccent,
                Colors.lightBlueAccent,
              ],
              sizeFactor: 0.16,
              duration: 8,
              opacity: currOpacity,
              paintingStyle: PaintingStyle.fill,
              strokeWidth: 4,
              shape: BubbleShape.circle,
              speed: BubbleSpeed.normal,
            );
          },
        ),
      ),
    );
  }

  void dispose() {
    try {
      _volumeFadeTimer?.cancel();
      _audioPlayer?.stop();
      _audioPlayer?.dispose();
    } catch (e) {
      debugPrint('Error disposing audio service: $e');
    }
  }
}