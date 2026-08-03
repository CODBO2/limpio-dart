import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/amount_parser.dart';
import '../core/utils/currency_formatter.dart';
import '../models/topic.dart';

class TopicCard extends StatelessWidget {
  const TopicCard({
    super.key,
    required this.item,
    required this.activityCount,
    required this.onPress,
    this.extremes = const TopicExtremes(),
    this.isDefault = false,
    this.cardKey,
  });

  final Topic item;
  final int activityCount;
  final void Function(Topic item) onPress;
  final TopicExtremes extremes;
  final bool isDefault;
  final Key? cardKey;

  @override
  Widget build(BuildContext context) {
    final countLabel = activityCount == 1
        ? '1 movimiento'
        : '$activityCount movimientos';
    final peak = extremes.largest;
    final amountColor =
        extremes.isIncome ? AppColors.ink : AppColors.textSecondary;

    return Material(
      key: cardKey,
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => onPress(item),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDefault ? AppColors.borderStrong : AppColors.border,
              width: isDefault ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 10, 16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isDefault ? AppColors.softFillDark : AppColors.ink,
                    borderRadius: BorderRadius.circular(14),
                    border: isDefault
                        ? Border.all(color: AppColors.borderStrong)
                        : null,
                  ),
                  child: Icon(
                    isDefault ? Icons.inbox_outlined : Icons.sell_outlined,
                    size: 22,
                    color: isDefault ? AppColors.ink : Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.name,
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
                          if (isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.softFill,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Text(
                                'FIJO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isDefault
                            ? '$countLabel · sin tópico explícito'
                            : countLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (peak != null) ...[
                        const SizedBox(height: 6),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: extremes.label,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              TextSpan(
                                text:
                                    '  ${CurrencyFormatter.normalizeAmountDisplay(peak.amount)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: amountColor,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textMuted,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
