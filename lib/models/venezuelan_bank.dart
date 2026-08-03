import 'package:flutter/material.dart';
import 'package:u_credit_card/u_credit_card.dart';

import '../models/payment_card.dart';

/// Bancos venezolanos soportados para el componente `VenezuelanBankCard`.
///
/// Amplía este enum y [VenezuelanBankUi] al añadir nuevos assets en
/// `assets/logos/` y `assets/backgrounds/`.
enum VenezuelanBank {
  /// Banco de Venezuela (BDV).
  bdv,

  /// Banco Nacional de Crédito (BNC).
  bnc,

  /// Banco Mercantil.
  mercantil;

  /// Resuelve un nombre de banco almacenado en la app (ej. desde el picker).
  static VenezuelanBank? fromBankName(String? bankName) {
    if (bankName == null || bankName.trim().isEmpty) return null;
    final normalized = bankName.trim().toLowerCase();

    if (normalized.contains('banco de venezuela') || normalized == 'bdv') {
      return VenezuelanBank.bdv;
    }
    if (normalized.contains('bnc') ||
        normalized.contains('nacional de crédito') ||
        normalized.contains('nacional de credito')) {
      return VenezuelanBank.bnc;
    }
    if (normalized.contains('mercantil')) {
      return VenezuelanBank.mercantil;
    }
    return null;
  }
}

/// Tipo de tarjeta mostrado en la UI (débito o crédito).
enum VenezuelanCardType {
  debit,
  credit,
}

/// Rutas de assets, colores de respaldo y metadatos visuales por banco.
extension VenezuelanBankUi on VenezuelanBank {
  /// Ruta del logotipo del banco (reemplaza con tu PNG real).
  String get logoAssetPath => 'assets/logos/$name.png';

  /// Ruta del fondo de la tarjeta (reemplaza con tu PNG real).
  String get backgroundAssetPath => 'assets/backgrounds/${name}_bg.png';

  /// Diseño completo de la cara de la tarjeta (si existe).
  String? get cardFaceAssetPath => switch (this) {
        VenezuelanBank.bnc => 'assets/Cards/tarjeta_bnc.png',
        _ => null,
      };

  /// Color principal si el asset de fondo no carga o como gradiente base.
  Color get fallbackColor => switch (this) {
        VenezuelanBank.bdv => const Color(0xFFE30613), // Rojo BDV
        VenezuelanBank.bnc => const Color(0xFF0085A1), // Azul oscuro / turquesa BNC
        VenezuelanBank.mercantil => const Color(0xFF003087), // Azul medio Mercantil
      };

  /// Segundo color del gradiente de la tarjeta.
  Color get fallbackSecondaryColor => Color.lerp(fallbackColor, Colors.black, 0.35)!;

  /// Nombre legible del banco.
  String get displayName => switch (this) {
        VenezuelanBank.bdv => 'Banco de Venezuela',
        VenezuelanBank.bnc => 'Banco Nacional de Crédito',
        VenezuelanBank.mercantil => 'Banco Mercantil',
      };

  /// Etiqueta corta para fallback cuando el logo no está disponible.
  String get shortLabel => switch (this) {
        VenezuelanBank.bdv => 'BDV',
        VenezuelanBank.bnc => 'BNC',
        VenezuelanBank.mercantil => 'Mercantil',
      };
}

extension VenezuelanCardTypeUi on VenezuelanCardType {
  /// Mapeo al `CardType` de `u_credit_card`.
  CardType get creditCardUiType => switch (this) {
        VenezuelanCardType.debit => CardType.debit,
        VenezuelanCardType.credit => CardType.credit,
      };

  String get label => switch (this) {
        VenezuelanCardType.debit => 'Débito',
        VenezuelanCardType.credit => 'Crédito',
      };

  /// Convierte el [CardKind] almacenado en la app.
  static VenezuelanCardType fromCardKind(CardKind kind) =>
      kind == CardKind.credit ? VenezuelanCardType.credit : VenezuelanCardType.debit;
}

/// Formatea el número de tarjeta para `CreditCardUi` usando solo los últimos 4 dígitos.
String formatCardNumberForUi(String? lastFour) {
  final digits = (lastFour ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '0000000000000000';
  final last4 = digits.length <= 4
      ? digits.padLeft(4, '0')
      : digits.substring(digits.length - 4);
  return '000000000000$last4';
}
