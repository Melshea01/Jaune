import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'package:rive/rive.dart' as rive;
import 'package:flutter/services.dart' show rootBundle;
import 'package:floating_bubbles/floating_bubbles.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

// A safe Rive loader similar to the docs' builder example but adapted
// to the available runtime API in this project.
class ExampleRiveBuilder extends StatefulWidget {
  const ExampleRiveBuilder({super.key});

  @override
  State<ExampleRiveBuilder> createState() => _ExampleRiveBuilderState();
}

class _ExampleRiveBuilderState extends State<ExampleRiveBuilder> {
  // _loadError holds null on success, or a String with the error message+stack
  late Future<String?> _loadError;

  Future<String?> _tryLoadAndParse() async {
    try {
      final data = await rootBundle.load('assets/jaune.riv');
      try {
        // parse to detect errors early
        rive.RiveFile.import(data);
        return null; // success
      } catch (e, st) {
        final msg = 'Rive parse error: $e\n$st';
        debugPrint(msg);
        return msg;
      }
    } catch (e, st) {
      final msg = 'Asset load error: $e\n$st';
      debugPrint(msg);
      return msg;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadError = _tryLoadAndParse();
  }

  Widget _errorWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/avatar.png', width: 120, height: 120),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _loadError,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && snapshot.data != null) {
          // Parsing failed: show error details
          return _errorWidget(snapshot.data!);
        }

