import 'package:flutter/material.dart';
import '../utils/jaune_haptics.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

import '../l10n/gen/app_localizations.dart';
import '../theme/jaune_design.dart';
import '../utils/date_keys.dart';

class CalendarDialog {
  static void show({
    required BuildContext context,
    required GlobalKey buttonKey,
    required AnimationController animationController,
    required Map<String, int> dailyMap,
  }) {
    final RenderBox buttonBox =
        buttonKey.currentContext!.findRenderObject() as RenderBox;
    final buttonSize = buttonBox.size;
    final buttonPosition = buttonBox.localToGlobal(Offset.zero);

    final Rect beginRect = Rect.fromLTWH(
      buttonPosition.dx,
      buttonPosition.dy,
      buttonSize.width,
      buttonSize.height,
    );

    final media = MediaQuery.of(context);
    final screenRect = Rect.fromLTWH(
      0,
      0,
      media.size.width,
      media.size.height,
    );

    // Hauteur adaptative : on ne dépasse jamais l'espace disponible entre le
    // haut sûr (encoche) et le bas du dialogue (ancré à 40 px du bord).
    const double bottomAnchor = 40;
    final double availableH =
        media.size.height - media.padding.top - bottomAnchor - 12;
    final double dialogHeight = math.min(540.0, availableH);

    final finalRect = Rect.fromCenter(
      center: screenRect.center,
      width: math.min(420, screenRect.width - 32),
      height: dialogHeight,
    ).shift(Offset(0, (screenRect.height - dialogHeight - 30) / 2 - 40));

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    final animation = CurvedAnimation(
      parent: animationController,
      // Ouverture décélérée (l'élément "arrive"), fermeture accélérée
      curve: Curves.easeOutQuart,
      reverseCurve: Curves.easeInCubic,
    );

    entry = OverlayEntry(
      builder:
          (ctx) => _CalendarOverlay(
            animation: animation,
            beginRect: beginRect,
            finalRect: finalRect,
            dailyMap: dailyMap,
            onClose: () async {
              await animationController.reverse();
              entry.remove();
            },
          ),
    );

    overlay.insert(entry);
    animationController.forward(from: 0.0);
  }
}

class _CalendarOverlay extends StatefulWidget {
  final Animation<double> animation;
  final Rect beginRect;
  final Rect finalRect;
  final Map<String, int> dailyMap;
  final VoidCallback onClose;

  const _CalendarOverlay({
    required this.animation,
    required this.beginRect,
    required this.finalRect,
    required this.dailyMap,
    required this.onClose,
  });

  @override
  State<_CalendarOverlay> createState() => _CalendarOverlayState();
}

