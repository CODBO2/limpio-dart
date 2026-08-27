import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/activity_builder.dart';
import '../models/fixed_expense_preset.dart';
import '../models/topic.dart';
import '../providers/activities_provider.dart';
import '../providers/fixed_expense_presets_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/empty_state.dart';
import 'edit_fixed_expense_screen.dart';

Future<void> pushFixedExpensesScreen(
  BuildContext context, {
  required Topic topic,
}) {
  return Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, __, ___) => FixedExpensesScreen(topic: topic),
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    ),
  );
}

class FixedExpensesScreen extends ConsumerWidget {
  const FixedExpensesScreen({super.key, required this.topic});

  final Topic topic;

  Future<void> _createOrEdit(
    BuildContext context,
    WidgetRef ref, {
    FixedExpensePreset? editing,
  }) async {
    final draft = await pushEditFixedExpenseScreen(context, editing: editing);
    if (draft == null) return;

    if (editing == null) {
      await ref.read(fixedExpensePresetsProvider.notifier).add(
            topicId: topic.id,
            title: draft.title,
            amount: draft.amount,
            currency: draft.currency,
            paymentMethod: draft.paymentMethod,
          );
      return;
    }

    await ref.read(fixedExpensePresetsProvider.notifier).update(
          editing.copyWith(
            title: draft.title,
            amount: draft.amount,
            currency: draft.currency,
            paymentMethod: draft.paymentMethod,
          ),
        );
  }

  Future<void> _registerNow(
    BuildContext context,
    WidgetRef ref,
    FixedExpensePreset preset,
  ) async {
    final rate = ref.read(settingsProvider).effectiveRate;
    final activity = ActivityBuilder.buildFromForm(
      concepto: preset.title,
      monto: preset.amount,
      currency: preset.isVes ? 'bolivares' : 'dolares',
      isIncome: false,
      effectiveRate: rate,
      topicId: topic.id,
      paymentMethod: preset.paymentMethod,
    );
    await ref.read(activitiesProvider.notifier).add(activity);

    if (!context.mounted) return;
    final amountLabel = preset.isVes
        ? CurrencyFormatter.formatBs(
            double.tryParse(preset.amount) ?? 0,
          )
        : CurrencyFormatter.formatUsd(
            double.tryParse(preset.amount) ?? 0,
          );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Registrado · ${preset.title} · $amountLabel'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presets = ref
        .watch(fixedExpensePresetsProvider)
        .where((p) => p.topicId == topic.id)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gastos fijos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              topic.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createOrEdit(context, ref),
        backgroundColor: AppColors.fab,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.add, size: 28),
      ),
      body: presets.isEmpty
          ? const EmptyState(
              title: 'Sin gastos fijos todavía',
              tutorial:
                  'Crea atajos como «Cajero · 1000 \$». Al tocarlos se registran al instante en este tópico.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              itemCount: presets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final preset = presets[index];
                final amountLabel = preset.isVes
                    ? CurrencyFormatter.formatBs(
                        double.tryParse(preset.amount) ?? 0,
                      )
                    : CurrencyFormatter.formatUsd(
                        double.tryParse(preset.amount) ?? 0,
                      );
                return Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _registerNow(context, ref, preset),
                    onLongPress: () =>
                        _createOrEdit(context, ref, editing: preset),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.softFill,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(
                              Icons.push_pin_outlined,
                              size: 20,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  preset.title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$amountLabel · ${preset.paymentMethod.label}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Toca para registrar ahora',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Editar',
                            onPressed: () =>
                                _createOrEdit(context, ref, editing: preset),
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 20,
                              color: AppColors.textMuted,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Eliminar',
                            onPressed: () => ref
                                .read(fixedExpensePresetsProvider.notifier)
                                .remove(preset.id),
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
