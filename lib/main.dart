import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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

class _MyHomePageState extends State<MyHomePage> {
  static const int maxHealth = 100;
  static const int damagePerClick = 10;
  static const int regenPerDay = 5;

  int _health = maxHealth;
  DateTime _lastUpdate = DateTime.now();

  final String _kHealthKey = 'player_health';
  final String _kLastUpdateKey = 'player_last_update';

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedHealth = prefs.getInt(_kHealthKey);
    final savedMillis = prefs.getInt(_kLastUpdateKey);

    if (savedHealth != null && savedMillis != null) {
      DateTime savedDate = DateTime.fromMillisecondsSinceEpoch(savedMillis);
      final days = DateTime.now().difference(savedDate).inDays;
      int newHealth = savedHealth + days * regenPerDay;
      if (newHealth > maxHealth) newHealth = maxHealth;

      setState(() {
        _health = newHealth;
        _lastUpdate = savedDate;
      });

      await _saveState();
    } else {
      setState(() {
        _health = maxHealth;
        _lastUpdate = DateTime.now();
      });
      await _saveState();
    }
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kHealthKey, _health);
    await prefs.setInt(_kLastUpdateKey, DateTime.now().millisecondsSinceEpoch);
    _lastUpdate = DateTime.now();
  }

  void _drinkBeer() {
    setState(() {
      _health = (_health - damagePerClick).clamp(0, maxHealth);
    });
    _saveState();
  }

  void _simulateDays(int days) {
    setState(() {
      _health = (_health + days * regenPerDay).clamp(0, maxHealth);
    });
    _saveState();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final double percent = _health / maxHealth;

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // === Ligne du haut : niveau + info ===
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Niveau : ${(_health / 10).floor()}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Tooltip(
                        message:
                            'Ton niveau dépend de ta vie. Clique sur bière pour perdre, attends pour regagner.',
                        child: const Icon(Icons.info_outline),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // === Barre de vie ===
                  Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade300,
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: percent,
                        child: Container(
                          height: 24,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color:
                                percent > 0.6
                                    ? Colors.green
                                    : (percent > 0.3
                                        ? Colors.orange
                                        : Colors.red),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          '${_health} / $maxHealth',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // === Image du personnage ===
                  Center(
                    child: Image.asset(
                      'assets/avatar.png',
                      height: 200,
                      fit: BoxFit.contain,
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
                          });
                          _saveState();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Remettre full'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Règles à gauche
                      Expanded(
                        child: Text(
                          'Règles :\n'
                          '- Cliquer sur "Bière" retire $damagePerClick points de vie.\n'
                          '- Si aucune bière pendant un jour, +$regenPerDay points.\n'
                          '- Vie max : $maxHealth.',
                          textAlign: TextAlign.left,
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _drinkBeer,
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(16),
                        ),
                        child: const Icon(Icons.local_drink, size: 28),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
