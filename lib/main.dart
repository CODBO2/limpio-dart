import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'app.dart';
import 'core/navigation/app_tab.dart';
import 'core/navigation/register_transaction_route.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'models/invoice_scan_draft.dart';
import 'models/payment_method.dart';
import 'providers/activities_provider.dart';
import 'providers/app_providers.dart';
import 'providers/cards_provider.dart';
import 'providers/main_tab_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/topics_provider.dart';
import 'providers/trash_provider.dart';
import 'screens/main_shell.dart';
import 'services/shared_scan_coordinator.dart';
import 'services/storage_service.dart';
import 'widgets/modals/invoice_scan_review_modal.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();
  await storageService.init();

  appContainer = ProviderContainer(
    overrides: [
      storageServiceProvider.overrideWithValue(storageService),
    ],
  );

  runApp(
    UncontrolledProviderScope(
      container: appContainer,
      child: const BootstrapApp(),
    ),
  );
}

class BootstrapApp extends ConsumerStatefulWidget {
  const BootstrapApp({super.key});

  @override
  ConsumerState<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends ConsumerState<BootstrapApp> {
  bool _storageReady = false;
  bool _sharePending = false;
  Future<InvoiceScanDraft>? _shareDraftFuture;
  bool _shareUiPresented = false;

  @override
  void initState() {
    super.initState();
    // Evita setState durante el primer mount (assertion !_dirty).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_boot());
    });
  }

  Future<void> _boot() async {
    final sharePeek = ReceiveSharingIntent.instance.getInitialMedia();
    final storageFuture = _loadStorageOnly();

    final files = await sharePeek;
    if (!mounted) return;

    final imagePath = SharedScanCoordinator.firstImagePath(files);
    if (imagePath != null) {
      SharedScanCoordinator.initialHandled = true;
      unawaited(ReceiveSharingIntent.instance.reset());
      final draftFuture = SharedScanCoordinator.startFastScan(imagePath);
      if (!mounted) return;
      setState(() {
        _sharePending = true;
        _shareDraftFuture = draftFuture;
      });
    }

    await storageFuture;
    if (!mounted) return;
    setState(() => _storageReady = true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(settingsProvider.notifier).refreshRates());
      if (_shareDraftFuture != null) {
        unawaited(_presentShareWhenReady());
      }
    });
  }

  Future<void> _loadStorageOnly() async {
    await Future.wait([
      ref.read(activitiesProvider.notifier).load(),
      ref.read(topicsProvider.notifier).load(),
      ref.read(cardsProvider.notifier).load(),
      ref.read(trashProvider.notifier).load(),
      ref.read(settingsProvider.notifier).load(),
    ]);
    final topicIds =
        ref.read(topicsProvider).map((t) => t.id).toSet();
    await ref
        .read(activitiesProvider.notifier)
        .migrateUnassignedToDefault(topicIds);
  }

  Future<void> _presentShareWhenReady() async {
    if (_shareUiPresented || !mounted) return;
    if (SharedScanCoordinator.uiSessionActive) return;
    final draftFuture =
        SharedScanCoordinator.takeInFlight() ?? _shareDraftFuture;
    if (draftFuture == null) return;
    _shareUiPresented = true;
    SharedScanCoordinator.uiSessionActive = true;

    try {
      for (var i = 0; i < 40; i++) {
        if (LimpioApp.navigatorKey.currentContext != null) break;
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }

      final navContext = LimpioApp.navigatorKey.currentContext;
      if (navContext == null || !navContext.mounted) {
        if (mounted) setState(() => _sharePending = false);
        return;
      }

      var loadingShown = false;
      final loadingTimer = Timer(const Duration(milliseconds: 40), () {
        final ctx = LimpioApp.navigatorKey.currentContext;
        if (ctx == null || !ctx.mounted) return;
        loadingShown = true;
        showDialog<void>(
          context: ctx,
          barrierDismissible: false,
          builder: (_) => const PopScope(
            canPop: false,
            child: Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Analizando captura…'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      });

      InvoiceScanDraft draft;
      try {
        draft = await draftFuture;
      } catch (_) {
        draft = const InvoiceScanDraft(rawText: '');
      }

      loadingTimer.cancel();
      final ctx = LimpioApp.navigatorKey.currentContext;
      if (loadingShown && ctx != null && ctx.mounted) {
        Navigator.of(ctx, rootNavigator: true).pop();
      }
      if (mounted) setState(() => _sharePending = false);
      if (ctx == null || !ctx.mounted) return;

      final adjusted = SharedScanCoordinator.preferBolivaresIfUncertain(draft);
      final confirmed = await showInvoiceScanReviewModal(ctx, adjusted);
      if (!ctx.mounted || confirmed == null) return;

      await pushRegisterTransactionScreen(
        ctx,
        RegisterTransactionArgs(
          initialDraft: confirmed,
          initialPaymentMethod: PaymentMethod.pagoMovil,
          onSave: (_) {
            appContainer.read(mainTabProvider.notifier).state =
                AppTab.actividad.tabIndex;
          },
        ),
      );
    } finally {
      SharedScanCoordinator.uiSessionActive = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Un solo MaterialApp: evita destruir el árbol al pasar de splash → app.
    return MaterialApp(
      navigatorKey: LimpioApp.navigatorKey,
      title: 'Limpio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _storageReady
          ? const MainShell()
          : _BootSplash(sharePending: _sharePending),
    );
  }
}

class _BootSplash extends StatelessWidget {
  const _BootSplash({required this.sharePending});

  final bool sharePending;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.green),
            const SizedBox(height: 16),
            Text(
              sharePending ? 'Analizando captura…' : 'Cargando…',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
