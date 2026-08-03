import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../core/theme/app_colors.dart';
import '../models/activity.dart';
import 'activity_card.dart';

class SwipeableActivityCard extends StatelessWidget {
  const SwipeableActivityCard({
    super.key,
    required this.item,
    this.onPress,
    this.onLongPress,
    required this.onDelete,
    this.showTopicLabel = false,
    this.selected = false,
    this.selectionMode = false,
  });

  final Activity item;
  final void Function(Activity item)? onPress;
  final void Function(Activity item)? onLongPress;
  final void Function(Activity item) onDelete;
  final bool showTopicLabel;
  final bool selected;
  final bool selectionMode;

  @override
  Widget build(BuildContext context) {
    final card = ActivityCard(
      item: item,
      showTopicLabel: showTopicLabel,
      selected: selected,
      selectionMode: selectionMode,
      onTap: () => onPress?.call(item),
      onLongPress: onLongPress == null ? null : () => onLongPress!(item),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: selectionMode
          ? card
          : Slidable(
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

class SwipeableRestoreCard extends StatelessWidget {
  const SwipeableRestoreCard({
    super.key,
    required this.item,
    required this.onRestore,
  });

  final Activity item;
  final void Function(Activity item) onRestore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Slidable(
        key: ValueKey(item.id),
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.35,
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
        child: ActivityCard(item: item),
      ),
    );
  }
}

class SwipeableLockedCard extends StatelessWidget {
  const SwipeableLockedCard({
    super.key,
    required this.item,
    required this.onLockedSwipe,
  });

  final Activity item;
  final VoidCallback onLockedSwipe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Slidable(
        key: ValueKey(item.id),
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (_) => onLockedSwipe(),
              backgroundColor: AppColors.lockedSwipeBg,
              foregroundColor: AppColors.textSecondary,
              icon: Icons.lock_outline,
              label: '',
            ),
          ],
        ),
        child: ActivityCard(item: item),
      ),
    );
  }
}
