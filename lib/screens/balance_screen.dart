import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/navigation/app_tab.dart';
import '../core/theme/app_colors.dart';
import '../providers/activities_provider.dart';
import '../providers/balance_provider.dart';
import '../providers/main_tab_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/tutorial_provider.dart';
import '../widgets/summary_cards.dart';
import '../widgets/weekly_expense_chart.dart';

class BalanceScreen extends ConsumerWidget {
  const BalanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final settings = settingsState.settings;
    final totals = ref.watch(balanceProvider);
    final activities = ref.watch(activitiesProvider);
    final rate = settingsState.effectiveRate;
    final activeTab = ref.watch(mainTabProvider);

    if (activeTab == AppTab.balance.tabIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final tutorialCtrl = ref.read(tutorialControllerProvider);
        if (!tutorialCtrl.isTourRunning) {
          tutorialCtrl.showScreenTutorial(context, 0);
        }
      });
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'BILLETERA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
              IconButton(
                onPressed: () => ref.read(tutorialControllerProvider).startGlobalTour(context),
                icon: const Icon(Icons.help_outline_rounded, size: 18, color: AppColors.textSecondary),
                tooltip: 'Ver tutorial completo',
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(32, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  KeyedSubtree(
                    key: TutorialKeys.summaryCards,
                    child: SummaryCards(
                      totalIncome: totals.totalIncome,
                      totalExpenses: totals.totalExpenses,
                      rateBcv: settings.lastRateBcv,
                      rateParalelo: settings.lastRateParalelo,
                      inBs: false,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      key: TutorialKeys.refreshRate,
                      onPressed: settingsState.ratesRefreshing
                          ? null
                          : () => ref.read(settingsProvider.notifier).refreshRates(),
                      icon: settingsState.ratesRefreshing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh, size: 16, color: AppColors.ink),
                      label: const Text(
                        'Refrescar tasa',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.softFill,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  KeyedSubtree(
                    key: TutorialKeys.weeklyChart,
                    child: WeeklyExpenseChart(
                      activities: activities,
                      rate: rate,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
