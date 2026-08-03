import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpio_dart/core/utils/money_amount_input.dart';

void main() {
  group('MoneyAmountInput', () {
    test('formatCents starts at 0,00', () {
      expect(MoneyAmountInput.formatCents(0), '0,00');
    });

    test('formatCents builds from the right', () {
      expect(MoneyAmountInput.formatCents(1), '0,01');
      expect(MoneyAmountInput.formatCents(12), '0,12');
      expect(MoneyAmountInput.formatCents(123), '1,23');
      expect(MoneyAmountInput.formatCents(1234), '12,34');
      expect(MoneyAmountInput.formatCents(123456), '1.234,56');
    });

    test('parse understands es_VE and plain decimals', () {
      expect(MoneyAmountInput.parse('0,00'), 0);
      expect(MoneyAmountInput.parse('12,34'), 12.34);
      expect(MoneyAmountInput.parse('1.234,56'), 1234.56);
      expect(MoneyAmountInput.parse('12.34'), 12.34);
    });
  });

  group('MoneyAmountInputFormatter', () {
    const formatter = MoneyAmountInputFormatter();

    TextEditingValue apply(String oldText, String newText) {
      return formatter.formatEditUpdate(
        TextEditingValue(
          text: oldText,
          selection: TextSelection.collapsed(offset: oldText.length),
        ),
        TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        ),
      );
    }

    test('typing digits appends from the right', () {
      var value = apply('0,00', '0,001');
      expect(value.text, '0,01');

      value = apply(value.text, '${value.text}2');
      expect(value.text, '0,12');

      value = apply(value.text, '${value.text}3');
      expect(value.text, '1,23');

      value = apply(value.text, '${value.text}4');
      expect(value.text, '12,34');
    });

    test('backspace removes from the right', () {
      var value = apply('12,34', '12,3');
      expect(value.text, '1,23');

      value = apply(value.text, '1,2');
      expect(value.text, '0,12');

      value = apply(value.text, '0,1');
      expect(value.text, '0,01');

      value = apply(value.text, '0,');
      expect(value.text, '0,00');
    });
  });
}
