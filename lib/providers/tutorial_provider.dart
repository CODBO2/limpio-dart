import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../core/navigation/app_tab.dart';
import '../core/theme/app_colors.dart';
import '../widgets/tutorial_tooltip.dart';
import 'main_tab_provider.dart';
import 'settings_provider.dart';

class TutorialKeys {
  static final billeteraTab = GlobalKey(debugLabel: 'billeteraTab');
  static final actividadTab = GlobalKey(debugLabel: 'actividadTab');
  static final topicosTab = GlobalKey(debugLabel: 'topicosTab');
  static final tarjetasTab = GlobalKey(debugLabel: 'tarjetasTab');
  static final papeleraTab = GlobalKey(debugLabel: 'papeleraTab');

  static final summaryCards = GlobalKey(debugLabel: 'summaryCards');
  static final refreshRate = GlobalKey(debugLabel: 'refreshRate');
  static final weeklyChart = GlobalKey(debugLabel: 'weeklyChart');

  static final activityFilter = GlobalKey(debugLabel: 'activityFilter');

  static final topicDefaultCard = GlobalKey(debugLabel: 'topicDefaultCard');
  static final topicAdd = GlobalKey(debugLabel: 'topicAdd');
  static final firstCustomTopicCard = GlobalKey(debugLabel: 'firstCustomTopicCard');

  static final topicDetailFab = GlobalKey(debugLabel: 'topicDetailFab');
  static final registerModeManual = GlobalKey(debugLabel: 'registerModeManual');
  static final registerSaveButton = GlobalKey(debugLabel: 'registerSaveButton');

  static final cardAdd = GlobalKey(debugLabel: 'cardAdd');
}

class TutorialController {
  TutorialController(this._ref);

  final Ref _ref;
  bool _isTourRunning = false;

  bool get isTourRunning => _isTourRunning;

