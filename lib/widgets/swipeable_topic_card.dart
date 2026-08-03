import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/amount_parser.dart';
import '../models/topic.dart';
import 'topic_card.dart';

class SwipeableTopicCard extends StatelessWidget {
  const SwipeableTopicCard({
    super.key,
    required this.item,
    required this.activityCount,
    required this.onPress,
    required this.onDelete,
    this.extremes = const TopicExtremes(),
    this.deletable = true,
    this.isDefault = false,
    this.cardKey,
  });

  final Topic item;
  final int activityCount;
  final void Function(Topic item) onPress;
  final void Function(Topic item) onDelete;
  final TopicExtremes extremes;
  final bool deletable;
  final bool isDefault;
  final Key? cardKey;

  @override
  Widget build(BuildContext context) {
    final card = TopicCard(
      cardKey: cardKey,
      item: item,
      activityCount: activityCount,
      extremes: extremes,
      onPress: onPress,
      isDefault: isDefault,
    );

    if (!deletable) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: card,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: ValueKey(item.id),
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.35,
          dismissible: DismissiblePane(
            onDismissed: () => onDelete(item),
            dismissThreshold: 0.6,
          ),
          children: [
            SlidableAction(
              onPressed: (_) => onDelete(item),
              backgroundColor: AppColors.deleteSwipeBg,
              foregroundColor: AppColors.ink,
              icon: Icons.delete_outline,
              label: 'Borrar',
            ),
          ],
        ),
        child: card,
      ),
    );
  }
}

class SwipeableRestoreTopicCard extends StatelessWidget {
  const SwipeableRestoreTopicCard({
    super.key,
    required this.item,
    required this.linkedCount,
    required this.onRestore,
  });

  final Topic item;
  final int linkedCount;
  final void Function(Topic item) onRestore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Slidable(
        key: ValueKey('restore-topic-${item.id}'),
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.35,
          dismissible: DismissiblePane(
            onDismissed: () => onRestore(item),
            dismissThreshold: 0.6,
          ),
          children: [
            SlidableAction(
              onPressed: (_) => onRestore(item),
              backgroundColor: AppColors.restoreSwipeBg,
              foregroundColor: AppColors.greenDark,
              icon: Icons.reply,
              label: 'Restaurar',
            ),
          ],
        ),
        child: TopicCard(
          item: item,
          activityCount: linkedCount,
          onPress: (_) {},
        ),
      ),
    );
  }
}
