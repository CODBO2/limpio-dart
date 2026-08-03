import 'package:flutter/material.dart';

import '../core/constants/venezuelan_bank_branding.dart';
import '../models/payment_card.dart';
import 'bank_card_pattern_painter.dart';

class VenezuelanBankCardFace extends StatelessWidget {
  const VenezuelanBankCardFace({
    super.key,
    required this.branding,
    required this.item,
    required this.usageLabel,
    required this.onPress,
    required this.onDelete,
  });

  final VenezuelanBankBranding branding;
  final PaymentCard item;
  final String usageLabel;
  final void Function(PaymentCard item) onPress;
  final void Function(PaymentCard item) onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: branding.primary.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onPress(item),
            child: CustomPaint(
              painter: BankCardPatternPainter(branding: branding),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 8, 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _BankMark(
                                label: branding.shortLabel,
                                accent: branding.accent,
                                textColor: branding.textOnCard,
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.18),
                                  ),
                                ),
                                child: Text(
                                  item.kind.label.toUpperCase(),
                                  style: TextStyle(
                                    color: branding.textMutedOnCard,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.contactless,
                                color: branding.textOnCard.withValues(alpha: 0.55),
                                size: 22,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            item.name,
                            style: TextStyle(
                              color: branding.textOnCard,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.lastFour == null || item.lastFour!.isEmpty
                                ? item.subtitle
                                : '${item.subtitle} · •••• ${item.lastFour}',
                            style: TextStyle(
                              color: branding.textMutedOnCard,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            usageLabel,
                            style: TextStyle(
                              color: branding.textOnCard.withValues(alpha: 0.55),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => onDelete(item),
                      icon: Icon(
                        Icons.delete_outline,
                        color: branding.textOnCard.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BankMark extends StatelessWidget {
  const _BankMark({
    required this.label,
    required this.accent,
    required this.textColor,
  });

  final String label;
  final Color accent;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
