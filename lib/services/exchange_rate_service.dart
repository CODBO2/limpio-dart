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

  Future<({ExchangeRateResult? bcv, ExchangeRateResult? paralelo})> fetchAllRates() async {
    final results = await Future.wait([
      fetchRate(ApiUrls.dolarBcv),
      fetchRate(ApiUrls.dolarParalelo),
    ]);
    return (bcv: results[0], paralelo: results[1]);
  }

  /// Rate for a calendar date. Prefers historical endpoints; falls back to live rates.
  Future<ExchangeRateResult?> fetchRateForDate({
    required DateTime date,
    required RateType rateType,
    required double customRate,
    required double fallbackBcv,
    required double fallbackParalelo,
  }) async {
    if (rateType == RateType.personalizado) {
      final rate = customRate > 0 ? customRate : fallbackParalelo;
      return ExchangeRateResult(promedio: rate, fromHistory: false);
    }

    final isToday = _isSameDay(date, DateTime.now());
    if (isToday) {
      final liveUrl =
          rateType == RateType.bcv ? ApiUrls.dolarBcv : ApiUrls.dolarParalelo;
      final live = await fetchRate(liveUrl);
      if (live != null) return live;
      final fallback = rateType == RateType.bcv ? fallbackBcv : fallbackParalelo;
      return ExchangeRateResult(promedio: fallback);
    }

    final historyUrl = rateType == RateType.bcv
        ? ApiUrls.historicoOficial(date)
        : ApiUrls.historicoParalelo(date);
    final historical = await fetchRate(historyUrl, fromHistory: true);
    if (historical != null) return historical;

    // Paralelo histórico a veces no está; intenta BCV histórico como respaldo.
    if (rateType == RateType.paralelo) {
      final bcvHistory =
          await fetchRate(ApiUrls.historicoOficial(date), fromHistory: true);
      if (bcvHistory != null) return bcvHistory;
    }

    final liveUrl =
        rateType == RateType.bcv ? ApiUrls.dolarBcv : ApiUrls.dolarParalelo;
    final live = await fetchRate(liveUrl);
    if (live != null) return live;

    final fallback = rateType == RateType.bcv ? fallbackBcv : fallbackParalelo;
    return ExchangeRateResult(promedio: fallback);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
