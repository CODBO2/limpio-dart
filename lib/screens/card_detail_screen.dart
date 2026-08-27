import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../models/activity.dart';
import '../models/payment_card.dart';
import '../models/payment_method.dart';
import '../providers/activities_provider.dart';
import '../providers/cards_provider.dart';
import '../providers/trash_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/modals/register_transaction_flow.dart';
import '../widgets/swipeable_activity_card.dart';
import '../widgets/undo_bar.dart';
import 'edit_payment_card_screen.dart';

class CardDetailScreen extends ConsumerStatefulWidget {
  const CardDetailScreen({super.key, required this.card});

  final PaymentCard card;

  @override
  ConsumerState<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends ConsumerState<CardDetailScreen> {
  final Set<String> _selectedIds = {};

  bool get _selectionMode => _selectedIds.isNotEmpty;

  PaymentCard get _card {
    final cards = ref.watch(cardsProvider);
    for (final card in cards) {
      if (card.id == widget.card.id) return card;
    }
    return widget.card;
  }

  void _openRegister([Activity? item]) {
    showRegisterTransactionFlow(
      context,
      editingItem: item,
      initialCardId: widget.card.id,
      initialPaymentMethod: PaymentMethod.card,
      onSave: (_) {},
    );
  }

  Future<void> _editCard() async {
    final draft = await pushEditPaymentCardScreen(context, editing: _card);
    if (draft == null || !mounted) return;

    await ref.read(cardsProvider.notifier).update(
          _card.copyWith(
            name: draft.name,
            kind: draft.kind,
            lastFour: draft.lastFour,
            clearLastFour: draft.lastFour == null,
            bank: draft.bank,
            clearBank: draft.bank == null,
            colorHex: draft.colorHex,
            currencyMode: draft.currencyMode,
          ),
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

  @override
  Widget build(BuildContext context) {
    final card = _card;
    final activities = ref
        .watch(activitiesProvider)
        .where((a) => a.cardId == card.id)
        .toList(growable: false);

    final visibleIds = activities.map((a) => a.id).toSet();
    final selectedCount =
        _selectedIds.where(visibleIds.contains).length;
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
                : card.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          actions: [
            if (_selectionMode && selectedCount > 0)
              TextButton(
                onPressed: _clearSelection,
                child: const Text('Desmarcar todo'),
              )
            else if (!_selectionMode)
              IconButton(
                onPressed: _editCard,
                tooltip: 'Editar tarjeta',
                icon: const Icon(Icons.edit_outlined),
              ),
          ],
        ),
        body: activities.isEmpty
            ? const EmptyState(
                variant: EmptyStateVariant.cards,
                title: 'Sin movimientos en esta tarjeta',
                tutorial:
                    'Toca el botón + para registrar una compra asociada a esta tarjeta.',
              )
            : ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  _selectionMode ? 120 : 100,
                ),
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final item = activities[index];
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
                        child: FilledButton.icon(
                          onPressed: selectedCount == 0
                              ? null
                              : () => _deleteSelected(activities),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: Text(
                            selectedCount <= 1
                                ? 'Eliminar'
                                : 'Eliminar ($selectedCount)',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.fab,
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
        floatingActionButton: _selectionMode
            ? null
            : FloatingActionButton(
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
