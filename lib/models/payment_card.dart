enum CardKind {
  debit,
  credit;

  String get label => switch (this) {
        CardKind.debit => 'Débito',
        CardKind.credit => 'Crédito',
      };

  static CardKind fromString(String? value) {
    switch (value) {
      case 'credit':
        return CardKind.credit;
      default:
        return CardKind.debit;
    }
  }

  String get value => name;
}

/// Monedas que puede manejar la tarjeta.
enum CardCurrencyMode {
  /// Solo bolívares (pagos locales en VES).
  bolivares,

  /// Solo dólares / libre convertibilidad (suscripciones, pagos internacionales).
  dollars,

  /// Bolívares y dólares (ej. BNC).
  both;

  String get label => switch (this) {
        CardCurrencyMode.bolivares => 'Solo bolívares',
        CardCurrencyMode.dollars => 'Solo dólares',
        CardCurrencyMode.both => 'Bolívares y dólares',
      };

  String get shortLabel => switch (this) {
        CardCurrencyMode.bolivares => 'Bs',
        CardCurrencyMode.dollars => 'USD',
        CardCurrencyMode.both => 'Bs · USD',
      };

  String get description => switch (this) {
        CardCurrencyMode.bolivares => 'Pagos locales en bolívares',
        CardCurrencyMode.dollars =>
          'Libre convertibilidad: suscripciones y pagos en USD',
        CardCurrencyMode.both =>
          'Como BNC: puede registrar gastos en Bs o en dólares',
      };

  bool get supportsBolivares =>
      this == CardCurrencyMode.bolivares || this == CardCurrencyMode.both;

  bool get supportsDollars =>
      this == CardCurrencyMode.dollars || this == CardCurrencyMode.both;

  bool supportsCurrency(String currency) {
    if (currency == 'bolivares') return supportsBolivares;
    if (currency == 'dollars') return supportsDollars;
    return false;
  }

  /// Preferencia al elegir la tarjeta si hay que fijar moneda.
  String get preferredFormCurrency =>
      supportsDollars && !supportsBolivares ? 'dollars' : 'bolivares';

  static CardCurrencyMode fromString(String? value) {
    switch (value) {
      case 'dollars':
        return CardCurrencyMode.dollars;
      case 'bolivares':
        return CardCurrencyMode.bolivares;
      case 'both':
        return CardCurrencyMode.both;
      default:
        // Tarjetas antiguas sin campo: asumir ambas para no romper usos.
        return CardCurrencyMode.both;
    }
  }

  String get value => name;
}

/// Non-sensitive card info only (no full number, CVV, or PIN).
class PaymentCard {
  const PaymentCard({
    required this.id,
    required this.name,
    required this.kind,
    this.lastFour,
    this.bank,
    this.colorHex = '#1A1F2D',
    this.currencyMode = CardCurrencyMode.both,
  });

  final String id;
  final String name;
  final CardKind kind;
  final String? lastFour;
  final String? bank;
  final String colorHex;
  final CardCurrencyMode currencyMode;

  String get displayLabel {
    final parts = <String>[name];
    if (lastFour != null && lastFour!.isNotEmpty) {
      parts.add('•••• $lastFour');
    }
    return parts.join(' · ');
  }

  String get subtitle {
    final parts = <String>[kind.label, currencyMode.shortLabel];
    if (bank != null && bank!.trim().isNotEmpty) {
      parts.add(bank!.trim());
    }
    return parts.join(' · ');
  }

  PaymentCard copyWith({
    String? id,
    String? name,
    CardKind? kind,
    String? lastFour,
    bool clearLastFour = false,
    String? bank,
    bool clearBank = false,
    String? colorHex,
    CardCurrencyMode? currencyMode,
  }) {
    return PaymentCard(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      lastFour: clearLastFour ? null : (lastFour ?? this.lastFour),
      bank: clearBank ? null : (bank ?? this.bank),
      colorHex: colorHex ?? this.colorHex,
      currencyMode: currencyMode ?? this.currencyMode,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind.value,
        'lastFour': lastFour,
        'bank': bank,
        'colorHex': colorHex,
        'currencyMode': currencyMode.value,
      };

  factory PaymentCard.fromJson(Map<String, dynamic> json) => PaymentCard(
        id: json['id'] as String,
        name: json['name'] as String,
        kind: CardKind.fromString(json['kind'] as String?),
        lastFour: json['lastFour'] as String?,
        bank: json['bank'] as String?,
        colorHex: json['colorHex'] as String? ?? '#1A1F2D',
        currencyMode: CardCurrencyMode.fromString(json['currencyMode'] as String?),
      );
}
