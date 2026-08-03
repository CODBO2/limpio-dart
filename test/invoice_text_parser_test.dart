import 'package:flutter_test/flutter_test.dart';
import 'package:limpio_dart/services/invoice_amount_utils.dart';
import 'package:limpio_dart/services/invoice_text_parser.dart';

void main() {
  final parser = InvoiceTextParser();

  group('InvoiceTextParser', () {
    test('detects total on same line with comma decimals', () {
      final draft = parser.parse('''
SUPERMERCADO XYZ
FECHA 15/03/2026
SUBTOTAL 120,00
IVA 19,20
TOTAL 139,20 Bs
''');

      expect(draft.monto, 139.20);
      expect(draft.currency, 'bolivares');
    });

    test('detects amount on next line after TOTAL label', () {
      final draft = parser.parse('''
CAFE CENTRAL
TOTAL
1.250,75 Bs
''');

      expect(draft.monto, 1250.75);
    });

    test('detects USD amount with dollar sign', () {
      final draft = parser.parse('''
TIENDA ONLINE
MONTO A PAGAR
\$ 24.99
''');

      expect(draft.monto, 24.99);
      expect(draft.currency, 'dollars');
    });

    test('detects inline TOTAL: pattern', () {
      final draft = parser.parse('FACTURA\nTOTAL: 3.450,00 Bs');

      expect(draft.monto, 3450.00);
    });

    test('ignores RIF line and prefers total', () {
      final draft = parser.parse('''
COMERCIO ABC
RIF J-12345678-9
TOTAL 890,50 Bs
''');

      expect(draft.monto, 890.50);
    });

    test('handles OCR-like separators and spaces', () {
      final draft = parser.parse('TOTAL 12 345,67 Bs');

      expect(draft.monto, 12345.67);
    });

    test('extracts date dd/mm/yyyy', () {
      final draft = parser.parse('FECHA 18/07/2026\nTOTAL 100,00 Bs');

      expect(draft.date?.year, 2026);
      expect(draft.date?.month, 7);
      expect(draft.date?.day, 18);
    });

    test('parses POS voucher MONTOBs with thousands dots', () {
      final draft = parser.parse('''
PAN. Y PAST. LA MANSION
RIF J0306480110
VENTA MASTERCARD DEBITO
Fecha: 30/07/2026
Hora: 07:56:37 p. m.
No. Autor. 383902
No.Operac. 121224
Terminal 02
Lote 325
Ticket 1940
MONTOBs. 1.043,89
NO REQUIERE FIRMA
V 09.06.06 - Platco 80
''');

      expect(draft.monto, closeTo(1043.89, 0.001));
      expect(draft.currency, 'bolivares');
      expect(draft.amountLabel, '1.043,89 Bs');
      expect(draft.date?.day, 30);
      expect(draft.date?.month, 7);
      expect(draft.date?.year, 2026);
      expect(draft.date?.hour, 19);
      expect(draft.date?.minute, 56);
    });

    test('recovers OCR-garbled MONTO amounts', () {
      expect(parser.parse('MONTOBs. 1 .043, 89').monto, closeTo(1043.89, 0.001));
      expect(parser.parse('MONTOBs. 1.043.89').monto, closeTo(1043.89, 0.001));
      expect(parser.parse('MONTOBs. 1.043 ,89').monto, closeTo(1043.89, 0.001));
      expect(parser.parse('MONTO Bs.\n1.043,89').monto, closeTo(1043.89, 0.001));
      expect(
        InvoiceAmountUtils.extractNumbers('1.043.89').map((n) => n.value).toList(),
        [1043.89],
      );
    });

    test('parses dashed and OCR-garbled date formats', () {
      expect(
        InvoiceAmountUtils.extractDate('Fecha: 30-07-2026\nHora: 07:56').value?.day,
        30,
      );
      expect(
        InvoiceAmountUtils.extractDate('Fecha: 3O/O7/2O26').value?.year,
        2026,
      );
      expect(
        InvoiceAmountUtils.extractDate('25-07-2026 11:53\nTOTAL 10,00').value?.day,
        25,
      );
      // Año con dígito extra pegado por OCR
      expect(
        InvoiceAmountUtils.extractDate('Fecha: 30/07/20261').value?.year,
        2026,
      );
    });

    test('ignores version-only dates when no Fecha label', () {
      final result = InvoiceAmountUtils.extractDate(
        'TOTAL Bs 50,00\nV 09.06.06 - Platco 80',
      );
      expect(result.value, isNull);
    });

    test('pago móvil prefers monto over referencia', () {
      final draft = parser.refinePagoMovil(
        parser.parse('''
Pago móvil
Operación exitosa
Banco Mercantil
Referencia: 001234567890
Monto: Bs. 250,00
30 jul 2026 14:32
'''),
      );

      expect(draft.monto, 250.00);
      expect(draft.currency, 'bolivares');
      expect(draft.date?.day, 30);
      expect(draft.date?.month, 7);
      expect(draft.date?.year, 2026);
    });

    test('ignores referencia as amount candidate', () {
      final draft = parser.parse('''
Transferencia
Referencia 987654321012
Monto transferido 1.580,25 Bs
''');

      expect(draft.monto, 1580.25);
    });

    test('parses Venezuelan receipt TOTAL with thousands dots', () {
      final draft = parser.parse('''
INVERSIONES K FOOD 2017, C.A.
RIF J-410102497
FACTURA 00200718
25-07-2026 11:53
COMBO PAPAS Y REFRES (G) Bs 2.559,38
JUGO DE NARANJA MEDI (G) Bs 3.327,19
BAGEL CON PROSCIUTTO (G) Bs 9.725,64
NESTEA LIMON (G) Bs 1.727,58
SUBTTL Bs 17.339,79
BI G16,00% Bs 17.339,79
IVA G16,00% Bs 2.774,37
CREDITO Bs 20.114,18
CAMBIO Bs 0,02
TOTAL Bs 20.114,16
''');

      expect(draft.monto, closeTo(20114.16, 0.001));
      expect(draft.currency, 'bolivares');
      expect(draft.date?.day, 25);
      expect(draft.date?.month, 7);
      expect(draft.date?.year, 2026);
      expect(draft.amountLabel, '20.114,16 Bs');
    });

    test('recovers amount when OCR drops decimal comma', () {
      expect(
        InvoiceAmountUtils.parseNumberToken('20.11416'),
        closeTo(20114.16, 0.001),
      );
      expect(
        InvoiceAmountUtils.parseNumberToken('Bs 20.114,16'),
        closeTo(20114.16, 0.001),
      );
      expect(
        InvoiceAmountUtils.parseNumberToken('20.114.16'),
        closeTo(20114.16, 0.001),
      );
      expect(
        InvoiceAmountUtils.parseNumberToken('20114,16'),
        closeTo(20114.16, 0.001),
      );
      expect(
        InvoiceAmountUtils.parseNumberToken('20114.16'),
        closeTo(20114.16, 0.001),
      );
      expect(InvoiceAmountUtils.parseNumberToken('20.11'), closeTo(20.11, 0.001));
      expect(InvoiceAmountUtils.parseNumberToken('20,11'), closeTo(20.11, 0.001));
    });

    test('does not take 20.11 out of 20.114,16', () {
      final nums = InvoiceAmountUtils.extractNumbers('TOTAL Bs 20.114,16');
      expect(nums.map((n) => n.value).toList(), [20114.16]);
    });
  });
}
