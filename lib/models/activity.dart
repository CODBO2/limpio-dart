class Activity {
  Activity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.amountColor,
    required this.date,
    required this.iconName,
    required this.iconBg,
    required this.iconColor,
    this.equivalentBs,
    this.equivalentUsd,
    this.topicId,
    this.cardId,
    this.paymentMethod,
  });

  final String id;
  final String title;
  final String subtitle;
  final String amount;
  final String amountColor;
  final double? equivalentBs;
  final double? equivalentUsd;
  final String date;
  final String iconName;
  final String iconBg;
  final String iconColor;
  final String? topicId;
  final String? cardId;
  final String? paymentMethod;

  Activity copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? amount,
    String? amountColor,
    double? equivalentBs,
    bool clearEquivalentBs = false,
    double? equivalentUsd,
    bool clearEquivalentUsd = false,
    String? date,
    String? iconName,
    String? iconBg,
    String? iconColor,
    String? topicId,
    bool clearTopicId = false,
    String? cardId,
    bool clearCardId = false,
    String? paymentMethod,
    bool clearPaymentMethod = false,
  }) {
    return Activity(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      amount: amount ?? this.amount,
      amountColor: amountColor ?? this.amountColor,
      equivalentBs: clearEquivalentBs ? null : (equivalentBs ?? this.equivalentBs),
      equivalentUsd:
          clearEquivalentUsd ? null : (equivalentUsd ?? this.equivalentUsd),
      date: date ?? this.date,
      iconName: iconName ?? this.iconName,
      iconBg: iconBg ?? this.iconBg,
      iconColor: iconColor ?? this.iconColor,
      topicId: clearTopicId ? null : (topicId ?? this.topicId),
      cardId: clearCardId ? null : (cardId ?? this.cardId),
      paymentMethod: clearPaymentMethod ? null : (paymentMethod ?? this.paymentMethod),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'amount': amount,
        'amountColor': amountColor,
        'equivalentBs': equivalentBs,
        'equivalentUsd': equivalentUsd,
        'date': date,
        'icon': iconName,
        'iconBg': iconBg,
        'iconColor': iconColor,
        'topicId': topicId,
        'cardId': cardId,
        'paymentMethod': paymentMethod,
      };

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
        id: json['id'] as String,
        title: json['title'] as String,
        subtitle: json['subtitle'] as String,
        amount: json['amount'] as String,
        amountColor: json['amountColor'] as String? ?? '#2C2C2C',
        equivalentBs: (json['equivalentBs'] as num?)?.toDouble(),
        equivalentUsd: (json['equivalentUsd'] as num?)?.toDouble(),
        date: json['date'] as String,
        iconName: json['icon'] as String? ?? 'help-circle',
        iconBg: json['iconBg'] as String? ?? '#EEEEEE',
        iconColor: json['iconColor'] as String? ?? '#575757',
        topicId: json['topicId'] as String?,
        cardId: json['cardId'] as String?,
        paymentMethod: json['paymentMethod'] as String?,
      );
}
