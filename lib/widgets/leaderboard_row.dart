import 'package:flutter/material.dart';

import '../models/friend.dart';
import '../theme/jaune_design.dart';
import 'citron_avatar.dart';
import 'mini_health_bar.dart';

/// Une ligne du classement (positions hors podium) : rang · monogramme ·
/// pseudo · barre de vie miniature (avec %) · flamme. La ligne de
/// l'utilisateur courant ([LeaderboardEntry.isMe]) est mise en avant.
class LeaderboardRow extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;

  const LeaderboardRow({super.key, required this.rank, required this.entry});

  @override
  Widget build(BuildContext context) {
    final isMe = entry.isMe;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? JauneColors.lemon.withValues(alpha: 0.16) : Colors.white,
        borderRadius: BorderRadius.circular(JauneRadii.card),
        border: isMe
            ? Border.all(
                color: JauneColors.lemonDeep.withValues(alpha: 0.55),
                width: 1.5)
            : Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: JauneColors.inkSoft,
              ),
            ),
          ),
          const SizedBox(width: 6),
          CitronAvatar(
            size: 44,
            skin: entry.equippedSkin,
            healthPercent: entry.healthPercent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: JauneColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                MiniHealthBar(percent: entry.healthPercent, height: 12),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FlameChip(days: entry.streakDays),
        ],
      ),
    );
  }
}

/// Pastille monogramme : première lettre du pseudo sur un dégradé dérivé du
/// pseudo (stable, varié, on-brand). Remplace l'avatar citron dans les listes.
class LeaderboardMonogram extends StatelessWidget {
  final String name;
  final double size;

  /// Dégradé d'anneau prioritaire (médailles du podium). Si null, dérivé du nom.
  final List<Color>? ringColors;

  const LeaderboardMonogram({
    super.key,
    required this.name,
    this.size = 40,
    this.ringColors,
  });

  static const List<List<Color>> _palette = [
    [Color(0xFF95C6F4), Color(0xFF5E9FD5)], // ciel
    [Color(0xFFF7D83F), Color(0xFFF6B73F)], // citron
    [Color(0xFF43E97B), Color(0xFF38B98C)], // menthe
    [Color(0xFFB388FF), Color(0xFF7C4DFF)], // violet
    [Color(0xFFFF8A65), Color(0xFFFF5E3A)], // corail
    [Color(0xFF4FD1C5), Color(0xFF2C9E92)], // turquoise
  ];

  static List<Color> _colorsFor(String name) {
    if (name.isEmpty) return _palette.first;
    final hash = name.codeUnits.fold<int>(0, (a, b) => a + b);
    return _palette[hash % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final colors = ringColors ?? _colorsFor(name);
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.35),
            offset: const Offset(0, 3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Flamme compacte (sans animation, contrairement à StreakBadge) pour les
/// listes et le podium.
class FlameChip extends StatelessWidget {
  final int days;
  final bool dense;
  const FlameChip({super.key, required this.days, this.dense = false});

  static List<Color> _tier(int d) {
    if (d >= 30) return const [Color(0xFFF7D83F), Color(0xFFFF6B35)];
    if (d >= 7) return const [Color(0xFFFF6B35), Color(0xFFE63946)];
    return const [Color(0xFFFF9D42), Color(0xFFFF6B35)];
  }

  @override
  Widget build(BuildContext context) {
    if (days <= 0) {
      return Text(
        '—',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: JauneColors.inkSoft.withValues(alpha: 0.5),
        ),
      );
    }
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 7 : 9,
        vertical: dense ? 4 : 5,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _tier(days),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🔥', style: TextStyle(fontSize: dense ? 12 : 14)),
          const SizedBox(width: 3),
          Text(
            '$days',
            style: TextStyle(
              fontSize: dense ? 12 : 14,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
