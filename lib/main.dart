import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:jaune/widgets/rive_builder.dart';
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:typicons_flutter/typicons_flutter.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'models.dart';
import 'widgets/consumption_gauge_painter.dart';
import 'widgets/health_bar.dart';
import 'package:floating_bubbles/floating_bubbles.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

// Simple character profile to manage XP/level and zone messages/animations.
class CharacterProfile {
  int xp;
  int level;
  String lastXpAwardDate; // 'yyyy-MM-dd'
  int maxPv;
  int currentPv;

  static const int xpPerLevel = 100;

  CharacterProfile({
    this.xp = 0,
    this.level = 1,
    this.lastXpAwardDate = '',
    this.maxPv = 100,
    int? currentPv,
  }) : currentPv = currentPv ?? 100;

  // Asset-backed messages cache. Loaded lazily on first use.
  static final Map<String, List<String>> _assetMessages = {};
  static bool _assetLoadingStarted = false;

  static Future<void> _loadMessagesFromAsset() async {
    if (_assetMessages.isNotEmpty || _assetLoadingStarted) return;
    _assetLoadingStarted = true;
    try {
      final String raw = await rootBundle.loadString(
        'assets/character_messages.json',
      );
      final Map<String, dynamic> decoded =
          json.decode(raw) as Map<String, dynamic>;
      decoded.forEach((k, v) {
        if (v is List) {
          _assetMessages[k] = v.map((e) => e.toString()).toList();
        }
      });
      debugPrint(
        'Loaded character messages from assets: ${_assetMessages.keys.toList()}',
      );
    } catch (e) {
      debugPrint('Failed to load character messages asset: $e');
    }
  }

  void addXp(int amount) {
    xp += amount;
    while (xp >= xpPerLevel) {
      xp -= xpPerLevel;
      level += 1;
    }
  }

  String getMessage() {
    // Determine current zone from health percent and return a random message
    try {
      final String zone = zoneFromPercent();
      final List<String> pool = messagesForZone(zone);
      if (pool.isEmpty) return '';
      return pool[math.Random().nextInt(pool.length)];
    } catch (_) {
      return '';
    }
  }

  // Convenience getter used by UI; delegates to getMessage()
  String get message => getMessage();

  double healthPercent() {
    if (maxPv <= 0) return 1.0;
    return (currentPv / maxPv).clamp(0.0, 1.0).toDouble();
  }

  void setHealthPercent(double pct) {
    final p = pct.clamp(0.0, 1.0);
    currentPv = (p * maxPv).round().clamp(0, maxPv);
  }

  String zoneFromPercent() {
    // pct is 0.0..1.0
    if (currentPv > 0.75) return 'power';
    if (currentPv > 0.50) return 'warning';
    if (currentPv > 0.25) return 'danger';
    if (currentPv > 0.0)
      return 'critical';
    else
      return 'dead';
  }

  List<String> messagesForZone(String zone) {
    // If asset messages are loaded, return them
    if (_assetMessages.containsKey(zone)) {
      return List<String>.from(_assetMessages[zone]!);
    }

    // Trigger background load if not started
    if (!_assetLoadingStarted) {
      _loadMessagesFromAsset();
    }

    return [];
  }

  Map<String, String> animationsForZone(String zone) {
    // placeholder names for future Rive animations
    return {
      'power': 'anim_power',
      'warning': 'anim_warning',
      'danger': 'anim_danger',
      'critical': 'anim_critical',
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'xp': xp,
      'level': level,
      'lastXpAwardDate': lastXpAwardDate,
      'maxPv': maxPv,
      'currentPv': currentPv,
    };
  }

  static CharacterProfile fromJson(Map<String, dynamic> p) {
    return CharacterProfile(
      xp: (p['xp'] as int?) ?? 0,
      level: (p['level'] as int?) ?? 1,
      lastXpAwardDate: (p['lastXpAwardDate'] as String?) ?? '',
      maxPv: (p['maxPv'] as int?) ?? 100,
      currentPv: (p['currentPv'] as int?) ?? 100,
    );
  }

  static Future<CharacterProfile> loadFromPrefs(
    SharedPreferences prefs,
    String key,
  ) async {
    try {
      final String? raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return CharacterProfile();
      final Map<String, dynamic> p = json.decode(raw) as Map<String, dynamic>;
      return fromJson(p);
    } catch (_) {
      return CharacterProfile();
    }
  }

