enum RateType {
  bcv,
  paralelo,
  personalizado;

  String get value {
    switch (this) {
      case RateType.bcv:
        return 'bcv';
      case RateType.paralelo:
        return 'paralelo';
      case RateType.personalizado:
        return 'personalizado';
    }
  }

  static RateType fromString(String? value) {
    switch (value) {
      case 'bcv':
        return RateType.bcv;
      case 'personalizado':
        return RateType.personalizado;
      default:
        return RateType.paralelo;
    }
  }

  String get label {
    switch (this) {
      case RateType.bcv:
        return 'BCV';
      case RateType.paralelo:
        return 'Paralelo';
      case RateType.personalizado:
        return 'Personalizado';
    }
  }
}
