import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../providers/main_tab_provider.dart';
import '../providers/tutorial_provider.dart';
import '../services/shared_image_intake.dart';
import '../widgets/curved_bottom_nav_bar.dart';
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
          CurvedBottomNavBar(
            currentIndex: activeIndex,
            onTap: _goToTab,
            items: [
              CurvedNavItem(
                key: TutorialKeys.billeteraTab,
                icon: Icons.account_balance_wallet_outlined,
                label: 'BILLETERA',
              ),
              CurvedNavItem(
                key: TutorialKeys.actividadTab,
                icon: Icons.receipt_long_outlined,
                label: 'ACTIVIDAD',
              ),
              CurvedNavItem(
                key: TutorialKeys.topicosTab,
                icon: Icons.sell_outlined,
                label: 'TÓPICOS',
              ),
              CurvedNavItem(
                key: TutorialKeys.tarjetasTab,
                icon: Icons.credit_card,
                label: 'TARJETAS',
              ),
              CurvedNavItem(
                key: TutorialKeys.papeleraTab,
                icon: Icons.delete_outline,
                label: 'PAPELERA',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
