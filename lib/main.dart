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

      // À l'ouverture de l'app — attribuer +3 XP
      final xpEvent = await _characterService.awardAppOpenXp();
      if (xpEvent != null) {
        _showXpToast(xpEvent);
      }

      // Mettre à jour l'état Rive basé sur la santé et les déblocables
      _updateRiveState();
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

      // Quand l'user enregistre sa conso — vérifier les bonus de comportement
      final result = await _characterService.awardDailyLogXp(
        _storageService.dailyMap,
      );

      // Afficher les toasts XP gagnés
      for (final event in result.xpEvents) {
        _showXpToast(event);
      }

      // Afficher les modales de déblocage
      for (final unlock in result.newUnlocks) {
        _showUnlockModal(unlock);
      }

      // Mettre à jour l'état Rive si la santé a changé
      _updateRiveState();

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

  // ==================== XP & Unlock UI Integration ====================

  /// Affiche un toast avec un événement XP (ex: "+3 XP")
  void _showXpToast(XpEvent event) {
    debugPrint('XP Toast: +${event.amount} XP (${event.reason})');
    // TODO: Implémenter l'affichage du toast avec animation
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text('+${event.amount} XP — ${event.reason}'),
    //     duration: const Duration(seconds: 2),
    //   ),
    // );
  }

  /// Affiche une modal pour un déblocage (nouvel état Rive, badge, message, etc.)
  void _showUnlockModal(LevelUnlock unlock) {
    debugPrint('🎉 Unlock: ${unlock.title} (${unlock.key})');
    // TODO: Implémenter la modal avec animation Rive si state
    // showCupertinoDialog(
    //   context: context,
    //   builder: (context) => CupertinoAlertDialog(
    //     title: Text('🎉 ${unlock.title}'),
    //     content: Text(unlock.description),
    //     actions: [
    //       CupertinoDialogAction(
    //         child: const Text('OK'),
    //         onPressed: () => Navigator.pop(context),
    //       ),
    //     ],
    //   ),
    // );
  }

  /// Met à jour l'état Rive basé sur les déblocables et la santé
  void _updateRiveState() {
    final hp = _characterService.healthPercent;
    final hasHappyState = _characterService.hasUnlock('state_happy');
    final hasSadState = _characterService.hasUnlock('state_sad');

    String riveState = 'state_neutral'; // État par défaut
    if (hasHappyState && hp > 0.75) {
      riveState = 'state_happy';
    } else if (hasSadState && hp < 0.25) {
      riveState = 'state_sad';
    }

    debugPrint(
      '🎨 Rive State: $riveState (HP: ${(hp * 100).toStringAsFixed(1)}%)',
    );
    // TODO: appliquer à riveController.setInput('state', riveState);
  }

  void _showCalendarDialog() {
    CalendarDialog.show(
      context: context,
      buttonKey: _calendarButtonKey,
      animationController: _calendarAnimationController,
      dailyMap: _storageService.dailyMap,
    );
  }

  void _showLevelDialog() {
    final level = _characterService.level;
    final phase = _characterService.levelPhase;
    final xp = _characterService.profile.xp;
    final xpToNext = _characterService.xpToNextLevel;
    final progress = _characterService.levelProgress;
    final unlocks = _characterService.acquiredUnlocks;

    // Feature #1: Phase progression percentage
    final phaseLevels = switch (phase) {
      'discovery' => 5,
      'engagement' => 10,
      _ => 20,
    };
    final levelInPhase = (level - 1) % phaseLevels + 1;
    final phasePercentage = ((levelInPhase / phaseLevels) * 100)
        .toStringAsFixed(0);

    String phaseLabel = switch (phase) {
      'discovery' => '🌱 Découverte',
      'engagement' => '⚡ Engagement',
      _ => '🏆 Maîtrise',
    };

    Color phaseColor = switch (phase) {
      'discovery' => Colors.green,
      'engagement' => Colors.purple,
      _ => Colors.amber,
    };

    // Feature #2: Dynamic rank titles
    String rankTitle = switch (level) {
      <= 5 => 'Apprenti 🌱',
      <= 15 => 'Explorateur 🗺️',
      <= 30 => 'Maître 🏆',
      _ => 'Légende ⭐',
    };

    final currentLevelUnlocks = unlocks.where((u) => u.level == level).toList();
    final nextUnlocks = unlocks.where((u) => u.level > level).take(3).toList();

    // Feature #3: Highlight next key unlock
    final nextUnlock = nextUnlocks.isNotEmpty ? nextUnlocks.first : null;
    final xpToNextKeyUnlock =
        nextUnlock != null ? ((nextUnlock.level - level) * xpToNext) - xp : 0;

    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Column(
              children: [
                Text('🎮 Niveau $level'),
                const SizedBox(height: 8),
                Text(
                  rankTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: phaseColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$phaseLabel • $levelInPhase/$phaseLevels ($phasePercentage%)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // XP Progress
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('XP'),
                                Text(
                                  '$xp/$xpToNext',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 10,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  phaseColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Déblocables actuels
                  if (currentLevelUnlocks.isNotEmpty) ...[
                    const Text(
                      '✨ Déblocables ce niveau',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...currentLevelUnlocks.map((unlock) {
                      final icon = switch (unlock.type) {
                        UnlockType.citronState => '🎨',
                        UnlockType.feature => '⭐',
                        UnlockType.badge => '🏅',
                        UnlockType.message => '💬',
                      };
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$icon ${unlock.title}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              unlock.description,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                  ],
                  // Next key unlock highlighted
                  if (nextUnlock != null) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: phaseColor.withValues(alpha: 0.1),
                        border: Border.all(color: phaseColor, width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🎯 Prochain défi',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Niveau ${nextUnlock.level}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      '${nextUnlock.title}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: phaseColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Text(
                                  '+$xpToNextKeyUnlock XP',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Prochains déblocables
                  if (nextUnlocks.isNotEmpty) ...[
                    const Text(
                      '🎯 Autres déblocables',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...nextUnlocks.skip(1).map((unlock) {
                      final icon = switch (unlock.type) {
                        UnlockType.citronState => '🎨',
                        UnlockType.feature => '⭐',
                        UnlockType.badge => '🏅',
                        UnlockType.message => '💬',
                      };
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          'Niv. ${unlock.level} - $icon ${unlock.title}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Fermer'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
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
              HealthBar(
                percent: percent,
                level: _characterService.level,
                onTap: _showLevelDialog,
              ),

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
                  child: Text(
                    '🍻',
                    style: TextStyle(fontSize: 32, color: Colors.amber),
                  ),
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
