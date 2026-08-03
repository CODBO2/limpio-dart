import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/defaults.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/money_amount_input.dart';
import 'activity.dart';
import 'fuente.dart';
import 'payment_card.dart';
import 'payment_method.dart';
import 'topic.dart';
import 'trash_entry.dart';

const _uuid = Uuid();

class ActivityKind {
  static const income = 'Ingreso';
  static const expense = 'Egreso';

  static bool isIncome(String subtitle) {
    final normalized = subtitle.trim().toLowerCase();
    return normalized == 'ingreso' ||
        normalized == 'ingresos' ||
        normalized == 'ingresos fijos';
  }

  /// UI label; maps legacy «Gasto» to «Egreso».
  static String displayLabel(String subtitle) =>
      isIncome(subtitle) ? income : expense;

  static String label(bool isIncome) => isIncome ? income : expense;
}

class ActivityBuilder {
  static Activity buildFromForm({
    String? id,
    required String concepto,
    required String monto,
    required String currency,
    required bool isIncome,
    required double effectiveRate,
    DateTime? date,
    String? topicId,
    String? cardId,
    PaymentMethod? paymentMethod,
  }) {
    final rate = effectiveRate > 0 ? effectiveRate : Defaults.defaultBsToUsdRate;
    final amountNum = MoneyAmountInput.parse(monto);

    final String amountStr;
    double? equivalentBs;
    double? equivalentUsd;

    if (currency == 'bolivares') {
      amountStr = '${amountNum.toStringAsFixed(2)} Bs';
      if (amountNum > 0 && rate > 0) equivalentUsd = amountNum / rate;
    } else {
      amountStr = '${amountNum.toStringAsFixed(2)} \$';
      if (amountNum > 0) equivalentBs = amountNum * rate;
    }

    final activityDate = date ?? DateTime.now();
    final resolvedMethod = isIncome
        ? null
        : (paymentMethod ?? PaymentMethod.pagoMovil);
    final resolvedCardId =
        !isIncome && resolvedMethod == PaymentMethod.card ? cardId : null;

    return Activity(
      id: id ?? _uuid.v4(),
      title: concepto.isEmpty ? 'Sin concepto' : concepto,
      subtitle: ActivityKind.label(isIncome),
      amount: amountStr,
      equivalentBs: equivalentBs,
      equivalentUsd: equivalentUsd,
      amountColor: isIncome ? '#0A0A0A' : '#525252',
      date: CurrencyFormatter.formatActivityDate(activityDate),
      iconName: isIncome ? 'trending-up' : 'arrow-up-right',
      iconBg: isIncome ? '#F5F5F5' : '#EEEEEE',
      iconColor: isIncome ? '#171717' : '#404040',
      topicId: topicId ?? Defaults.defaultTopicId,
      cardId: resolvedCardId,
      paymentMethod: resolvedMethod?.value,
    );
  }

  static Activity fuenteToActivityItem(Fuente fuente) {
    final isVes = fuente.currency == 'VES';
    final amountStr = isVes ? '${fuente.amount} Bs' : '${fuente.amount} \$';
    return Activity(
      id: 'fuente-${fuente.id}',
      title: fuente.name,
      subtitle: ActivityKind.income,
      amount: amountStr,
      amountColor: '#0A0A0A',
      date: 'Día ${fuente.day}',
      iconName: 'trending-up',
      iconBg: '#F5F5F5',
      iconColor: '#171717',
    );
  }

  static Color parseHexColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }
    if (cleaned.length == 8) {
      return Color(int.parse(cleaned, radix: 16));
    }
    return const Color(0xFF2C2C2C);
  }

  static IconData iconFromName(String name) {
    switch (name) {
      case 'trending-up':
        return Icons.trending_up;
      case 'arrow-up-right':
        return Icons.north_east_rounded;
      case 'home':
        return Icons.home_outlined;
      case 'coffee':
        return Icons.coffee_outlined;
      case 'shopping-bag':
        return Icons.shopping_bag_outlined;
      case 'layers':
        return Icons.layers_outlined;
      default:
        return Icons.help_outline;
    }
  }

  static List<Map<String, dynamic>> activitiesToJson(List<Activity> items) =>
      items.map((e) => e.toJson()).toList();

  static List<Activity> activitiesFromJson(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Activity.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  static List<Map<String, dynamic>> fuentesToJson(List<Fuente> items) =>
      items.map((e) => e.toJson()).toList();

  static List<Fuente> fuentesFromJson(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Fuente.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  static List<Map<String, dynamic>> topicsToJson(List<Topic> items) =>
      items.map((e) => e.toJson()).toList();

  static List<Topic> topicsFromJson(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Topic.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  static List<Map<String, dynamic>> trashToJson(List<TrashEntry> items) =>
      items.map((e) => e.toJson()).toList();

  static List<TrashEntry> trashFromJson(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => TrashEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static List<Map<String, dynamic>> cardsToJson(List<PaymentCard> items) =>
      items.map((e) => e.toJson()).toList();

  static List<PaymentCard> cardsFromJson(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => PaymentCard.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }
}
