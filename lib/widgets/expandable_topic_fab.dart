import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// FAB que se expande en dos acciones: registro tradicional y montos fijos.
class ExpandableTopicFab extends StatefulWidget {
  const ExpandableTopicFab({
    super.key,
    required this.onNewRegister,
    required this.onFixedAmount,
  });

  final VoidCallback onNewRegister;
  final VoidCallback onFixedAmount;

  @override
  State<ExpandableTopicFab> createState() => _ExpandableTopicFabState();
}

class _ExpandableTopicFabState extends State<ExpandableTopicFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _expand;

  bool get _open => _controller.value > 0.5;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _expand = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_open) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  void _run(VoidCallback action) {
    _controller.reverse();
    action();
  }

  double _segmentT(double t, double start, double end) {
    if (t <= start) return 0;
    if (t >= end) return 1;
    return (t - start) / (end - start);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _expand,
      builder: (context, _) {
        final t = _expand.value;
        final registerT = _segmentT(t, 0.08, 0.62);
        final fixedT = _segmentT(t, 0.18, 0.78);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _LiquidFabAction(
              progress: fixedT,
              icon: Icons.push_pin_outlined,
              label: 'Monto fijo',
              onPressed: () => _run(widget.onFixedAmount),
            ),
            if (fixedT > 0.001) const SizedBox(height: 12),
            _LiquidFabAction(
              progress: registerT,
              icon: Icons.add,
              label: 'Nuevo registro',
              onPressed: () => _run(widget.onNewRegister),
            ),
            if (registerT > 0.001) const SizedBox(height: 12),
            FloatingActionButton(
              heroTag: 'topicExpandFab',
              onPressed: _toggle,
              backgroundColor: AppColors.fab,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: RotationTransition(
                      turns: Tween<double>(begin: 0.15, end: 0).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  _open ? Icons.unfold_less : Icons.unfold_more,
                  key: ValueKey<bool>(_open),
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LiquidFabAction extends StatelessWidget {
  const _LiquidFabAction({
    required this.progress,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final double progress;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (progress <= 0.001) return const SizedBox.shrink();

    final emerge = Curves.easeOutBack.transform(progress.clamp(0.0, 1.0));
    final fade = Curves.easeOut.transform(progress.clamp(0.0, 1.0));
    final offsetY = (1 - emerge) * 28;
    // Ligero “goteo” horizontal al expandirse.
    final bulge = math.sin(progress * math.pi) * 0.08;
    final scaleX = (0.72 + emerge * 0.28 + bulge).clamp(0.0, 1.15);
    final scaleY = (0.55 + emerge * 0.45).clamp(0.0, 1.1);

    return Opacity(
      opacity: fade.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, offsetY),
        child: Transform.scale(
          scaleX: scaleX,
          scaleY: scaleY,
          alignment: Alignment.bottomRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: AppColors.surface,
                elevation: 2 * emerge,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FloatingActionButton.small(
                heroTag: 'topicFab_$label',
                onPressed: onPressed,
                backgroundColor: AppColors.ink,
                foregroundColor: Colors.white,
                child: Icon(icon, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
