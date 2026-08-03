class Fuente {
  const Fuente({
    required this.id,
    required this.name,
    required this.amount,
    required this.currency,
    required this.day,
  });

  final String id;
  final String name;
  final String amount;
  final String currency;
  final int day;

  Fuente copyWith({
    String? id,
    String? name,
    String? amount,
    String? currency,
    int? day,
  }) {
    return Fuente(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      day: day ?? this.day,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'currency': currency,
        'day': day,
      };

  factory Fuente.fromJson(Map<String, dynamic> json) => Fuente(
        id: json['id'] as String,
        name: json['name'] as String,
        amount: json['amount'] as String,
        currency: json['currency'] as String? ?? 'USD',
        day: (json['day'] as num).toInt(),
      );
}
