import 'package:flutter_test/flutter_test.dart';
import 'package:limpio_dart/core/utils/weekly_expense_calculator.dart';
import 'package:limpio_dart/models/activity.dart';

void main() {
  group('WeeklyExpenseCalculator', () {
    test('aggregates expenses by weekday of current week', () {
      // Wednesday of a fixed week: 2026-07-29 is Wednesday
      final reference = DateTime(2026, 7, 29);

      final activities = [
        _expense('1', '10 \$', '27 jul · 10:00 a. m.'),
        _expense('2', '20 \$', '29 jul · 1:00 p. m.'),
        Activity(
          id: '3',
          title: 'Salario',
          subtitle: 'Ingreso',
          amount: '100 \$',
          amountColor: '#000',
          date: '31 jul · 9:00 a. m.',
          iconName: 'x',
          iconBg: '#eee',
          iconColor: '#000',
        ),
        _expense('4', '5 \$', '31 jul · 8:00 p. m.'),
      ];

      final stats = WeeklyExpenseCalculator.compute(
        activities,
        reference: reference,
      );

      expect(stats.days.length, 7);
      expect(stats.days[0].amountUsd, 10); // Monday
      expect(stats.days[2].amountUsd, 20); // Wednesday
      expect(stats.days[4].amountUsd, 5); // Friday expenses only
      expect(stats.totalUsd, 35);
    });

    test('parseActivityDate reads spanish day month labels', () {
      final date = WeeklyExpenseCalculator.parseActivityDate(
        '18 jul · 2:31 p. m.',
        fallbackYear: 2026,
      );
      expect(date?.year, 2026);
      expect(date?.month, 7);
      expect(date?.day, 18);
    });
  });
}

Activity _expense(String id, String amount, String date) {
  return Activity(
    id: id,
    title: 'Gasto',
    subtitle: 'Gasto',
    amount: amount,
    amountColor: '#000',
    date: date,
    iconName: 'x',
    iconBg: '#eee',
    iconColor: '#000',
  );
}
