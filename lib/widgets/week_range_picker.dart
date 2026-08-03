import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/weekly_expense_calculator.dart';
import '../models/activity.dart';

/// Calendar popup used by Billetera and topic date filter (7-day range).

/// Inserts an overlay anchored to [link] with [WeekRangePickerPopup].
/// Returns the [OverlayEntry] so the caller can remove it.
OverlayEntry insertWeekRangePickerOverlay({
  required BuildContext context,
  required LayerLink link,
  required DateTime initialWeekStart,
  List<Activity> activities = const [],
  Alignment targetAnchor = Alignment.bottomCenter,
  Alignment followerAnchor = Alignment.topCenter,
  Offset offset = const Offset(0, 6),
  required ValueChanged<DateTime> onConfirm,
  required VoidCallback onDismiss,
}) {
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: link,
          targetAnchor: targetAnchor,
          followerAnchor: followerAnchor,
          offset: offset,
          showWhenUnlinked: false,
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 268,
                maxHeight: MediaQuery.sizeOf(context).height * 0.55,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.65),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SingleChildScrollView(
                    child: WeekRangePickerPopup(
                      initialWeekStart: initialWeekStart,
                      activities: activities,
                      onConfirm: (weekStart) {
                        onConfirm(weekStart);
                        onDismiss();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
  Overlay.of(context).insert(entry);
  return entry;
}

class WeekRangePickerPopup extends StatefulWidget {
  const WeekRangePickerPopup({
    super.key,
    required this.initialWeekStart,
    required this.onConfirm,
    this.activities = const [],
  });

  final DateTime initialWeekStart;
  final List<Activity> activities;
  final ValueChanged<DateTime> onConfirm;

  @override
  State<WeekRangePickerPopup> createState() => _WeekRangePickerPopupState();
}

class _WeekRangePickerPopupState extends State<WeekRangePickerPopup> {
  static const _weekStrong = Color(0xFFE8A54A);
  static const _weekWeak = Color(0xFFFFF4E8);
  static final _firstDate = DateTime(2018, 1, 1);
  static const _weekdayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _rangeStart = WeeklyExpenseCalculator.dayOnly(DateTime.now());
  DateTime _rangeEnd =
      WeeklyExpenseCalculator.dayOnly(DateTime.now()).add(const Duration(days: 6));

  DateTime get _lastDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    _rangeStart = widget.initialWeekStart;
    _rangeEnd = widget.initialWeekStart.add(const Duration(days: 6));
    _visibleMonth = DateTime(
      widget.initialWeekStart.year,
      widget.initialWeekStart.month,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _dayOnly(DateTime day) =>
      DateTime(day.year, day.month, day.day);

  bool _inHighlightRange(DateTime day) {
    final d = _dayOnly(day);
    return !d.isBefore(_rangeStart) && !d.isAfter(_rangeEnd);
  }

  int _rangeSpanDays() => _rangeEnd.difference(_rangeStart).inDays;

  int _rangeIndex(DateTime day) => _dayOnly(day).difference(_rangeStart).inDays;

  Color _colorAtDay(DateTime day) {
    final span = _rangeSpanDays();
    if (span <= 0) return _weekStrong;
    final t = _rangeIndex(day) / span;
    return Color.lerp(_weekStrong, _weekWeak, t)!;
  }

  bool _isSelectable(DateTime day) {
    final d = _dayOnly(day);
    return !d.isBefore(_firstDate) && !d.isAfter(_lastDate);
  }

  void _onDayTap(DateTime day) {
    if (!_isSelectable(day)) return;
    final anchor = _dayOnly(day);
    setState(() {
      _rangeStart = anchor;
      _rangeEnd = anchor.add(const Duration(days: 6));
    });
  }

  void _onToday() {
    final today = _dayOnly(DateTime.now());
    setState(() {
      _rangeStart = today;
      _rangeEnd = today.add(const Duration(days: 6));
      _visibleMonth = DateTime(today.year, today.month);
    });
  }

  void _onConfirm() {
    widget.onConfirm(_dayOnly(_rangeStart));
  }

  void _shiftMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  List<_CalendarCell> _daysInMonthGrid() {
    final first = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final monthEnd =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0);
    final daysInMonth = monthEnd.day;
    final leading = first.weekday - DateTime.monday;
    final cells = <_CalendarCell>[];

    for (var i = 0; i < leading; i++) {
      cells.add(const _CalendarCell());
    }
    for (var d = 1; d <= daysInMonth; d++) {
      cells.add(
        _CalendarCell(
          date: DateTime(_visibleMonth.year, _visibleMonth.month, d),
        ),
      );
    }

    var nextDay = 1;
    while (cells.length % 7 != 0) {
      cells.add(
        _CalendarCell(
          date: DateTime(_visibleMonth.year, _visibleMonth.month + 1, nextDay),
          isOutsideMonth: true,
        ),
      );
      nextDay++;
    }

    // Solo extender si la semana seleccionada cruza el mes visible
    // (p. ej. 28 may → 3 jun). No rellenar hasta rangeEnd si estás en otro mes.
    final rangeTouchesMonth =
        !_rangeEnd.isBefore(first) && !_rangeStart.isAfter(monthEnd);

    if (rangeTouchesMonth) {
      DateTime? lastInGrid;
      for (final cell in cells.reversed) {
        if (cell.date != null) {
          lastInGrid = cell.date!;
          break;
        }
      }
      while (lastInGrid != null &&
          _dayOnly(lastInGrid).isBefore(_rangeEnd) &&
          cells.length < 7 * 7) {
        cells.add(
          _CalendarCell(
            date: DateTime(
              _visibleMonth.year,
              _visibleMonth.month + 1,
              nextDay,
            ),
            isOutsideMonth: true,
          ),
        );
        lastInGrid = DateTime(
          _visibleMonth.year,
          _visibleMonth.month + 1,
          nextDay,
        );
        nextDay++;
      }
      while (cells.length % 7 != 0) {
        cells.add(const _CalendarCell());
      }
    }

    return cells;
  }

  Set<DateTime> _daysWithTransactions() {
    final years = <int>{
      _visibleMonth.year,
      DateTime.now().year,
      _rangeStart.year,
    };
    final days = <DateTime>{};
    for (final year in years) {
      for (final activity in widget.activities) {
        final parsed = WeeklyExpenseCalculator.parseActivityDate(
          activity.date,
          fallbackYear: year,
        );
        if (parsed == null) continue;
        days.add(DateTime(parsed.year, parsed.month, parsed.day));
      }
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMM yyyy', 'es').format(_visibleMonth);
    final cells = _daysInMonthGrid();
    final rowCount = cells.length ~/ 7;
    final canGoPrev = DateTime(_visibleMonth.year, _visibleMonth.month)
        .isAfter(DateTime(_firstDate.year, _firstDate.month));
    final canGoNext = DateTime(_visibleMonth.year, _visibleMonth.month)
        .isBefore(DateTime(_lastDate.year, _lastDate.month));
    final transactionDays = _daysWithTransactions();

    final rangeSpan = _rangeSpanDays();

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: SizedBox(
        width: 252,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: canGoPrev ? () => _shiftMonth(-1) : null,
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      size: 22,
                      color: canGoPrev
                          ? AppColors.ink
                          : AppColors.textMuted.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    monthLabel[0].toUpperCase() + monthLabel.substring(1),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: canGoNext ? () => _shiftMonth(1) : null,
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: canGoNext
                          ? AppColors.ink
                          : AppColors.textMuted.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: _onToday,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Text(
                        'Hoy',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Material(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: _onConfirm,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                for (final label in _weekdayLabels)
                  Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
              ],
            ),
            for (var row = 0; row < rowCount; row++)
              _WeekPickerRow(
                cells: List.generate(7, (col) => cells[row * 7 + col]),
                inRange: (date) => date != null && _inHighlightRange(date),
                rangeIndex: (date) => _rangeIndex(date!),
                rangeSpan: rangeSpan,
                rangeColorAt: _colorAtDay,
                isSelectable: (date) => date != null && _isSelectable(date),
                isToday: (date) =>
                    date != null && _isSameDay(date, DateTime.now()),
                hasTransaction: (date) =>
                    date != null &&
                    transactionDays.contains(
                      DateTime(date.year, date.month, date.day),
                    ),
                onDayTap: _onDayTap,
              ),
          ],
        ),
      ),
    );
  }
}

