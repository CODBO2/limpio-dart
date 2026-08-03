import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/exchange_rate_service.dart';
import '../services/storage_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService must be overridden in main');
});

final exchangeRateServiceProvider = Provider<ExchangeRateService>((ref) {
  return ExchangeRateService();
});

final dataReadyProvider = StateProvider<bool>((ref) => false);
