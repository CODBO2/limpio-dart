/// Bancos disponibles al registrar una tarjeta.
///
/// Por ahora solo BNC tiene diseño de tarjeta propio en `assets/Cards/`.
class VenezuelanBanks {
  static const String bnc = 'Banco Nacional de Crédito (BNC)';

  static const List<String> all = [bnc];

  static List<String> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((bank) => bank.toLowerCase().contains(q)).toList();
  }
}
