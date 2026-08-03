import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/navigation/app_tab.dart';
import '../core/theme/app_colors.dart';
import '../providers/main_tab_provider.dart';
import '../providers/tutorial_provider.dart';
import '../services/shared_image_intake.dart';
import '../widgets/undo_bar.dart';
import 'activity_screen.dart';
import 'balance_screen.dart';
import 'papelera_screen.dart';
import 'tarjetas_screen.dart';
import 'topicos_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static const _transitionDuration = Duration(milliseconds: 280);

  bool _isSwitching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SharedImageIntake.start();
      ref.read(tutorialControllerProvider).checkAndStartGlobalTour(context);
    });
  }

  @override
  void dispose() {
    SharedImageIntake.stop();
    super.dispose();
  }

  Future<void> _goToTab(int index) async {
    final activeIndex = ref.read(mainTabProvider);
    if (index == activeIndex || _isSwitching) return;
    ref.read(mainTabProvider.notifier).state = index;
    setState(() => _isSwitching = true);
    await Future<void>.delayed(_transitionDuration);
    if (mounted) setState(() => _isSwitching = false);
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = ref.watch(mainTabProvider);
    final pages = <Widget>[
      const BalanceScreen(),
      const ActivityScreen(),
      const TopicosScreen(),
      const TarjetasScreen(),
      const PapeleraScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: IndexedStack(
          index: activeIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const UndoBar(),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(top: BorderSide(color: AppColors.border)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _TabItem(
                  key: TutorialKeys.billeteraTab,
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'BILLETERA',
                  active: activeIndex == AppTab.balance.tabIndex,
                  onTap: () => _goToTab(AppTab.balance.tabIndex),
                ),
                _TabItem(
                  key: TutorialKeys.actividadTab,
                  icon: Icons.receipt_long_outlined,
                  label: 'ACTIVIDAD',
                  active: activeIndex == AppTab.actividad.tabIndex,
                  onTap: () => _goToTab(AppTab.actividad.tabIndex),
                ),
                _TabItem(
                  key: TutorialKeys.topicosTab,
                  icon: Icons.sell_outlined,
                  label: 'TÓPICOS',
                  active: activeIndex == AppTab.topicos.tabIndex,
                  onTap: () => _goToTab(AppTab.topicos.tabIndex),
                ),
                _TabItem(
                  key: TutorialKeys.tarjetasTab,
                  icon: Icons.credit_card,
                  label: 'TARJETAS',
                  active: activeIndex == AppTab.tarjetas.tabIndex,
                  onTap: () => _goToTab(AppTab.tarjetas.tabIndex),
                ),
                _TabItem(
                  key: TutorialKeys.papeleraTab,
                  icon: Icons.delete_outline,
                  label: 'PAPELERA',
                  active: activeIndex == AppTab.papelera.tabIndex,
                  onTap: () => _goToTab(AppTab.papelera.tabIndex),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.ink : AppColors.textMuted;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: active ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeInOutCubic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeInOutCubic,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: active ? AppColors.softFill : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeInOutCubic,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
                child: Text(label, textAlign: TextAlign.center, maxLines: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