  // Checks if the global tour should start on app launch
  void checkAndStartGlobalTour(BuildContext context) {
    final settings = _ref.read(settingsProvider).settings;
    if (!settings.hasCompletedAppTour) {
      // Start after a small delay to ensure UI is fully rendered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (context.mounted) {
            startGlobalTour(context);
          }
        });
      });
    }
  }

  void startGlobalTour(BuildContext context) {
    if (isTourRunning) return;
    _isTourRunning = true;
    _runTourStage(context, 0);
  }

  Future<void> _runTourStage(BuildContext context, int stageIndex) async {
    if (!context.mounted) {
      _isTourRunning = false;
      return;
    }

    // Switch to the appropriate tab for the stage
    _ref.read(mainTabProvider.notifier).state = stageIndex;
    // Wait for tab transition
    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (!context.mounted) {
      _isTourRunning = false;
      return;
    }

    final targets = _getTargetsForStage(stageIndex, isGlobalTour: true);
    if (targets.isEmpty) {
      _finishGlobalTour(context);
      return;
    }

    final isLastStage = stageIndex == 3; // Billetera (0), Actividad (1), Tópicos (2), Tarjetas (3)

    final tutorial = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.75,
      paddingFocus: 10,
      hideSkip: true, // We have custom Skip buttons in our tooltips
      onFinish: () {
        if (isLastStage) {
          _finishGlobalTour(context);
        } else {
          _runTourStage(context, stageIndex + 1);
        }
      },
      onSkip: () {
        _cancelGlobalTour(context);
        return true;
      },
    );

    tutorial.show(context: context);
  }

  void _finishGlobalTour(BuildContext context) {
    _isTourRunning = false;
    _ref.read(settingsProvider.notifier).setHasCompletedAppTour(true);
    _ref.read(mainTabProvider.notifier).state = 0; // Back to Billetera

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          '¡Tutorial completado! Ya estás listo para usar Limpio.',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _cancelGlobalTour(BuildContext context) {
    _isTourRunning = false;
    _ref.read(settingsProvider.notifier).setHasCompletedAppTour(true);
    _ref.read(mainTabProvider.notifier).state = 0; // Back to Billetera

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Tutorial omitido. Puedes iniciarlo de nuevo desde la configuración.',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Shows a screen-specific tutorial manually
  void showScreenTutorial(BuildContext context, int tabIndex, {bool force = false}) {
    final settings = _ref.read(settingsProvider).settings;
    final screenId = _getScreenId(tabIndex);
    
    // Only auto-start for Billetera (tabIndex 0). Other screens must be activated manually.
    if (tabIndex != 0 && !force) {
      return;
    }

    if (!force && settings.seenScreenTutorials.contains(screenId)) {
      return;
    }

    // Wait 350ms to ensure transition animations are finished and widgets are stable
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!context.mounted) return;

      final targets = _getTargetsForStage(tabIndex, isGlobalTour: false);
      if (targets.isEmpty) return;

      final tutorial = TutorialCoachMark(
        targets: targets,
        colorShadow: Colors.black,
        opacityShadow: 0.75,
        paddingFocus: 10,
        hideSkip: true,
        onFinish: () {
          _ref.read(settingsProvider.notifier).markScreenTutorialSeen(screenId);
        },
        onSkip: () {
          _ref.read(settingsProvider.notifier).markScreenTutorialSeen(screenId);
          return true;
        },
      );

      tutorial.show(context: context);
    });
  }

  // Starts the step-by-step topic creation & transaction registration tutorial
  void startInteractiveTopicTour(BuildContext context) {
    showScreenTutorial(context, 2, force: true);
  }

  // Shows a dedicated single-target explanation coach mark

  // Shows a dedicated single-target explanation coach mark
  void showSingleTargetTutorial(
    BuildContext context, {
    required GlobalKey keyTarget,
    required String title,
    required String description,
    ContentAlign align = ContentAlign.bottom,
  }) {
    final target = TargetFocus(
      identify: keyTarget.toString(),
      keyTarget: keyTarget,
      contents: [
        TargetContent(
          align: align,
          builder: (context, controller) {
            return TutorialTooltip(
              title: title,
              description: description,
              currentStep: 1,
              totalSteps: 1,
              nextLabel: 'Entendido',
              skipLabel: 'Cerrar',
              onNext: () => controller.skip(),
              onSkip: () => controller.skip(),
            );
          },
        ),
      ],
    );

    final tutorial = TutorialCoachMark(
      targets: [target],
      colorShadow: Colors.black,
      opacityShadow: 0.75,
      paddingFocus: 10,
      hideSkip: true,
    );

    tutorial.show(context: context);
  }

  String _getScreenId(int tabIndex) {
    return switch (tabIndex) {
      0 => 'billetera',
      1 => 'actividad',
      2 => 'topicos',
      3 => 'tarjetas',
      4 => 'papelera',
      _ => 'unknown',
    };
  }

  List<TargetFocus> _getTargetsForStage(int stageIndex, {required bool isGlobalTour}) {
    final List<TargetFocus> targets = [];

    switch (stageIndex) {
      case 0: // Billetera (BalanceScreen)
        targets.add(
          TargetFocus(
            identify: 'summaryCards',
            keyTarget: TutorialKeys.summaryCards,
            alignSkip: Alignment.bottomRight,
            contents: [
              TargetContent(
                align: ContentAlign.bottom,
                builder: (context, controller) {
                  return TutorialTooltip(
                    title: 'Balance General',
                    description: 'Aquí puedes ver el total de tus ingresos y egresos consolidados en dólares. Toca cualquier tarjeta para ver el detalle.',
                    currentStep: 1,
                    totalSteps: 3,
                    nextLabel: 'Siguiente',
                    skipLabel: isGlobalTour ? 'Omitir' : 'Salir',
                    onNext: () => controller.next(),
                    onSkip: () => controller.skip(),
                  );
                },
              ),
            ],
          ),
        );
        targets.add(
          TargetFocus(
            identify: 'refreshRate',
            keyTarget: TutorialKeys.refreshRate,
            alignSkip: Alignment.bottomRight,
            contents: [
              TargetContent(
                align: ContentAlign.bottom,
                builder: (context, controller) {
                  return TutorialTooltip(
                    title: 'Tasa de Cambio',
                    description: 'Toca esta opción para actualizar al instante las tasas oficiales del BCV y paralelo en Venezuela.',
                    currentStep: 2,
                    totalSteps: 3,
                    nextLabel: 'Siguiente',
                    skipLabel: isGlobalTour ? 'Omitir' : 'Salir',
                    onNext: () => controller.next(),
                    onSkip: () => controller.skip(),
                  );
                },
              ),
            ],
          ),
        );
        targets.add(
          TargetFocus(
            identify: 'weeklyChart',
            keyTarget: TutorialKeys.weeklyChart,
            alignSkip: Alignment.bottomRight,
            contents: [
              TargetContent(
                align: ContentAlign.top,
                builder: (context, controller) {
                  return TutorialTooltip(
                    title: 'Gastos Semanales',
                    description: 'Visualiza de forma gráfica la distribución de tus egresos durante la semana para un mejor control de tus finanzas.',
                    currentStep: 3,
                    totalSteps: 3,
                    nextLabel: isGlobalTour ? 'Siguiente pestaña' : 'Finalizar',
                    skipLabel: isGlobalTour ? 'Omitir' : 'Salir',
                    onNext: () => controller.next(),
                    onSkip: () => controller.skip(),
                  );
                },
              ),
            ],
          ),
        );
        break;

      case 1: // Actividad (ActivityScreen)
        targets.add(
          TargetFocus(
            identify: 'activityFilter',
            keyTarget: TutorialKeys.activityFilter,
            alignSkip: Alignment.bottomRight,
            contents: [
              TargetContent(
                align: ContentAlign.bottom,
                builder: (context, controller) {
                  return TutorialTooltip(
                    title: 'Filtros y Búsqueda',
                    description: 'Busca transacciones por descripción o fíltralas por tipo, moneda, tópico o rango de fechas para encontrar lo que necesitas.',
                    currentStep: 1,
                    totalSteps: 2,
                    nextLabel: 'Siguiente',
                    skipLabel: isGlobalTour ? 'Omitir' : 'Salir',
                    onNext: () => controller.next(),
                    onSkip: () => controller.skip(),
                  );
                },
              ),
            ],
          ),
        );
        targets.add(
          TargetFocus(
            identify: 'actividadTab',
            keyTarget: TutorialKeys.actividadTab,
            alignSkip: Alignment.bottomRight,
            contents: [
              TargetContent(
                align: ContentAlign.top,
                builder: (context, controller) {
                  return TutorialTooltip(
                    title: 'Historial de Movimientos',
                    description: 'Aquí se listarán todos tus ingresos y egresos. Puedes deslizar un elemento a la izquierda para borrarlo, o mantenerlo presionado para seleccionar varios.',
                    currentStep: 2,
                    totalSteps: 2,
                    nextLabel: isGlobalTour ? 'Siguiente pestaña' : 'Finalizar',
                    skipLabel: isGlobalTour ? 'Omitir' : 'Salir',
                    onNext: () => controller.next(),
                    onSkip: () => controller.skip(),
                  );
                },
              ),
            ],
          ),
        );
        break;

      case 2: // Tópicos (TopicosScreen)
        targets.add(
          TargetFocus(
            identify: 'topicDefaultCard',
            keyTarget: TutorialKeys.topicDefaultCard,
            alignSkip: Alignment.bottomRight,
            contents: [
              TargetContent(
                align: ContentAlign.bottom,
                builder: (context, controller) {
                  return TutorialTooltip(
                    title: 'Tópico por Defecto',
                    description: 'Este tópico es fijo y agrupa todas tus actividades iniciales. No se puede eliminar.',
                    currentStep: 1,
                    totalSteps: 3,
                    nextLabel: 'Siguiente',
                    skipLabel: isGlobalTour ? 'Omitir' : 'Salir',
                    onNext: () => controller.next(),
                    onSkip: () => controller.skip(),
                  );
                },
              ),
            ],
          ),
        );
        targets.add(
          TargetFocus(
            identify: 'topicAdd',
            keyTarget: TutorialKeys.topicAdd,
            alignSkip: Alignment.bottomRight,
            contents: [
              TargetContent(
                align: ContentAlign.bottom,
                builder: (context, controller) {
                  return TutorialTooltip(
                    title: 'Crear Tópicos',
                    description: 'Escribe un nombre aquí (ej. Alimentos, Servicios, Entretenimiento) y presiona el botón de check para crear un nuevo tópico personalizado.',
                    currentStep: 2,
                    totalSteps: 3,
                    nextLabel: 'Siguiente',
                    skipLabel: isGlobalTour ? 'Omitir' : 'Salir',
                    onNext: () => controller.next(),
                    onSkip: () => controller.skip(),
                  );
                },
              ),
            ],
          ),
        );
        targets.add(
          TargetFocus(
            identify: 'topicManualRegister',
            keyTarget: TutorialKeys.topicDefaultCard,
            alignSkip: Alignment.bottomRight,
            contents: [
              TargetContent(
                align: ContentAlign.bottom,
                builder: (context, controller) {
                  return TutorialTooltip(
                    title: 'Registrar Movimiento Manual',
                    description: 'Para registrar un ingreso o egreso asociado a un tópico, toca el tópico para abrir su detalle, presiona el botón + y selecciona la opción "Manual" para ingresar los datos de tu transacción.',
                    currentStep: 3,
                    totalSteps: 3,
                    nextLabel: isGlobalTour ? 'Siguiente pestaña' : 'Finalizar',
                    skipLabel: isGlobalTour ? 'Omitir' : 'Salir',
                    onNext: () => controller.next(),
                    onSkip: () => controller.skip(),
                  );
                },
              ),
            ],
          ),
        );
        break;

      case 3: // Tarjetas (TarjetasScreen)
        targets.add(
          TargetFocus(
            identify: 'cardAdd',
            keyTarget: TutorialKeys.cardAdd,
            alignSkip: Alignment.bottomRight,
            contents: [
              TargetContent(
                align: ContentAlign.top,
                builder: (context, controller) {
                  return TutorialTooltip(
                    title: 'Registrar Tarjetas',
                    description: 'Registra tus tarjetas de débito, crédito o cuentas bancarias (ej. BNC) para asociar tus transacciones a un medio de pago específico.',
                    currentStep: 1,
                    totalSteps: 1,
                    nextLabel: 'Finalizar',
                    skipLabel: isGlobalTour ? 'Omitir' : 'Salir',
                    onNext: () => controller.next(),
                    onSkip: () => controller.skip(),
                  );
                },
              ),
            ],
          ),
        );
        break;
    }

    return targets;
  }
}

final tutorialControllerProvider = Provider<TutorialController>((ref) {
  return TutorialController(ref);
});