/// Dialog calendar to pick an arbitrary date range, with orange dots on
/// days that have transactions (same markers as Billetera).
Future<DateTimeRange?> showAppDateRangePicker(
  BuildContext context, {
  required DateTime firstDate,
  required DateTime lastDate,
  DateTimeRange? initialDateRange,
  List<Activity> activities = const [],
}) {
  return showDialog<DateTimeRange>(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.border.withValues(alpha: 0.65),
            width: 0.5,
          ),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 288,
            maxHeight: MediaQuery.sizeOf(context).height * 0.7,
          ),
          child: SingleChildScrollView(
            child: DateRangePickerPopup(
              firstDate: firstDate,
              lastDate: lastDate,
              initialDateRange: initialDateRange,
              activities: activities,
              onConfirm: (range) => Navigator.pop(context, range),
              onCancel: () => Navigator.pop(context),
            ),
          ),
        ),
      );
    },
  );
}

class DateRangePickerPopup extends StatefulWidget {
  const DateRangePickerPopup({
    super.key,
    required this.firstDate,
    required this.lastDate,
    required this.onConfirm,
    this.onCancel,
    this.initialDateRange,
    this.activities = const [],
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTimeRange? initialDateRange;
  final List<Activity> activities;
  final ValueChanged<DateTimeRange> onConfirm;
  final VoidCallback? onCancel;

  @override
  State<DateRangePickerPopup> createState() => _DateRangePickerPopupState();
}

class _DateRangePickerPopupState extends State<DateRangePickerPopup> {
  static const _rangeStrong = Color(0xFFE8A54A);
  static const _rangeWeak = Color(0xFFFFF4E8);
  static const _weekdayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  late DateTime _visibleMonth;
  late DateTime _rangeStart;
  late DateTime _rangeEnd;
  bool _pickingEnd = false;

  DateTime get _firstDate =>
      DateTime(widget.firstDate.year, widget.firstDate.month, widget.firstDate.day);

  DateTime get _lastDate =>
      DateTime(widget.lastDate.year, widget.lastDate.month, widget.lastDate.day);

  @override
  void initState() {
    super.initState();
    final today = WeeklyExpenseCalculator.dayOnly(DateTime.now());
    final initial = widget.initialDateRange;
    _rangeStart = WeeklyExpenseCalculator.dayOnly(
      initial?.start ?? today.subtract(const Duration(days: 6)),
    );
    _rangeEnd = WeeklyExpenseCalculator.dayOnly(initial?.end ?? today);
    if (_rangeStart.isAfter(_rangeEnd)) {
      final tmp = _rangeStart;
      _rangeStart = _rangeEnd;
      _rangeEnd = tmp;
    }
    _visibleMonth = DateTime(_rangeStart.year, _rangeStart.month);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _dayOnly(DateTime day) => DateTime(day.year, day.month, day.day);

  bool _inHighlightRange(DateTime day) {
    final d = _dayOnly(day);
    return !d.isBefore(_rangeStart) && !d.isAfter(_rangeEnd);
  }

  int _rangeSpanDays() => _rangeEnd.difference(_rangeStart).inDays;

  int _rangeIndex(DateTime day) => _dayOnly(day).difference(_rangeStart).inDays;

  Color _colorAtDay(DateTime day) {
    final span = _rangeSpanDays();
    if (span <= 0) return _rangeStrong;
    final t = _rangeIndex(day) / span;
    return Color.lerp(_rangeStrong, _rangeWeak, t)!;
  }

  bool _isSelectable(DateTime day) {
    final d = _dayOnly(day);
    return !d.isBefore(_firstDate) && !d.isAfter(_lastDate);
  }

  void _onDayTap(DateTime day) {
    if (!_isSelectable(day)) return;
    final tapped = _dayOnly(day);
    setState(() {
      if (!_pickingEnd) {
        _rangeStart = tapped;
        _rangeEnd = tapped;
        _pickingEnd = true;
      } else {
        if (tapped.isBefore(_rangeStart)) {
          _rangeEnd = _rangeStart;
          _rangeStart = tapped;
        } else {
          _rangeEnd = tapped;
        }
        _pickingEnd = false;
      }
    });
  }

  void _onToday() {
    final today = _dayOnly(DateTime.now());
    if (!_isSelectable(today)) return;
    setState(() {
      _rangeStart = today;
      _rangeEnd = today;
      _pickingEnd = false;
      _visibleMonth = DateTime(today.year, today.month);
    });
  }

  void _onConfirm() {
    widget.onConfirm(DateTimeRange(start: _rangeStart, end: _rangeEnd));
  }

  void _shiftMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  List<_CalendarCell> _daysInMonthGrid() {
    final first = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final monthEnd = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0);
    final daysInMonth = monthEnd.day;
    final leading = first.weekday - DateTime.monday;
    final cells = <_CalendarCell>[];

    for (var i = 0; i < leading; i++) {
      cells.add(const _CalendarCell());
    }
    for (var d = 1; d <= daysInMonth; d++) {
      cells.add(
        _CalendarCell(
          date: DateTime(_visibleMonth.year, _visibleMonth.month, d),
        ),
      );
    }

    var nextDay = 1;
    while (cells.length % 7 != 0) {
      cells.add(
        _CalendarCell(
          date: DateTime(_visibleMonth.year, _visibleMonth.month + 1, nextDay),
          isOutsideMonth: true,
        ),
      );
      nextDay++;
    }

    return cells;
  }

  Set<DateTime> _daysWithTransactions() {
    final years = <int>{
      _visibleMonth.year,
      DateTime.now().year,
      _rangeStart.year,
      _rangeEnd.year,
    };
    final days = <DateTime>{};
    for (final year in years) {
      for (final activity in widget.activities) {
        final parsed = WeeklyExpenseCalculator.parseActivityDate(
          activity.date,
          fallbackYear: year,
        );
        if (parsed == null) continue;
        days.add(DateTime(parsed.year, parsed.month, parsed.day));
      }
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMM yyyy', 'es').format(_visibleMonth);
    final cells = _daysInMonthGrid();
    final rowCount = cells.length ~/ 7;
    final canGoPrev = DateTime(_visibleMonth.year, _visibleMonth.month)
        .isAfter(DateTime(_firstDate.year, _firstDate.month));
    final canGoNext = DateTime(_visibleMonth.year, _visibleMonth.month)
        .isBefore(DateTime(_lastDate.year, _lastDate.month));
    final transactionDays = _daysWithTransactions();
    final rangeSpan = _rangeSpanDays();

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: SizedBox(
        width: 252,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: canGoPrev ? () => _shiftMonth(-1) : null,
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      size: 22,
                      color: canGoPrev
                          ? AppColors.ink
                          : AppColors.textMuted.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    monthLabel[0].toUpperCase() + monthLabel.substring(1),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: canGoNext ? () => _shiftMonth(1) : null,
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: canGoNext
                          ? AppColors.ink
                          : AppColors.textMuted.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.onCancel != null) ...[
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: widget.onCancel,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: _onToday,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Text(
                        'Hoy',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Material(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: _onConfirm,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                for (final label in _weekdayLabels)
                  Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
              ],
            ),
            for (var row = 0; row < rowCount; row++)
              _WeekPickerRow(
                cells: List.generate(7, (col) => cells[row * 7 + col]),
                inRange: (date) => date != null && _inHighlightRange(date),
                rangeIndex: (date) => _rangeIndex(date!),
                rangeSpan: rangeSpan,
                rangeColorAt: _colorAtDay,
                isSelectable: (date) => date != null && _isSelectable(date),
                isToday: (date) =>
                    date != null && _isSameDay(date, DateTime.now()),
                hasTransaction: (date) =>
                    date != null &&
                    transactionDays.contains(
                      DateTime(date.year, date.month, date.day),
                    ),
                onDayTap: _onDayTap,
              ),
          ],
        ),
      ),
    );
  }
}

