import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'l10n/gen/app_localizations.dart';
import 'onboarding/onboarding_flow.dart';
import 'services/audio_service.dart';
import 'services/character_service.dart';
import 'services/home_widget_service.dart';
import 'services/milestone_scheduler.dart';
import 'services/settings_service.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'services/deterministic_scheduler.dart';
import 'controllers/citron_animation_controller.dart';
import 'be_real_capture_page.dart';
import 'widgets/calendar_dialog.dart';
import 'widgets/character_card.dart';
import 'widgets/confirm_sheet.dart';
import 'widgets/consumption_gauge_painter.dart';
import 'widgets/ground_shadow_painter.dart';
import 'widgets/health_bar.dart';
import 'widgets/settings_sheet.dart';
import 'widgets/stats_sheet.dart';
import 'widgets/citron_character.dart';
import 'widgets/citron_debug_panel.dart';
import 'widgets/xp_toast.dart';
import 'widgets/level_up_celebration.dart';
import 'widgets/streak_badge.dart';
import 'widgets/level_sheet.dart';
import 'widgets/info_sheet.dart';
import 'widgets/pressable.dart';
import 'theme/jaune_design.dart';
import 'utils/date_keys.dart';
import 'utils/jaune_haptics.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // Initialisation de l'application Jaune
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone data
  tz.initializeTimeZones();

  // Initialize notifications
  await NotificationService.initialize();

  // Appliquer le style à la barre de statut
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF95C6F4),
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.dark,
    ),
  );

  // Forcer l'orientation portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Préférences utilisateur (langue, etc.) avant le premier build
  await SettingsService.instance.load();

  // Date formatting (TableCalendar / intl) pour toutes les locales supportées
  await initializeDateFormatting();

  // Premier lancement : onboarding avant la home
  final prefs = await SharedPreferences.getInstance();
  final bool onboardingDone = prefs.getBool(kOnboardingDoneKey) ?? false;

  runApp(MyApp(showOnboarding: !onboardingDone));
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;

  const MyApp({super.key, this.showOnboarding = false});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: SettingsService.instance.localeOverride,
      builder: (context, localeOverride, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          locale: localeOverride,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          home: showOnboarding ? const OnboardingFlow() : const MyHomePage(),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Services
  late final CharacterService _characterService;
  late final StorageService _storageService;
  final AudioService _audioService = AudioService.instance;

  // State variables
  int _consos = 0;
  double _animatedConsos = 0.0;
  DateTime? _lastBejaunePost;

  /// Jour auquel appartient le compteur _consos — détecte le passage de
  /// minuit (app ouverte pendant une soirée) pour ne pas écrire le compteur
  /// d'hier sur la clé d'aujourd'hui
  String _consosDay = '';

  // Animation controllers
  late AnimationController _gaugeController;
  late AnimationController _bubbleController;
  late AnimationController _calendarAnimationController;
  late AnimationController _shadowController;
  late AnimationController _shineController;
  late CitronAnimationController _citronController;

  // Calendar state
  final GlobalKey _calendarButtonKey = GlobalKey();
  bool _showDebugPanel = false;

  // Citron interaction state
  Timer? _citronReactionTimer;
  final List<DateTime> _citronTaps = [];

  // Bulle de dialogue du citron (personnalité)
  String _bubbleMessage = '';
  bool _bubbleVisible = false;
  Timer? _bubbleTimer;
  DateTime? _lastTapBubbleAt;
  String _lastHealthZone = '';

  /// Réglage système « Réduire les animations » : coupe les boucles
  /// décoratives (reflet, ombre) — l'information d'état reste intacte
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce == _reduceMotion) return;
    _reduceMotion = reduce;
    if (reduce) {
      _shadowController.stop();
      _shineController.stop();
    } else {
      _shadowController.repeat();
      _shineController.repeat();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
    _initializeAnimations();
    _initializeShineAnimation();
    _loadState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Retour au premier plan : si on a changé de jour entre-temps,
    // recharger le compteur et recalculer santé/XP du nouveau jour
    if (state == AppLifecycleState.resumed && _consosDay.isNotEmpty) {
      final today = dateKey(DateTime.now());
      if (today != _consosDay) {
        _rolloverToNewDay();
      }
    }
  }

  /// Passage de minuit : repartir du compteur du nouveau jour
  Future<void> _rolloverToNewDay() async {
    _consosDay = dateKey(DateTime.now());
    setState(() {
      _consos = _storageService.getTodayConsos();
      _animatedConsos = _consos.toDouble();
    });
    await _recomputeHealth(isUserLog: false);
    await _scheduleDailyNotification();
  }

  /// Garde-fou avant toute écriture du compteur : si minuit est passé
  /// pendant que l'app était ouverte, bascule sur le nouveau jour d'abord
  Future<void> _ensureCurrentDay() async {
    if (_consosDay.isEmpty) return;
    if (dateKey(DateTime.now()) != _consosDay) {
      await _rolloverToNewDay();
    }
  }

  void _initializeServices() {
    _characterService = CharacterService();
    _storageService = StorageService();
    _citronController = CitronAnimationController();

    NotificationService.onNotificationTap = (payload) async {
      if (payload == 'be_real_capture') {
        await _openBeRealCapture();
      }
    };
  }

  /// Ouvre la page de capture BeJaune et marque le post si une photo
  /// a été partagée. Point d'entrée unique (notification + bouton CTA).
  Future<void> _openBeRealCapture() async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    final health = _characterService.healthPercent;
    final l10n = lookupAppLocalizations(
      SettingsService.instance.effectiveLocale,
    );
    final message = l10n.bejauneScoreMessage((health * 100).round());

    final result = await navigator.push(
      MaterialPageRoute(
        builder:
            (context) => BeRealCapturePage(
              avatarAsset: 'assets/avatar.png',
              message: message,
              healthPercent: health,
              level: _characterService.level,
              streakDays: _characterService.soberStreakDays,
            ),
      ),
    );
    if (result != null) {
      await _markBejaunePosted();
    }
  }

  void _initializeAnimations() {
    _gaugeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addListener(() {
      setState(() {
        // Courbe easeOutCubic : la jauge file vite puis se pose en douceur
        final double t = JauneMotion.smooth.transform(_gaugeController.value);
        final double start = (_consos - 1).clamp(0, double.infinity).toDouble();
        _animatedConsos =
            ui.lerpDouble(start, _consos.toDouble(), t) ?? _consos.toDouble();
      });
    });

    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    _calendarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      // La fermeture doit être plus rapide que l'ouverture (convention iOS)
      reverseDuration: const Duration(milliseconds: 260),
    );

    _shadowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  void _initializeShineAnimation() {
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  Future<void> _loadState() async {
    try {
      // FIX: Ensure messages are loaded before app starts
      await CharacterProfile.ensureMessagesLoaded(
        SettingsService.instance.effectiveLocale.languageCode,
      );

      final data = await _storageService.loadAppState();
      final profile = await _characterService.loadProfile();
      final lastBejaunePost = await _storageService.getLastBejaunePost();

      setState(() {
        _consos = data.todayConsos;
        _animatedConsos = data.todayConsos.toDouble();
        _characterService.updateProfile(profile);
        _lastBejaunePost = lastBejaunePost;
        _consosDay = dateKey(DateTime.now());
      });

      // Recalcul à l'ouverture : pas une action de log de l'utilisateur
      await _recomputeHealth(isUserLog: false);

      // Programmer la notification BeReal du jour si pas encore envoyée
      await _scheduleDailyNotification();

      // À l'ouverture de l'app — attribuer +3 XP
      final xpResult = await _characterService.awardAppOpenXp();
      if (xpResult.xpEvent != null) {
        _showXpToast(xpResult.xpEvent!);
      }
      if (xpResult.newLevels.isNotEmpty) {
        _showLevelUpCelebration(xpResult.newLevels, xpResult.newUnlocks);
      }

      // Mettre à jour l'état Rive basé sur la santé et les déblocables
      _updateRiveState();

      // Petit salut de bienvenue du citron
      _playCitronReaction('greeting', duration: const Duration(seconds: 3));

      // Première ouverture du jour : le citron a un mot pour toi
      _lastHealthZone = _characterService.profile.zone;
      await _maybeGreetWithBubble();
    } catch (e) {
      debugPrint('Error loading state: $e');
    }
  }

  bool get _hasPostedBejauneToday {
    final last = _lastBejaunePost;
    if (last == null) return false;
    return isSameCalendarDay(last, DateTime.now());
  }

  bool get _isWithinAperoWindow {
    return DeterministicNotificationScheduler.isWithinAperoWindow();
  }

  bool get _canPostBejaune {
    return _isWithinAperoWindow && !_hasPostedBejauneToday;
  }

  Future<void> _markBejaunePosted() async {
    final now = DateTime.now();
    await _storageService.setLastBejaunePost(now);
    if (mounted) {
      setState(() => _lastBejaunePost = now);
    }
  }

  /// [isUserLog] : true quand le recalcul vient d'une vraie action de log
  /// (bouton conso / reset) — conditionne le bonus « Enregistrement du jour »
  Future<void> _recomputeHealth({
    bool save = true,
    bool isUserLog = true,
  }) async {
    try {
      await _storageService.updateTodayConsos(_consos);
      final newHealth = _characterService.computeHealthFromRisk(
        _storageService.dailyMap,
      );

      setState(() {
        _characterService.updateHealth(newHealth);
      });

      // Changement de palier de santé après un vrai log : le citron commente
      final String zone = _characterService.profile.zone;
      if (isUserLog && _lastHealthZone.isNotEmpty && zone != _lastHealthZone) {
        _showCitronBubble(engineEvent: 'curious');
      }
      _lastHealthZone = zone;

      // Quand l'user enregistre sa conso — vérifier les bonus de comportement
      final result = await _characterService.awardDailyLogXp(
        _storageService.dailyMap,
        includeLogBonus: isUserLog,
      );

      // Afficher les toasts XP gagnés + saut de joie du citron
      for (final event in result.xpEvents) {
        _showXpToast(event);
        // Palier de streak : carillon + double haptique
        if (event.reason == XpReason.soberStreak) {
          JauneHaptics.milestone();
          await _audioService.playStreakChime();
        }
      }
      if (result.xpEvents.isNotEmpty && !_citronController.hasActiveEvent) {
        _citronController.triggerEvent('jump_joy');
      }

      // Célébration de level-up avec les déblocables gagnés
      if (result.newLevels.isNotEmpty) {
        _showLevelUpCelebration(result.newLevels, result.newUnlocks);
      }

      // Mettre à jour l'état Rive si la santé a changé
      _updateRiveState();

      // Les consos sont déjà persistées en tête de méthode ; il ne reste
      // que le profil (XP/PV) à sauvegarder
      if (save) await _characterService.saveProfile();

      // Notifications de rétention (palier de streak, teaser de niveau) —
      // ré-évaluées idempotemment à chaque changement d'état
      await MilestoneScheduler.evaluate(
        character: _characterService,
        todayDrinks: _consos,
      );

      // Widget d'écran d'accueil : reflète le citron du moment
      await HomeWidgetService.sync(
        healthPercent: _characterService.healthPercent,
        streakDays: _characterService.soberStreakDays,
        level: _characterService.level,
      );
    } catch (e) {
      debugPrint('Error in _recomputeHealth: $e');
    }
  }

  Future<void> _addConso() async {
    // Minuit passé pendant que l'app était ouverte ? Nouveau jour d'abord.
    await _ensureCurrentDay();

    HapticFeedback.mediumImpact();
    // Feedback immédiat : le citron penche la tête en arrière et "boit"
    _citronController.triggerEvent('drink_beer');
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
      HapticFeedback.heavyImpact();
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

    // _recomputeHealth persiste consos + profil : pas de double save
    await _recomputeHealth();

    // Réaction visuelle du citron au verre loggé. Seuil 'drunk' à 6 verres :
    // aligné sur la pénalité binge de la formule PV (OMS)
    _playCitronReaction(_consos >= 6 ? 'drunk' : 'tipsy');
  }

  Future<void> _resetTodayConsos() async {
    try {
      setState(() {
        _storageService.resetTodayConsos();
        _consos = 0;
        _animatedConsos = 0.0;
      });

      // _recomputeHealth persiste consos + profil : pas de double save
      await _recomputeHealth();
    } catch (e) {
      debugPrint('Error in _resetTodayConsos: $e');
    }
  }

  Future<void> _scheduleDailyNotification() async {
    if (!SettingsService.instance.notificationsEnabled.value) return;
    try {
      final scheduledTime =
          DeterministicNotificationScheduler.getNextNotificationTime();
      final lastSent = await _storageService.getLastNotificationSent();

      if (!DeterministicNotificationScheduler.isNotificationSentToday(
        lastSent,
      )) {
        // Copie localisée figée au moment du scheduling — re-planifiée chaque
        // jour, donc un changement de langue est rattrapé dès le lendemain
        final l10n = lookupAppLocalizations(
          SettingsService.instance.effectiveLocale,
        );
        await NotificationService.scheduleNotification(
          scheduledTime: scheduledTime,
          title: l10n.notifAperoTitle,
          body: l10n.notifAperoBody,
          payload: 'be_real_capture',
        );
        // Marquer comme programmée
        await _storageService.setLastNotificationSent(DateTime.now());
      }
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  // ==================== XP & Unlock UI Integration ====================

  /// Affiche un toast animé avec un événement XP (ex: "+3 XP")
  void _showXpToast(XpEvent event) {
    debugPrint('XP Toast: +${event.amount} XP (${event.reason.name})');
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay != null) {
      XpToastManager.show(overlay, event);
    } else {
      // Premier frame pas encore rendu : on attend la fin du build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final o = navigatorKey.currentState?.overlay;
        if (o != null) XpToastManager.show(o, event);
      });
    }
  }

  /// Affiche la célébration plein écran de level-up (confettis + déblocables)
  void _showLevelUpCelebration(List<int> newLevels, List<LevelUnlock> unlocks) {
    if (newLevels.isEmpty) return;
    void doShow() {
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;
      LevelUpCelebration.show(
        context: ctx,
        newLevel: newLevels.last,
        unlocks: unlocks,
        skin: _characterService.profile.equippedSkin,
      ).then((_) {
        // Payoff à la fermeture : saut spectaculaire + flash d'aura dorée
        if (mounted) {
          _citronController.triggerEvent('mega_jump');
          _citronController.kickGlow();
        }
      });
    }

    if (navigatorKey.currentContext != null) {
      doShow();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => doShow());
    }
  }

  // ==================== Personnalité du citron ====================

  /// Affiche un message du citron dans sa bulle (4 s), avec une réaction
  /// d'animation optionnelle synchronisée.
  void _showCitronBubble({String? engineEvent}) {
    final String msg = _characterService.currentMessage;
    if (msg.isEmpty) return;

    _bubbleTimer?.cancel();
    setState(() {
      _bubbleMessage = msg;
      _bubbleVisible = true;
    });
    if (engineEvent != null && !_citronController.hasActiveEvent) {
      _citronController.triggerEvent(engineEvent);
    }
    _bubbleTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _bubbleVisible = false);
    });
  }

  /// Salut parlé du citron à la première ouverture du jour
  Future<void> _maybeGreetWithBubble() async {
    final prefs = await SharedPreferences.getInstance();
    final today = dateKey(DateTime.now());
    if (prefs.getString('last_bubble_greet_date') == today) return;
    await prefs.setString('last_bubble_greet_date', today);

    // Laisse le greeting d'animation s'installer avant la bulle
    Timer(const Duration(milliseconds: 1200), () {
      if (mounted) _showCitronBubble(engineEvent: 'encourage');
    });
  }

  /// Joue une animation spéciale du citron puis revient à l'état de santé
  void _playCitronReaction(
    String name, {
    Duration duration = const Duration(milliseconds: 2500),
  }) {
    _citronReactionTimer?.cancel();
    _citronController.playSpecialAnimation(name);
    _citronReactionTimer = Timer(duration, () {
      if (mounted) _updateRiveState();
    });
  }

  /// Tap sur le citron : salut + easter egg danse secrète (10 taps rapides)
  void _onCitronTap() {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    _citronTaps.add(now);
    _citronTaps.removeWhere(
      (t) => now.difference(t) > const Duration(seconds: 5),
    );

    if (_citronTaps.length >= 10) {
      _citronTaps.clear();
      HapticFeedback.heavyImpact();
      _playCitronReaction('secretDance', duration: const Duration(seconds: 5));
    } else {
      // Variété : le citron ne réagit jamais deux fois pareil au toucher
      const tapEvents = ['jump_joy', 'curious', 'hiccup', 'coin_spin'];
      _citronController.triggerEvent(
        tapEvents[_citronTaps.length % tapEvents.length],
      );
      _playCitronReaction('greeting');

      // Et parfois il parle — avec un cooldown pour ne pas spammer
      final now2 = DateTime.now();
      if (_lastTapBubbleAt == null ||
          now2.difference(_lastTapBubbleAt!) > const Duration(seconds: 30)) {
        _lastTapBubbleAt = now2;
        _showCitronBubble();
      }
    }
  }

  /// Met à jour l'état du citron basé sur la santé
  void _updateRiveState() {
    final hp = _characterService.healthPercent;

    _citronController.updateHealth((hp * 100).toInt());

    // Humeur pour les micro-comportements d'idle, alignée sur les presets
    // d'animation : happy ≥75 %, neutral ≥50 % (citron souriant),
    // low <50 % (citron fatigué/malade)
    _citronController.idleMood =
        hp >= 0.75
            ? 'happy'
            : hp >= 0.50
            ? 'neutral'
            : hp > 0
            ? 'low'
            : 'none';

    debugPrint('🎨 Citron Animation: HP ${(hp * 100).toStringAsFixed(1)}%');
  }

  void _showCalendarDialog() {
    HapticFeedback.selectionClick();
    CalendarDialog.show(
      context: context,
      buttonKey: _calendarButtonKey,
      animationController: _calendarAnimationController,
      dailyMap: _storageService.dailyMap,
    );
  }

  void _showLevelDialog() {
    LevelSheet.show(context, _characterService);
  }

  void _showStatsSheet() {
    StatsSheet.show(
      context,
      dailyMap: _storageService.dailyMap,
      character: _characterService,
    );
  }

  void _showInfoDialog() {
    InfoSheet.show(context);
  }

  void _showSettingsSheet() {
    SettingsSheet.show(
      context,
      onNotificationsChanged: _onNotificationsChanged,
      onDeleteData: _deleteAllData,
    );
  }

  Future<void> _onNotificationsChanged(bool enabled) async {
    if (enabled) {
      // L'utilisateur a pu refuser la permission à l'onboarding :
      // re-déclencher le dialogue système si nécessaire
      await NotificationService.requestPermissions();
      // Le marqueur « déjà programmée aujourd'hui » bloquerait le
      // re-scheduling immédiat : on l'efface avant de re-planifier
      await _storageService.clearLastNotificationSent();
      await _scheduleDailyNotification();
    } else {
      await NotificationService.cancelAll();
    }
  }

  /// Suppression complète : consommations, progression et réglages.
  /// L'app repart d'un état neuf, onboarding compris.
  Future<void> _deleteAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await NotificationService.cancelAll();
    await SettingsService.instance.load();
    _characterService.updateProfile(
      CharacterProfile(maxPv: 100, currentPv: 100),
    );
    navigatorKey.currentState?.pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: JauneMotion.standard,
        pageBuilder: (_, __, ___) => const OnboardingFlow(),
        transitionsBuilder:
            (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
      ),
      (route) => false,
    );
  }

  Future<void> _navigateToBeRealCapture() async {
    if (!_canPostBejaune) return;
    await _openBeRealCapture();
  }

  Widget _buildShineEffect() {
    const buttonWidth = 200.0; // approximate width

    // Le reflet balaye pendant 40% du cycle puis se repose : plus élégant
    // qu'un balayage permanent, et attire l'œil par intermittence.
    final sweep = Curves.easeInOut.transform(
      (_shineController.value / 0.4).clamp(0.0, 1.0),
    );
    final shinePosition = (sweep * (buttonWidth + 60)) - 60;

    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Transform.translate(
          offset: Offset(shinePosition, 0),
          child: Container(
            width: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.white.withAlpha(0),
                  Colors.white.withAlpha((0.4 * 255).round()),
                  Colors.white.withAlpha(0),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
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
            // Trois stops : le ciel garde de la présence jusqu'à mi-écran
            // avant de fondre vers le blanc — plus de profondeur
            gradient: LinearGradient(
              colors: [JauneColors.sky, JauneColors.skyLight, Colors.white],
              stops: [0.0, 0.45, 1.0],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              // Header with streak badge and info button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  StreakBadge(
                    streakDays: _characterService.soberStreakDays,
                    onTap: _showLevelDialog,
                  ),
                  const Spacer(),
                  // Outil de debug : uniquement en build debug, jamais en prod
                  if (kDebugMode) ...[
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed:
                          () => setState(
                            () => _showDebugPanel = !_showDebugPanel,
                          ),
                      child: Icon(
                        Icons.bug_report,
                        color: Colors.grey.shade100.withAlpha(
                          (0.7 * 255).round(),
                        ),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
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
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _showSettingsSheet,
                    child: Icon(
                      CupertinoIcons.gear,
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
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        bottom: 0,
                        child: AnimatedBuilder(
                          animation: _shadowController,
                          builder: (context, _) {
                            // Hauteur de saut du citron (0..1) : l'ombre
                            // rétrécit et s'éclaircit quand il décolle
                            final jumpHeight =
                                (-_citronController.engine.frame.translateY)
                                    .clamp(0.0, 200.0) /
                                200.0;
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
                                jumpFactor: jumpHeight,
                              ),
                            );
                          },
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: AppLocalizations.of(context).a11yCitron,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: _onCitronTap,
                          child: ValueListenableBuilder<String>(
                            valueListenable: _characterService.equippedSkin,
                            builder:
                                (context, skin, _) => CitronCharacter(
                                  controller: _citronController,
                                  skin: skin,
                                ),
                          ),
                        ),
                      ),
                      // Bulle de dialogue du citron, au-dessus de sa tête
                      Positioned(
                        top: -64,
                        left: -40,
                        right: -40,
                        child: Center(
                          child: CitronSpeechBubble(
                            message: _bubbleMessage,
                            visible: _bubbleVisible,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Debug panel (toggleable, debug uniquement)
              if (kDebugMode && _showDebugPanel)
                SizedBox(
                  height: 220,
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CitronDebugPanel(controller: _citronController),
                    ),
                  ),
                ),

              const SizedBox(height: 40),
              // Capture button with shine effect — le swap actif/verrouillé
              // est animé (fondu + pop) au lieu d'un changement sec
              AnimatedSwitcher(
                duration: JauneMotion.standard,
                switchInCurve: JauneMotion.springy,
                switchOutCurve: JauneMotion.smooth,
                transitionBuilder:
                    (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(
                          begin: 0.92,
                          end: 1.0,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                child: _buildBejauneCta(),
              ),
              const SizedBox(height: 30),

              // Bottom controls
              _buildBottomControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBejauneCta() {
    if (_canPostBejaune) {
      return PressableScale(
        key: const ValueKey('bejaune-active'),
        onTap: _navigateToBeRealCapture,
        semanticLabel: AppLocalizations.of(context).postBejaune,
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF95C6F4), Color(0xFF5E9FD5)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFF95C6F4,
                    ).withAlpha((0.5 * 255).round()),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context).postBejaune,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Shine effect overlay
            AnimatedBuilder(
              animation: _shineController,
              builder: (context, _) {
                return _buildShineEffect();
              },
            ),
          ],
        ),
      );
    }

    final label =
        _hasPostedBejauneToday
            ? AppLocalizations.of(context).alreadyPostedToday
            : AppLocalizations.of(context).availableAtApero;
    // Le bas de l'écran est blanc : il faut un contraste sombre
    return CustomPaint(
      key: const ValueKey('bejaune-locked'),
      painter: _DashedRoundedRectPainter(
        color: JauneColors.inkSoft.withValues(alpha: 0.45),
        radius: 16,
        strokeWidth: 2.0,
        dashLength: 10,
        gapLength: 6,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: JauneColors.inkSoft,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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
        const SizedBox(width: 10),
        // Stats button
        _buildStatsButton(),
        const Spacer(),
        // Consumption controls
        _buildConsumptionControls(),
      ],
    );
  }

  Widget _buildStatsButton() {
    return PressableScale(
      onTap: _showStatsSheet,
      semanticLabel: AppLocalizations.of(context).a11yStatsButton,
      child: Container(
        width: 44,
        height: 44,
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
          CupertinoIcons.chart_bar_alt_fill,
          color: Color(0xFFF7D83F),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildCalendarButton() {
    return PressableScale(
      onTap: _showCalendarDialog,
      haptic: false, // _showCalendarDialog gère déjà l'haptique
      semanticLabel: AppLocalizations.of(context).a11yCalendarButton,
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
                  AppLocalizations.of(context).calendarTitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context).calendarSee,
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
    );
  }

  Widget _buildConsumptionControls() {
    return Row(
      children: [
        // Reset button
        PressableScale(
          pressedScale: 0.9,
          haptic: false,
          semanticLabel: AppLocalizations.of(context).a11yResetButton,
          onTap: () async {
            HapticFeedback.lightImpact();
            final l10n = AppLocalizations.of(context);
            final confirmed = await ConfirmSheet.show(
              context,
              title: l10n.resetDayTitle,
              message: l10n.resetDayMessage,
              confirmLabel: l10n.resetAction,
              cancelLabel: l10n.cancel,
            );
            if (confirmed) await _resetTodayConsos();
          },
          // Zone de hit ≥44pt (HIG) sans changer le visuel 32pt
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            color: Colors.transparent,
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
        ),
        const SizedBox(width: 2),
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
    return PressableScale(
      onTap: _addConso,
      pressedScale: 0.88,
      haptic: false, // _addConso joue déjà un mediumImpact
      semanticLabel: AppLocalizations.of(context).a11yAddDrink(_consos),
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
          // Count badge — pop d'échelle à chaque verre ajouté
          Positioned(
            left: 0,
            right: 0,
            bottom: 6,
            child: Center(
              child: AnimatedSwitcher(
                duration: JauneMotion.quick,
                switchInCurve: JauneMotion.springy,
                transitionBuilder:
                    (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                child: KeyedSubtree(
                  // Le switcher détecte le changement par cette clé ;
                  // la Key('conso-count') reste pour les widget tests
                  key: ValueKey<int>(_consos),
                  child: Text(
                    '$_consos',
                    key: const Key('conso-count'),
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
            ),
          ),
          // Bubble animation overlay
          // _audioService.buildBubbleAnimation(_bubbleController),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gaugeController.dispose();
    _bubbleController.dispose();
    _calendarAnimationController.dispose();
    _shadowController.dispose();
    _shineController.dispose();
    _citronReactionTimer?.cancel();
    _bubbleTimer?.cancel();
    _citronController.dispose();
    super.dispose();
  }
}

class _DashedRoundedRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  _DashedRoundedRectPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashLength;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRoundedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.gapLength != gapLength;
  }
}
