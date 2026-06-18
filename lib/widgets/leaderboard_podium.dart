import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../models/friend.dart';
import '../theme/jaune_design.dart';
import 'citron_avatar.dart';
import 'leaderboard_row.dart';
import 'mini_health_bar.dart';

/// Podium des 3 premiers du classement. Mise en scène façon « gala » :
/// le n°1 est central, surélevé et couronné. Avatar citron (teinté selon la
/// santé) + nombre de PV sous chaque marche.
class LeaderboardPodium extends StatelessWidget {
  /// Classement complet trié (santé décroissante). On n'affiche que le top 3.
  final List<LeaderboardEntry> ranking;

  const LeaderboardPodium({super.key, required this.ranking});

  static const _gold = [Color(0xFFFFE259), Color(0xFFFFA751)];
  static const _silver = [Color(0xFFE6E9F0), Color(0xFFBFC4D1)];
  static const _bronze = [Color(0xFFF0B27A), Color(0xFFD68910)];

  @override
  Widget build(BuildContext context) {
    final top = ranking.take(3).toList();
    if (top.isEmpty) return const SizedBox.shrink();

    // Ordre visuel : 2 — 1 — 3
    LeaderboardEntry? at(int i) => i < top.length ? top[i] : null;
    final first = at(0);
    final second = at(1);
    final third = at(2);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: JauneMotion.standard,
      curve: JauneMotion.springy,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, (1 - t) * 16), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        padding: const EdgeInsets.only(top: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _PodiumColumn(
                entry: second,
                rank: 2,
                ringColors: _silver,
                pedestalHeight: 58,
                avatarSize: 54,
              ),
            ),
            Expanded(
              child: _PodiumColumn(
                entry: first,
                rank: 1,
                ringColors: _gold,
                pedestalHeight: 82,
                avatarSize: 66,
                crowned: true,
              ),
            ),
            Expanded(
              child: _PodiumColumn(
                entry: third,
                rank: 3,
                ringColors: _bronze,
                pedestalHeight: 42,
                avatarSize: 54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final LeaderboardEntry? entry;
  final int rank;
  final List<Color> ringColors;
  final double pedestalHeight;
  final double avatarSize;
  final bool crowned;

  const _PodiumColumn({
    required this.entry,
    required this.rank,
    required this.ringColors,
    required this.pedestalHeight,
    required this.avatarSize,
    this.crowned = false,
  });

  @override
  Widget build(BuildContext context) {
    final e = entry;
    // Emplacement vide (moins de 3 amis) : pedestal fantôme discret.
    if (e == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: avatarSize + 38),
          _Pedestal(rank: rank, colors: ringColors, height: pedestalHeight, ghost: true),
        ],
      );
    }

    final isMe = e.isMe;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (crowned)
          const Padding(
            padding: EdgeInsets.only(bottom: 2),
            child: Text('👑', style: TextStyle(fontSize: 22)),
          )
        else
          const SizedBox(height: 24),
        // Avatar citron avec anneau médaille
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: ringColors),
            boxShadow: [
              BoxShadow(
                color: ringColors.last.withValues(alpha: 0.45),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CitronAvatar(
            size: avatarSize,
            skin: e.equippedSkin,
            healthPercent: e.healthPercent,
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            isMe ? 'Toi' : e.username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: JauneColors.ink,
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Nombre de PV (0–100), dans la couleur de sa zone de santé.
        Text(
          '${(e.healthPercent.clamp(0.0, 1.0) * 100).round()} ${AppLocalizations.of(context).hpLabel}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: JauneColors.healthGradient(e.healthPercent).last,
          ),
        ),
        const SizedBox(height: 4),
        // Vie = barre (langage visuel distinct de la flamme du streak, pour
        // qu'on ne confonde plus les deux indicateurs).
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: MiniHealthBar(
            percent: e.healthPercent,
            height: 8,
            showLabel: false,
          ),
        ),
        const SizedBox(height: 7),
        FlameChip(days: e.streakDays, dense: true),
        const SizedBox(height: 8),
        _Pedestal(rank: rank, colors: ringColors, height: pedestalHeight),
      ],
    );
  }
}

class _Pedestal extends StatelessWidget {
  final int rank;
  final List<Color> colors;
  final double height;
  final bool ghost;

  const _Pedestal({
    required this.rank,
    required this.colors,
    required this.height,
    this.ghost = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        gradient: ghost
            ? null
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: colors,
              ),
        color: ghost ? Colors.black.withValues(alpha: 0.04) : null,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        boxShadow: ghost
            ? null
            : [
                BoxShadow(
                  color: colors.last.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
      ),
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        '$rank',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: ghost ? JauneColors.inkSoft.withValues(alpha: 0.4) : Colors.white,
        ),
      ),
    );
  }
}
