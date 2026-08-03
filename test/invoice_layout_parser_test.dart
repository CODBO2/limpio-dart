import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:limpio_dart/services/invoice_layout_parser.dart';

void main() {
  final parser = InvoiceLayoutParser();

  group('InvoiceLayoutParser', () {
    test('pairs TOTAL label with amount on the right', () {
      final draft = parser.parseVisualLines(
        [
          OcrVisualLine(
            text: 'SUPERMERCADO',
            box: const Rect.fromLTWH(10, 10, 200, 20),
            elements: const [
              OcrVisualElement(text: 'SUPERMERCADO', box: Rect.fromLTWH(10, 10, 200, 20)),
            ],
          ),
          OcrVisualLine(
            text: 'TOTAL 139,20 Bs',
            box: const Rect.fromLTWH(10, 300, 280, 22),
            elements: const [
              OcrVisualElement(text: 'TOTAL', box: Rect.fromLTWH(10, 300, 70, 22)),
              OcrVisualElement(text: '139,20', box: Rect.fromLTWH(180, 300, 70, 22)),
              OcrVisualElement(text: 'Bs', box: Rect.fromLTWH(255, 300, 30, 22)),
            ],
          ),
        ],
        rawText: 'SUPERMERCADO\nTOTAL 139,20 Bs',
      );

      expect(draft.monto, 139.20);
      expect(draft.currency, 'bolivares');
      expect(draft.amountConfidence, greaterThan(0.45));
    });

    test('pairs TOTAL on one line with amount on next line', () {
      final draft = parser.parseVisualLines(
        [
          OcrVisualLine(
            text: 'TOTAL',
            box: const Rect.fromLTWH(20, 280, 80, 20),
            elements: const [
              OcrVisualElement(text: 'TOTAL', box: Rect.fromLTWH(20, 280, 80, 20)),
            ],
          ),
          OcrVisualLine(
            text: '1.250,75 Bs',
            box: const Rect.fromLTWH(180, 305, 120, 20),
            elements: const [
              OcrVisualElement(text: '1.250,75', box: Rect.fromLTWH(180, 305, 90, 20)),
              OcrVisualElement(text: 'Bs', box: Rect.fromLTWH(275, 305, 25, 20)),
            ],
          ),
        ],
        rawText: 'TOTAL\n1.250,75 Bs',
      );

      expect(draft.monto, 1250.75);
    });

    test('ignores RIF and prefers TOTAL amount', () {
      final draft = parser.parseVisualLines(
        [
          OcrVisualLine(
            text: 'RIF J-12345678-9',
            box: const Rect.fromLTWH(10, 40, 200, 18),
            elements: const [
              OcrVisualElement(text: 'RIF', box: Rect.fromLTWH(10, 40, 40, 18)),
              OcrVisualElement(text: 'J-12345678-9', box: Rect.fromLTWH(55, 40, 140, 18)),
            ],
          ),
          OcrVisualLine(
            text: 'TOTAL A PAGAR 890,50',
            box: const Rect.fromLTWH(10, 320, 260, 20),
            elements: const [
              OcrVisualElement(text: 'TOTAL', box: Rect.fromLTWH(10, 320, 55, 20)),
              OcrVisualElement(text: 'A', box: Rect.fromLTWH(70, 320, 20, 20)),
              OcrVisualElement(text: 'PAGAR', box: Rect.fromLTWH(95, 320, 60, 20)),
              OcrVisualElement(text: '890,50', box: Rect.fromLTWH(200, 320, 60, 20)),
            ],
          ),
        ],
        rawText: 'RIF J-12345678-9\nTOTAL A PAGAR 890,50',
      );

      expect(draft.monto, 890.50);
    });

    test('detects USD amount near MONTO label', () {
      final draft = parser.parseVisualLines(
        [
          OcrVisualLine(
            text: 'MONTO A PAGAR \$ 24.99',
            box: const Rect.fromLTWH(15, 250, 240, 20),
            elements: const [
              OcrVisualElement(text: 'MONTO', box: Rect.fromLTWH(15, 250, 60, 20)),
              OcrVisualElement(text: 'A', box: Rect.fromLTWH(80, 250, 15, 20)),
              OcrVisualElement(text: 'PAGAR', box: Rect.fromLTWH(100, 250, 55, 20)),
              OcrVisualElement(text: '\$', box: Rect.fromLTWH(170, 250, 15, 20)),
              OcrVisualElement(text: '24.99', box: Rect.fromLTWH(190, 250, 50, 20)),
            ],
          ),
        ],
        rawText: 'MONTO A PAGAR \$ 24.99',
      );

      expect(draft.monto, 24.99);
      expect(draft.currency, 'dollars');
    });
  });
}
