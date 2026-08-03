import 'dart:async';

import 'package:flutter/material.dart';

import '../../app.dart';
import '../../models/activity.dart';
import '../../models/invoice_scan_draft.dart';
import '../../models/payment_method.dart';
import '../../screens/register_transaction_screen.dart';

class RegisterTransactionArgs {
  const RegisterTransactionArgs({
    this.editingItem,
    this.initialTopicId,
    this.topicName,
    this.topicMode = false,
    this.initialDraft,
    this.initialPaymentMethod,
    this.initialCardId,
    required this.onSave,
  });

  final Activity? editingItem;
  final String? initialTopicId;
  final String? topicName;
  final bool topicMode;
  final InvoiceScanDraft? initialDraft;
  final PaymentMethod? initialPaymentMethod;
  final String? initialCardId;
  final FutureOr<void> Function(Activity item) onSave;
}

Route<void> buildRegisterTransactionRoute(RegisterTransactionArgs args) {
  return PageRouteBuilder<void>(
    settings: const RouteSettings(name: RegisterTransactionScreen.routeName),
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (_, __, ___) => RegisterTransactionScreen(
      editingItem: args.editingItem,
      initialTopicId: args.initialTopicId,
      topicName: args.topicName,
      topicMode: args.topicMode,
      initialDraft: args.initialDraft,
      initialPaymentMethod: args.initialPaymentMethod,
      initialCardId: args.initialCardId,
      onSave: args.onSave,
    ),
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

Future<void> pushRegisterTransactionScreen(
  BuildContext context,
  RegisterTransactionArgs args,
) {
  final navigator = LimpioApp.navigatorKey.currentState ?? Navigator.of(context, rootNavigator: true);
  return navigator.push<void>(buildRegisterTransactionRoute(args));
}
