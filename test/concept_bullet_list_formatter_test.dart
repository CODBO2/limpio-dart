import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpio_dart/screens/register_transaction_screen.dart';

void main() {
  const formatter = ConceptBulletListFormatter();

  TextEditingValue apply(String oldText, String newText, {int? cursor}) {
    return formatter.formatEditUpdate(
      TextEditingValue(
        text: oldText,
        selection: TextSelection.collapsed(offset: oldText.length),
      ),
      TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursor ?? newText.length),
      ),
    );
  }

  test('empty becomes bullet', () {
    final value = apply('• ', '');
    expect(value.text, '• ');
  });

  test('enter inserts bullet on next line', () {
    final old = '• Pan';
    final afterEnter = '• Pan\n';
    final value = apply(old, afterEnter, cursor: afterEnter.length);
    expect(value.text, '• Pan\n• ');
    expect(value.selection.baseOffset, value.text.length);
  });

  test('prefixes first line without bullet', () {
    final value = apply('', 'Pan');
    expect(value.text, '• Pan');
  });
}