class _CalendarCell {
  const _CalendarCell({this.date, this.isOutsideMonth = false});

  final DateTime? date;
  final bool isOutsideMonth;
}

class _WeekPickerRow extends StatelessWidget {
  const _WeekPickerRow({
    required this.cells,
    required this.inRange,
    required this.rangeIndex,
    required this.rangeSpan,
    required this.rangeColorAt,
    required this.isSelectable,
    required this.isToday,
    required this.hasTransaction,
    required this.onDayTap,
  });

  final List<_CalendarCell> cells;
  final bool Function(DateTime? date) inRange;
  final int Function(DateTime? date) rangeIndex;
  final int rangeSpan;
  final Color Function(DateTime day) rangeColorAt;
  final bool Function(DateTime? date) isSelectable;
  final bool Function(DateTime? date) isToday;
  final bool Function(DateTime? date) hasTransaction;
  final void Function(DateTime day) onDayTap;

  @override
  Widget build(BuildContext context) {
    int? startCol;
    int? endCol;
    for (var col = 0; col < 7; col++) {
      final date = cells[col].date;
      if (date != null && inRange(date)) {
        startCol ??= col;
        endCol = col;
      }
    }

    final hasBand = startCol != null;
    final radius = hasBand
        ? BorderRadius.circular(8)
        : BorderRadius.zero;

    return SizedBox(
      height: 34,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth = constraints.maxWidth / 7;
          final bandLeft = startCol != null ? startCol * cellWidth : 0.0;
          final bandWidth = startCol != null
              ? (endCol! - startCol + 1) * cellWidth
              : 0.0;
          final startDate = startCol != null ? cells[startCol].date : null;
          final endDate = endCol != null ? cells[endCol].date : null;

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              if (hasBand && startDate != null && endDate != null)
                Positioned(
                  left: bandLeft,
                  width: bandWidth,
                  top: 2,
                  bottom: 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          rangeColorAt(startDate),
                          rangeColorAt(endDate),
                        ],
                      ),
                      borderRadius: radius,
                    ),
                  ),
                ),
              Row(
                children: [
                  for (var col = 0; col < 7; col++)
                    Expanded(
                      child: _DayCell(
                        cell: cells[col],
                        inRange: cells[col].date != null &&
                            inRange(cells[col].date),
                        rangePosition: cells[col].date != null &&
                                inRange(cells[col].date)
                            ? rangeIndex(cells[col].date) /
                                (rangeSpan <= 0 ? 1 : rangeSpan)
                            : null,
                        selectable: isSelectable(cells[col].date),
                        isToday: isToday(cells[col].date),
                        hasTransaction: hasTransaction(cells[col].date),
                        onTap: cells[col].date == null
                            ? null
                            : () => onDayTap(cells[col].date!),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.cell,
    required this.inRange,
    required this.rangePosition,
    required this.selectable,
    required this.isToday,
    required this.hasTransaction,
    required this.onTap,
  });

  final _CalendarCell cell;
  final bool inRange;
  final double? rangePosition;
  final bool selectable;
  final bool isToday;
  final bool hasTransaction;
  final VoidCallback? onTap;

  static const _dotColor = Color(0xFFE67E22);

  @override
  Widget build(BuildContext context) {
    final date = cell.date;
    if (date == null) {
      return const SizedBox.shrink();
    }

    final textWeight =
        inRange || isToday ? FontWeight.w800 : FontWeight.w600;
    final textColor = !selectable && !inRange
        ? AppColors.textMuted.withValues(alpha: 0.35)
        : inRange
            ? Color.lerp(
                const Color(0xFF5C3A12),
                AppColors.textPrimary,
                rangePosition ?? 0,
              )!
            : cell.isOutsideMonth
                ? AppColors.textMuted.withValues(alpha: 0.45)
                : isToday
                    ? AppColors.ink
                    : AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: selectable ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: textWeight,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: 5,
                height: 5,
                child: hasTransaction
                    ? const DecoratedBox(
                        decoration: BoxDecoration(
                          color: _dotColor,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

