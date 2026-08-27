import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/api_urls.dart';
import '../models/rate_type.dart';

class ExchangeRateResult {
  const ExchangeRateResult({
    required this.promedio,
    this.fechaActualizacion,
    this.fromHistory = false,
  });

  final double promedio;
  final String? fechaActualizacion;
  final bool fromHistory;
}

class ExchangeRateService {
  Future<ExchangeRateResult?> fetchRate(String url, {bool fromHistory = false}) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final promedio = data['promedio'];
      if (promedio is! num || promedio <= 0) return null;
      return ExchangeRateResult(
        promedio: promedio.toDouble(),
        fechaActualizacion:
            (data['fechaActualizacion'] as String?) ?? (data['fecha'] as String?),
        fromHistory: fromHistory,
      );
    } catch (_) {
      return null;
    }
  }

  Future<ExchangeRateResult?> fetchBcvRate() => fetchRate(ApiUrls.dolarBcv);

  /// Rate for a calendar date. Prefers historical endpoints; falls back to live rates.
  Future<ExchangeRateResult?> fetchRateForDate({
    required DateTime date,
    required RateType rateType,
    required double customRate,
    required double fallbackBcv,
  }) async {
    if (rateType == RateType.personalizado) {
      final rate = customRate > 0 ? customRate : fallbackBcv;
      return ExchangeRateResult(promedio: rate, fromHistory: false);
    }

    final isToday = _isSameDay(date, DateTime.now());
    if (isToday) {
      final live = await fetchRate(ApiUrls.dolarBcv);
      if (live != null) return live;
      return ExchangeRateResult(promedio: fallbackBcv);
    }

    final historical =
        await fetchRate(ApiUrls.historicoOficial(date), fromHistory: true);
    if (historical != null) return historical;

    final live = await fetchRate(ApiUrls.dolarBcv);
    if (live != null) return live;

    return ExchangeRateResult(promedio: fallbackBcv);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
