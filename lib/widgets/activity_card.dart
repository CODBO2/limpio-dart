import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../core/constants/defaults.dart';
import '../models/activity.dart';
import '../models/activity_builder.dart';
import '../models/payment_method.dart';
import '../providers/cards_provider.dart';
import '../providers/topics_provider.dart';

class ActivityCard extends ConsumerWidget {
  const ActivityCard({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
    this.showTopicLabel = false,
    this.selected = false,
    this.selectionMode = false,
  });

  final Activity item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showTopicLabel;
  final bool selected;
  final bool selectionMode;

  String _metaLabel(WidgetRef ref) {
    final kindLabel = ActivityKind.displayLabel(item.subtitle);
    if (ActivityKind.isIncome(item.subtitle)) return kindLabel;

    final method = PaymentMethod.resolve(
      paymentMethod: item.paymentMethod,
      cardId: item.cardId,
    );

    if (method == PaymentMethod.card) {
      final cards = ref.watch(cardsProvider);
      for (final card in cards) {
        if (card.id == item.cardId) {
          return '$kindLabel · ${card.displayLabel}';
        }
      }
      return '$kindLabel · Tarjeta';
    }

    return '$kindLabel · ${method.label}';
  }

  String _topicLabel(WidgetRef ref) {
    final topicId = item.topicId ?? Defaults.defaultTopicId;

    final topics = ref.watch(topicsProvider);
    for (final topic in topics) {
      if (topic.id == topicId) return topic.name;
    }
    if (topicId == Defaults.defaultTopicId) {
      return Defaults.defaultTopicName;
    }
    return 'Tópico eliminado';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncome = ActivityKind.isIncome(item.subtitle);
    final iconColor = isIncome ? AppColors.inkSoft : AppColors.red;
    final iconBg = isIncome ? AppColors.softFill : AppColors.softFillDark;
    final amountColor = isIncome ? AppColors.ink : AppColors.textSecondary;
    final meta = _metaLabel(ref);

    return Material(
      color: selected ? AppColors.softFill : AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.ink : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              if (selectionMode) ...[
                Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.ink : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: selected ? AppColors.ink : AppColors.textMuted,
                      width: 1.5,
                    ),
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 10),
              ],
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  ActivityBuilder.iconFromName(item.iconName),
                  size: 20,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyFormatter.normalizeAmountDisplay(item.amount),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: amountColor,
                              ),
                            ),
                            if (item.equivalentBs != null)
                              Text(
                                '≈ ${CurrencyFormatter.formatBs(item.equivalentBs!)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              )
                            else if (item.equivalentUsd != null)
                              Text(
                                '≈ ${CurrencyFormatter.formatUsd(item.equivalentUsd!)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    if (showTopicLabel) ...[
                      const SizedBox(height: 8),
                      _TopicTag(label: _topicLabel(ref)),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ),
                        Text(
                          item.date,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicTag extends StatelessWidget {
  const _TopicTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.softFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sell_outlined, size: 12, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
