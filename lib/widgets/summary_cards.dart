import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/currency_formatter.dart';

class SummaryCards extends StatelessWidget {
  const SummaryCards({
    super.key,
    required this.totalIncome,
    required this.totalExpenses,
    required this.rateBcv,
    required this.rateParalelo,
    required this.inBs,
  });

  final double totalIncome;
  final double totalExpenses;
  final double rateBcv;
  final double rateParalelo;
  final bool inBs;

  @override
  Widget build(BuildContext context) {
    final formatMoney = inBs ? CurrencyFormatter.formatBs : CurrencyFormatter.formatUsd;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'INGRESOS',
                  value: formatMoney(totalIncome),
                  icon: Icons.south_west_rounded,
                  iconBg: AppColors.incomeBg,
                  iconColor: AppColors.ink,
                  valueStyle: _SummaryValueStyle.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  label: 'GASTOS',
                  value: formatMoney(totalExpenses),
                  icon: Icons.north_east_rounded,
                  iconBg: AppColors.expenseBg,
                  iconColor: AppColors.red,
                  valueStyle: _SummaryValueStyle.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'BCV',
                  value: '1\$ = ${rateBcv.toStringAsFixed(2)}',
                  icon: Icons.account_balance_outlined,
                  iconBg: AppColors.bcvBg,
                  iconColor: AppColors.bcvText,
                  valueStyle: _SummaryValueStyle.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  label: 'PARALELO',
                  value: '1\$ = ${rateParalelo.toStringAsFixed(2)}',
                  icon: Icons.show_chart_rounded,
                  iconBg: AppColors.paraleloBg,
                  iconColor: AppColors.paraleloText,
                  valueStyle: _SummaryValueStyle.secondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _SummaryValueStyle {
  primary,
  secondary,
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.valueStyle,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final _SummaryValueStyle valueStyle;

  @override
  Widget build(BuildContext context) {
    final valueFontSize = valueStyle == _SummaryValueStyle.primary ? 22.0 : 18.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.9,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: valueFontSize,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                height: 1.1,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
