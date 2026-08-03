import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/navigation/app_tab.dart';
import '../core/theme/app_colors.dart';
import '../models/activity.dart';
import '../providers/activities_provider.dart';
import '../providers/cards_provider.dart';
import '../providers/main_tab_provider.dart';
import '../providers/trash_provider.dart';
import '../providers/tutorial_provider.dart';
import '../widgets/activity_filter_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/modals/register_transaction_flow.dart';
import '../widgets/swipeable_activity_card.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  ActivityFilterState _filter = const ActivityFilterState();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _selectedIds = {};

  bool get _selectionMode => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openRegister([Activity? item]) {
    showRegisterTransactionFlow(
      context,
      editingItem: item,
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

  Future<void> _deleteSelected(List<Activity> visible) async {
    final selected = visible
        .where((a) => _selectedIds.contains(a.id))
        .toList(growable: false);
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

  Future<void> _openFilter() async {
    final cards = ref.read(cardsProvider);
    final activities = ref.read(activitiesProvider);
    final selected = await showActivityFilterSheet(
      context,
      current: _filter,
      cards: cards,
      activities: activities,
    );
    if (!mounted || selected == null) return;
    setState(() => _filter = selected);
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

  @override
  Widget build(BuildContext context) {
    final activities = ref.watch(activitiesProvider);
    final cards = ref.watch(cardsProvider);
    final filterActive = _filter.isActive;
    final searchActive = _searchQuery.trim().isNotEmpty;
    final activeTab = ref.watch(mainTabProvider);

    if (activeTab == AppTab.actividad.tabIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final tutorialCtrl = ref.read(tutorialControllerProvider);
        if (!tutorialCtrl.isTourRunning) {
          tutorialCtrl.showScreenTutorial(context, 1);
        }
      });
    }

    final filteredActivities = activities
        .where(_filter.matches)
        .where(_matchesSearch)
        .toList(growable: false);

    final visibleIds = filteredActivities.map((a) => a.id).toSet();
    final selectedCount =
        _selectedIds.where(visibleIds.contains).length;

    final isEmpty = filteredActivities.isEmpty;
    final hasNoDataAtAll = activities.isEmpty;

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_selectionMode) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'ACTIVIDAD',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                                letterSpacing: 1.2,
                              ),
                            ),
                            IconButton(
                              onPressed: () => ref.read(tutorialControllerProvider).showScreenTutorial(context, 1, force: true),
                              icon: const Icon(Icons.help_outline_rounded, size: 18, color: AppColors.textSecondary),
                              tooltip: 'Ver tutorial de esta pantalla',
                              style: IconButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(32, 32),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Historial completo',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hasNoDataAtAll
                              ? 'Aquí verás todos tus ingresos y egresos registrados.'
                              : '${filteredActivities.length} movimiento${filteredActivities.length == 1 ? '' : 's'}'
                                  '${filterActive ? ' · ${_filter.summaryLabel(cards)}' : ''}'
                                  '${searchActive ? ' · búsqueda' : ''}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              if (_selectionMode)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SelectionHeaderDelegate(
                    count: selectedCount,
                    onCancel: _clearSelection,
                    onDeselectAll: _clearSelection,
                  ),
                )
              else
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SearchBarHeaderDelegate(
                    searchController: _searchController,
                    searchQuery: _searchQuery,
                    filterActive: filterActive,
                    onSearchChanged: (value) =>
                        setState(() => _searchQuery = value),
                    onSearchClear: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    onFilterTap: _openFilter,
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  _selectionMode ? 96 : 24,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (hasNoDataAtAll)
                      const EmptyState(
                        title: 'Aquí aparecerán tus movimientos',
                        tutorial:
                            'Registra un ingreso o egreso desde Billetera. También puedes organizarlos por tópicos en la pestaña «Tópicos».',
                      )
                    else if (isEmpty)
                      EmptyState(
                        title: searchActive
                            ? 'Sin resultados para la búsqueda'
                            : 'No hay movimientos con este filtro',
                        tutorial: searchActive
                            ? 'Prueba con otro término o limpia el buscador.'
                            : 'Ajusta el filtro para ver otros movimientos.',
                      )
                    else
                      ...filteredActivities.map(
                        (item) => SwipeableActivityCard(
                          item: item,
                          showTopicLabel: true,
                          selected: _selectedIds.contains(item.id),
                          selectionMode: _selectionMode,
                          onPress: _onItemPress,
                          onLongPress: _enterSelection,
                          onDelete: _handleDelete,
                        ),
                      ),
                  ]),
                ),
              ),
            ],
          ),
          if (_selectionMode)
            Positioned(
              left: 20,
              right: 20,
              bottom: 16,
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: selectedCount == 0 ? null : _clearSelection,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.borderStrong),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Desmarcar todo'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: selectedCount == 0
                            ? null
                            : () => _deleteSelected(filteredActivities),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: Text(
                          selectedCount == 1
                              ? 'Eliminar'
                              : 'Eliminar ($selectedCount)',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.ink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SelectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SelectionHeaderDelegate({
    required this.count,
    required this.onCancel,
    required this.onDeselectAll,
  });

  final int count;
  final VoidCallback onCancel;
  final VoidCallback onDeselectAll;

  static const double _height = 72;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: Row(
          children: [
            IconButton(
              onPressed: onCancel,
              icon: const Icon(Icons.close_rounded),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.softFill,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    count == 1 ? '1 seleccionado' : '$count seleccionados',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  GestureDetector(
                    onTap: onDeselectAll,
                    child: const Text(
                      'Desmarcar todo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SelectionHeaderDelegate oldDelegate) {
    return count != oldDelegate.count;
  }
}

class _SearchBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SearchBarHeaderDelegate({
    required this.searchController,
    required this.searchQuery,
    required this.filterActive,
    required this.onSearchChanged,
    required this.onSearchClear,
    required this.onFilterTap,
  });

  final TextEditingController searchController;
  final String searchQuery;
  final bool filterActive;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClear;
  final VoidCallback onFilterTap;

  static const double _height = 64;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: Row(
          children: [
            Expanded(
              child: _SearchField(
                controller: searchController,
                onChanged: onSearchChanged,
                onClear: onSearchClear,
              ),
            ),
            const SizedBox(width: 10),
            KeyedSubtree(
              key: TutorialKeys.activityFilter,
              child: _FilterButton(
                active: filterActive,
                onTap: onFilterTap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SearchBarHeaderDelegate oldDelegate) {
    return searchQuery != oldDelegate.searchQuery ||
        filterActive != oldDelegate.filterActive ||
        searchController != oldDelegate.searchController;
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.ink : AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                Icons.tune_rounded,
                size: 18,
                color: active ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Filtro',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
