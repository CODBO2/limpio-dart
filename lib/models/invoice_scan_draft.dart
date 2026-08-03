class InvoiceScanDraft {
  const InvoiceScanDraft({
    required this.rawText,
    this.monto,
    this.currency,
    this.date,
    this.amountConfidence = 0,
    this.currencyConfidence = 0,
    this.dateConfidence = 0,
  });

  final String rawText;
  final double? monto;
  /// `dollars` or `bolivares` (matches register form).
  final String? currency;
  final DateTime? date;
  final double amountConfidence;
  final double currencyConfidence;
  final double dateConfidence;

  bool get hasAmount => monto != null && monto! > 0;

  String get currencyLabel => currency == 'dollars' ? 'USD (\$)' : 'Bs';

  String get amountLabel {
    if (monto == null) return 'No detectado';
    if (currency == 'dollars') {
      return '\$${monto!.toStringAsFixed(2)}';
    }
    return '${_formatBolivares(monto!)} Bs';
  }

  static String _formatBolivares(double value) {
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts[0];
    final decimals = parts[1];
    final reversed = whole.split('').reversed.toList();
    final withDots = <String>[];
    for (var i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) withDots.add('.');
      withDots.add(reversed[i]);
    }
    return '${withDots.reversed.join()},$decimals';
  }

  String? get dateLabel {
    if (date == null) return null;
    final d = date!;
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }
}
