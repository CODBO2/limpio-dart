enum RateType {
  bcv,
  personalizado;

  String get value {
    switch (this) {
      case RateType.bcv:
        return 'bcv';
      case RateType.personalizado:
        return 'personalizado';
    }
  }

  static RateType fromString(String? value) {
    switch (value) {
      case 'personalizado':
        return RateType.personalizado;
      case 'bcv':
      case 'paralelo': // legado → BCV
      default:
        return RateType.bcv;
    }
  }

  String get label {
    switch (this) {
      case RateType.bcv:
        return 'BCV';
      case RateType.personalizado:
        return 'Personalizado';
    }
  }
}
