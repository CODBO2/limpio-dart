import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

Future<bool> showEmptyTrashConfirmModal(
  BuildContext context, {
  required int count,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => _EmptyTrashConfirmDialog(count: count),
  );
  return confirmed == true;
}

class _EmptyTrashConfirmDialog extends StatelessWidget {
  const _EmptyTrashConfirmDialog({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count == 1
        ? '1 elemento'
        : '$count elementos';

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.softFill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.delete_forever_outlined,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Vaciar papelera',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Vas a eliminar definitivamente $label. Esta acción no se puede deshacer.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.45,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.borderStrong),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Eliminar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Overlay a pantalla completa: papelera que se abre, traga papeles y se vacía.
Future<void> playEmptyTrashAnimation(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Vaciar papelera',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, _, __) => const _EmptyTrashAnimationPage(),
    transitionBuilder: (context, animation, _, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

class _EmptyTrashAnimationPage extends StatefulWidget {
  const _EmptyTrashAnimationPage();

  @override
  State<_EmptyTrashAnimationPage> createState() =>
      _EmptyTrashAnimationPageState();
}

class _EmptyTrashAnimationPageState extends State<_EmptyTrashAnimationPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward().whenComplete(() {
        if (mounted) Navigator.of(context).pop();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 180,
                  height: 200,
                  child: CustomPaint(
                    painter: _TrashEmptyPainter(progress: t),
                  ),
                ),
                const SizedBox(height: 20),
                AnimatedOpacity(
                  opacity: t > 0.72 ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    t > 0.85 ? 'Papelera vacía' : 'Eliminando…',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TrashEmptyPainter extends CustomPainter {
  _TrashEmptyPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final bodyTop = size.height * 0.38;
    final bodyBottom = size.height * 0.92;
    final bodyWidth = size.width * 0.46;
    final bodyLeft = cx - bodyWidth / 2;
    final bodyRight = cx + bodyWidth / 2;

    // Timeline:
    // 0.00–0.18 lid opens
    // 0.15–0.55 papers fall in
    // 0.50–0.70 shake + lid closes
    // 0.70–1.00 shrink / fade
    final lidOpen = Curves.easeOutCubic.transform(
      ((progress - 0.0) / 0.18).clamp(0.0, 1.0),
    );
    final lidClose = Curves.easeInOutCubic.transform(
      ((progress - 0.52) / 0.18).clamp(0.0, 1.0),
    );
    final lidAngle = -0.95 * lidOpen * (1 - lidClose);

    final shakePhase = ((progress - 0.48) / 0.22).clamp(0.0, 1.0);
    final shake = shakePhase > 0 && shakePhase < 1
        ? math.sin(shakePhase * math.pi * 6) * 4 * (1 - shakePhase)
        : 0.0;

    final shrink = Curves.easeInCubic.transform(
      ((progress - 0.78) / 0.22).clamp(0.0, 1.0),
    );
    final scale = 1 - 0.35 * shrink;
    final opacity = 1 - 0.85 * shrink;

    canvas.save();
    canvas.translate(cx + shake, size.height / 2);
    canvas.scale(scale);
    canvas.translate(-cx, -size.height / 2);

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final stroke = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round;

    // Falling papers (behind / into bin)
    for (var i = 0; i < 5; i++) {
      final start = 0.12 + i * 0.055;
      final local = ((progress - start) / 0.38).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final fall = Curves.easeInCubic.transform(local);
      final x = cx + (i - 2) * 18.0 + math.sin(local * math.pi * 2 + i) * 8;
      final y = size.height * 0.08 + fall * (bodyTop - size.height * 0.05);
      final paperOpacity =
          opacity * (local < 0.85 ? 1.0 : (1 - (local - 0.85) / 0.15));
      final paperPaint = Paint()
        ..color = Colors.white.withValues(alpha: paperOpacity * 0.95);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((i.isEven ? 1 : -1) * 0.35 * local);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 22, height: 28),
        const Radius.circular(3),
      );
      canvas.drawRRect(rect, paperPaint);
      // fold line
      canvas.drawLine(
        const Offset(-6, -4),
        const Offset(6, -4),
        Paint()
          ..color = AppColors.ink.withValues(alpha: paperOpacity * 0.25)
          ..strokeWidth = 1.5,
      );
      canvas.restore();
    }

    // Bin body (trapezoid)
    final bottomInset = bodyWidth * 0.12;
    final bodyPath = Path()
      ..moveTo(bodyLeft, bodyTop)
      ..lineTo(bodyRight, bodyTop)
      ..lineTo(bodyRight - bottomInset, bodyBottom)
      ..lineTo(bodyLeft + bottomInset, bodyBottom)
      ..close();

    canvas.drawPath(
      bodyPath,
      Paint()..color = const Color(0xFF1A1A1A).withValues(alpha: opacity),
    );
    canvas.drawPath(bodyPath, stroke);

    // Vertical ribs
    for (final dx in [-0.18, 0.0, 0.18]) {
      final x1 = cx + bodyWidth * dx;
      final x2 = cx + (bodyWidth - bottomInset * 2) * dx;
      canvas.drawLine(
        Offset(x1, bodyTop + 10),
        Offset(x2, bodyBottom - 10),
        Paint()
          ..color = Colors.white.withValues(alpha: opacity * 0.2)
          ..strokeWidth = 2,
      );
    }

    // Lid
    final lidY = bodyTop - 6;
    final lidWidth = bodyWidth + 18;
    canvas.save();
    canvas.translate(bodyLeft - 4, lidY);
    canvas.rotate(lidAngle);
    final lidRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, -10, lidWidth, 14),
      const Radius.circular(4),
    );
    canvas.drawRRect(lidRect, paint);
    // handle
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(lidWidth / 2, -18), width: 28, height: 8),
        const Radius.circular(4),
      ),
      paint,
    );
    canvas.restore();

    // Soft glow under bin near end
    if (progress > 0.75) {
      final glow = ((progress - 0.75) / 0.25).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(cx, bodyBottom + 8),
        28 * glow,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.15 * (1 - glow))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TrashEmptyPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
