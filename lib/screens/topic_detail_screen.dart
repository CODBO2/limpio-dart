import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/amount_parser.dart';
import '../core/utils/weekly_expense_calculator.dart';
import '../models/activity.dart';
import '../models/topic.dart';
import '../providers/activities_provider.dart';
import '../providers/balance_provider.dart';
import '../providers/trash_provider.dart';
import '../providers/tutorial_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/modals/register_transaction_flow.dart';
import '../widgets/modals/topic_picker_modal.dart';
import '../widgets/swipeable_activity_card.dart';
import '../widgets/undo_bar.dart';
import '../widgets/week_range_picker.dart';
enum _TopicSort {
  date,
  amountDesc,
  amountAsc,
  titleAsc,
}

extension on _TopicSort {
  String get label => switch (this) {
        _TopicSort.date => 'Fecha',
        _TopicSort.amountDesc => 'Mayor a menor',
        _TopicSort.amountAsc => 'Menor a mayor',
        _TopicSort.titleAsc => 'A–Z',
      };

  String get shortLabel => switch (this) {
        _TopicSort.date => 'Fecha',
        _TopicSort.amountDesc => 'Mayor',
        _TopicSort.amountAsc => 'Menor',
        _TopicSort.titleAsc => 'A–Z',
      };

  IconData get icon => switch (this) {
        _TopicSort.date => Icons.calendar_today_outlined,
        _TopicSort.amountDesc => Icons.arrow_downward_rounded,
        _TopicSort.amountAsc => Icons.arrow_upward_rounded,
        _TopicSort.titleAsc => Icons.sort_by_alpha_rounded,
      };
}

class TopicDetailScreen extends ConsumerStatefulWidget {
  const TopicDetailScreen({super.key, required this.topic});

  final Topic topic;

