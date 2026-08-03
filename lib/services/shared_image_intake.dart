import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../app.dart';
import '../core/navigation/app_tab.dart';
import '../providers/main_tab_provider.dart';
import '../widgets/modals/register_transaction_flow.dart';
import 'shared_scan_coordinator.dart';

/// Escucha imágenes compartidas en caliente (app ya abierta).
///
/// El cold start lo maneja [BootstrapApp] con OCR en paralelo.
class SharedImageIntake {
  SharedImageIntake._();

  static StreamSubscription<List<SharedMediaFile>>? _subscription;
  static bool _handling = false;

  static void start() {
    _subscription?.cancel();
    _subscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      _handleWarm,
      onError: (Object err) {
        debugPrint('SharedImageIntake stream error: $err');
      },
    );

    if (!SharedScanCoordinator.initialHandled) {
      ReceiveSharingIntent.instance.getInitialMedia().then((files) {
        if (SharedScanCoordinator.initialHandled) return;
        _handleWarm(files);
      });
    }
  }

  static void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  static Future<void> _handleWarm(List<SharedMediaFile> files) async {
    if (files.isEmpty || _handling) return;
    // Bootstrap ya presentó (o está presentando) el flujo de cold start.
    if (SharedScanCoordinator.uiSessionActive) return;

    final imagePath = SharedScanCoordinator.firstImagePath(files);
    if (imagePath == null) return;

    _handling = true;
    SharedScanCoordinator.initialHandled = true;
    SharedScanCoordinator.uiSessionActive = true;
    try {
      await ReceiveSharingIntent.instance.reset();

      final draftFuture = SharedScanCoordinator.startFastScan(imagePath);

      for (var i = 0; i < 40; i++) {
        if (LimpioApp.navigatorKey.currentContext != null) break;
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }

      final context = LimpioApp.navigatorKey.currentContext;
      if (context == null || !context.mounted) return;

      await showSharedImageScanFlow(
        context,
        imagePath: imagePath,
        precomputedDraft: SharedScanCoordinator.takeInFlight() ?? draftFuture,
        onSave: (_) {
          appContainer.read(mainTabProvider.notifier).state =
              AppTab.actividad.tabIndex;
        },
      );
    } finally {
      _handling = false;
      SharedScanCoordinator.uiSessionActive = false;
    }
  }
}