  Future<void> saveToPrefs(SharedPreferences prefs, String key) async {
    try {
      await prefs.setString(key, json.encode(toJson()));
    } catch (_) {
      // ignore
    }
  }

  Future<void> awardDailyXpIfNeeded(
    double healthPct,
    SharedPreferences prefs,
    String key,
  ) async {
    final String today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastXpAwardDate == today) return; // already awarded today
    if (healthPct > 0.75) {
      addXp(10);
      lastXpAwardDate = today;
      await saveToPrefs(prefs, key);
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Appliquer le style à la barre de statut
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF95C6F4), // Couleur de fond de la barre
      statusBarIconBrightness:
          Brightness.dark, // Icônes sombres pour un fond clair
      statusBarBrightness: Brightness.dark, // Pour iOS
    ),
  );

  // initialize French date formatting for TableCalendar / intl
  await initializeDateFormatting('fr_FR');
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
  // health is now owned by CharacterProfile (maxPv / currentPv)
  // _lastUpdate removed — no time-based regen logic
  int _consos = 0;
  double _animatedConsos = 0.0;
  bool _isSaving = false;
  late AnimationController _gaugeController;
  late AnimationController _bubbleController;
  late AnimationController
  _calendarAnimationController; // Contrôleur pour l'animation du calendrier
  late AnimationController _shadowController;
  AudioPlayer? _audioPlayer;
  Timer? _volumeFadeTimer;
  final String _kDailyConsosKey = 'daily_consos';
  final String _kProfileKey = 'character_profile';

  CharacterProfile _profile = CharacterProfile();

  // in-memory map date->consos (keys 'yyyy-MM-dd')
  Map<String, int> _dailyMap = {};
  DateTime? _calendarSelectedDay;
  final GlobalKey _calendarButtonKey =
      GlobalKey(); // Clé pour trouver le bouton
  bool _isCalendarButtonPressed = false; // Variable d'état pour l'animation

  // last-update persistence removed

  // Rive file loader
  // ...existing code...
  // character message is stored in _profile.message

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
    _calendarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shadowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(); // boucle douce
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

  /// Retourne le numéro ISO de la semaine pour une date donnée
  int isoWeekNumber(DateTime date) {
    // Ajuster pour que lundi = premier jour de la semaine
    // weekday: lundi=1 ... dimanche=7
    int weekday = date.weekday;

    // On calcule le lundi de la même semaine
    DateTime monday = date.add(Duration(days: 1 - weekday));

    // On prend le janvier de l'année du lundi
    DateTime jan1 = DateTime(date.year, 1, 1);

    // Calcul du nombre de jours à ajouter pour atteindre lundi
    int daysToAdd = (8 - jan1.weekday) % 7;

    DateTime firstMonday = jan1.add(Duration(days: daysToAdd));

    // Calcul du nombre de semaines entre le premier lundi et notre lundi
    int weekNumber = ((monday.difference(firstMonday).inDays) / 7).floor() + 1;
    return weekNumber;
  }

  // Group samples by ISO week (starting Monday) and compute average risk per week.
  // This function supports two input forms:
  //  - or provide `dailyConsos` (Map<String,int>) where keys are 'yyyy-MM-dd' and
  //    values are number of consumptions for that day; in that case we compute a
  //    per-day risk using quad2Predict(x=consos, y=0.0, gender) and average by week.
  Map<String, double> computeWeeklyAverageRisk({String gender = 'H'}) {
    // Step 0: get the earliestKey dateKey from dailyConsos
    DateTime? earliestKey;
    _dailyMap.forEach((dateKey, val) {
      if (earliestKey == null ||
          DateTime.parse(dateKey).isBefore(earliestKey!)) {
        earliestKey = DateTime.parse(dateKey);
      }
    });

    if (earliestKey == null) return <String, double>{};

    //Step 1 : generate all Weeks
    final Map<String, Map<String, int>> agg =
        {}; // monday -> {'sum':..., 'drinking_days':...}

    int endYear = DateTime.now().year;
    int endWeek = isoWeekNumber(DateTime.now());
    int year = earliestKey!.year;
    int week = isoWeekNumber(earliestKey!);

    while (year < endYear || (year == endYear && week <= endWeek)) {
      agg.putIfAbsent(
        "$year-$week",
        () => <String, int>{'sum': 0, 'drinking_days': 0},
      );

      week++;
      // Vérifier si on dépasse le nombre de semaines dans l’année
      int weeksInYear = 52;
      if (week > weeksInYear) {
        week = 1;
        year++;
      }
    }

    // Step 2: aggregate only weeks that have at least one recorded day.

    _dailyMap.forEach((dateKey, val) {
      try {
        final DateTime dRaw = DateTime.parse(dateKey);
        final DateTime day = DateTime(dRaw.year, dRaw.month, dRaw.day);
        final String weekNumber = isoWeekNumber(day).toString();
        final String key = "${dRaw.year}-$weekNumber";

        final int count = val;
        final w = agg.putIfAbsent(
          key,
          () => <String, int>{'sum': 0, 'drinking_days': 0},
        );
        w['sum'] = (w['sum'] ?? 0) + count;
        if (count > 0) w['drinking_days'] = (w['drinking_days'] ?? 0) + 1;
      } catch (_) {
        // ignore malformed date keys
      }
    });

    final Map<String, double> weeklyRisks = {};

    // Compute risk for aggregated weeks (weeks that had at least one recorded day)
    agg.forEach((weekKey, data) {
      final int total = data['sum'] ?? 0;
      final int drinkingDays = data['drinking_days'] ?? 0;

      double risk = 0.0;
      if (drinkingDays > 0) {
        final String sheet =
            gender.toUpperCase().startsWith('F') ? 'Femme' : 'Homme';
        try {
          risk = ModelPredictor.predict(sheet, drinkingDays, total);
          debugPrint(
            "Predicted risk for $sheet (y=$drinkingDays, x=$total): $risk",
          );
        } catch (e) {
          debugPrint(
            'ModelPredictor.predict error for $sheet y=$drinkingDays x=$total: $e',
          );
          risk = 0.0;
        }
      }
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
    _calendarAnimationController.dispose();
    _shadowController.dispose();
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
      // Ensure today's in-memory consumption is included so recompute is
      // robust even if callers didn't save before requesting recompute.
      final String todayKey = DateTime.now().toIso8601String().substring(0, 10);
      _dailyMap[todayKey] = _consos;

      // Compute weekly average risk from daily map (includes today)
      final Map<String, double> weekly = computeWeeklyAverageRisk();
      if (weekly.isNotEmpty) {
        final double sumAll = weekly.values.fold(0.0, (p, e) => p + e);
        final double avgRisk = sumAll / weekly.length;
        // Map risk to percent-of-health (PV). risk >= 0.15 => 0 PV
        final double hp = riskToHealthPercent(avgRisk);

        final int pvHealth = (hp * _profile.maxPv).round().clamp(
          0,
          _profile.maxPv,
        );
        setState(() {
          _profile.currentPv = pvHealth;
        });
      } else {
        // No weekly risk data: do not apply damage/regen logic — default to full health
        setState(() {
          _profile.currentPv = _profile.maxPv;
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
        final Map<String, dynamic> decoded =
            json.decode(savedDaily) as Map<String, dynamic>;
        _dailyMap = decoded.map<String, int>((k, v) {
          if (v is int) return MapEntry(k, v);
          return MapEntry(k, int.tryParse(v.toString()) ?? 0);
        });
        final todayKey = DateTime.now().toIso8601String().substring(0, 10);
        savedConsos = _dailyMap[todayKey] ?? 0;
        debugPrint(todayKey);
      } catch (e) {
        debugPrint('Error parsing savedDaily map: $e');

        savedConsos = 0;
      }
    }

    // load profile (xp / level, PV)
    try {
      final String? rawProfile = prefs.getString(_kProfileKey);
      if (rawProfile != null && rawProfile.isNotEmpty) {
        final Map<String, dynamic> p =
            json.decode(rawProfile) as Map<String, dynamic>;
        _profile = CharacterProfile(
          xp: (p['xp'] as int?) ?? 0,
          level: (p['level'] as int?) ?? 1,
          lastXpAwardDate: (p['lastXpAwardDate'] as String?) ?? '',
          maxPv: (p['maxPv'] as int?) ?? 100,
          currentPv: (p['currentPv'] as int?) ?? 100,
        );
      } else {
        _profile = CharacterProfile(maxPv: 100, currentPv: 100);
      }
    } catch (_) {
      _profile = CharacterProfile(maxPv: 100, currentPv: 100);
    }

    // initialize in-memory state from saved daily consumptions and profile
    setState(() {
      _consos = savedConsos;
      _animatedConsos = savedConsos.toDouble();
      _profile.currentPv = _profile.currentPv.clamp(0, _profile.maxPv);
    });

    // award daily XP if not yet awarded today (run after health initialized)
    await _recomputeHealth();
    await _profile.awardDailyXpIfNeeded(
      _profile.currentPv / _profile.maxPv,
      prefs,
      _kProfileKey,
    );
  }

  Future<void> _saveState() async {
    if (_isSaving) return;
    _isSaving = true;
    try {
      final prefs = await SharedPreferences.getInstance();

      final todayKey = DateTime.now().toIso8601String().substring(0, 10);

      _dailyMap[todayKey] = _consos;

      await prefs.setString(_kDailyConsosKey, json.encode(_dailyMap));
      // also persist profile
      final Map<String, dynamic> p = {
        'xp': _profile.xp,
        'level': _profile.level,
        'lastXpAwardDate': _profile.lastXpAwardDate,
        'maxPv': _profile.maxPv,
        'currentPv': _profile.currentPv,
      };
      await prefs.setString(_kProfileKey, json.encode(p));
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
      //await _audioPlayer?.setReleaseMode(ReleaseMode.loop);
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

  // Remet à zéro les consommations du jour avec sauvegarde et recalcul de la santé
  Future<void> _resetTodayConsos() async {
    try {
      final String todayKey = DateTime.now().toIso8601String().substring(0, 10);
      setState(() {
        _dailyMap.remove(todayKey); // on efface l'entrée du jour
        _consos = 0;
        _animatedConsos = 0.0;
      });
      await _saveState();
      await _recomputeHealth();
    } catch (e) {
      debugPrint('Error in _resetTodayConsos: $e');
    }
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

  void _showCalendarDialog() {
    // 1. Obtenir la géométrie du bouton
    final RenderBox buttonBox =
        _calendarButtonKey.currentContext!.findRenderObject() as RenderBox;
    final buttonSize = buttonBox.size;
    final buttonPosition = buttonBox.localToGlobal(Offset.zero);

    final Rect beginRect = Rect.fromLTWH(
      buttonPosition.dx,
      buttonPosition.dy,
      buttonSize.width,
      buttonSize.height,
    );

    // 2. Définir la géométrie finale de la boîte de dialogue
    final screenRect = Rect.fromLTWH(
      0,
      0,
      MediaQuery.of(context).size.width,
      MediaQuery.of(context).size.height,
    );
    final finalRect = Rect.fromCenter(
      center: screenRect.center,
      width: math.min(420, screenRect.width - 32),
      height: 460, // Hauteur approximative de votre dialogue
    ).shift(
      Offset(0, (screenRect.height - 500) / 2 - 40),
    ); // La positionne en bas

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    final animation = CurvedAnimation(
      parent: _calendarAnimationController,
      curve: Curves.easeInOutCubic,
    );

    entry = OverlayEntry(
      builder: (ctx) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final currentRect =
                Rect.lerp(beginRect, finalRect, animation.value)!;
            final borderRadius =
                BorderRadius.lerp(
                  BorderRadius.circular(24),
                  BorderRadius.circular(24),
                  animation.value,
                )!;

            return Stack(
              children: [
                // Fond flouté qui apparaît
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () async {
                    await _calendarAnimationController.reverse();
                    entry.remove();
                  },
                  child: Opacity(
                    opacity: animation.value,
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                      child: Container(color: Colors.black.withOpacity(0.3)),
                    ),
                  ),
                ),

                // La boîte de dialogue animée
                Positioned(
                  //top: currentRect.top,
                  bottom: 40,
                  left: currentRect.left,
                  width: currentRect.width,
                  height: currentRect.height,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.fromARGB(255, 250, 225, 100),
                            Color.fromARGB(255, 245, 200, 80),
                          ],
                        ),
                        borderRadius: borderRadius,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              0.2 * animation.value,
                            ),
                            offset: const Offset(0, 8),
                            blurRadius: 20,
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(
                            0.3 * animation.value,
                          ),
                          width: 1.0,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      // Le contenu apparaît en fondu
                      child: Opacity(opacity: animation.value, child: child),
                    ),
                  ),
                ),
              ],
            );
          },
          // Le contenu réel du calendrier
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(CupertinoIcons.calendar, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'Calendrier',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      await _calendarAnimationController.reverse();
                      entry.remove();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.xmark,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Fermer',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withOpacity(0.85),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        offset: const Offset(0, 4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: TableCalendar(
                    locale: 'fr_FR',
                    firstDay: DateTime.utc(2000, 1, 1),
                    lastDay: DateTime.utc(2100, 12, 31),
                    focusedDay: _calendarSelectedDay ?? DateTime.now(),
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    selectedDayPredicate:
                        (day) =>
                            _calendarSelectedDay != null &&
                            isSameDay(day, _calendarSelectedDay),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _calendarSelectedDay = selectedDay;
                      });
                      entry
                          .markNeedsBuild(); // Reconstruit l'overlay pour la sélection
                    },
                    daysOfWeekHeight: 28,
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      leftChevronIcon: Icon(CupertinoIcons.chevron_left),
                      rightChevronIcon: Icon(CupertinoIcons.chevron_right),
                      headerPadding: EdgeInsets.symmetric(vertical: 8),
                      titleTextStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    calendarStyle: const CalendarStyle(
                      todayDecoration: BoxDecoration(),
                      defaultDecoration: BoxDecoration(),
                      outsideDecoration: BoxDecoration(),
                      selectedDecoration: BoxDecoration(
                        color: Color(0xFFF7D83F),
                        shape: BoxShape.circle,
                      ),
                    ),
                    calendarBuilders: CalendarBuilders(
                      dowBuilder: (context, day) {
                        const labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
                        final idx = (day.weekday - 1) % 7;
                        return Center(
                          child: Text(
                            labels[idx],
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                      defaultBuilder: (context, day, focusedDay) {
                        final dayKey = day.toIso8601String().substring(0, 10);
                        final count = _dailyMap[dayKey] ?? 0;
                        final isSelected = isSameDay(day, _calendarSelectedDay);

                        if (count > 0) {
                          return _buildConsumptionCell(day, count, isSelected);
                        }
                        return _buildEmptyCell(
                          day,
                          isSelected,
                          isSameDay(day, DateTime.now()),
                        );
                      },
                      todayBuilder: (context, day, focusedDay) {
                        final dayKey = day.toIso8601String().substring(0, 10);
                        final count = _dailyMap[dayKey] ?? 0;
                        final isSelected = isSameDay(day, _calendarSelectedDay);

                        if (count > 0) {
                          return _buildConsumptionCell(
                            day,
                            count,
                            isSelected,
                            isToday: true,
                          );
                        }
                        return _buildEmptyCell(day, isSelected, true);
                      },
                      selectedBuilder: (context, day, focusedDay) {
                        final dayKey = day.toIso8601String().substring(0, 10);
                        final count = _dailyMap[dayKey] ?? 0;

                        if (count > 0) {
                          return _buildConsumptionCell(
                            day,
                            count,
                            true,
                            isToday: isSameDay(day, DateTime.now()),
                          );
                        }
                        return _buildEmptyCell(
                          day,
                          true,
                          isSameDay(day, DateTime.now()),
                        );
                      },
                      outsideBuilder: (context, day, focusedDay) {
                        return Center(
                          child: Text(
                            '${day.day}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey.shade400),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    overlay.insert(entry);
    _calendarAnimationController.forward(from: 0.0);
  }

  Widget _buildConsumptionCell(
    DateTime day,
    int count,
    bool isSelected, {
    bool isToday = false,
  }) {
    Color bg;
    if (count <= 2) {
      bg = Colors.green.shade600;
    } else if (count <= 4) {
      bg = Colors.yellow.shade700;
    } else if (count <= 6) {
      bg = Colors.deepOrange.shade600;
    } else {
      bg = Colors.redAccent.shade700;
    }

    if (isSelected) {
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.yellow, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Typicons.beer, color: Colors.white, size: 22),
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              height: 0.9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCell(DateTime day, bool isSelected, bool isToday) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isPast = day.isBefore(today);

    BoxDecoration decoration = BoxDecoration(
      color: (isPast && !isToday ? Colors.grey.shade200 : Colors.transparent),
      shape: BoxShape.circle,
      border:
          isToday && !isSelected
              ? Border.all(color: Colors.black54, width: 1.5)
              : (isSelected
                  ? Border.all(color: Colors.yellow, width: 1.5)
                  : (!isPast && !isToday
                      ? Border.all(color: Colors.grey.shade300, width: 1.0)
                      : null)),
    );

    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: decoration,
      child: Text(
        '${day.day}',
        style: TextStyle(
          color:
              isSelected
                  ? Colors.black
                  : (isPast && !isToday
                      ? Colors.grey.shade600
                      : Colors.black87),
          fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w600,
        ),
      ),
    );
  }

  // ...existing code...

  @override
  Widget build(BuildContext context) {
    final double percent = _profile.currentPv / _profile.maxPv;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        top: false,
        child: Container(
          padding: const EdgeInsets.only(
            top: 48,
            left: 16,
            right: 16,
            bottom: 32,
          ),
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
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      showCupertinoDialog(
                        context: context,
                        builder:
                            (context) => CupertinoAlertDialog(
                              title: const Text('Comment ça marche ?'),
                              content: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Chaque fois que tu bois, appuie sur le bouton « 🍻 »",
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "1 verre standard = 1 clic (ex : une pinte = 2 clics).",
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Ton 🍋 a des points de vie qui montent ou descendent selon ta consommation.",
                                  ),
                                  const SizedBox(height: 8),
                                  RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                      ),
                                      children: [
                                        const TextSpan(
                                          text:
                                              "Les règles de calcul viennent d’un ",
                                        ),
                                        TextSpan(
                                          text: 'rapport officiel',
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                          recognizer:
                                              TapGestureRecognizer()
                                                ..onTap = () async {
                                                  final uri = Uri.parse(
                                                    'https://www.santepubliquefrance.fr/content/download/8230/file/avis-alcool-040517.pdf',
                                                  );
                                                  if (await canLaunchUrl(uri)) {
                                                    await launchUrl(uri);
                                                  } else {
                                                    debugPrint(
                                                      'Could not launch $uri',
                                                    );
                                                  }
                                                },
                                        ),
                                        const TextSpan(
                                          text:
                                              ' de Santé Publique France, basé sur des données de chercheurs britanniques.',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                CupertinoDialogAction(
                                  child: const Text('OK'),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ],
                            ),
                      );
                    },
                    minimumSize: Size(0, 0),
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
              const SizedBox(height: 16),
              HealthBar(percent: percent, level: _profile.level),

              const SizedBox(height: 24),

              // === Image / Rive du personnage (fix layout) ===
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        bottom: 0,
                        child: AnimatedBuilder(
                          animation: _shadowController,
                          builder: (context, _) {
                            final t = _shadowController.value; // 0..1
                            return CustomPaint(
                              size: Size(
                                math.min(
                                  MediaQuery.of(context).size.width * 0.50,
                                  260,
                                ),
                                math.min(
                                  MediaQuery.of(context).size.width * 0.22,
                                  70,
                                ),
                              ),
                              painter: GroundShadowPainter(
                                color: Colors.grey.shade800.withOpacity(0.35),
                                blurSigma: 32,
                                coreFactor: 0.55,
                                t: t, // temps animé
                                squashAmp: 0.06, // amplitude d’écrasement
                                shiftAmp: 6.0, // amplitude du léger décalage
                              ),
                            );
                          },
                        ),
                      ),
                      const RiveBuilder(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              /*CharacterCard(
                name: 'Jaune',
                message: _profile.message,
                healthPercent: percent,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (_) => BeRealCapturePage(
                            avatarAsset: 'assets/avatar.png',
                            message: _profile.message,
                            healthPercent: percent,
                          ),
                    ),
                  );
                },
              ),*/

              // === Boutons de simulation ===
              /* Wrap(
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
              ),*/
              SizedBox(height: 80),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Calendrier / résumé stylé (amélioré)
                  GestureDetector(
                    onTap: _showCalendarDialog,
                    onTapDown:
                        (_) => setState(() => _isCalendarButtonPressed = true),
                    onTapUp:
                        (_) => setState(() => _isCalendarButtonPressed = false),
                    onTapCancel:
                        () => setState(() => _isCalendarButtonPressed = false),
                    child: AnimatedScale(
                      scale: _isCalendarButtonPressed ? 0.95 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOut,
                      child: Container(
                        key: _calendarButtonKey,
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
                              color: const Color(
                                0xFFF7D83F,
                              ).withAlpha((0.65 * 255).round()),
                              offset: const Offset(0, 6),
                              blurRadius: 16,
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withAlpha((0.22 * 255).round()),
                            width: 1.0,
                          ),
                        ),
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
                  ),
                  const SizedBox(width: 16),
                  // Bouton entouré par la jauge (taille plus grande pour visibilité)
                  Row(
                    children: [
                      //Bonton réinitialisation conso journée
                      GestureDetector(
                        onTap: () {
                          showCupertinoDialog(
                            context: context,
                            builder:
                                (context) => ResetConfirmDialog(
                                  onConfirm: () async {
                                    await _resetTodayConsos();
                                    Navigator.of(context).pop();
                                  },
                                ),
                          );
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withAlpha((0.95 * 255).round()),
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
                            CupertinoIcons.refresh,
                            color: Colors.grey,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withAlpha(
                                (0.85 * 255).round(),
                              ),
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
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
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
            ],
          ),
        ),
      ),
    );
  }
}

// Boîte de dialogue de confirmation pour réinitialiser les consommations du jour
class ResetConfirmDialog extends StatelessWidget {
  const ResetConfirmDialog({super.key, required this.onConfirm});

  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('Réinitialiser la journée ?'),
      content: const Text(
        "Cela remettra à zéro tes consommations d'aujourd'hui. Tu confirmes ?",
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () async {
            await onConfirm();
          },
          child: const Text('Réinitialiser'),
        ),
      ],
    );
  }
}

