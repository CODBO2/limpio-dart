import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/navigation/app_tab.dart';
import '../core/theme/app_colors.dart';
import '../models/payment_card.dart';
import '../providers/activities_provider.dart';
import '../providers/cards_provider.dart';
import '../providers/main_tab_provider.dart';
import '../providers/tutorial_provider.dart';
import '../widgets/draggable_edge_fab.dart';
import '../widgets/empty_state.dart';
import '../widgets/payment_card_tile.dart';
import 'card_detail_screen.dart';
import 'edit_payment_card_screen.dart';

class TarjetasScreen extends ConsumerWidget {
  const TarjetasScreen({super.key});

  Future<void> _createOrEdit(
    BuildContext context,
    WidgetRef ref, {
    PaymentCard? editing,
  }) async {
    final draft = await pushEditPaymentCardScreen(context, editing: editing);
    if (draft == null) return;

    if (editing == null) {
      await ref.read(cardsProvider.notifier).add(
            name: draft.name,
            kind: draft.kind,
            lastFour: draft.lastFour,
            bank: draft.bank,
            colorHex: draft.colorHex,
            currencyMode: draft.currencyMode,
          );
      return;
    }

    await ref.read(cardsProvider.notifier).update(
          editing.copyWith(
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

  void _openCard(BuildContext context, PaymentCard card) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, __, ___) => CardDetailScreen(card: card),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.06, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(cardsProvider);
    final activities = ref.watch(activitiesProvider);
    final activeTab = ref.watch(mainTabProvider);

    if (activeTab == AppTab.tarjetas.tabIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final tutorialCtrl = ref.read(tutorialControllerProvider);
        if (!tutorialCtrl.isTourRunning) {
          tutorialCtrl.showScreenTutorial(context, 3);
        }
      });
    }

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TARJETAS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 1.2,
                        ),
                      ),
                      IconButton(
                        onPressed: () => ref.read(tutorialControllerProvider).showScreenTutorial(context, 3, force: true),
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
                  SizedBox(height: 4),
                  Text(
                    'Mis medios de pago',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Registra solo datos no sensibles (alias, débito/crédito y últimos 4 dígitos). Luego podrás asociarlos a tus compras.',
                    style: TextStyle(color: AppColors.textSecondary, height: 1.45),
                  ),
                ],
              ),
            ),
            Expanded(
              child: cards.isEmpty
                  ? const EmptyState(
                      variant: EmptyStateVariant.cards,
                      title: 'Aquí aparecerán tus tarjetas',
                      tutorial:
                          'Toca el botón + para añadir una tarjeta (por ejemplo «Visa personal»). No guardamos el número completo ni el CVV.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                      itemCount: cards.length,
                      itemBuilder: (context, index) {
                        final card = cards[index];
                        return PaymentCardTile(
                          item: card,
                          usageCount: activities
                              .where((a) => a.cardId == card.id)
                              .length,
                          onPress: (item) => _openCard(context, item),
                          onEdit: (item) =>
                              _createOrEdit(context, ref, editing: item),
                          onDelete: (item) =>
                              ref.read(cardsProvider.notifier).remove(item.id),
                        );
                      },
                    ),
            ),
          ],
        ),
        DraggableEdgeFab(
          buttonKey: TutorialKeys.cardAdd,
          onPressed: () => _createOrEdit(context, ref),
          bottomSafePadding: 24,
        ),
      ],
    );
  }
}
