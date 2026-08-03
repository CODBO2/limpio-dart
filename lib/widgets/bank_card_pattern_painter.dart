import 'package:flutter/material.dart';

import '../core/constants/venezuelan_bank_branding.dart';

class BankCardPatternPainter extends CustomPainter {
  BankCardPatternPainter({required this.branding});

  final VenezuelanBankBranding branding;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final bgPaint = Paint()
      ..shader = branding.backgroundGradient.createShader(rect);
    canvas.drawRect(rect, bgPaint);

    switch (branding.pattern) {
      case BankCardPattern.gradient:
        _paintSubtleSheen(canvas, size);
      case BankCardPattern.diagonalBands:
        _paintDiagonalBands(canvas, size);
      case BankCardPattern.waveAccent:
        _paintWaveAccent(canvas, size);
      case BankCardPattern.cornerGlow:
        _paintCornerGlow(canvas, size);
      case BankCardPattern.splitTone:
        _paintSplitTone(canvas, size);
      case BankCardPattern.circles:
        _paintCircles(canvas, size);
      case BankCardPattern.digital:
        _paintDigital(canvas, size);
    }
  }

  void _paintSubtleSheen(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.14),
          Colors.transparent,
          Colors.black.withValues(alpha: 0.08),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
  }

  void _paintDiagonalBands(Canvas canvas, Size size) {
    _paintSubtleSheen(canvas, size);
    final paint = Paint()
      ..color = branding.accent.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.22;

    for (var i = -2; i < 6; i++) {
      final x = size.width * 0.15 * i;
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height * 0.9, 0),
        paint,
      );
    }
  }

  void _paintWaveAccent(Canvas canvas, Size size) {
    _paintSubtleSheen(canvas, size);
    final path = Path();
    path.moveTo(0, size.height * 0.55);
    path.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.35,
      size.width * 0.7,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.95,
      size.height * 0.62,
      size.width,
      size.height * 0.42,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(
      path,
      Paint()..color = branding.accent.withValues(alpha: 0.22),
    );
  }

  void _paintCornerGlow(Canvas canvas, Size size) {
    _paintSubtleSheen(canvas, size);
    final glow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.85, -0.6),
        radius: 0.9,
        colors: [
          branding.accent.withValues(alpha: 0.45),
          branding.accent.withValues(alpha: 0.0),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, glow);

    final linePaint = Paint()
      ..color = branding.accent.withValues(alpha: 0.55)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(size.width * 0.08, size.height * 0.22),
      Offset(size.width * 0.42, size.height * 0.22),
      linePaint,
    );
  }

  void _paintSplitTone(Canvas canvas, Size size) {
    final splitPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          branding.primary,
          Color.lerp(branding.primary, branding.secondary, 0.5)!,
          branding.secondary,
        ],
        stops: const [0.0, 0.52, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, splitPaint);

    final accentRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.62, 0, size.width * 0.38, size.height),
      const Radius.circular(0),
    );
    canvas.drawRRect(
      accentRect,
      Paint()..color = branding.accent.withValues(alpha: 0.14),
    );
    _paintSubtleSheen(canvas, size);
  }

  void _paintCircles(Canvas canvas, Size size) {
    _paintSubtleSheen(canvas, size);
    final paint = Paint()..color = branding.accent.withValues(alpha: 0.16);
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.28),
      size.width * 0.22,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.38),
      size.width * 0.14,
      Paint()..color = branding.accent.withValues(alpha: 0.10),
    );
  }

  void _paintDigital(Canvas canvas, Size size) {
    _paintSubtleSheen(canvas, size);
    final gridPaint = Paint()
      ..color = branding.accent.withValues(alpha: 0.12)
      ..strokeWidth = 1;

    final step = size.width / 8.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final chipRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.06, size.height * 0.14, 36, 26),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      chipRect,
      Paint()..color = branding.accent.withValues(alpha: 0.35),
    );
    canvas.drawRRect(
      chipRect,
      Paint()
        ..color = branding.accent.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant BankCardPatternPainter oldDelegate) {
    return oldDelegate.branding != branding;
  }
}
