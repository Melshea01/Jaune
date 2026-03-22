import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:url_launcher/url_launcher.dart';

import 'services/audio_service.dart';
import 'services/character_service.dart';
import 'services/storage_service.dart';
import 'widgets/calendar_dialog.dart';
import 'widgets/consumption_gauge_painter.dart';
import 'widgets/ground_shadow_painter.dart';
import 'widgets/health_bar.dart';
import 'widgets/reset_confirm_dialog.dart';
import 'widgets/rive_builder.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Appliquer le style à la barre de statut
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF95C6F4),
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.dark,
    ),
  );

  // Initialize French date formatting for TableCalendar / intl
  await initializeDateFormatting('fr_FR');
  runApp(const MyApp());
}

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
  // Services
  late final CharacterService _characterService;
  late final StorageService _storageService;
  late final AudioService _audioService;

  // State variables
  int _consos = 0;
  double _animatedConsos = 0.0;
  bool _isSaving = false;

  // Animation controllers
  late AnimationController _gaugeController;
  late AnimationController _bubbleController;
  late AnimationController _calendarAnimationController;
  late AnimationController _shadowController;

  // Calendar state
  final GlobalKey _calendarButtonKey = GlobalKey();
  bool _isCalendarButtonPressed = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeAnimations();
    _loadState();
  }

  void _initializeServices() {
    _characterService = CharacterService();
    _storageService = StorageService();
    _audioService = AudioService();
  }

  void _initializeAnimations() {
    _gaugeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..addListener(() {
      setState(() {
        final double start = (_consos - 1).clamp(0, double.infinity).toDouble();
        _animatedConsos =
            ui.lerpDouble(start, _consos.toDouble(), _gaugeController.value) ??
            _consos.toDouble();
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
    )..repeat();
  }

  Future<void> _loadState() async {
    try {
      // FIX: Ensure messages are loaded before app starts
      await CharacterProfile.ensureMessagesLoaded();

      final data = await _storageService.loadAppState();
      final profile = await _characterService.loadProfile();

      setState(() {
        _consos = data.todayConsos;
        _animatedConsos = data.todayConsos.toDouble();
        _characterService.updateProfile(profile);
      });

      await _recomputeHealth();
      await _characterService.awardDailyXpIfNeeded();
    } catch (e) {
      debugPrint('Error loading state: $e');
    }
  }

  Future<void> _saveState() async {
    if (_isSaving) return;
    _isSaving = true;

    try {
      await _storageService.saveAppState(
        todayConsos: _consos,
        dailyMap: _storageService.dailyMap,
      );
      await _characterService.saveProfile();
    } catch (e) {
      debugPrint('Error saving state: $e');
    } finally {
      _isSaving = false;
    }
  }

  Future<void> _recomputeHealth({bool save = true}) async {
    try {
      _storageService.updateTodayConsos(_consos);
      final newHealth = _characterService.computeHealthFromRisk(
        _storageService.dailyMap,
      );

      setState(() {
        _characterService.updateHealth(newHealth);
      });

      if (save) await _saveState();
    } catch (e) {
      debugPrint('Error in _recomputeHealth: $e');
    }
  }

  Future<void> _addConso() async {
    setState(() {
      _consos += 1;
    });

    // Animations
    _gaugeController.forward(from: 0.0);
    _bubbleController.reset();

    // Audio: play special 'jaune' sound on 8th glass, otherwise normal beer sound
    bool playedJaune = false;
    if (_consos == 8) {
      playedJaune = true;
      await _audioService.playJauneSound();
    } else {
      await _audioService.playConsumptionSound();
    }

    // Fade out audio when animation completes
    // Make the fade much longer when the jaune sound was played so it lasts more
    final Duration fadeDuration =
        playedJaune
            ? const Duration(seconds: 30)
            : const Duration(milliseconds: 800);

    _bubbleController.forward().whenComplete(() {
      _audioService.fadeOutAudio(fadeDuration);
    });

    await _saveState();
    await _recomputeHealth();
  }

  Future<void> _resetTodayConsos() async {
    try {
      setState(() {
        _storageService.resetTodayConsos();
        _consos = 0;
        _animatedConsos = 0.0;
      });

      await _saveState();
      await _recomputeHealth();
    } catch (e) {
      debugPrint('Error in _resetTodayConsos: $e');
    }
  }

  void _showCalendarDialog() {
    CalendarDialog.show(
      context: context,
      buttonKey: _calendarButtonKey,
      animationController: _calendarAnimationController,
      dailyMap: _storageService.dailyMap,
    );
  }

  void _showInfoDialog() {
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
                    style: TextStyle(color: Colors.black87, fontSize: 13),
                    children: [
                      const TextSpan(
                        text: "Les règles de calcul viennent d’un ",
                      ),
                      TextSpan(
                        text: 'rapport officiel',
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
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
                                  debugPrint('Could not launch $uri');
                                }
                              },
                      ),
                      const TextSpan(text: ' de Santé Publique France.'),
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
  }

  @override
  Widget build(BuildContext context) {
    final double percent = _characterService.healthPercent;

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
            children: [
              // Header with info button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _showInfoDialog,
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

              // Health bar
              HealthBar(percent: percent, level: _characterService.level),

              const SizedBox(height: 24),

              // Character with shadow
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
                            return CustomPaint(
                              size: Size(
                                (MediaQuery.of(context).size.width * 0.50)
                                    .clamp(0, 260),
                                (MediaQuery.of(context).size.width * 0.22)
                                    .clamp(0, 70),
                              ),
                              painter: GroundShadowPainter(
                                color: Colors.grey.shade800.withValues(
                                  alpha: 0.35,
                                ),
                                blurSigma: 32,
                                coreFactor: 0.55,
                                t: _shadowController.value,
                                squashAmp: 0.06,
                                shiftAmp: 6.0,
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

              // Character card
              /*CharacterCard(
                name: 'Jaune',
                message: _characterService.currentMessage,
                healthPercent: percent,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BeRealCapturePage(
                        avatarAsset: 'assets/avatar.png',
                        message: _characterService.currentMessage,
                        healthPercent: percent,
                      ),
                    ),
                  );
                },
              ),*/
              const SizedBox(height: 80),

              // Bottom controls
              _buildBottomControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Calendar button
        _buildCalendarButton(),
        const SizedBox(width: 16),
        // Consumption controls
        _buildConsumptionControls(),
      ],
    );
  }

  Widget _buildCalendarButton() {
    return GestureDetector(
      onTap: _showCalendarDialog,
      onTapDown: (_) => setState(() => _isCalendarButtonPressed = true),
      onTapUp: (_) => setState(() => _isCalendarButtonPressed = false),
      onTapCancel: () => setState(() => _isCalendarButtonPressed = false),
      child: AnimatedScale(
        scale: _isCalendarButtonPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          key: _calendarButtonKey,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF7D83F), Color(0xFFF6C84A)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF7D83F).withAlpha((0.65 * 255).round()),
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Voir',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha((0.95 * 255).round()),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.08 * 255).round()),
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
    );
  }

  Widget _buildConsumptionControls() {
    return Row(
      children: [
        // Reset button
        GestureDetector(
          onTap: () {
            showCupertinoDialog(
              context: context,
              builder:
                  (context) => ResetConfirmDialog(
                    onConfirm: () async {
                      await _resetTodayConsos();
                      if (!context.mounted) return;
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
                  color: Colors.black.withAlpha((0.08 * 255).round()),
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
        // Main consumption button with gauge
        _buildConsumptionButton(),
      ],
    );
  }

  Widget _buildConsumptionButton() {
    return Stack(
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
        // Consumption gauge
        CustomPaint(
          size: const Size(88, 88),
          painter: ConsumptionGaugePainter(_animatedConsos),
        ),
        // Main button
        _buildMainButton(),
      ],
    );
  }

  Widget _buildMainButton() {
    return GestureDetector(
      onTap: _addConso,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shadow
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.2 * 255).round()),
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          // Glass effect button
          ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withAlpha((0.28 * 255).round()),
                      Colors.white.withAlpha((0.10 * 255).round()),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withAlpha((0.35 * 255).round()),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  // FIX: Replace emoji with flutter icon for better compatibility
                  child: Icon(Icons.local_bar, size: 32, color: Colors.amber),
                ),
              ),
            ),
          ),
          // Count badge
          Positioned(
            left: 0,
            right: 0,
            bottom: 6,
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
                      color: Colors.black.withAlpha((0.32 * 255).round()),
                      offset: const Offset(0, 1),
                      blurRadius: 6,
                    ),
                    Shadow(
                      color: Colors.white.withAlpha((0.6 * 255).round()),
                      offset: const Offset(0, -1),
                      blurRadius: 0,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Bubble animation overlay
          _audioService.buildBubbleAnimation(_bubbleController),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _gaugeController.dispose();
    _bubbleController.dispose();
    _calendarAnimationController.dispose();
    _shadowController.dispose();
    _audioService.dispose();
    super.dispose();
  }
}
