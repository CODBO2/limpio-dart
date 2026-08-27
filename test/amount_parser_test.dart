import 'package:flutter_test/flutter_test.dart';
import 'package:limpio_dart/core/utils/amount_parser.dart';
import 'package:limpio_dart/models/activity.dart';
import 'package:limpio_dart/models/fuente.dart';

void main() {
  group('AmountParser', () {
    test('parseAmountToUsd parses dollars', () {
      expect(AmountParser.parseAmountToUsd('12.50 \$'), 12.5);
    });

    test('parseAmountToUsd parses bolivares with rate', () {
      expect(AmountParser.parseAmountToUsd('400 Bs', rate: 40), 10);
    });

    test('fuenteAmountToUsd converts VES', () {
      const fuente = Fuente(
        id: '1',
        name: 'Salario',
        amount: '400',
        currency: 'VES',
        day: 1,
      );
      expect(AmountParser.fuenteAmountToUsd(fuente, rate: 40), 10);
    });
  });

  group('BalanceCalculator', () {
    test('computeTotals calculates income expenses and balance', () {
      final activities = [
        Activity(
          id: '1',
          title: 'Salario',
          subtitle: 'Ingreso',
          amount: '100 \$',
          amountColor: '#2ECC71',
          date: '01 Mar',
          iconName: 'trending-up',
          iconBg: '#E6F9F0',
          iconColor: '#2ECC71',
        ),
        Activity(
          id: '2',
          title: 'Mercado',
          subtitle: 'Gasto',
          amount: '30 \$',
          amountColor: '#2C2C2C',
          date: '02 Mar',
          iconName: 'arrow-up-right',
          iconBg: '#FFEBEE',
          iconColor: '#B91C1C',
        ),
      ];

      final totals = BalanceCalculator.computeTotals(activities);
      expect(totals.totalIncome, 100);
      expect(totals.totalExpenses, 30);
      expect(totals.balance, 70);
    });
  });

  group('getEffectiveRate', () {
    test('returns custom rate when personalizado', () {
      expect(
        getEffectiveRate(
          rateType: 'personalizado',
          customRate: 45,
          rateBcv: 36.5,
        ),
        45,
      );
    });

    test('returns BCV rate by default', () {
      expect(
        getEffectiveRate(
          rateType: 'bcv',
          customRate: 45,
          rateBcv: 36.5,
        ),
        36.5,
      );
    });
  });
}
