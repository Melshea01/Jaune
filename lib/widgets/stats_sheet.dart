import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../l10n/gen/app_localizations.dart';
import '../services/audio_service.dart';
import '../services/character_service.dart';
import '../services/stats_service.dart';
import '../theme/jaune_design.dart';

/// Bottom sheet de statistiques : graphe des 7 derniers jours, tendance
/// semaine vs semaine, records et verres évités. Tout est calculé par
/// StatsService (fonctions pures) à partir de la map des consommations.
class StatsSheet {
  static void show(
    BuildContext context, {
    required Map<String, int> dailyMap,
    required CharacterService character,
  }) {
    HapticFeedback.selectionClick();
    AudioService.instance.playUiPop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _StatsSheetContent(dailyMap: dailyMap, character: character),
    );
  }
}

class _StatsSheetContent extends StatelessWidget {
  final Map<String, int> dailyMap;
  final CharacterService character;

  const _StatsSheetContent({required this.dailyMap, required this.character});

  /// Mêmes paliers de couleur que le calendrier : ≤2 modéré, ≤4 attention,
  /// ≤5 limite, ≥6 binge — l'app raconte partout la même histoire
  static Color _barColor(int count) {
    if (count == 0) return JauneColors.healthVibrant.first;
    if (count <= 2) return Colors.green.shade600;
    if (count <= 4) return Colors.yellow.shade700;
    if (count <= 5) return Colors.deepOrange.shade600;
    return Colors.redAccent.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();

    final List<int> week = StatsService.last7Days(dailyMap, now);
    final comparison = StatsService.weekComparison(dailyMap, now);
    final int longestStreak = StatsService.longestSoberStreak(
      dailyMap,
      character.profile.firstUseDate,
      now,
    );
    final int? lightestWeek = StatsService.lightestFullWeekTotal(
      dailyMap,
      character.profile.firstUseDate,
      now,
    );
    final int? avoided = StatsService.drinksAvoided(
      dailyMap,
      character.profile.firstUseDate,
      now,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(JauneRadii.sheet),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).padding.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      l10n.statsTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: JauneColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Graphe 7 jours ---
                  _SectionTitle(l10n.statsLast7Days),
                  const SizedBox(height: 12),
                  _WeekChart(
                    values: week,
                    locale: locale,
                    now: now,
                    barColor: _barColor,
                  ),
                  const SizedBox(height: 24),

                  // --- Tendance semaine vs semaine ---
                  _TrendCard(
                    l10n: l10n,
                    thisWeek: comparison.thisWeek,
                    lastWeek: comparison.lastWeek,
                  ),

                  // --- Records ---
                  const SizedBox(height: 24),
                  _SectionTitle(l10n.statsRecords),
                  const SizedBox(height: 10),
                  _RecordRow(
                    emoji: '🔥',
                    label: l10n.statsLongestStreak,
                    value: l10n.daysCount(longestStreak),
                  ),
                  if (lightestWeek != null) ...[
                    const SizedBox(height: 10),
                    _RecordRow(
                      emoji: '🪶',
                      label: l10n.statsLightestWeek,
                      value: l10n.statsDrinksCount(lightestWeek),
                    ),
                  ],

                  // --- Verres évités ---
                  if (avoided != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            JauneColors.lemon.withValues(alpha: 0.25),
                            JauneColors.lemonDeep.withValues(alpha: 0.18),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(JauneRadii.card),
                        border: Border.all(
                          color: JauneColors.lemonDeep.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '🍋 $avoided',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: JauneColors.ink,
                            ),
                          ),
                          Text(
                            l10n.statsDrinksAvoided,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: JauneColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.statsAvoidedHint,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: JauneColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: JauneColors.ink,
        letterSpacing: 0.2,
      ),
    );
  }
}

/// Graphe en barres des 7 derniers jours — les hauteurs s'animent à
/// l'ouverture, les couleurs suivent les paliers du calendrier
class _WeekChart extends StatelessWidget {
  final List<int> values;
  final String locale;
  final DateTime now;
  final Color Function(int) barColor;

  const _WeekChart({
    required this.values,
    required this.locale,
    required this.now,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final int maxValue = values.fold(1, (m, v) => v > m ? v : m);
    const double chartHeight = 110;

    return SizedBox(
      height: chartHeight + 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final int v = values[i];
          final DateTime day = now.subtract(Duration(days: 6 - i));
          final String label =
              DateFormat.E(locale).format(day).characters.first.toUpperCase();
          final double h = v == 0 ? 6 : chartHeight * v / maxValue;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (v > 0)
                    Text(
                      '$v',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: JauneColors.inkSoft,
                      ),
                    ),
                  //const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: h),
                    duration: JauneMotion.emphasized,
                    curve: JauneMotion.smooth,
                    builder:
                        (context, height, _) => Container(
                          height: height,
                          decoration: BoxDecoration(
                            color: v == 0 ? Colors.grey.shade200 : barColor(v),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  final AppLocalizations l10n;
  final int thisWeek;
  final int lastWeek;

  const _TrendCard({
    required this.l10n,
    required this.thisWeek,
    required this.lastWeek,
  });

  @override
  Widget build(BuildContext context) {
    final String trend;
    final Color color;
    if (lastWeek == 0 || thisWeek == lastWeek) {
      trend = l10n.statsTrendFlat;
      color = JauneColors.inkSoft;
    } else if (thisWeek < lastWeek) {
      trend = l10n.statsTrendDown(
        ((lastWeek - thisWeek) * 100 / lastWeek).round(),
      );
      color = const Color(0xFF34C759);
    } else {
      trend = l10n.statsTrendUp(
        ((thisWeek - lastWeek) * 100 / lastWeek).round(),
      );
      color = JauneColors.flame;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(JauneRadii.card),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.statsThisWeek} · ${l10n.statsDrinksCount(thisWeek)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: JauneColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${l10n.statsLastWeek} · ${l10n.statsDrinksCount(lastWeek)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: JauneColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              trend,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;

  const _RecordRow({
    required this.emoji,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: JauneColors.lemon.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 18)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: JauneColors.ink,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: JauneColors.ink,
          ),
        ),
      ],
    );
  }
}
