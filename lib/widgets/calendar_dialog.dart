import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:typicons_flutter/typicons_flutter.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

import '../l10n/gen/app_localizations.dart';
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
    final double dialogHeight = math.min(520.0, availableH);

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
  DateTime? _selectedDay;

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

        final borderRadius =
            BorderRadius.lerp(
              BorderRadius.circular(24),
              BorderRadius.circular(24),
              widget.animation.value,
            )!;

        return Stack(
          children: [
            // Blurred background
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

            // Animated dialog
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
                      colors: [
                        Color.fromARGB(255, 250, 225, 100),
                        Color.fromARGB(255, 245, 200, 80),
                      ],
                    ),
                    borderRadius: borderRadius,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        const SizedBox(height: 8),
        Flexible(
          fit: FlexFit.loose,
          child: SingleChildScrollView(child: _buildCalendar()),
        ),
        if (widget.dailyMap.isEmpty) _buildEmptyState(),
        _buildSelectedDayDetail(),
      ],
    );
  }

  /// Premier usage : aucun verre loggé — accueillir plutôt que montrer
  /// une grille vide sans explication
  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.85),
      ),
      child: Row(
        children: [
          const Text('🍋', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.calendarEmptyTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  l10n.calendarEmptyText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
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
      duration: const Duration(milliseconds: 250),
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
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white.withValues(alpha: 0.85),
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

    final (String emoji, String text) = switch (count) {
      0 => ('💧', l10n.dayDetailSober),
      1 || 2 => ('🍺', l10n.dayDetailModerate(count)),
      <= 5 => ('🍻', l10n.dayDetailRising(count)),
      _ => ('🥴', l10n.dayDetailHeavy(count)),
    };

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
                ),
              ),
              Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(CupertinoIcons.calendar, size: 22),
        const SizedBox(width: 8),
        Text(
          AppLocalizations.of(context).calendarTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        TextButton(
          onPressed: widget.onClose,
          style: TextButton.styleFrom(
            backgroundColor: Colors.black.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.xmark, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context).calendarClose,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.85),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: TableCalendar(
        locale: Localizations.localeOf(context).toString(),
        firstDay: DateTime.utc(2000, 1, 1),
        lastDay: DateTime.utc(2100, 12, 31),
        focusedDay: _selectedDay ?? DateTime.now(),
        startingDayOfWeek: StartingDayOfWeek.monday,
        selectedDayPredicate:
            (day) => _selectedDay != null && isSameDay(day, _selectedDay),
        onDaySelected: (selectedDay, focusedDay) {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedDay = selectedDay;
          });
        },
        daysOfWeekHeight: 28,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          leftChevronIcon: Icon(CupertinoIcons.chevron_left),
          rightChevronIcon: Icon(CupertinoIcons.chevron_right),
          headerPadding: EdgeInsets.symmetric(vertical: 8),
          titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        calendarStyle: const CalendarStyle(
          todayDecoration: BoxDecoration(),
          defaultDecoration: BoxDecoration(),
          outsideDecoration: BoxDecoration(),
          selectedDecoration: BoxDecoration(
            color: Color(0xFFF7D83F),
            shape: BoxShape.circle,
          ),
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          },
          defaultBuilder:
              (context, day, focusedDay) =>
                  _buildCalendarCell(day, false, false),
          todayBuilder:
              (context, day, focusedDay) =>
                  _buildCalendarCell(day, false, true),
          selectedBuilder:
              (context, day, focusedDay) =>
                  _buildCalendarCell(day, true, isSameDay(day, DateTime.now())),
          outsideBuilder: (context, day, focusedDay) {
            return Center(
              child: Text(
                '${day.day}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade400),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCalendarCell(DateTime day, bool isSelected, bool isToday) {
    final dayKey = dateKey(day);
    final count = widget.dailyMap[dayKey] ?? 0;

    if (count > 0) {
      return CalendarConsumptionCell(
        day: day,
        count: count,
        isSelected: isSelected,
        isToday: isToday,
      );
    }

    return CalendarEmptyCell(
      day: day,
      isSelected: isSelected,
      isToday: isToday,
    );
  }
}

class CalendarConsumptionCell extends StatelessWidget {
  final DateTime day;
  final int count;
  final bool isSelected;
  final bool isToday;

  const CalendarConsumptionCell({
    super.key,
    required this.day,
    required this.count,
    required this.isSelected,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    // Paliers alignés sur la formule PV : ≤2 modéré, 3-4 attention,
    // 5 limite, ≥6 binge (seuil de pénalité OMS)
    Color bg;
    if (count <= 2) {
      bg = Colors.green.shade600;
    } else if (count <= 4) {
      bg = Colors.yellow.shade700;
    } else if (count <= 5) {
      bg = Colors.deepOrange.shade600;
    } else {
      bg = Colors.redAccent.shade700;
    }

    if (isSelected) {
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border:
              (isToday) ? Border.all(color: Colors.black54, width: 1.5) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border:
            (isToday) ? Border.all(color: Colors.black54, width: 1.5) : null,
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Typicons.beer, color: Colors.white, size: 22),
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              height: 0.9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class CalendarEmptyCell extends StatelessWidget {
  final DateTime day;
  final bool isSelected;
  final bool isToday;

  const CalendarEmptyCell({
    super.key,
    required this.day,
    required this.isSelected,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isPast = day.isBefore(today);

    BoxDecoration decoration = BoxDecoration(
      color: (isPast && !isToday ? Colors.grey.shade200 : Colors.transparent),
      shape: BoxShape.circle,
      border:
          isToday
              ? Border.all(color: Colors.black54, width: 1.5)
              : (!isPast && !isToday
                  ? Border.all(color: Colors.grey.shade300, width: 1.0)
                  : null),
    );

    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: decoration,
      child: Text(
        '${day.day}',
        style: TextStyle(
          color:
              isSelected
                  ? Colors.black
                  : (isPast && !isToday
                      ? Colors.grey.shade600
                      : Colors.black87),
          fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w600,
        ),
      ),
    );
  }
}
