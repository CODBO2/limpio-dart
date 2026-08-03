import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../models/trash_entry.dart';
import '../providers/trash_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/modals/empty_trash_confirm_modal.dart';
import '../widgets/swipeable_activity_card.dart';
import '../widgets/swipeable_topic_card.dart';

class PapeleraScreen extends ConsumerWidget {
  const PapeleraScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trash = ref.watch(trashProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 120),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _HeaderIcon(),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PAPELERA',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'Elementos eliminados',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                'Desliza a la derecha para restaurar. Al restaurar un tópico también vuelven sus movimientos asociados.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (trash.isNotEmpty) ...[
          _EmptyTrashButton(count: trash.length),
          const SizedBox(height: 20),
        ],
        if (trash.isEmpty)
          const Column(
            children: [
              EmptyState(
                title: 'Papelera vacía',
                tutorial:
                    'Las actividades y tópicos que borres aparecerán aquí. Puedes restaurarlos deslizando o eliminarlos para siempre.',
              ),
            ],
          )
        else
          ...trash.reversed.map((entry) {
            if (entry.isTopic) {
              final linkedCount = trash
                  .where(
                    (e) =>
                        e.isActivity && e.activity!.topicId == entry.topic!.id,
                  )
                  .length;
              return SwipeableRestoreTopicCard(
                item: entry.topic!,
                linkedCount: linkedCount,
                onRestore: (topic) => ref
                    .read(trashProvider.notifier)
                    .restore(TrashEntry.topic(topic)),
              );
            }
            return SwipeableRestoreCard(
              item: entry.activity!,
              onRestore: (activity) =>
                  ref.read(trashProvider.notifier).restoreActivity(activity),
            );
          }),
      ],
    );
  }
}

class _EmptyTrashButton extends ConsumerStatefulWidget {
  const _EmptyTrashButton({required this.count});

  final int count;

  @override
  ConsumerState<_EmptyTrashButton> createState() => _EmptyTrashButtonState();
}

class _EmptyTrashButtonState extends ConsumerState<_EmptyTrashButton> {
  bool _emptying = false;

  Future<void> _emptyTrash() async {
    if (_emptying || widget.count == 0) return;

    final confirmed = await showEmptyTrashConfirmModal(
      context,
      count: widget.count,
    );
    if (!confirmed || !mounted) return;

    setState(() => _emptying = true);
    await playEmptyTrashAnimation(context);
    if (!mounted) return;
    await ref.read(trashProvider.notifier).emptyAll();
    if (mounted) setState(() => _emptying = false);
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: _emptying ? null : _emptyTrash,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.ink,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      icon: const Icon(Icons.delete_outline),
      label: const Text('Eliminar todas'),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.delete_outline, color: Colors.white),
    );
  }
}