  @override
  ConsumerState<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends ConsumerState<TopicDetailScreen> {
  final Set<String> _selectedIds = {};
  final _searchController = TextEditingController();
  String _searchQuery = '';
  _TopicSort _sort = _TopicSort.date;
  DateTime? _weekStart;

  bool get _selectionMode => _selectedIds.isNotEmpty;
  bool get _dateFilterActive =>
      _sort == _TopicSort.date && _weekStart != null;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openRegister([Activity? item]) {
    showRegisterTransactionFlow(
      context,
      editingItem: item,
      initialTopicId: widget.topic.id,
      topicName: widget.topic.name,
      topicMode: true,
      onSave: (_) {},
    );
  }

  void _clearSelection() {
    setState(() => _selectedIds.clear());
  }

  void _enterSelection(Activity item) {
    setState(() {
      _selectedIds
        ..clear()
        ..add(item.id);
    });
  }

  void _toggleSelection(Activity item) {
    setState(() {
      if (_selectedIds.contains(item.id)) {
        _selectedIds.remove(item.id);
      } else {
        _selectedIds.add(item.id);
      }
    });
  }

  void _onItemPress(Activity item) {
    if (_selectionMode) {
      _toggleSelection(item);
      return;
    }
    _openRegister(item);
  }

  Future<void> _handleDelete(Activity item) async {
    await ref.read(trashProvider.notifier).moveToTrash(item);
    ref.read(undoControllerProvider).show();
  }

  List<Activity> _selectedFrom(List<Activity> activities) {
    return activities
        .where((a) => _selectedIds.contains(a.id))
        .toList(growable: false);
  }

  Future<void> _moveSelected(List<Activity> activities) async {
    final selected = _selectedFrom(activities);
    if (selected.isEmpty) return;

    final destination = await showTopicPickerModal(
      context,
      excludeTopicId: widget.topic.id,
      title: selected.length == 1
          ? 'Mover 1 movimiento'
          : 'Mover ${selected.length} movimientos',
    );
    if (destination == null || !mounted) return;

    await ref.read(activitiesProvider.notifier).moveToTopic(
          selected.map((a) => a.id).toList(growable: false),
          destination.id,
        );
    _clearSelection();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          selected.length == 1
              ? 'Movido a «${destination.name}»'
              : '${selected.length} movimientos enviados a «${destination.name}»',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteSelected(List<Activity> activities) async {
    final selected = _selectedFrom(activities);
    if (selected.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar movimientos'),
        content: Text(
          selected.length == 1
              ? '¿Mover este movimiento a la papelera?'
              : '¿Mover ${selected.length} movimientos a la papelera?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ref.read(trashProvider.notifier).moveToTrashMany(selected);
    _clearSelection();
    ref.read(undoControllerProvider).show();
  }

  bool _matchesSearch(Activity activity) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return true;
    final haystack = [
      activity.title,
      activity.subtitle,
      activity.amount,
      activity.date,
      activity.paymentMethod ?? '',
    ].join(' ').toLowerCase();
    return haystack.contains(q);
  }

  bool _matchesWeek(Activity activity) {
    if (!_dateFilterActive) return true;
    final day = _activityDate(activity);
    if (day.millisecondsSinceEpoch == 0) return false;
    final start = WeeklyExpenseCalculator.dayOnly(_weekStart!);
    final end = start.add(const Duration(days: 6));
    return !day.isBefore(start) && !day.isAfter(end);
  }

  DateTime _activityDate(Activity activity) {
    final now = DateTime.now();
    return WeeklyExpenseCalculator.parseActivityDate(
          activity.date,
          fallbackYear: now.year,
        ) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  double _activityAmountUsd(Activity activity, double rate) {
    return activity.equivalentUsd ??
        AmountParser.parseAmountToUsd(activity.amount, rate: rate);
  }

  List<Activity> _sorted(List<Activity> activities, double rate) {
    final sorted = List<Activity>.of(activities);
    sorted.sort((a, b) {
      switch (_sort) {
        case _TopicSort.date:
          return _activityDate(b).compareTo(_activityDate(a));
        case _TopicSort.amountDesc:
          return _activityAmountUsd(b, rate)
              .compareTo(_activityAmountUsd(a, rate));
        case _TopicSort.amountAsc:
          return _activityAmountUsd(a, rate)
              .compareTo(_activityAmountUsd(b, rate));
        case _TopicSort.titleAsc:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
    });
    return sorted;
  }

  void _onSortSelected(_TopicSort sort, {DateTime? weekStart}) {
    setState(() {
      _sort = sort;
      if (sort == _TopicSort.date) {
        _weekStart = weekStart != null
            ? WeeklyExpenseCalculator.dayOnly(weekStart)
            : _weekStart;
      } else {
        _weekStart = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final topicActivities = ref
        .watch(activitiesProvider)
        .where((a) => a.topicId == widget.topic.id)
        .toList(growable: false);
    final rate = ref.watch(effectiveRateProvider);
    final searchActive = _searchQuery.trim().isNotEmpty;
    final dateFilterActive = _dateFilterActive;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(tutorialControllerProvider).checkAndStartInteractiveTopicTourStage3(context);
    });

    final visibleActivities = _sorted(
      topicActivities
          .where(_matchesSearch)
          .where(_matchesWeek)
          .toList(growable: false),
      rate,
    );

    final visibleIds = visibleActivities.map((a) => a.id).toSet();
    final selectedCount =
        _selectedIds.where(visibleIds.contains).length;

    final hasNoDataAtAll = topicActivities.isEmpty;
    final isEmpty = visibleActivities.isEmpty;
    final showUndo = ref.watch(showUndoProvider);

    return PopScope(
      canPop: !_selectionMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selectionMode) _clearSelection();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
          leading: _selectionMode
              ? IconButton(
                  onPressed: _clearSelection,
                  icon: const Icon(Icons.close_rounded),
                )
              : null,
          title: Text(
            _selectionMode
                ? (selectedCount == 1
                    ? '1 seleccionado'
                    : '$selectedCount seleccionados')
                : widget.topic.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          actions: [
            if (_selectionMode && selectedCount > 0)
              TextButton(
                onPressed: _clearSelection,
                child: const Text('Desmarcar todo'),
              ),
          ],
        ),
        body: hasNoDataAtAll
            ? const EmptyState(
                variant: EmptyStateVariant.topics,
                title: 'Sin movimientos en este tópico',
                tutorial:
                    'Toca el botón + para registrar un ingreso o egreso dentro de este tópico.',
              )
            : Column(
                children: [
                  if (!_selectionMode)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: _SearchField(
                              controller: _searchController,
                              onChanged: (value) =>
                                  setState(() => _searchQuery = value),
                              onClear: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          _SortSelector(
                            value: _sort,
                            weekStart: _weekStart,
                            activities: topicActivities,
                            onChanged: _onSortSelected,
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: isEmpty
                        ? EmptyState(
                            variant: EmptyStateVariant.activity,
                            title: searchActive
                                ? 'Sin resultados para la búsqueda'
                                : dateFilterActive
                                    ? 'Sin movimientos en este rango'
                                    : 'Sin movimientos en este tópico',
                            tutorial: searchActive
                                ? 'Prueba con otro término o limpia la búsqueda.'
                                : dateFilterActive
                                    ? 'Elige otro rango en Fecha o cambia el filtro.'
                                    : 'Toca el botón + para registrar un ingreso o egreso dentro de este tópico.',
                          )
                        : ListView.builder(
                            padding: EdgeInsets.fromLTRB(
                              20,
                              8,
                              20,
                              _selectionMode ? 120 : 100,
                            ),
                            itemCount: visibleActivities.length,
                            itemBuilder: (context, index) {
                              final item = visibleActivities[index];
                              return SwipeableActivityCard(
                                item: item,
                                selected: _selectedIds.contains(item.id),
                                selectionMode: _selectionMode,
                                onPress: _onItemPress,
                                onLongPress: _enterSelection,
                                onDelete: _handleDelete,
                              );
                            },
                          ),
                  ),
                ],
              ),
        bottomNavigationBar: !showUndo && !_selectionMode
            ? null
            : SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const UndoBar(),
                    if (_selectionMode)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: selectedCount == 0
                                    ? null
                                    : () => _moveSelected(visibleActivities),
                                icon: const Icon(Icons.drive_file_move_outlined),
                                label: const Text('Mover'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.ink,
                                  backgroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  side: const BorderSide(
                                    color: AppColors.borderStrong,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: selectedCount == 0
                                    ? null
                                    : () =>
                                        _deleteSelected(visibleActivities),
                                icon: const Icon(Icons.delete_outline_rounded),
                                label: Text(
                                  selectedCount <= 1
                                      ? 'Eliminar'
                                      : 'Eliminar ($selectedCount)',
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.fab,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
        floatingActionButton: _selectionMode
            ? null
            : FloatingActionButton(
                key: TutorialKeys.topicDetailFab,
                onPressed: () => _openRegister(),
                backgroundColor: AppColors.fab,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.add, size: 28),
              ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.isNotEmpty;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscar movimiento…',
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: hasText
            ? IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded, size: 18),
              )
            : null,
        filled: true,
        fillColor: AppColors.softFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
        ),
        isDense: true,
      ),
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _SortSelector extends StatefulWidget {
  const _SortSelector({
    required this.value,
    required this.weekStart,
    required this.activities,
    required this.onChanged,
  });

  final _TopicSort value;
  final DateTime? weekStart;
  final List<Activity> activities;
  final void Function(_TopicSort sort, {DateTime? weekStart}) onChanged;

  @override
  State<_SortSelector> createState() => _SortSelectorState();
}

class _SortSelectorState extends State<_SortSelector> {
  final _layerLink = LayerLink();
  OverlayEntry? _calendarEntry;

  @override
  void dispose() {
    _closeCalendar();
    super.dispose();
  }

  void _closeCalendar() {
    final entry = _calendarEntry;
    _calendarEntry = null;
    entry?.remove();
  }

  void _openCalendar() {
    _closeCalendar();
    final initial = widget.weekStart ??
        WeeklyExpenseCalculator.dayOnly(DateTime.now());
    _calendarEntry = insertWeekRangePickerOverlay(
      context: context,
      link: _layerLink,
      initialWeekStart: initial,
      activities: widget.activities,
      targetAnchor: Alignment.bottomRight,
      followerAnchor: Alignment.topRight,
      onConfirm: (weekStart) {
        widget.onChanged(_TopicSort.date, weekStart: weekStart);
      },
      onDismiss: _closeCalendar,
    );
  }

  void _onMenuSelected(_TopicSort sort) {
    if (sort == _TopicSort.date) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openCalendar();
      });
      return;
    }
    widget.onChanged(sort);
  }

  String get _buttonLabel {
    if (widget.value == _TopicSort.date && widget.weekStart != null) {
      final start = WeeklyExpenseCalculator.dayOnly(widget.weekStart!);
      final end = start.add(const Duration(days: 6));
      final today = WeeklyExpenseCalculator.dayOnly(DateTime.now());
      if (start.year == today.year &&
          start.month == today.month &&
          start.day == today.day) {
        return 'Hoy';
      }
      final fmt = DateFormat('d MMM', 'es');
      return '${fmt.format(start)} – ${fmt.format(end)}';
    }
    return widget.value.shortLabel;
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.value != _TopicSort.date || widget.weekStart != null;

    return CompositedTransformTarget(
      link: _layerLink,
      child: PopupMenuButton<_TopicSort>(
        initialValue: widget.value,
        onSelected: _onMenuSelected,
        offset: const Offset(0, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        color: AppColors.surface,
        itemBuilder: (context) => [
          for (final option in _TopicSort.values)
            PopupMenuItem<_TopicSort>(
              value: option,
              child: Row(
                children: [
                  Icon(
                    option.icon,
                    size: 18,
                    color: option == widget.value
                        ? AppColors.ink
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      option.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: option == widget.value
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (option == widget.value)
                    const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: AppColors.ink,
                    ),
                ],
              ),
            ),
        ],
        child: Material(
          color: active ? AppColors.ink : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active ? AppColors.ink : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sort_rounded,
                  size: 18,
                  color: active ? Colors.white : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 110),
                  child: Text(
                    _buttonLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: active ? Colors.white : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
