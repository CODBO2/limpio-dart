import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

enum EmptyStateVariant { activity, fuentes, topics, cards }

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.tutorial,
    this.variant = EmptyStateVariant.activity,
  });

  final String title;
  final String tutorial;
  final EmptyStateVariant variant;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _EmptyIllustration(variant: variant),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            tutorial,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyIllustration extends StatelessWidget {
  const _EmptyIllustration({required this.variant});

  final EmptyStateVariant variant;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      height: 128,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(
        switch (variant) {
          EmptyStateVariant.activity => Icons.account_balance_wallet_outlined,
          EmptyStateVariant.fuentes => Icons.repeat,
          EmptyStateVariant.topics => Icons.sell_outlined,
          EmptyStateVariant.cards => Icons.credit_card,
        },
        size: 40,
        color: AppColors.textMuted,
      ),
    );
  }
}