class GroundShadowPainter extends CustomPainter {
  final Color color;
  final double blurSigma;
  final double coreFactor; // proportion du cœur (0.5..0.7)

  // Nouveaux paramètres animés
  final double t; // 0..1 (phase)
  final double squashAmp; // amplitude de squash/scale
  final double shiftAmp; // amplitude du déplacement horizontal

  GroundShadowPainter({
    required this.color,
    this.blurSigma = 28,
    this.coreFactor = 0.6,
    this.t = 0.0,
    this.squashAmp = 0.06,
    this.shiftAmp = 6.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect full = Offset.zero & size;

    // Oscillations douces
    final double twoPi = math.pi * 2.0;
    final double s = math.sin(twoPi * t);
    final double c = math.cos(twoPi * t);

    // Légère respiration + décalage
    final double scaleX = 1.0 + squashAmp * s;
    final double scaleY = 1.0 - squashAmp * s * 0.5;
    final double dx = shiftAmp * math.sin(twoPi * t + math.pi / 3);

    // Variation subtile du flou
    final double extraBlur = 4.0 * (0.5 + 0.5 * (1.0 - c.abs()));

    canvas.save();
    // translation légère
    canvas.translate(dx, 0);
    // scale par rapport au centre
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scaleX, scaleY);
    canvas.translate(-size.width / 2, -size.height / 2);

    // Halo large (très doux)
    final Paint halo =
        Paint()
          ..color = color.withOpacity(0.26)
          ..maskFilter = ui.MaskFilter.blur(
            ui.BlurStyle.normal,
            blurSigma + extraBlur,
          );
    canvas.drawOval(full, halo);

    // Cœur de contact (plus sombre, un peu plus petit)
    final double deflateDy = size.height * (1 - coreFactor);
    final Rect core = full.deflate(deflateDy);
    final Paint corePaint =
        Paint()
          ..color = color.withOpacity(0.42)
          ..maskFilter = ui.MaskFilter.blur(
            ui.BlurStyle.normal,
            (blurSigma * 0.6) + (extraBlur * 0.5),
          );
    canvas.drawOval(core, corePaint);

    // Traîne asymétrique pour naturel
    final Rect tail = full
        .inflate(size.height * 0.08)
        .shift(const Offset(0, 2));
    final Paint tailPaint =
        Paint()
          ..color = color.withOpacity(0.16)
          ..maskFilter = ui.MaskFilter.blur(
            ui.BlurStyle.normal,
            (blurSigma * 1.2) + (extraBlur * 0.3),
          );
    canvas.drawOval(tail, tailPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GroundShadowPainter old) {
    return old.color != color ||
        old.blurSigma != blurSigma ||
        old.coreFactor != coreFactor ||
        old.t != t ||
        old.squashAmp != squashAmp ||
        old.shiftAmp != shiftAmp;
  }
}
