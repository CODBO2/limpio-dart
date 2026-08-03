import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Entrada de monto tipo Al Cambio: parte de `0,00` y cada dígito
/// se inserta por la derecha; el borrado quita el último dígito a la derecha.
class MoneyAmountInput {
  MoneyAmountInput._();

  static const maxCents = 999999999999; // 9.999.999.999,99

  static final _thousands = NumberFormat('#,##0', 'es_VE');

  /// Formatea centavos enteros como `1.234,56`.
  static String formatCents(int cents) {
    final safe = cents.clamp(0, maxCents);
    final whole = safe ~/ 100;
    final frac = (safe % 100).toString().padLeft(2, '0');
    return '${_thousands.format(whole)},$frac';
  }

  /// Convierte un double a texto de entrada (`0,00`).
  static String formatDouble(double value) {
    if (value.isNaN || value.isInfinite || value <= 0) {
      return formatCents(0);
    }
    return formatCents((value * 100).round());
  }

  /// Extrae centavos desde el texto mostrado (solo dígitos).
  static int centsFromDisplay(String text) {
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 0;
    final parsed = int.tryParse(digits) ?? 0;
    return parsed.clamp(0, maxCents);
  }

  /// Parsea el texto del campo a double (acepta `1.234,56` o `1234.56`).
  static double parse(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    if (trimmed.contains(',') && trimmed.contains('.')) {
      return double.tryParse(trimmed.replaceAll('.', '').replaceAll(',', '.')) ??
          0;
    }
    if (trimmed.contains(',')) {
      return double.tryParse(trimmed.replaceAll(',', '.')) ?? 0;
    }
    return double.tryParse(trimmed) ?? 0;
  }
}

/// Formateador para [TextField] con teclado numérico.
class MoneyAmountInputFormatter extends TextInputFormatter {
  const MoneyAmountInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cents = MoneyAmountInput.centsFromDisplay(newValue.text);
    final formatted = MoneyAmountInput.formatCents(cents);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
