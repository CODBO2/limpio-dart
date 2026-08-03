import 'package:flutter/material.dart';

import '../../core/navigation/register_transaction_route.dart';
import '../../models/activity.dart';
import '../../models/invoice_scan_draft.dart';
import '../../screens/register_transaction_screen.dart';

/// Opens the full-screen register form (legacy name kept for callers).
Future<void> showRegisterTransactionModal(
  BuildContext context, {
  Activity? editingItem,
  String? initialTopicId,
  String? topicName,
  bool topicMode = false,
  InvoiceScanDraft? initialDraft,
  required void Function(Activity item) onSave,
}) {
  return showRegisterTransactionScreen(
    context,
    editingItem: editingItem,
    initialTopicId: initialTopicId,
    topicName: topicName,
    topicMode: topicMode,
    initialDraft: initialDraft,
    onSave: onSave,
  );
}
