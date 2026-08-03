import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum RegisterMode { manual, scan, gallery }

Future<RegisterMode?> showRegisterModeModal(BuildContext context) {
  return showDialog<RegisterMode>(
    context: context,
    barrierDismissible: true,
    builder: (context) => const _RegisterModeDialog(),
  );
}

class _RegisterModeDialog extends StatelessWidget {
  const _RegisterModeDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Nuevo movimiento',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(backgroundColor: AppColors.softFill),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Elige cómo quieres registrar el ingreso o egreso.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            _ModeCard(
              icon: Icons.edit_note_outlined,
              title: 'Manual',
              caption: 'Completa el formulario tú mismo',
              onTap: () => Navigator.pop(context, RegisterMode.manual),
            ),
            const SizedBox(height: 10),
            _ModeCard(
              icon: Icons.document_scanner_outlined,
              title: 'Escaneo',
              caption: 'Toma una foto de la factura',
              onTap: () => Navigator.pop(context, RegisterMode.scan),
            ),
            const SizedBox(height: 10),
            _ModeCard(
              icon: Icons.photo_library_outlined,
              title: 'Galería',
              caption: 'Importa una captura o imagen guardada',
              onTap: () => Navigator.pop(context, RegisterMode.gallery),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.caption,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.softFill,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      caption,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
