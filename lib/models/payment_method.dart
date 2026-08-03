enum PaymentMethod {
  pagoMovil,
  card,
  cashUsd,
  cashVes;

  String get value => switch (this) {
        PaymentMethod.pagoMovil => 'pago_movil',
        PaymentMethod.card => 'card',
        PaymentMethod.cashUsd => 'cash_usd',
        PaymentMethod.cashVes => 'cash_ves',
      };

  String get label => switch (this) {
        PaymentMethod.pagoMovil => 'Pago móvil',
        PaymentMethod.card => 'Tarjeta',
        PaymentMethod.cashUsd => 'Efectivo en \$',
        PaymentMethod.cashVes => 'Efectivo en Bs',
      };

  static PaymentMethod fromString(String? value) {
    switch (value) {
      case 'card':
        return PaymentMethod.card;
      case 'cash_usd':
        return PaymentMethod.cashUsd;
      case 'cash_ves':
        return PaymentMethod.cashVes;
      case 'pago_movil':
      default:
        return PaymentMethod.pagoMovil;
    }
  }

  static PaymentMethod resolve({
    String? paymentMethod,
    String? cardId,
  }) {
    if (paymentMethod != null && paymentMethod.isNotEmpty) {
      return fromString(paymentMethod);
    }
    if (cardId != null && cardId.isNotEmpty) return PaymentMethod.card;
    return PaymentMethod.pagoMovil;
  }
}
