/// Bancos disponibles al registrar una tarjeta.
///
/// BNC, BDV y Mercantil tienen diseño de tarjeta propio en `assets/Cards/`.
class VenezuelanBanks {
  static const String bnc = 'Banco Nacional de Crédito (BNC)';
  static const String bdv = 'Banco de Venezuela (BDV)';
  static const String mercantil = 'Banco Mercantil';

  static const List<String> all = [bnc, bdv, mercantil];

  static List<String> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((bank) => bank.toLowerCase().contains(q)).toList();
  }
}
