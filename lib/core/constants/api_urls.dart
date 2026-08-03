class ApiUrls {
  static const dolarBcv = 'https://ve.dolarapi.com/v1/dolares/oficial';
  static const dolarParalelo = 'https://ve.dolarapi.com/v1/dolares/paralelo';

  static String historicoOficial(DateTime date) =>
      'https://ve.dolarapi.com/v1/historicos/dolares/oficial/${_pathDate(date)}';

  static String historicoParalelo(DateTime date) =>
      'https://ve.dolarapi.com/v1/historicos/dolares/paralelo/${_pathDate(date)}';

  static String _pathDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y/$m/$d';
  }
}
