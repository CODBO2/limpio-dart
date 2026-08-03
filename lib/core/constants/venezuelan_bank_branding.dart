import 'package:flutter/material.dart';

/// Visual identity for Venezuelan bank cards (colors and layout patterns).
class VenezuelanBankBranding {
  const VenezuelanBankBranding({
    required this.bankName,
    required this.shortLabel,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.pattern,
    this.textOnCard = Colors.white,
    this.textMutedOnCard = const Color(0xB3FFFFFF),
  });

  final String bankName;
  final String shortLabel;
  final Color primary;
  final Color secondary;
  final Color accent;
  final BankCardPattern pattern;
  final Color textOnCard;
  final Color textMutedOnCard;

  String get primaryHex {
    final argb = primary.toARGB32();
    return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  LinearGradient get backgroundGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, secondary],
      );

  static VenezuelanBankBranding? forBank(String? bank) {
    if (bank == null || bank.trim().isEmpty) return null;
    final normalized = bank.trim();
    return _byName[normalized];
  }

  static VenezuelanBankBranding resolve(String? bank, String fallbackHex) {
    final branded = forBank(bank);
    if (branded != null) return branded;
    final color = _parseHex(fallbackHex);
    return VenezuelanBankBranding(
      bankName: bank ?? '',
      shortLabel: 'Tarjeta',
      primary: color,
      secondary: Color.lerp(color, Colors.black, 0.35)!,
      accent: Color.lerp(color, Colors.white, 0.25)!,
      pattern: BankCardPattern.gradient,
    );
  }

  static Color _parseHex(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    final value = int.parse('FF$cleaned', radix: 16);
    return Color(value);
  }

  static const Map<String, VenezuelanBankBranding> _byName = {
    '100% Banco': VenezuelanBankBranding(
      bankName: '100% Banco',
      shortLabel: '100%',
      primary: Color(0xFF00A651),
      secondary: Color(0xFF007A3D),
      accent: Color(0xFF7ED957),
      pattern: BankCardPattern.gradient,
    ),
    'Bancamiga': VenezuelanBankBranding(
      bankName: 'Bancamiga',
      shortLabel: 'Bancamiga',
      primary: Color(0xFF004B8D),
      secondary: Color(0xFF002F5C),
      accent: Color(0xFF4DA3E0),
      pattern: BankCardPattern.waveAccent,
    ),
    'Bancaribe': VenezuelanBankBranding(
      bankName: 'Bancaribe',
      shortLabel: 'Bancaribe',
      primary: Color(0xFF0066B3),
      secondary: Color(0xFF004A82),
      accent: Color(0xFF5CB8E8),
      pattern: BankCardPattern.circles,
    ),
    'Banco Activo': VenezuelanBankBranding(
      bankName: 'Banco Activo',
      shortLabel: 'Activo',
      primary: Color(0xFFE85D04),
      secondary: Color(0xFFC44A00),
      accent: Color(0xFFFFB347),
      pattern: BankCardPattern.diagonalBands,
    ),
    'Banco Agrícola de Venezuela': VenezuelanBankBranding(
      bankName: 'Banco Agrícola de Venezuela',
      shortLabel: 'Agrícola',
      primary: Color(0xFF006B3F),
      secondary: Color(0xFF004D2E),
      accent: Color(0xFF8BC34A),
      pattern: BankCardPattern.gradient,
    ),
    'Banco Caroní': VenezuelanBankBranding(
      bankName: 'Banco Caroní',
      shortLabel: 'Caroní',
      primary: Color(0xFFD71920),
      secondary: Color(0xFF9E1218),
      accent: Color(0xFFFF6B6B),
      pattern: BankCardPattern.diagonalBands,
    ),
    'Banco de la FANB': VenezuelanBankBranding(
      bankName: 'Banco de la FANB',
      shortLabel: 'FANB',
      primary: Color(0xFF2D5016),
      secondary: Color(0xFF1A3010),
      accent: Color(0xFFD4AF37),
      pattern: BankCardPattern.splitTone,
    ),
    'Banco de Venezuela': VenezuelanBankBranding(
      bankName: 'Banco de Venezuela',
      shortLabel: 'BDV',
      primary: Color(0xFFE30613),
      secondary: Color(0xFFB00510),
      accent: Color(0xFFFFD100),
      pattern: BankCardPattern.waveAccent,
    ),
    'Banco del Tesoro': VenezuelanBankBranding(
      bankName: 'Banco del Tesoro',
      shortLabel: 'Tesoro',
      primary: Color(0xFF00843D),
      secondary: Color(0xFF00642E),
      accent: Color(0xFFFFD700),
      pattern: BankCardPattern.cornerGlow,
    ),
    'Banco Digital de los Trabajadores': VenezuelanBankBranding(
      bankName: 'Banco Digital de los Trabajadores',
      shortLabel: 'BDT',
      primary: Color(0xFF005EB8),
      secondary: Color(0xFF004494),
      accent: Color(0xFF64B5F6),
      pattern: BankCardPattern.digital,
    ),
    'Banco Exterior': VenezuelanBankBranding(
      bankName: 'Banco Exterior',
      shortLabel: 'Exterior',
      primary: Color(0xFF0085A1),
      secondary: Color(0xFF006678),
      accent: Color(0xFF4DD0E1),
      pattern: BankCardPattern.waveAccent,
    ),
    'Banco Internacional de Desarrollo': VenezuelanBankBranding(
      bankName: 'Banco Internacional de Desarrollo',
      shortLabel: 'BID',
      primary: Color(0xFF1B4F8C),
      secondary: Color(0xFF133A66),
      accent: Color(0xFF5C9CE6),
      pattern: BankCardPattern.gradient,
    ),
    'Banco Mercantil': VenezuelanBankBranding(
      bankName: 'Banco Mercantil',
      shortLabel: 'Mercantil',
      primary: Color(0xFF003087),
      secondary: Color(0xFF001F5C),
      accent: Color(0xFF4A90D9),
      pattern: BankCardPattern.waveAccent,
    ),
    'Banco Nacional de Crédito (BNC)': VenezuelanBankBranding(
      bankName: 'Banco Nacional de Crédito (BNC)',
      shortLabel: 'BNC',
      primary: Color(0xFF00A650),
      secondary: Color(0xFF007A3C),
      accent: Color(0xFF81C784),
      pattern: BankCardPattern.gradient,
    ),
    'Banco Plaza': VenezuelanBankBranding(
      bankName: 'Banco Plaza',
      shortLabel: 'Plaza',
      primary: Color(0xFF003087),
      secondary: Color(0xFF002060),
      accent: Color(0xFF5C9CE6),
      pattern: BankCardPattern.diagonalBands,
    ),
    'Banco Sofitasa': VenezuelanBankBranding(
      bankName: 'Banco Sofitasa',
      shortLabel: 'Sofitasa',
      primary: Color(0xFF5C4033),
      secondary: Color(0xFF3D2A22),
      accent: Color(0xFFBCAAA4),
      pattern: BankCardPattern.gradient,
    ),
    'Bancrecer': VenezuelanBankBranding(
      bankName: 'Bancrecer',
      shortLabel: 'Bancrecer',
      primary: Color(0xFF2E7D32),
      secondary: Color(0xFF1B5E20),
      accent: Color(0xFFA5D6A7),
      pattern: BankCardPattern.gradient,
    ),
    'Banesco': VenezuelanBankBranding(
      bankName: 'Banesco',
      shortLabel: 'Banesco',
      primary: Color(0xFFF47920),
      secondary: Color(0xFFE85D04),
      accent: Color(0xFF2CB368),
      pattern: BankCardPattern.cornerGlow,
    ),
    'Bangente': VenezuelanBankBranding(
      bankName: 'Bangente',
      shortLabel: 'Bangente',
      primary: Color(0xFF003DA5),
      secondary: Color(0xFF002D7A),
      accent: Color(0xFF64B5F6),
      pattern: BankCardPattern.gradient,
    ),
    'Banplus': VenezuelanBankBranding(
      bankName: 'Banplus',
      shortLabel: 'Banplus',
      primary: Color(0xFF0066CC),
      secondary: Color(0xFF00A651),
      accent: Color(0xFFFFD700),
      pattern: BankCardPattern.splitTone,
    ),
    'BBVA Provincial': VenezuelanBankBranding(
      bankName: 'BBVA Provincial',
      shortLabel: 'Provincial',
      primary: Color(0xFF14549C),
      secondary: Color(0xFF00AAE8),
      accent: Color(0xFFBEE7FB),
      pattern: BankCardPattern.waveAccent,
    ),
    'BFC Banco Fondo Común': VenezuelanBankBranding(
      bankName: 'BFC Banco Fondo Común',
      shortLabel: 'BFC',
      primary: Color(0xFF0066B2),
      secondary: Color(0xFF004D85),
      accent: Color(0xFF5C9CE6),
      pattern: BankCardPattern.gradient,
    ),
    'DelSur': VenezuelanBankBranding(
      bankName: 'DelSur',
      shortLabel: 'DelSur',
      primary: Color(0xFF00843D),
      secondary: Color(0xFF006030),
      accent: Color(0xFFFFC107),
      pattern: BankCardPattern.cornerGlow,
    ),
    'N58 Banco Digital': VenezuelanBankBranding(
      bankName: 'N58 Banco Digital',
      shortLabel: 'N58',
      primary: Color(0xFF4A148C),
      secondary: Color(0xFF311B92),
      accent: Color(0xFFCE93D8),
      pattern: BankCardPattern.digital,
    ),
    'R4 Banco Microfinanciero': VenezuelanBankBranding(
      bankName: 'R4 Banco Microfinanciero',
      shortLabel: 'R4',
      primary: Color(0xFFC62828),
      secondary: Color(0xFF8E0000),
      accent: Color(0xFFFF8A80),
      pattern: BankCardPattern.diagonalBands,
    ),
    'Venezolano de Crédito': VenezuelanBankBranding(
      bankName: 'Venezolano de Crédito',
      shortLabel: 'VC',
      primary: Color(0xFF003366),
      secondary: Color(0xFF002244),
      accent: Color(0xFF5C9CE6),
      pattern: BankCardPattern.gradient,
    ),
  };
}

enum BankCardPattern {
  gradient,
  diagonalBands,
  waveAccent,
  cornerGlow,
  splitTone,
  circles,
  digital,
}
