import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../core/constants/defaults.dart';
import '../core/navigation/register_transaction_route.dart';
import '../core/theme/app_colors.dart';
import '../models/topic.dart';
import '../screens/topic_detail_screen.dart';
import '../widgets/tutorial_tooltip.dart';
import '../app.dart';
import 'main_tab_provider.dart';
import 'settings_provider.dart';
import 'topics_provider.dart';

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
  static final registerType = GlobalKey(debugLabel: 'registerType');
  static final registerAmount = GlobalKey(debugLabel: 'registerAmount');
  static final registerConcept = GlobalKey(debugLabel: 'registerConcept');
  static final registerCurrency = GlobalKey(debugLabel: 'registerCurrency');
  static final registerPayment = GlobalKey(debugLabel: 'registerPayment');
  static final registerTopic = GlobalKey(debugLabel: 'registerTopic');
  static final registerDateTime = GlobalKey(debugLabel: 'registerDateTime');
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

      var skipped = false;
      final tutorial = TutorialCoachMark(
        targets: targets,
        colorShadow: Colors.black,
        opacityShadow: 0.75,
        paddingFocus: 10,
        hideSkip: true,
        onFinish: () {
          _ref.read(settingsProvider.notifier).markScreenTutorialSeen(screenId);
          if (!skipped && tabIndex == 2 && context.mounted) {
            openTopicDetailTutorial(context);
          }
        },
        onSkip: () {
          skipped = true;
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

  Topic _defaultTopic() {
    final topics = _ref.read(topicsProvider);
    for (final t in topics) {
      if (TopicsNotifier.isDefault(t)) return t;
    }
    return const Topic(
      id: Defaults.defaultTopicId,
      name: Defaults.defaultTopicName,
    );
  }

  /// Abre el detalle del tópico por defecto y explica el botón +.
  void openTopicDetailTutorial(BuildContext context) {
    final topic = _defaultTopic();
    final navigator =
        LimpioApp.navigatorKey.currentState ?? Navigator.of(context);

    navigator.push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, __, ___) => TopicDetailScreen(
          topic: topic,
          showFabTutorial: true,
        ),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.06, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  /// Explica el FAB del detalle y luego abre el formulario vacío.
  Future<void> showTopicDetailFabTutorial(BuildContext context) async {
    if (!context.mounted || isTourRunning) return;
    _isTourRunning = true;

    final continued = await _showFormTutorialStep(
      context,
      keyTarget: TutorialKeys.topicDetailFab,
      title: 'Añadir un registro',
      description:
          'Toca el botón de expansión para elegir: nuevo registro completo o un gasto de monto fijo (atajo con un toque).',
      align: ContentAlign.top,
      currentStep: 1,
      totalSteps: 1,
      nextLabel: 'Ver formulario',
    );

    _isTourRunning = false;
    if (!context.mounted) return;

    if (!continued) {
      Navigator.of(context).maybePop();
      return;
    }

    openRegisterFormTutorial(context);
  }

  /// Abre el formulario vacío de registro y explica cada sección.
  void openRegisterFormTutorial(BuildContext context) {
    final topic = _defaultTopic();

    pushRegisterTransactionScreen(
      context,
      RegisterTransactionArgs(
        initialTopicId: topic.id,
        topicName: topic.name,
        topicMode: true,
        showFormTutorial: true,
        onSave: (_) {},
      ),
    );
  }

  /// Recorre las secciones del formulario sin rellenar valores.
  Future<void> showRegisterFormTutorial(BuildContext context) async {
    if (!context.mounted || isTourRunning) return;
    _isTourRunning = true;

    final steps = <({
      GlobalKey key,
      String title,
      String description,
      ContentAlign align,
    })>[
      (
        key: TutorialKeys.registerType,
        title: 'Tipo de movimiento',
        description:
            'Elige si vas a registrar un egreso (gasto) o un ingreso. Esto cambia el título y el medio de pago disponible.',
        align: ContentAlign.bottom,
      ),
      (
        key: TutorialKeys.registerAmount,
        title: 'Monto',
        description:
            'Aquí escribes la cantidad del movimiento. El símbolo cambia según la moneda seleccionada más abajo.',
        align: ContentAlign.bottom,
      ),
      (
        key: TutorialKeys.registerConcept,
        title: 'Concepto',
        description:
            'Describe el movimiento. Puedes usar modo texto o lista (útil para varios ítems de una compra).',
        align: ContentAlign.bottom,
      ),
      (
        key: TutorialKeys.registerCurrency,
        title: 'Moneda',
        description:
            'Indica si el monto está en dólares o bolívares. Con bolívares verás opciones de tasa de cambio.',
        align: ContentAlign.bottom,
      ),
      (
        key: TutorialKeys.registerPayment,
        title: 'Medio de pago',
        description:
            'En un egreso eliges cómo pagaste: pago móvil, efectivo o una de tus tarjetas registradas.',
        align: ContentAlign.top,
      ),
      (
        key: TutorialKeys.registerTopic,
        title: 'Tópico',
        description:
            'Asocia el movimiento a un tópico. Desde el detalle de un tópico ya viene preseleccionado.',
        align: ContentAlign.top,
      ),
      (
        key: TutorialKeys.registerDateTime,
        title: 'Fecha y hora',
        description:
            'Por defecto se usa la hora actual. Desactiva «Usar ahora» si necesitas registrar una fecha u hora distinta.',
        align: ContentAlign.top,
      ),
      (
        key: TutorialKeys.registerSaveButton,
        title: 'Guardar',
        description:
            'Cuando completes los datos, toca este botón para registrar el ingreso o egreso. Por ahora déjalo vacío: solo estás aprendiendo el formulario.',
        align: ContentAlign.top,
      ),
    ];

    var aborted = false;
    for (var i = 0; i < steps.length; i++) {
      if (!context.mounted || aborted) break;
      final step = steps[i];
      final targetContext = step.key.currentContext;
      if (targetContext != null) {
        await Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: 0.25,
        );
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
      if (!context.mounted) break;

      final isLast = i == steps.length - 1;
      final continued = await _showFormTutorialStep(
        context,
        keyTarget: step.key,
        title: step.title,
        description: step.description,
        align: step.align,
        currentStep: i + 1,
        totalSteps: steps.length,
        nextLabel: isLast ? 'Listo' : 'Siguiente',
      );
      if (!continued) aborted = true;
    }

    _isTourRunning = false;
    if (!context.mounted) return;

    if (aborted) {
      Navigator.of(context).maybePop();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Ya conoces el formulario. Complétalo cuando quieras registrar un movimiento.',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<bool> _showFormTutorialStep(
    BuildContext context, {
    required GlobalKey keyTarget,
    required String title,
    required String description,
    required ContentAlign align,
    required int currentStep,
    required int totalSteps,
    required String nextLabel,
  }) {
    final completer = Completer<bool>();

    final target = TargetFocus(
      identify: 'formStep$currentStep',
      keyTarget: keyTarget,
      contents: [
        TargetContent(
          align: align,
          builder: (context, controller) {
            return TutorialTooltip(
              title: title,
              description: description,
              currentStep: currentStep,
              totalSteps: totalSteps,
              nextLabel: nextLabel,
              skipLabel: 'Salir',
              onNext: () => controller.next(),
              onSkip: () => controller.skip(),
            );
          },
        ),
      ],
    );

    TutorialCoachMark(
      targets: [target],
      colorShadow: Colors.black,
      opacityShadow: 0.75,
      paddingFocus: 10,
      hideSkip: true,
      onFinish: () {
        if (!completer.isCompleted) completer.complete(true);
      },
      onSkip: () {
        if (!completer.isCompleted) completer.complete(false);
        return true;
      },
    ).show(context: context);

    return completer.future;
  }

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
                    description: 'Toca esta opción para actualizar al instante la tasa oficial del BCV.',
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
                    title: 'Registrar ingreso o egreso',
                    description: isGlobalTour
                        ? 'Desde el detalle de un tópico, toca el botón + y elige «Manual» para abrir el formulario de registro.'
                        : 'A continuación entraremos al detalle del tópico para ver el botón + y luego el formulario de registro.',
                    currentStep: 3,
                    totalSteps: 3,
                    nextLabel: isGlobalTour ? 'Siguiente pestaña' : 'Ver detalle',
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
