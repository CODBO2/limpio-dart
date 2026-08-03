import 'package:flutter/material.dart';
import 'package:u_credit_card/u_credit_card.dart';

import '../models/venezuelan_bank.dart';

/// Tarjeta de débito o crédito con identidad visual de un banco venezolano.
///
/// Usa `u_credit_card` como base e inyecta logo y fondo desde assets locales.
/// Sustituye los PNG en `assets/logos/` y `assets/backgrounds/` con tus diseños
/// reales; las rutas se resuelven automáticamente vía [VenezuelanBankUi].
class VenezuelanBankCard extends StatelessWidget {
  const VenezuelanBankCard({
    super.key,
    required this.bank,
    required this.cardNumber,
    required this.cardHolderFullName,
    required this.validThru,
    required this.cardType,
    this.width,
    this.showValidFrom = false,
    this.placeNfcIconAtTheEnd = true,
    this.shouldMaskCardNumber = true,
  });

  /// Banco emisor de la tarjeta.
  final VenezuelanBank bank;

  /// Número completo o parcial (se enmascara si [shouldMaskCardNumber] es true).
  final String cardNumber;

  /// Nombre del titular o alias de la tarjeta.
  final String cardHolderFullName;

  /// Fecha de vencimiento (ej. `12/28`).
  final String validThru;

  /// Débito o crédito.
  final VenezuelanCardType cardType;

  /// Ancho de la tarjeta; por defecto usa el ancho disponible del padre.
  final double? width;

  /// Muestra el campo "valid from" en la tarjeta.
  final bool showValidFrom;

  /// Ubica el ícono NFC al final de la tarjeta.
  final bool placeNfcIconAtTheEnd;

  /// Enmascara dígitos del número de tarjeta.
  final bool shouldMaskCardNumber;

  @override
  Widget build(BuildContext context) {
    final primary = bank.fallbackColor;
    final secondary = bank.fallbackSecondaryColor;

    return CreditCardUi(
      width: width ?? MediaQuery.sizeOf(context).width - 40,
      cardHolderFullName: cardHolderFullName,
      cardNumber: cardNumber,
      validThru: validThru,
      topLeftColor: primary,
      bottomRightColor: secondary,
      doesSupportNfc: true,
      placeNfcIconAtTheEnd: placeNfcIconAtTheEnd,
      cardType: cardType.creditCardUiType,
      showValidFrom: showValidFrom,
      showValidThru: true,
      shouldMaskCardNumber: shouldMaskCardNumber,
      cardProviderLogo: _BankLogo(bank: bank),
      cardProviderLogoPosition: CardProviderLogoPosition.right,
      backgroundDecorationImage: DecorationImage(
        fit: BoxFit.cover,
        image: AssetImage(bank.backgroundAssetPath),
      ),
    );
  }
}

/// Logo del banco con fallback de texto si el asset no existe.
class _BankLogo extends StatelessWidget {
  const _BankLogo({required this.bank});

  final VenezuelanBank bank;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      bank.logoAssetPath,
      height: 28,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          bank.shortLabel,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
