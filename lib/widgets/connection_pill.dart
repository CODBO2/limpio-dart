import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class ConnectionPill extends StatelessWidget {
  const ConnectionPill({
    super.key,
    required this.isOnline,
    this.lightBackground = false,
  });

  final bool isOnline;
  final bool lightBackground;

  @override
  Widget build(BuildContext context) {
    final bgColor = lightBackground
        ? AppColors.surface
        : Colors.white.withValues(alpha: 0.1);
    final borderColor = lightBackground
        ? AppColors.border
        : Colors.white.withValues(alpha: 0.12);
    final textColor = lightBackground
        ? AppColors.textSecondary
        : const Color(0xFFE5E5E5);
    final dotColor = isOnline
        ? (lightBackground ? AppColors.inkSoft : Colors.white)
        : AppColors.textMuted;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isOnline ? 'En línea' : 'Sin conexión',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
