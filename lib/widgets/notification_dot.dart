import 'package:flutter/material.dart';

/// Pastille de notification iOS-like : superposée en haut-droite d'une icône
/// via un [Stack]. Affiche un point si [count] == 0 n'est jamais le cas (le
/// parent décide de l'afficher), sinon le nombre (plafonné à « 9+ »).
class NotificationDot extends StatelessWidget {
  final int count;

  /// Couleur d'accent (rouge d'alerte par défaut, aligné sur le palier streak).
  final Color color;

  const NotificationDot({
    super.key,
    required this.count,
    this.color = const Color(0xFFE63946),
  });

  @override
  Widget build(BuildContext context) {
    final label = count > 9 ? '9+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            offset: const Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
