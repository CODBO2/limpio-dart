import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../providers/trash_provider.dart';

/// Global "Deshacer" control shown after moving items to trash.
class UndoBar extends ConsumerWidget {
  const UndoBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showUndo = ref.watch(showUndoProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.18),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: showUndo
          ? Padding(
              key: const ValueKey('undo-bar'),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Material(
                color: AppColors.snackbarDark,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () async {
                    await ref.read(trashProvider.notifier).undoLastDelete();
                    ref.read(undoControllerProvider).hide();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    child: Center(
                      child: Text(
                        'Deshacer',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(key: ValueKey('undo-empty')),
    );
  }
}