        // Parsed OK: return the Rive animation. Use a try/catch to fallback at runtime.
        try {
          return rive.RiveAnimation.asset(
            'assets/jaune.riv',
            fit: BoxFit.contain,
            alignment: Alignment.center,
          );
        } catch (e, st) {
          final msg = 'Rive runtime error: $e\n$st';
          debugPrint(msg);
          return _errorWidget(msg);
        }
      },
    );
  }
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
  static const int maxHealth = 100;
  static const int damagePerClick = 10;
  static const int regenPerDay = 5;

  int _health = maxHealth;
  // ignore: unused_field
  DateTime _lastUpdate = DateTime.now();
  int _consos = 0;
  int _prevConsos = 0;
  double _animatedConsos = 0.0;
  late AnimationController _gaugeController;
  late AnimationController _bubbleController;
  final String _kConsosKey = 'player_consos';

  final String _kHealthKey = 'player_health';
  final String _kLastUpdateKey = 'player_last_update';

  // Rive file loader
  // ...existing code...

  @override
  void initState() {
    super.initState();
    _gaugeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420))
      ..addListener(() {
        setState(() {
          _animatedConsos = (ui.lerpDouble(_prevConsos.toDouble(),
                  _consos.toDouble(), _gaugeController.value) ??
              _consos.toDouble());
        });
      });
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    // init Rive FileLoader
    // debug load removed: use onInit in RiveAnimation.asset to inspect/play animations

    _loadState();
  }

  @override
  void dispose() {
    _gaugeController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedHealth = prefs.getInt(_kHealthKey);
    final savedMillis = prefs.getInt(_kLastUpdateKey);
    final savedConsos = prefs.getInt(_kConsosKey) ?? 0;

    if (savedHealth != null && savedMillis != null) {
      DateTime savedDate = DateTime.fromMillisecondsSinceEpoch(savedMillis);
      final days = DateTime.now().difference(savedDate).inDays;
      int newHealth = savedHealth + days * regenPerDay;
      if (newHealth > maxHealth) newHealth = maxHealth;

      setState(() {
        _health = newHealth;
        _lastUpdate = savedDate;
        _consos = savedConsos;
        _prevConsos = savedConsos;
        _animatedConsos = savedConsos.toDouble();
      });

      await _saveState();
    } else {
      setState(() {
        _health = maxHealth;
        _lastUpdate = DateTime.now();
        _consos = savedConsos;
        _prevConsos = savedConsos;
        _animatedConsos = savedConsos.toDouble();
      });
      await _saveState();
    }
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kHealthKey, _health);
    await prefs.setInt(_kLastUpdateKey, DateTime.now().millisecondsSinceEpoch);
    await prefs.setInt(_kConsosKey, _consos);
    _lastUpdate = DateTime.now();
  }

  void _addConso() {
    setState(() {
      _prevConsos = _consos;
      _consos += 1;
      _health = (_health - damagePerClick).clamp(0, maxHealth);
    });
    _gaugeController.forward(from: 0.0);
    _bubbleController.reset();
    _bubbleController.forward();
    _saveState();
  }

  void _simulateDays(int days) {
    setState(() {
      _health = (_health + days * regenPerDay).clamp(0, maxHealth);
    });
    _saveState();
  }

  // ...existing code...

  @override
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
                    minSize: 0,
                    onPressed: () {
                      showCupertinoDialog(
                        context: context,
                        builder: (context) => CupertinoAlertDialog(
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
                    },
                    child: Icon(
                      Icons.info_outline,
                      color: Colors.grey.shade100.withOpacity(0.7),
                      size: 24,
                    ),
                  ),
                ],
              ),

              Row(children: [
                Text(
                  'Niveau ${(_health / 10).floor()}',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ]),

              // === Barre de vie améliorée ===
              Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Ombre portée pour effet 3D
                  Container(
                    height: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.18),
                          offset: const Offset(0, 4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  // Fond de la barre (effet liquid glass via liquid_glass_renderer)
                  /*LiquidGlass(
                    // utilise la même courbure que précédemment
                    shape: LiquidRoundedSuperellipse(
                        borderRadius: Radius.circular(14)),
                    // Le child contient la décoration (gradient + bord)
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.28),
                            Colors.white.withOpacity(0.10),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.35),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),*/
                  // Barre de vie avec dégradé
                  FractionallySizedBox(
                    widthFactor: percent,
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          colors: percent > 0.6
                              ? [Color(0xFF43e97b), Color(0xFF38f9d7)]
                              : (percent > 0.3
                                  ? [Color(0xFFf7971e), Color(0xFFffd200)]
                                  : [Color(0xFFf85757), Color(0xFFf857a6)]),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.10),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Fond de la barre (effet glass/frosted)

                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                      child: Container(
                        height: 16,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.28),
                              Colors.white.withOpacity(0.10),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.35),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Petite lueur pour renforcer l'effet 3D
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.02),
                              Colors.transparent,
                            ],
                            stops: [0.0, 0.6],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Texte dynamique avec design amélioré
                  Center(
                    child: Text(
                      '${(percent * 100).round()}%',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Colors.transparent,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.32),
                            offset: const Offset(0, 1),
                            blurRadius: 6,
                          ),
                          Shadow(
                            color: Colors.white.withOpacity(0.6),
                            offset: const Offset(0, -1),
                            blurRadius: 0,
                          ),
                        ],
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // === Image / Rive du personnage (fix layout) ===
              /*Center(
                child: SizedBox(
                  width: 320,
                  height: 320,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: Colors.transparent,
                      child: ExampleRiveBuilder(),
                    ),
                  ),
                ),
              ),*/

              const SizedBox(height: 20),

              // === Message du personnage ===

              Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.only(left: 32, right: 32),
                      decoration: BoxDecoration(
                          color: const Color(0xFFF7D83F),
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8))),
                      child: Text(
                        "Jaune",
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Colors.black87,
                          letterSpacing: 0.6,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.20),
                              offset: const Offset(0, 2),
                              blurRadius: 6,
                            ),
                            Shadow(
                              color: Colors.white.withOpacity(0.85),
                              offset: const Offset(0, -1),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              end: Alignment.bottomCenter,
                              begin: Alignment.topCenter,
                              colors: [
                                const Color(0xFFF7D83F),
                                const Color(0xFFEFB192)
                              ]),
                          borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                              topRight: Radius.circular(16))),
                      child: Container(
                          padding: const EdgeInsets.only(
                              left: 16, right: 8, bottom: 8, top: 16),
                          margin: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(32),
                              bottomRight: Radius.circular(16),
                              topRight: Radius.circular(32),
                              topLeft: Radius.circular(16),
                            ),
                            color: Colors.white,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(0.98),
                                Colors.grey.shade50,
                              ],
                            ),
                            boxShadow: [
                              // ombre principale
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                offset: const Offset(0, 8),
                                blurRadius: 18,
                              ),
                              // ombre douce sous la carte pour le relief
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                offset: const Offset(0, 4),
                                blurRadius: 8,
                              ),
                              // léger halo intérieur en haut (simulé par offset négatif)
                              BoxShadow(
                                color: Colors.white.withOpacity(0.9),
                                offset: const Offset(0, -2),
                                blurRadius: 6,
                                spreadRadius: -4,
                              ),
                            ],
                          ),
                          child: Column(children: [
                            Text(
                              "Un autre ? Bien sûr. Ta volonté, c'est de l'eau gazeuse.",
                              textAlign: TextAlign.left,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                fontSize: 16,
                                color: Colors.black87,
                                fontStyle: FontStyle.italic,
                                height: 1.35,
                                letterSpacing: 0.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.08),
                                    offset: const Offset(0, 2),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            //Logo instagram à droite
                            Container(
                              alignment: Alignment.centerRight,
                              child: Image.asset(
                                'assets/instagram.png',
                                width: 32,
                                height: 32,
                              ),
                            )
                          ])),
                    ),
                  ],
                ),
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
                    onPressed: () {
                      setState(() {
                        _health = maxHealth;
                        _consos = 0;
                      });
                      _saveState();
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
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFF7D83F), Color(0xFFF6C84A)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          offset: const Offset(0, 6),
                          blurRadius: 16,
                        ),
                      ],
                      border: Border.all(
                          color: Colors.white.withOpacity(0.22), width: 1.0),
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
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black87,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Voir',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.black54,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.95),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
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
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                      // Jauge de consommation (anneau visible)
                      CustomPaint(
                        size: const Size(88, 88),
                        painter: ConsumptionGaugePainter(
                          _animatedConsos,
                        ),
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
                                    color: Colors.black.withOpacity(0.2),
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
                                    sigmaX: 6.0, sigmaY: 6.0),
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.white.withOpacity(0.28),
                                        Colors.white.withOpacity(0.10),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.35),
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
                                        color: Colors.black.withOpacity(0.32),
                                        offset: const Offset(0, 1),
                                        blurRadius: 6,
                                      ),
                                      Shadow(
                                        color: Colors.white.withOpacity(0.6),
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
                                    if (_bubbleController.value == 0 ||
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
                                      opacity: 40,
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
class ConsumptionGaugePainter extends CustomPainter {
  final double
      segments; // nombre de demi-cercles à afficher (peut être fractionnel pour animation)

  ConsumptionGaugePainter(this.segments);

  // Retourne la couleur interpolée pour un segment.
  // Si l'index dépasse la palette, on reste sur la couleur rouge finale.
  Color _colorForIndex(int i, double t) {
    final List<Color> gradientColors = [
      const Color(0xFF43e97b),
      const Color(0xFF38f9d7),
      const Color(0xFFc6e66b),
      const Color(0xFFffd200),
      const Color(0xFFf6a564),
      const Color(0xFFfb8c00),
      const Color(0xFFe53935),
      const Color(0xFFbf1b1b),
      const Color(0xFFff5252),
      const Color(0xFFFF0000)
    ];

    if (i >= gradientColors.length - 1) {
      // Si on dépasse la palette, rester sur le rouge final
      return gradientColors.last;
    }

    final int colorIndexStart = i;
    final int colorIndexEnd =
        (colorIndexStart + 1).clamp(0, gradientColors.length - 1);

    return Color.lerp(
        gradientColors[colorIndexStart], gradientColors[colorIndexEnd], t)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseStroke = 8.0;
    final baseRadius =
        math.min(size.width, size.height) / 2 - baseStroke / 2 - 2;

    // anneau de fond glass (visible même si segments == 0)
    final Paint bg = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = baseStroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    final rectBg = Rect.fromCircle(center: center, radius: baseRadius);
    canvas.drawArc(rectBg, 0, 2 * math.pi, false, bg);

    if (segments <= 0) return;

    final int totalToDraw = segments.ceil();
    int lastVisible = totalToDraw - 1;
    double lastCompleted = (segments - lastVisible).clamp(0.0, 1.0);
    if (lastCompleted == 0.0) {
      lastVisible -= 1;
      lastCompleted = 1.0;
    }

    for (int i = 0; i < totalToDraw; i++) {
      final startAngle = -math.pi / 2 + i * math.pi;
      final sweep = math.pi; // demi-tour
      final completed = (segments - i).clamp(0.0, 1.0);
      if (completed <= 0) break;

      final rect = Rect.fromCircle(center: center, radius: baseRadius);
      // Découpage en petits arcs pour un dégradé parfait
      const int subdivisions = 32;
      final int maxSub = (subdivisions * completed).ceil();
      for (int s = 0; s < maxSub; s++) {
        final double t0 = s / subdivisions;
        final double t1 = (s + 1) / subdivisions;
        if (t1 > completed) break;
        final double angle0 = startAngle + sweep * t0;
        final double angle1 = startAngle + sweep * t1;
        final path = Path()
          ..moveTo(
            center.dx + baseRadius * math.cos(angle0),
            center.dy + baseRadius * math.sin(angle0),
          )
          ..arcTo(
            rect,
            angle0,
            angle1 - angle0,
            false,
          );

        final color = _colorForIndex(i, t0);

        // Ajout d'un halo lumineux autour de la jauge
        final haloPaint = Paint()
          ..color = color.withOpacity(0.2)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = baseStroke * 1.5;
        canvas.drawPath(path, haloPaint);

        final paint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true
          ..strokeWidth = baseStroke;
        canvas.drawPath(path, paint);
      }
    }

    // Ajouter une ombre au dernier segment visible
    if (lastVisible >= 0) {
      final double startAngle = -math.pi / 2 + lastVisible * math.pi;
      final double sweep = math.pi * lastCompleted;
      final rect = Rect.fromCircle(center: center, radius: baseRadius);

      // Découpage en petits arcs pour un dégradé d'ombre
      const int subdivisions = 32;
      for (int s = 0; s < subdivisions; s++) {
        final double t0 = s / subdivisions;
        final double t1 = (s + 1) / subdivisions;
        if (t1 > lastCompleted) break;

        final double angle0 = startAngle + sweep * t0;
        final double angle1 = startAngle + sweep * t1;
        final path = Path()
          ..moveTo(
            center.dx + baseRadius * math.cos(angle0),
            center.dy + baseRadius * math.sin(angle0),
          )
          ..arcTo(
            rect,
            angle0,
            angle1 - angle0,
            false,
          );

        final shadowOpacity = t1; // Opacité progressive
        final shadowPaint = Paint()
          ..color = Colors.black.withOpacity(0.05 * shadowOpacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = baseStroke;
        canvas.drawPath(path, shadowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
