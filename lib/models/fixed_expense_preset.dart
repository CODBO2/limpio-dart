import 'payment_method.dart';

/// Plantilla de egreso de monto fijo asociada a un tópico.
class FixedExpensePreset {
  const FixedExpensePreset({
    required this.id,
    required this.topicId,
    required this.title,
    required this.amount,
    required this.currency,
    this.paymentMethod = PaymentMethod.cashUsd,
  });

  final String id;
  final String topicId;
  final String title;

  /// Monto como texto numérico (ej. `1000` o `1000.00`).
  final String amount;

  /// `USD` o `VES`.
  final String currency;
  final PaymentMethod paymentMethod;

  bool get isVes => currency == 'VES';

  FixedExpensePreset copyWith({
    String? id,
    String? topicId,
    String? title,
    String? amount,
    String? currency,
    PaymentMethod? paymentMethod,
  }) {
    return FixedExpensePreset(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'topicId': topicId,
        'title': title,
        'amount': amount,
        'currency': currency,
        'paymentMethod': paymentMethod.value,
      };

  factory FixedExpensePreset.fromJson(Map<String, dynamic> json) =>
      FixedExpensePreset(
        id: json['id'] as String,
        topicId: json['topicId'] as String,
        title: json['title'] as String,
        amount: json['amount'] as String,
        currency: json['currency'] as String? ?? 'USD',
        paymentMethod: PaymentMethod.fromString(
          json['paymentMethod'] as String?,
        ),
      );
}
