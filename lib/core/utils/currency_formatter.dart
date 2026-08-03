import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String formatUsd(double value) {
    if (value.isNaN) return '\$0.00';
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return formatter.format(value);
  }

  static String formatBs(double value) {
    if (value.isNaN) return '0,00 Bs';
    final formatter = NumberFormat('#,##0.00', 'es_VE');
    return '${formatter.format(value)} Bs';
  }

  static String normalizeAmountDisplay(String amountStr) {
    final trimmed = amountStr.trim();
    if (trimmed.isEmpty) return amountStr;

    final isBs = RegExp(r'\s*(Bs|VES)\s*$', caseSensitive: false).hasMatch(trimmed);
    var numStr = trimmed
        .replaceAll(',', '')
        .replaceAll(RegExp(r'\s*(Bs|VES)\s*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*\$\s*$'), '')
        .trim();
    final num = double.tryParse(numStr) ?? 0;
    return isBs ? formatBs(num) : formatUsd(num);
  }

  static String formatActivityDate(DateTime date) {
    return DateFormat("dd MMM · h:mm a", 'es').format(date);
  }

  static String formatDateTimeFull(DateTime date) {
    return DateFormat("EEEE d MMM yyyy · h:mm a", 'es').format(date);
  }
}
