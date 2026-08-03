import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/fuente.dart';

class FuenteCard extends StatelessWidget {
  const FuenteCard({
    super.key,
    required this.item,
    this.onPress,
    required this.onDelete,
  });

  final Fuente item;
  final void Function(Fuente item)? onPress;
  final void Function(Fuente item) onDelete;

  @override
  Widget build(BuildContext context) {
    final amountDisplay = item.currency == 'VES'
        ? CurrencyFormatter.formatBs(double.tryParse(item.amount.replaceAll(',', '')) ?? 0)
        : '${(double.tryParse(item.amount.replaceAll(',', '')) ?? 0).toStringAsFixed(2)} \$';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => onPress?.call(item),
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFA5D6A7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_today, size: 22, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        Text(
                          'Día ${item.day} de cada mes',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        amountDisplay,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const Text(
                        'fijo mensual',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () => onDelete(item),
            icon: const Icon(Icons.delete_outline, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
