import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/common/common_widgets.dart';

// ── Flight Calendar ────────────────────────────────────────────────────────────
class FlightCalendarScreen extends StatefulWidget {
  const FlightCalendarScreen({super.key});

  @override
  State<FlightCalendarScreen> createState() => _FlightCalendarScreenState();
}

class _FlightCalendarScreenState extends State<FlightCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  RangeSelectionMode _rangeMode = RangeSelectionMode.toggledOn;

  // Mock prices per date
  final Map<DateTime, String> _prices = {
    DateTime.now().add(const Duration(days: 3)): '189',
    DateTime.now().add(const Duration(days: 5)): '210',
    DateTime.now().add(const Duration(days: 7)): '175',
    DateTime.now().add(const Duration(days: 10)): '320',
    DateTime.now().add(const Duration(days: 12)): '189',
    DateTime.now().add(const Duration(days: 14)): '198',
    DateTime.now().add(const Duration(days: 21)): '145',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Calendrier des vols'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() {
              _rangeStart = null;
              _rangeEnd = null;
              _selectedDay = null;
            }),
            child: const Text('Réinitialiser',
                style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.pagePadding, vertical: 8),
            child: Row(
              children: [
                _LegendDot(color: AppColors.success, label: 'Pas cher'),
                const SizedBox(width: 16),
                _LegendDot(color: AppColors.warning, label: 'Moyen'),
                const SizedBox(width: 16),
                _LegendDot(color: AppColors.error, label: 'Cher'),
              ],
            ),
          ),

          // Calendar
          Container(
            margin: const EdgeInsets.symmetric(
                horizontal: AppConstants.pagePadding, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.radiusXl),
              border: Border.all(color: AppColors.border),
            ),
            child: TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              rangeSelectionMode: _rangeMode,
              onDaySelected: (selected, focused) {
                if (!isSameDay(_selectedDay, selected)) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                    _rangeStart = null;
                    _rangeEnd = null;
                  });
                }
              },
              onRangeSelected: (start, end, focused) {
                setState(() {
                  _selectedDay = null;
                  _focusedDay = focused;
                  _rangeStart = start;
                  _rangeEnd = end;
                });
              },
              calendarStyle: CalendarStyle(
                rangeHighlightColor: AppColors.accent.withOpacity(0.15),
                rangeStartDecoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                rangeEndDecoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                outsideDaysVisible: false,
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  final price = _prices.entries
                      .where((e) => isSameDay(e.key, day))
                      .map((e) => e.value)
                      .firstOrNull;
                  if (price == null) return null;
                  final p = int.parse(price);
                  final color = p < 200
                      ? AppColors.success
                      : p < 280
                          ? AppColors.warning
                          : AppColors.error;
                  return Positioned(
                    bottom: 2,
                    child: Text('$price',
                        style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                            color: color)),
                  );
                },
              ),
            ),
          ),

          // Price breakdown
          if (_rangeStart != null)
            _DateRangeInfo(
              start: _rangeStart!,
              end: _rangeEnd,
            ),

          const Spacer(),

          // Confirm button
          Padding(
            padding: EdgeInsets.fromLTRB(
                AppConstants.pagePadding, 0,
                AppConstants.pagePadding,
                MediaQuery.of(context).padding.bottom + 20),
            child: AppButton(
              label: _rangeStart != null
                  ? 'Confirmer les dates'
                  : 'Sélectionner les dates',
              onTap: _rangeStart != null ? () => context.pop() : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hotel Calendar ─────────────────────────────────────────────────────────────
class HotelCalendarScreen extends StatefulWidget {
  const HotelCalendarScreen({super.key});

  @override
  State<HotelCalendarScreen> createState() => _HotelCalendarScreenState();
}

class _HotelCalendarScreenState extends State<HotelCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  // Mock unavailable dates
  final List<DateTime> _unavailableDates = [
    DateTime.now().add(const Duration(days: 8)),
    DateTime.now().add(const Duration(days: 9)),
    DateTime.now().add(const Duration(days: 15)),
    DateTime.now().add(const Duration(days: 16)),
    DateTime.now().add(const Duration(days: 17)),
  ];

  bool _isUnavailable(DateTime day) =>
      _unavailableDates.any((d) => isSameDay(d, day));

  @override
  Widget build(BuildContext context) {
    final nights = _rangeStart != null && _rangeEnd != null
        ? _rangeEnd!.difference(_rangeStart!).inDays
        : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sélectionner les dates'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Hotel name context
          Container(
            margin: const EdgeInsets.fromLTRB(
                AppConstants.pagePadding, 8, AppConstants.pagePadding, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppColors.tealGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                Icon(Icons.hotel_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('The Majestic Sidi Bou',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                Spacer(),
                Text('280 TND / nuit',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),

          // Calendar
          Container(
            margin: const EdgeInsets.all(AppConstants.pagePadding),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.radiusXl),
              border: Border.all(color: AppColors.border),
            ),
            child: TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              rangeSelectionMode: RangeSelectionMode.toggledOn,
              enabledDayPredicate: (day) => !_isUnavailable(day),
              onRangeSelected: (start, end, focused) {
                setState(() {
                  _rangeStart = start;
                  _rangeEnd = end;
                  _focusedDay = focused;
                });
              },
              calendarStyle: CalendarStyle(
                disabledTextStyle: const TextStyle(
                    color: AppColors.textHint,
                    decoration: TextDecoration.lineThrough),
                rangeHighlightColor: AppColors.teal.withOpacity(0.15),
                rangeStartDecoration: const BoxDecoration(
                    color: AppColors.teal, shape: BoxShape.circle),
                rangeEndDecoration: const BoxDecoration(
                    color: AppColors.teal, shape: BoxShape.circle),
                todayDecoration: BoxDecoration(
                    color: AppColors.teal.withOpacity(0.3),
                    shape: BoxShape.circle),
                selectedDecoration: const BoxDecoration(
                    color: AppColors.teal, shape: BoxShape.circle),
                outsideDaysVisible: false,
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              calendarBuilders: CalendarBuilders(
                disabledBuilder: (ctx, day, focusedDay) => Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        size: 14, color: AppColors.error),
                  ),
                ),
              ),
            ),
          ),

          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.pagePadding),
            child: Row(
              children: [
                _LegendDot(color: AppColors.teal, label: 'Disponible'),
                const SizedBox(width: 16),
                _LegendDot(color: AppColors.error, label: 'Indisponible'),
              ],
            ),
          ),

          // Summary
          if (_rangeStart != null && _rangeEnd != null)
            Container(
              margin: const EdgeInsets.all(AppConstants.pagePadding),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.teal.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.teal.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$nights nuits sélectionnées',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.teal)),
                  Text('${280 * nights} TND',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.teal)),
                ],
              ),
            ),

          const Spacer(),

          Padding(
            padding: EdgeInsets.fromLTRB(
                AppConstants.pagePadding, 0,
                AppConstants.pagePadding,
                MediaQuery.of(context).padding.bottom + 20),
            child: AppButton(
              label: nights > 0
                  ? 'Confirmer ($nights nuits)'
                  : 'Sélectionner les dates',
              color: AppColors.teal,
              onTap: nights > 0 ? () => context.pop() : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared Widgets ─────────────────────────────────────────────────────────────
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _DateRangeInfo extends StatelessWidget {
  final DateTime start;
  final DateTime? end;
  const _DateRangeInfo({required this.start, this.end});

  @override
  Widget build(BuildContext context) {
    final nights = end != null ? end!.difference(start).inDays : 0;
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.pagePadding, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _InfoCell(
            label: 'Départ',
            value:
                '${start.day}/${start.month}/${start.year}',
          ),
          Container(
            height: 30,
            width: 1,
            color: AppColors.border,
          ),
          _InfoCell(
            label: end != null ? 'Retour' : 'Retour',
            value: end != null
                ? '${end!.day}/${end!.month}/${end!.year}'
                : '--',
          ),
          if (nights > 0) ...[
            Container(height: 30, width: 1, color: AppColors.border),
            _InfoCell(label: 'Durée', value: '$nights nuits'),
          ],
        ],
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  final String label;
  final String value;
  const _InfoCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 3),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
      ],
    );
  }
}
