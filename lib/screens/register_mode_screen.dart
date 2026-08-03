import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app.dart';
import '../core/theme/app_colors.dart';
import '../providers/tutorial_provider.dart';
import '../widgets/modals/register_mode_modal.dart';

class RegisterModeScreen extends StatelessWidget {
  const RegisterModeScreen({super.key});

  static const routeName = '/register/mode';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Nuevo movimiento'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          const Text(
            'Elige cómo quieres registrar el ingreso o egreso.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          _ModeCard(
            key: TutorialKeys.registerModeManual,
            icon: Icons.edit_note_outlined,
            title: 'Manual',
            caption: 'Completa el formulario tú mismo',
            onTap: () => Navigator.of(context).pop(RegisterMode.manual),
          ),
          const SizedBox(height: 12),
          _ModeCard(
            icon: Icons.document_scanner_outlined,
            title: 'Escaneo',
            caption: 'Toma una foto de la factura',
            onTap: () => Navigator.of(context).pop(RegisterMode.scan),
          ),
          const SizedBox(height: 12),
          _ModeCard(
            icon: Icons.photo_library_outlined,
            title: 'Galería',
            caption: 'Importa una captura o imagen guardada',
            onTap: () => Navigator.of(context).pop(RegisterMode.gallery),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    super.key,
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
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
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

Route<RegisterMode?> buildRegisterModeRoute() {
  return PageRouteBuilder<RegisterMode?>(
    settings: const RouteSettings(name: RegisterModeScreen.routeName),
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (_, __, ___) => const RegisterModeScreen(),
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}

Future<RegisterMode?> pushRegisterModeScreen(BuildContext context) {
  final navigator = LimpioApp.navigatorKey.currentState ?? Navigator.of(context, rootNavigator: true);
  return navigator.push<RegisterMode?>(buildRegisterModeRoute());
}
