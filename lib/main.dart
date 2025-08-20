import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:jaune/be_real_capture_page.dart';
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'dart:convert';

import 'models.dart';

import 'widgets/rive_builder.dart';
import 'widgets/consumption_gauge_painter.dart';
import 'widgets/health_bar.dart';
import 'widgets/character_card.dart';
import 'package:floating_bubbles/floating_bubbles.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

// A safe Rive loader similar to the docs' builder example but adapted
// to the available runtime API in this project.
// ExampleRiveBuilder extracted to lib/widgets/example_rive_builder.dart

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo - Vie personnage',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const MyHomePage(title: 'Personnage & barre de vie'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  static const int maxHealth = 100;

  int _health = maxHealth;
  // _lastUpdate removed — no time-based regen logic
  int _consos = 0;
  double _animatedConsos = 0.0;
  bool _isSaving = false;
  late AnimationController _gaugeController;
  late AnimationController _bubbleController;
  AudioPlayer? _audioPlayer;
  Timer? _volumeFadeTimer;
  final String _kDailyConsosKey = 'daily_consos';

  // last-update persistence removed

  // Rive file loader
  // ...existing code...
  final String _characterMessage =
      "Un autre ? Bien sûr. Ta volonté, c'est de l'eau gazeuse.";

  @override
  void initState() {
    super.initState();
    _gaugeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..addListener(() {
      setState(() {
        final double start = math.max(0, _consos - 1).toDouble();
        _animatedConsos =
            (ui.lerpDouble(start, _consos.toDouble(), _gaugeController.value) ??
                _consos.toDouble());
      });
    });
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    // prepare audio player
    _audioPlayer = AudioPlayer();
    // init Rive FileLoader
    // debug load removed: use onInit in RiveAnimation.asset to inspect/play animations

    // Load predictive models from assets; non-fatal if it fails but required for risk predictions.
    ModelPredictor.loadModels()
        .catchError((e) {
          debugPrint('Warning: failed to load risk models: $e');
        })
        .whenComplete(() {
          _loadState();
        });
    // no risk_samples loading by design
  }

  // Group samples by ISO week (starting Monday) and compute average risk per week.
  // This function supports two input forms:
  //  - or provide `dailyConsos` (Map<String,int>) where keys are 'yyyy-MM-dd' and
  //    values are number of consumptions for that day; in that case we compute a
  //    per-day risk using quad2Predict(x=consos, y=0.0, gender) and average by week.
  Map<String, double> computeWeeklyAverageRisk(
    Map<String, dynamic> dailyConsos, {
    String gender = 'H',
  }) {
    // Aggregate by ISO-week (Monday key). For each week we compute:
    //  - total count of consumptions during recorded days
    //  - drinking_days = number of days with count > 0 in that week
    // Then we compute x = mean_consumption_per_day_over_7 = total / 7.0
    // and y = drinking_days, and call quad2Predict(x, y, gender) once per week.
    final Map<String, Map<String, int>> agg = {};

    dailyConsos.forEach((dateKey, val) {
      try {
        final DateTime d = DateTime.parse(dateKey);
        final int weekday = d.weekday; // 1..7
        final DateTime dayOnly = DateTime(d.year, d.month, d.day);
        final DateTime monday = dayOnly.subtract(Duration(days: weekday - 1));
        final String weekKey =
            '${monday.year.toString().padLeft(4, '0')}-'
            '${monday.month.toString().padLeft(2, '0')}-'
            '${monday.day.toString().padLeft(2, '0')}';

        final int count =
            (val is int) ? val : int.tryParse(val.toString()) ?? 0;
        final w = agg.putIfAbsent(
          weekKey,
          () => <String, int>{'sum': 0, 'drinking_days': 0},
        );
        w['sum'] = (w['sum'] ?? 0) + count;
        if (count > 0) w['drinking_days'] = (w['drinking_days'] ?? 0) + 1;
      } catch (_) {
        // ignore malformed date keys
      }
    });

    final Map<String, double> weeklyRisks = {};
    agg.forEach((weekKey, data) {
      final int total = data['sum'] ?? 0;
      final int drinkingDays = data['drinking_days'] ?? 0;
      final double meanPerDay = total / drinkingDays; // include zero days

      // Use ModelPredictor from lib/models.dart. The models expect a sheet name
      // like 'Homme' or 'Femme' and y=drinkingDays (int), x=meanPerDay.
      double risk = 0.0;
      if (drinkingDays == 0) {
        // No drinking days this week -> minimal/no risk
        risk = 0.0;
      } else {
        final String sheet =
            gender.toUpperCase().startsWith('F') ? 'Femme' : 'Homme';
        try {
          risk = ModelPredictor.predict(sheet, drinkingDays, meanPerDay);
        } catch (e) {
          debugPrint(
            'ModelPredictor.predict error for $sheet y=$drinkingDays x=$meanPerDay: $e',
          );
          // fallback: assume no risk if model missing
          risk = 0.0;
        }
      }
      debugPrint(
        'Weekly risk for $weekKey: $risk, drinkingDays=$drinkingDays, meanPerDay=$meanPerDay',
      );
      weeklyRisks[weekKey] = risk;
    });

    return weeklyRisks;
  }

  // Map risk Z to health percent (0..1). Rule: risk >= 0.15 => 0 PV. Otherwise linear inverse mapping.
  double riskToHealthPercent(double risk) {
    if (risk.isNaN) return 1.0;
    if (risk >= 0.15) return 0.0;
    final double v = 1.0 - (risk / 0.15);
    return v.clamp(0.0, 1.0);
  }

  // risk_samples loading intentionally removed

  @override
  void dispose() {
    _gaugeController.dispose();
    _bubbleController.dispose();
    try {
      _volumeFadeTimer?.cancel();
    } catch (_) {}
    try {
      _audioPlayer?.stop();
    } catch (_) {}
    try {
      _audioPlayer?.dispose();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _recomputeHealth({bool save = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kDailyConsosKey);
      Map<String, dynamic> dailyMap = {};
      if (raw != null && raw.isNotEmpty) {
        try {
          dailyMap = json.decode(raw) as Map<String, dynamic>;
        } catch (_) {
          dailyMap = {};
        }
      }

      // Ensure today's in-memory consumption is included so recompute is
      // robust even if callers didn't save before requesting recompute.
      final String todayKey = DateTime.now().toIso8601String().substring(0, 10);
      dailyMap[todayKey] = _consos;

      // Compute weekly average risk from daily map (includes today)
      final Map<String, double> weekly = computeWeeklyAverageRisk(dailyMap);
      if (weekly.isNotEmpty) {
        final double sumAll = weekly.values.fold(0.0, (p, e) => p + e);
        final double avgRisk = sumAll / weekly.length;
        // Map risk to percent-of-health (PV). risk >= 0.15 => 0 PV
        final double hp = riskToHealthPercent(avgRisk);

        final int pvHealth = (hp * maxHealth).round().clamp(0, maxHealth);
        setState(() {
          _health = pvHealth;
        });
      } else {
        // No weekly risk data: do not apply damage/regen logic — default to full health
        setState(() {
          _health = maxHealth;
        });
      }

      if (save) await _saveState();
    } catch (e) {
      debugPrint('Error in _recomputeHealth: $e');
    }
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    // last-update removed; no persisted timestamp to load
    // load daily consumptions map and use today's value as _consos
    final savedDaily = prefs.getString(_kDailyConsosKey);
    int savedConsos = 0;
    if (savedDaily != null && savedDaily.isNotEmpty) {
      try {
        final Map<String, dynamic> m =
            json.decode(savedDaily) as Map<String, dynamic>;
        final todayKey = DateTime.now().toIso8601String().substring(0, 10);
        savedConsos = (m[todayKey] as int?) ?? 0;
      } catch (_) {
        savedConsos = 0;
      }
    }

    // initialize in-memory state from saved daily consumptions
    setState(() {
      _consos = savedConsos;
      _animatedConsos = savedConsos.toDouble();
    });
    await _recomputeHealth();
  }

  Future<void> _saveState() async {
    if (_isSaving) return;
    _isSaving = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      // save daily consumptions map (update today's value)
      final String? raw = prefs.getString(_kDailyConsosKey);
      Map<String, dynamic> m = {};
      if (raw != null && raw.isNotEmpty) {
        try {
          m = json.decode(raw) as Map<String, dynamic>;
        } catch (_) {
          m = {};
        }
      }
      final todayKey = DateTime.now().toIso8601String().substring(0, 10);
      m[todayKey] = _consos;
      await prefs.setString(_kDailyConsosKey, json.encode(m));
    } catch (e) {
      debugPrint('Error saving daily consos: $e');
    } finally {
      _isSaving = false;
    }
  }

  Future<void> _addConso() async {
    setState(() {
      _consos += 1;
    });
    _gaugeController.forward(from: 0.0);
    _bubbleController.reset();
    // Ensure any previous fade timer is cancelled
    try {
      _volumeFadeTimer?.cancel();
    } catch (_) {}

    // Start playback from the beginning and loop during the animation.
    try {
      // Single player: set to full volume and loop during animation
      await _audioPlayer?.stop();
      await _audioPlayer?.setVolume(1.0);
      await _audioPlayer?.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer?.setSource(AssetSource('beer_sound.mp3'));
      await _audioPlayer?.resume();
    } catch (e) {
      debugPrint('Error playing beer sound (main/boost): $e');
    }

    // out of the audio (prevent abrupt cut). We fade over 800ms by default.
    _bubbleController.forward().whenComplete(() {
      _fadeOutAndStopAudio(const Duration(milliseconds: 800));
    });
    await _saveState();
    // recompute health from updated daily map
    await _recomputeHealth();
  }

  void _fadeOutAndStopAudio(Duration fadeDuration) {
    // Cancel any existing fade
    try {
      _volumeFadeTimer?.cancel();
    } catch (_) {}

    final int stepMs = 60; // fade step interval in ms
    final int steps = (fadeDuration.inMilliseconds / stepMs).ceil();
    if (steps <= 0) {
      try {
        _audioPlayer?.stop();
        _audioPlayer?.setReleaseMode(ReleaseMode.stop);
      } catch (_) {}
      return;
    }

    int currentStep = 0;
    _volumeFadeTimer = Timer.periodic(Duration(milliseconds: stepMs), (
      t,
    ) async {
      currentStep += 1;
      final double remaining = (steps - currentStep) / steps;
      final double vol = remaining.clamp(0.0, 1.0);
      try {
        await _audioPlayer?.setVolume(vol);
      } catch (e) {
        debugPrint('Error while fading audio volume: $e');
      }

      if (currentStep >= steps) {
        try {
          await _audioPlayer?.stop();
          await _audioPlayer?.setReleaseMode(ReleaseMode.stop);
        } catch (_) {}
        try {
          _volumeFadeTimer?.cancel();
        } catch (_) {}
      }
    });
  }

  void _simulateDays(int days) {
    // simulate passage of time has no effect without last-update tracking;
    // simply recompute health (daily data may be manipulated separately).
    _recomputeHealth();
  }

  // ...existing code...

  @override
  Widget build(BuildContext context) {
    final double percent = _health / maxHealth;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF95C6F4), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            //crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // === Ligne du haut : niveau + info ===
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "",
                    //'Niveau : ${(_health / 10).floor()}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      showCupertinoDialog(
                        context: context,
                        builder:
                            (context) => CupertinoAlertDialog(
                              title: const Text('Information'),
                              content: const Text(
                                'Ton niveau dépend de ta vie. Clique sur bière pour perdre, attends pour regagner.',
                              ),
                              actions: [
                                CupertinoDialogAction(
                                  child: const Text('OK'),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ],
                            ),
                      );
                    }, minimumSize: Size(0, 0),
                    child: Icon(
                      Icons.info_outline,
                      color: Colors.grey.shade100.withAlpha(
                        (0.7 * 255).round(),
                      ),
                      size: 24,
                    ),
                  ),
                ],
              ),

              HealthBar(percent: percent),

              const SizedBox(height: 20),

              // === Image / Rive du personnage (fix layout) ===
              Center(
                child: SizedBox(
                  width: 320,
                  height: 320,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: Colors.transparent,
                      child: const RiveBuilder(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              CharacterCard(
                name: 'Jaune',
                message: _characterMessage,
                healthPercent: percent,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (_) => BeRealCapturePage(
                            avatarAsset: 'assets/avatar.png',
                            message: _characterMessage,
                            healthPercent: percent,
                          ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // === Boutons de simulation ===
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _simulateDays(1),
                    icon: const Icon(Icons.wb_sunny),
                    label: const Text('Simuler +1 jour'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      // reset daily consumptions and recompute health
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove(_kDailyConsosKey);
                      setState(() {
                        _consos = 0;
                        _animatedConsos = 0.0;
                        // _lastUpdate removed — nothing to set here
                      });
                      await _recomputeHealth();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Remettre full'),
                  ),
                ],
              ),

              Spacer(),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Calendrier / résumé stylé (amélioré)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFF7D83F), Color(0xFFF6C84A)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.10 * 255).round()),
                          offset: const Offset(0, 6),
                          blurRadius: 16,
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withAlpha((0.22 * 255).round()),
                        width: 1.0,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        // placeholder : ouvrir calendrier ou dialogue
                        // Navigator.of(context).push(...);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Calendrier',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Voir',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.black54),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withAlpha(
                                (0.95 * 255).round(),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(
                                    (0.08 * 255).round(),
                                  ),
                                  offset: const Offset(0, 3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Icon(
                              CupertinoIcons.calendar_today,
                              color: Color(0xFFF7D83F),
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Bouton entouré par la jauge (taille plus grande pour visibilité)
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withAlpha((0.85 * 255).round()),
                        ),
                      ),
                      // Jauge de consommation (anneau visible)
                      CustomPaint(
                        size: const Size(88, 88),
                        painter: ConsumptionGaugePainter(_animatedConsos),
                      ),

                      // Bouton au centre (container pour éviter la couleur par défaut d'ElevatedButton)
                      GestureDetector(
                        onTap: _addConso,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Ombre portée pour effet 3D
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(
                                      (0.2 * 255).round(),
                                    ),
                                    offset: const Offset(0, 4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),

                            // Effet glass (bouton circulaire) — la bière reste centrée
                            ClipRRect(
                              borderRadius: BorderRadius.circular(36),
                              child: BackdropFilter(
                                filter: ui.ImageFilter.blur(
                                  sigmaX: 6.0,
                                  sigmaY: 6.0,
                                ),
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.white.withAlpha(
                                          (0.28 * 255).round(),
                                        ),
                                        Colors.white.withAlpha(
                                          (0.10 * 255).round(),
                                        ),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withAlpha(
                                        (0.35 * 255).round(),
                                      ),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '🍻',
                                      style: TextStyle(fontSize: 40),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Badge du nombre de conso — positionné en absolu au dessus de la bière
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom:
                                  6, // ajuste cette valeur pour monter/descendre le badge
                              child: Center(
                                child: Text(
                                  '$_consos',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.transparent,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withAlpha(
                                          (0.32 * 255).round(),
                                        ),
                                        offset: const Offset(0, 1),
                                        blurRadius: 6,
                                      ),
                                      Shadow(
                                        color: Colors.white.withAlpha(
                                          (0.6 * 255).round(),
                                        ),
                                        offset: const Offset(0, -1),
                                        blurRadius: 0,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            Container(
                              height: 64,
                              width: 64,
                              decoration: BoxDecoration(shape: BoxShape.circle),
                              child: ClipOval(
                                child: AnimatedBuilder(
                                  animation: _bubbleController,
                                  builder: (context, child) {
                                    final t = _bubbleController.value.clamp(
                                      0.0,
                                      1.0,
                                    );
                                    // base opacity used previously (40). Fade to 0 as
                                    // t -> 1.0 so bubbles become increasingly
                                    // transparent at the end of the animation.
                                    const int baseOpacity = 40;
                                    final int currOpacity =
                                        (baseOpacity * (1.0 - t)).round();

                                    // If opacity is effectively zero, hide the widget
                                    if (currOpacity <= 2 ||
                                        _bubbleController.status ==
                                            AnimationStatus.dismissed) {
                                      return const SizedBox.shrink();
                                    }

                                    return FloatingBubbles(
                                      noOfBubbles: 16,
                                      colorsOfBubbles: [
                                        Colors.white,
                                        Colors.blueAccent,
                                        Colors.lightBlueAccent,
                                      ],
                                      sizeFactor: 0.16,
                                      duration: 8, // 8 seconds.
                                      opacity: currOpacity,
                                      paintingStyle: PaintingStyle.fill,
                                      strokeWidth: 4,
                                      shape: BubbleShape.circle,
                                      speed: BubbleSpeed.normal,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Painter pour dessiner les demi-cercles de la jauge autour du bouton
// ConsumptionGaugePainter extracted to lib/widgets/consumption_gauge_painter.dart