class _CalendarOverlayState extends State<_CalendarOverlay> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  bool _monthHasData(DateTime month) {
    final prefix =
        '${month.year.toString().padLeft(4, '0')}-'
        '${month.month.toString().padLeft(2, '0')}-';
    return widget.dailyMap.keys.any((k) => k.startsWith(prefix));
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _focusedDay.year == now.year && _focusedDay.month == now.month;
  }

  void _goToToday() {
    JauneHaptics.selection();
    setState(() => _focusedDay = DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        // FIX: Handle potential null from Rect.lerp during animation edge cases
        final currentRect =
            Rect.lerp(
              widget.beginRect,
              widget.finalRect,
              widget.animation.value.clamp(0.0, 1.0),
            ) ??
            widget.finalRect;

        return Stack(
          children: [
            // Fond flouté + assombri
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: widget.onClose,
              child: Opacity(
                opacity: widget.animation.value,
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: Container(color: Colors.black.withValues(alpha: 0.3)),
                ),
              ),
            ),

            // Dialogue animé
            Positioned(
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
                      colors: [JauneColors.lemon, JauneColors.lemonDeep],
                    ),
                    borderRadius: BorderRadius.circular(JauneRadii.sheet),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: 0.2 * widget.animation.value,
                        ),
                        offset: const Offset(0, 8),
                        blurRadius: 20,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withValues(
                        alpha: 0.3 * widget.animation.value,
                      ),
                      width: 1.0,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Opacity(
                    opacity: widget.animation.value,
                    child: _buildCalendarContent(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCalendarContent() {
    // Le calendrier ET le détail du jour vivent dans le MÊME scroll : ainsi le
    // détail s'affiche toujours sous la grille (jamais par-dessus) et, s'il
    // manque de place, tout l'ensemble défile au lieu de déborder.
    final monthEmpty = !_monthHasData(_focusedDay);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        const SizedBox(height: 8),
        Flexible(
          fit: FlexFit.loose,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCalendar(),
                const SizedBox(height: 10),
                _buildLegend(),
                // Premier usage (aucune donnée nulle part) : accueillir.
                // Sinon, si le mois affiché est vide : l'expliquer.
                if (widget.dailyMap.isEmpty)
                  _buildEmptyState()
                else if (monthEmpty)
                  _buildMonthEmptyHint(),
                _buildSelectedDayDetail(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Légende compacte des couleurs de cellule — sans elle, l'utilisateur
  /// doit deviner ce que signifie chaque teinte.
  Widget _buildLegend() {
    final l10n = AppLocalizations.of(context);
    Widget chip(Color color, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: JauneColors.ink,
          ),
        ),
      ],
    );

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 6,
      children: [
        chip(JauneColors.sober, l10n.calendarLegendSober),
        chip(JauneColors.consumptionColor(1), l10n.calendarLegendModerate),
        chip(JauneColors.consumptionColor(3), l10n.calendarLegendRising),
        chip(JauneColors.consumptionColor(6), l10n.calendarLegendHeavy),
      ],
    );
  }

  /// Premier usage : aucun verre loggé — accueillir plutôt que montrer
  /// une grille vide sans explication
  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    return _infoCard(
      emoji: '🍋',
      title: l10n.calendarEmptyTitle,
      text: l10n.calendarEmptyText,
    );
  }

  /// Mois affiché sans donnée alors que d'autres mois en ont.
  Widget _buildMonthEmptyHint() {
    final l10n = AppLocalizations.of(context);
    return _infoCard(emoji: '🗓️', title: l10n.calendarMonthEmpty);
  }

  Widget _infoCard({required String emoji, required String title, String? text}) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(JauneRadii.card),
        color: Colors.white.withValues(alpha: 0.96),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: JauneColors.ink,
                  ),
                ),
                if (text != null)
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: JauneColors.inkSoft,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Détail du jour sélectionné : date + nombre de verres
  Widget _buildSelectedDayDetail() {
    final day = _selectedDay;

    return AnimatedSwitcher(
      duration: JauneMotion.quick,
      transitionBuilder:
          (child, animation) => FadeTransition(
            opacity: animation,
            child: SizeTransition(sizeFactor: animation, child: child),
          ),
      child:
          day == null
              ? const SizedBox.shrink()
              : Container(
                key: ValueKey(day),
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(JauneRadii.card),
                  color: Colors.white.withValues(alpha: 0.96),
                ),
                child: _buildDayDetailContent(day),
              ),
    );
  }

  Widget _buildDayDetailContent(DateTime day) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final dayKey = dateKey(day);
    final count = widget.dailyMap[dayKey] ?? 0;
    final label = DateFormat('EEEE d MMMM', locale).format(day);
    final capitalized = label[0].toUpperCase() + label.substring(1);
    final (emoji, text) = _consumptionLabel(l10n, count);

    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                capitalized,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: JauneColors.ink,
                ),
              ),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: JauneColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Barème UNIQUE (aligné sur [JauneColors.consumptionColor]) : la
  /// frontière des couleurs et celle du texte coïncident.
  /// 0 sobre · 1-2 modéré · 3-5 ça monte · >=6 grosse soirée.
  (String, String) _consumptionLabel(AppLocalizations l10n, int count) {
    return switch (count) {
      0 => ('💧', l10n.dayDetailSober),
      1 || 2 => ('🍺', l10n.dayDetailModerate(count)),
      <= 5 => ('🍻', l10n.dayDetailRising(count)),
      _ => ('🥴', l10n.dayDetailHeavy(count)),
    };
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        const Icon(CupertinoIcons.calendar, size: 22, color: JauneColors.ink),
        const SizedBox(width: 8),
        Text(
          l10n.calendarTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: JauneColors.ink,
          ),
        ),
        const Spacer(),
        // Retour rapide au mois courant — visible seulement si on s'en
        // est éloigné.
        if (!_isCurrentMonth)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: TextButton(
              onPressed: _goToToday,
              style: TextButton.styleFrom(
                foregroundColor: JauneColors.ink,
                backgroundColor: Colors.white.withValues(alpha: 0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(JauneRadii.pill),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l10n.calendarToday,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        // Fermeture : un simple ✕ (le tap hors-dialogue ferme déjà).
        Semantics(
          button: true,
          label: l10n.calendarClose,
          child: IconButton(
            onPressed: widget.onClose,
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.08),
              shape: const CircleBorder(),
            ),
            icon: const Icon(
              CupertinoIcons.xmark,
              color: JauneColors.ink,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    // Carte légère, sans ombre : on évite l'empilement « boxy » et on laisse
    // respirer la grille sur le fond jaune.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(JauneRadii.card),
        color: Colors.white.withValues(alpha: 0.55),
      ),
      child: TableCalendar(
        locale: Localizations.localeOf(context).toString(),
        firstDay: DateTime.utc(2000, 1, 1),
        lastDay: DateTime.utc(2100, 12, 31),
        focusedDay: _focusedDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        availableGestures: AvailableGestures.horizontalSwipe,
        selectedDayPredicate:
            (day) => _selectedDay != null && isSameDay(day, _selectedDay),
        onDaySelected: (selectedDay, focusedDay) {
          JauneHaptics.selection();
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onPageChanged: (focusedDay) {
          setState(() => _focusedDay = focusedDay);
        },
        daysOfWeekHeight: 28,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          leftChevronIcon: Icon(CupertinoIcons.chevron_left, size: 20),
          rightChevronIcon: Icon(CupertinoIcons.chevron_right, size: 20),
          headerPadding: EdgeInsets.symmetric(vertical: 8),
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: JauneColors.ink,
          ),
        ),
        calendarStyle: const CalendarStyle(
          todayDecoration: BoxDecoration(),
          defaultDecoration: BoxDecoration(),
          outsideDecoration: BoxDecoration(),
          selectedDecoration: BoxDecoration(),
        ),
        calendarBuilders: CalendarBuilders(
          dowBuilder: (context, day) {
            // Initiale localisée du jour de la semaine (L M M J V S D / M T W…)
            final locale = Localizations.localeOf(context).toString();
            final initial =
                DateFormat.E(locale).format(day).characters.first.toUpperCase();
            return Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: JauneColors.inkSoft,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            );
          },
          defaultBuilder:
              (context, day, focusedDay) => _buildCalendarCell(day, false, false),
          todayBuilder:
              (context, day, focusedDay) => _buildCalendarCell(day, false, true),
          selectedBuilder:
              (context, day, focusedDay) =>
                  _buildCalendarCell(day, true, isSameDay(day, DateTime.now())),
          outsideBuilder: (context, day, focusedDay) {
            return Center(
              child: Text(
                '${day.day}',
                style: TextStyle(color: Colors.grey.shade400),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCalendarCell(DateTime day, bool isSelected, bool isToday) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final count = widget.dailyMap[dateKey(day)] ?? 0;
    final dateLabel = DateFormat('EEEE d MMMM', locale).format(day);
    final (_, detail) = _consumptionLabel(l10n, count);

    return Semantics(
      label: '$dateLabel, $detail',
      selected: isSelected,
      child: ExcludeSemantics(
        child: CalendarDayCell(
          day: day,
          count: count,
          isSelected: isSelected,
          isToday: isToday,
        ),
      ),
    );
  }
}

/// Cellule unique : le chiffre est TOUJOURS le numéro du jour ; la
/// consommation se lit à la couleur de fond (barème unique). Le nombre exact
/// de verres reste accessible en tapant le jour (panneau de détail). État
/// sélectionné/aujourd'hui = anneau, sans changer la sémantique.
class CalendarDayCell extends StatelessWidget {
  final DateTime day;
  final int count;
  final bool isSelected;
  final bool isToday;

  const CalendarDayCell({
    super.key,
    required this.day,
    required this.count,
    required this.isSelected,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isPast = day.isBefore(today);
    final hasDrinks = count > 0;

    Color fill;
    Color textColor;

    if (hasDrinks) {
      // Jour de conso : couleur du barème, chiffre blanc.
      fill = JauneColors.consumptionColor(count);
      textColor = Colors.white;
    } else if (isPast && !isToday) {
      // Jour sobre passé : valorisé (bleu eau), pas grisé.
      fill = JauneColors.soberTint;
      textColor = JauneColors.sober;
    } else {
      // Aujourd'hui (encore sobre) / futur : neutre.
      fill = Colors.transparent;
      textColor = JauneColors.ink;
    }

    // Anneau : sélection (fort) prioritaire sur aujourd'hui (doux).
    Border? border;
    if (isSelected) {
      border = Border.all(color: JauneColors.ink, width: 2);
    } else if (isToday) {
      border = Border.all(color: JauneColors.lemonDeep, width: 2);
    }

    return Center(
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: border,
        ),
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight:
                (hasDrinks || isSelected || isToday)
                    ? FontWeight.bold
                    : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
