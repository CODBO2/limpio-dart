class ParsedAmountNumber {
  const ParsedAmountNumber({required this.value, required this.hasDecimals});

  final double value;
  final bool hasDecimals;
}

class InvoiceAmountUtils {
  static const totalKeywords = [
    'total',
    'monto',
    'importe',
    'subtotal',
    'pagar',
    'amount due',
    'grand total',
    'total a pagar',
    'total general',
    'total factura',
    'total venta',
    'monto total',
    'valor total',
    'neto',
    'saldo',
    'debe',
    'contado',
    'efectivo',
    'a pagar',
    'pago movil',
    'pago móvil',
    'monto debitado',
    'monto transferido',
    'monto enviado',
    'monto abonado',
    'transferencia exitosa',
  ];

  static const strongTotalKeywords = [
    'total a pagar',
    'total general',
    'total factura',
    'total venta',
    'monto total',
    'valor total',
    'grand total',
    'amount due',
    'a pagar',
    'monto debitado',
    'monto transferido',
    'monto enviado',
    'monto abonado',
    'pago movil',
    'pago móvil',
  ];

  static const weakTotalKeywords = [
    'subtotal',
    'subttl',
    'iva',
    'descuento',
    'exento',
    'cambio',
    'bi g',
  ];

  static const negativeKeywords = [
    'rif',
    'nit',
    'telefono',
    'tel',
    'celular',
    'serial',
    'factura n',
    'factura no',
    'control',
    'cantidad',
    'cant.',
    'unid',
    'precio unit',
    'unitario',
    'descuento',
    'iva ',
    'exento',
    'cliente',
    'cajero',
    'caja',
    'referencia',
    'comprobante',
    'cuenta',
    'cedula',
    'cédula',
    'banco destino',
    'banco origen',
    'codigo',
    'código',
  ];

  static final rifPattern = RegExp(
    r'\b[JVEGPC]-?\d{6,12}\b',
    caseSensitive: false,
  );

  static final inlineTotalPattern = RegExp(
    r'(total|monto(?:\s*(?:bs\.?|total|debitado|transferido|enviado|abonado))?|importe|subtotal|pagar|saldo|neto)\s*[:.\-]?\s*'
    r'((?:Bs\.?\s*)?\d[\d\s.,]*|\$?\s*\d[\d\s.,]+)',
    caseSensitive: false,
  );

  static const _monthNames = <String, int>{
    'ene': 1,
    'enero': 1,
    'feb': 2,
    'febrero': 2,
    'mar': 3,
    'marzo': 3,
    'abr': 4,
    'abril': 4,
    'may': 5,
    'mayo': 5,
    'jun': 6,
    'junio': 6,
    'jul': 7,
    'julio': 7,
    'ago': 8,
    'agosto': 8,
    'sep': 9,
    'sept': 9,
    'septiembre': 9,
    'oct': 10,
    'octubre': 10,
    'nov': 11,
    'noviembre': 11,
    'dic': 12,
    'diciembre': 12,
  };

  static String cleanOcrText(String rawText) {
    return rawText
        .replaceAll('\u00A0', ' ')
        .replaceAll(RegExp(r'[|¦]'), '1')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }

  static String normalize(String line) {
    var t = line
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[^a-z0-9$.,:\s-]'), ' ');
    // Vouchers POS: "MONTOBs." / "TOTALBs." pegados.
    t = t
        .replaceAll('montobs', 'monto bs')
        .replaceAll('totalbs', 'total bs')
        .replaceAll('importebs', 'importe bs');
    return t;
  }

  static bool containsAny(String text, List<String> keywords) {
    for (final k in keywords) {
      if (text.contains(k)) return true;
    }
    return false;
  }

  static bool looksLikeTotalAmount(double value) {
    return value >= 0.01 && value <= 999999999.99;
  }

  static bool shouldSkipLine(String line, String norm) {
    if (rifPattern.hasMatch(line)) return true;
    if (containsAny(norm, [
      'referencia',
      'cedula',
      'cédula',
      'telefono',
      'celular',
      'cuenta',
    ])) {
      return true;
    }
    final digitsOnly = line.replaceAll(RegExp(r'[^\d]'), '');
    // Códigos/referencias largas (≥9 dígitos sin decimales de monto).
    if (digitsOnly.length >= 9 && !RegExp(r'[.,]\d{2}\b').hasMatch(line)) {
      return true;
    }
    if (RegExp(r'\b(19|20)\d{2}\b').hasMatch(line) &&
        !containsAny(norm, totalKeywords)) {
      return true;
    }
    return false;
  }

  static String normalizeSpacedAmounts(String line) {
    var s = line.replaceAllMapped(
      RegExp(r'\d{1,3}(?: \d{3})+(?:[.,]\d{2})?'),
      (match) => match.group(0)!.replaceAll(' ', ''),
    );
    // OCR inserta espacios alrededor de separadores: "1 .043 , 89" → "1.043,89"
    for (var i = 0; i < 3; i++) {
      s = s.replaceAllMapped(
        RegExp(r'(\d)\s*([.,])\s*(\d)'),
        (m) => '${m[1]}${m[2]}${m[3]}',
      );
    }
    return s;
  }

  static double? parseNumberToken(String token) {
    var t = token.trim();
    if (t.isEmpty) return null;

    t = t.replaceAll(RegExp(r'Bs\.?\s*', caseSensitive: false), '');
    t = t.replaceAll('\$', '');
    t = t.replaceAll(' ', '');
    t = t
        .replaceAll('O', '0')
        .replaceAll('o', '0')
        .replaceAll('l', '1')
        .replaceAll('I', '1')
        .replaceAll('S', '5')
        .replaceAll('s', '5');
    t = t.replaceAll(RegExp(r'[^\d.,]'), '');
    if (t.isEmpty || !RegExp(r'\d').hasMatch(t)) return null;

    return _interpretAmount(t);
  }

  /// Reglas de formato:
  /// - Grande: `xx.xxx,xx` | `xx,xxx.xx` | `xxxxx.xx` | `xxxxx,xx`
  /// - Pequeño: `xx.xx` | `xx,xx`
  static double? _interpretAmount(String t) {
    final lastComma = t.lastIndexOf(',');
    final lastDot = t.lastIndexOf('.');

    // Ambos separadores: el último indica decimales.
    if (lastComma >= 0 && lastDot >= 0) {
      if (lastComma > lastDot) {
        // 20.114,16 → 20114.16
        return double.tryParse(t.replaceAll('.', '').replaceAll(',', '.'));
      }
      // 20,114.16 → 20114.16
      return double.tryParse(t.replaceAll(',', ''));
    }

    if (lastComma >= 0) {
      final parts = t.split(',');
      if (parts.length == 2 && parts[1].length <= 2) {
        // xxxxx,xx (grande) o xx,xx (pequeño): la coma es decimal.
        return double.tryParse('${parts[0]}.${parts[1]}');
      }
      if (parts.length > 2 && parts.last.length <= 2) {
        // 20,114,16
        final whole = parts.sublist(0, parts.length - 1).join();
        return double.tryParse('$whole.${parts.last}');
      }
      // 1,234,567 miles
      return double.tryParse(parts.join());
    }

    if (lastDot >= 0) {
      final parts = t.split('.');
      if (parts.length == 2) {
        final whole = parts[0];
        final frac = parts[1];
        if (frac.length <= 2) {
          // xxxxx.xx o xx.xx: el punto es decimal.
          return double.tryParse(t);
        }
        if (frac.length == 3) {
          // 20.114 → miles sin decimales
          return double.tryParse('$whole$frac');
        }
        // OCR perdió la coma decimal: 20.11416 → 20114.16
        return double.tryParse(
          '$whole${frac.substring(0, 3)}.${frac.substring(3)}',
        );
      }
      if (parts.length > 2) {
        final last = parts.last;
        if (last.length <= 2) {
          // 20.114.16 → 20114.16
          final whole = parts.sublist(0, parts.length - 1).join();
          return double.tryParse('$whole.$last');
        }
        if (parts.skip(1).every((p) => p.length == 3)) {
          return double.tryParse(parts.join());
        }
      }
    }

    return double.tryParse(t.replaceAll(RegExp(r'[^\d]'), ''));
  }

  static List<ParsedAmountNumber> extractNumbers(String line) {
    final normalizedLine = normalizeSpacedAmounts(line);
    // Orden: formatos grandes primero; los pequeños no pueden ser prefijo
    // de un número más largo (evita tomar 20.11 de 20.114,16).
    final patterns = <RegExp>[
      // VE con miles: 20.114,16 / 1.043,89
      RegExp(r'(\d{1,3}(?:\.\d{3})+,\d{2})'),
      // OCR VE con punto decimal erróneo: 1.043.89 → 1043.89
      RegExp(r'(\d{1,3}(?:\.\d{3})+\.\d{2})'),
      // US con miles: 20,114.16
      RegExp(r'(\d{1,3}(?:,\d{3})+\.\d{2})'),
      // Plano grande (≥4 enteros): 20114,16 / 20114.16 / 1043,89
      RegExp(r'(\d{4,}[.,]\d{2})'),
      // Miles VE sin decimales: 20.114
      RegExp(r'(\d{1,3}(?:\.\d{3})+)(?![,\d])'),
      // Pequeño: 20,11 / 20.11 — no seguido ni precedido de más dígitos/separadores
      RegExp(r'(?<![\d.,])(\d{1,3}[.,]\d{2})(?![\d.,])'),
      // Entero suelto (fallback)
      RegExp(r'(?<![\d.,])(\d{1,6})(?![\d.,])'),
    ];

    final rawMatches = <_RawNumberMatch>[];

    for (final pattern in patterns) {
      for (final match in pattern.allMatches(normalizedLine)) {
        final token = match.group(1);
        if (token == null) continue;
        rawMatches.add(
          _RawNumberMatch(
            start: match.start,
            end: match.end,
            token: token,
          ),
        );
      }
    }

    // También capturar montos con prefijo/sufijo Bs o $.
    for (final match in RegExp(
      r'Bs\.?\s*(\d{1,3}(?:\.\d{3})+[.,]\d{2}|\d{4,}[.,]\d{2}|\d{1,3}[.,]\d{2})',
      caseSensitive: false,
    ).allMatches(normalizedLine)) {
      final token = match.group(1);
      if (token == null) continue;
      rawMatches.add(
        _RawNumberMatch(start: match.start, end: match.end, token: token),
      );
    }
    for (final match in RegExp(
      r'\$\s*(\d{1,3}(?:,\d{3})*\.\d{2}|\d{1,3}\.\d{2}|\d+)',
    ).allMatches(normalizedLine)) {
      final token = match.group(1);
      if (token == null) continue;
      rawMatches.add(
        _RawNumberMatch(start: match.start, end: match.end, token: token),
      );
    }

    rawMatches.sort((a, b) => b.length.compareTo(a.length));

    final results = <ParsedAmountNumber>[];
    final seen = <String>{};

    for (final match in rawMatches) {
      final overlapsLonger = rawMatches.any(
        (other) =>
            other.length > match.length &&
            match.start >= other.start &&
            match.end <= other.end,
      );
      if (overlapsLonger) continue;

      // Descarta prefijos numéricos: 20.11 dentro de 20.114,16
      final extendsFurther = normalizedLine.length > match.end &&
          RegExp(r'[\d.,]').hasMatch(normalizedLine[match.end]);
      if (extendsFurther) continue;

      final parsed = parseNumberToken(match.token);
      if (parsed == null) continue;

      final key = parsed.toStringAsFixed(2);
      if (seen.contains(key)) continue;
      seen.add(key);

      results.add(
        ParsedAmountNumber(
          value: parsed,
          hasDecimals: RegExp(r'[.,]\d{1,2}$').hasMatch(match.token.trim()),
        ),
      );
    }

    return results;
  }

  static ({String? value, double confidence}) detectCurrency(
    List<String> lines, {
    int amountLineIndex = -1,
    String? amountLineText,
  }) {
    final searchLines = <String>[];
    if (amountLineText != null && amountLineText.isNotEmpty) {
      searchLines.add(amountLineText);
    }
    if (amountLineIndex >= 0 && amountLineIndex < lines.length) {
      if (amountLineIndex > 0) searchLines.add(lines[amountLineIndex - 1]);
      searchLines.add(lines[amountLineIndex]);
      if (amountLineIndex < lines.length - 1) {
        searchLines.add(lines[amountLineIndex + 1]);
      }
    } else {
      searchLines.addAll(lines.take(12));
    }

    var bsScore = 0.0;
    var usdScore = 0.0;

    for (final line in searchLines) {
      final lower = line.toLowerCase();
      if (RegExp(r'\bbs\.?\b').hasMatch(lower) || lower.contains('ves')) {
        bsScore += 1;
      }
      if (lower.contains('usd') || line.contains('\$')) usdScore += 1;
    }

    for (final line in lines) {
      final lower = line.toLowerCase();
      if (RegExp(r'\bbs\.?\b').hasMatch(lower)) bsScore += 0.2;
      if (line.contains('\$')) usdScore += 0.2;
    }

    if (usdScore > bsScore && usdScore > 0) {
      return (value: 'dollars', confidence: 0.7);
    }
    if (bsScore > 0) {
      return (value: 'bolivares', confidence: 0.75);
    }
    return (value: 'bolivares', confidence: 0.35);
  }

  static ({DateTime? value, double confidence}) extractDate(String rawText) {
    final now = DateTime.now();
    // Normaliza separadores y dígitos OCR antes de buscar fechas.
    final text = _normalizeDateText(rawText);
    final candidates = <_DateCandidate>[];

    // Separadores de fecha: / - . o espacio (OCR a veces pierde el símbolo).
    const sep = r'[/\-. ]';

    // 1) Fecha etiquetada: "Fecha: 30/07/2026" | "Fecha 30-07-2026"
    final labeled = RegExp(
      r'fech[ao]?\s*[:.\-]?\s*(\d{1,2})' + sep + r'(\d{1,2})' + sep + r'(\d{2,5})',
      caseSensitive: false,
    );
    for (final match in labeled.allMatches(text)) {
      final parsed = _parseNumericDateParts(
        match.group(1)!,
        match.group(2)!,
        match.group(3)!,
        labeled: true,
      );
      if (parsed == null) continue;
      candidates.add(
        _DateCandidate(
          day: parsed.day,
          month: parsed.month,
          year: parsed.year,
          start: match.start,
          score: 120 + _yearRecencyScore(parsed.year, now),
          yearDigits: parsed.yearDigits,
          labeled: true,
        ),
      );
    }

    // 2) Fechas con año de 4 dígitos: 30/07/2026 | 30-07-2026 | 25-07-2026
    final withFullYear = RegExp(
      r'(?<![\d])(\d{1,2})' + sep + r'(\d{1,2})' + sep + r'(20\d{2})(?!\d)',
    );
    for (final match in withFullYear.allMatches(text)) {
      if (_looksLikeVersion(text, match.start, match.group(0)!)) continue;

      final parsed = _parseNumericDateParts(
        match.group(1)!,
        match.group(2)!,
        match.group(3)!,
      );
      if (parsed == null) continue;

      var score = 40.0 + _yearRecencyScore(parsed.year, now);
      if (_hasDateLabelNear(text, match.start)) score += 50;
      if (_extractTimeNear(text, match.start) != null) score += 15;
      if (_hasHoraLabelNear(text, match.start)) score += 20;
      // Preferir / o - sobre punto (el punto choca con versiones).
      final raw = match.group(0)!;
      if (raw.contains('/') || raw.contains('-')) score += 10;

      candidates.add(
        _DateCandidate(
          day: parsed.day,
          month: parsed.month,
          year: parsed.year,
          start: match.start,
          score: score,
          yearDigits: 4,
          labeled: _hasDateLabelNear(text, match.start),
        ),
      );
    }

    // 3) Fecha corta yy solo si está etiquetada o junto a hora (evitar 09.06.06).
    final shortYear = RegExp(
      r'(?<![\d])(\d{1,2})([/\-.])(\d{1,2})\2(\d{2})(?!\d)',
    );
    for (final match in shortYear.allMatches(text)) {
      final token = match.group(0)!;
      if (_looksLikeVersion(text, match.start, token)) continue;
      // Triple con puntos y 2 dígitos = firmware (09.06.06), no fecha.
      if (token.contains('.') && !_hasDateLabelNear(text, match.start)) {
        continue;
      }

      final nearLabel = _hasDateLabelNear(text, match.start);
      final nearTime = _extractTimeNear(text, match.start) != null;
      if (!nearLabel && !nearTime) continue;

      final parsed = _parseNumericDateParts(
        match.group(1)!,
        match.group(3)!,
        match.group(4)!,
        labeled: nearLabel,
      );
      if (parsed == null) continue;

      var score = 5.0 + _yearRecencyScore(parsed.year, now);
      if (nearLabel) score += 40;
      if (nearTime) score += 15;

      candidates.add(
        _DateCandidate(
          day: parsed.day,
          month: parsed.month,
          year: parsed.year,
          start: match.start,
          score: score,
          yearDigits: 2,
          labeled: nearLabel,
        ),
      );
    }

    // 4) Textual: "30 jul 2026" / "30 de julio de 2026"
    final textual = RegExp(
      r'(\d{1,2})\s+(?:de\s+)?([A-Za-záéíóúñÁÉÍÓÚÑ\.]+)\s+(?:de\s+)?(20\d{2})',
      unicode: true,
    );
    for (final match in textual.allMatches(text)) {
      final day = int.tryParse(match.group(1)!);
      final monthKey = match
          .group(2)!
          .toLowerCase()
          .replaceAll('.', '')
          .replaceAll('á', 'a')
          .replaceAll('é', 'e')
          .replaceAll('í', 'i')
          .replaceAll('ó', 'o')
          .replaceAll('ú', 'u');
      final month = _monthNames[monthKey];
      final year = int.tryParse(match.group(3)!);
      if (day == null ||
          month == null ||
          year == null ||
          day < 1 ||
          day > 31) {
        continue;
      }
      var score = 55.0 + _yearRecencyScore(year, now);
      if (_extractTimeNear(text, match.start) != null) score += 15;
      candidates.add(
        _DateCandidate(
          day: day,
          month: month,
          year: year,
          start: match.start,
          score: score,
          yearDigits: 4,
          labeled: false,
        ),
      );
    }

    if (candidates.isEmpty) return (value: null, confidence: 0);

    // Si hay alguna con año de 4 dígitos, ignora las de 2 dígitos.
    final fullYearOnes = candidates.where((c) => c.yearDigits >= 4).toList();
    final pool = fullYearOnes.isNotEmpty ? fullYearOnes : candidates;

    // Descarta años absurdamente viejos salvo que vengan etiquetados.
    final filtered = pool.where((c) {
      final delta = (c.year - now.year).abs();
      if (c.labeled) return delta <= 15;
      return delta <= 2;
    }).toList();

    final usable = filtered.isNotEmpty ? filtered : pool;
    usable.sort((a, b) => b.score.compareTo(a.score));
    final best = usable.first;
    final time = _extractTimeNear(text, best.start) ??
        _extractLabeledTime(text);

    final confidence = best.score >= 80
        ? 0.95
        : best.score >= 40
            ? 0.85
            : 0.6;

    return (
      value: DateTime(
        best.year,
        best.month,
        best.day,
        time?.hour ?? 0,
        time?.minute ?? 0,
      ),
      confidence: confidence,
    );
  }

  /// Corrige dígitos OCR y unifica separadores raros en el texto de fechas.
  static String _normalizeDateText(String raw) {
    var text = raw
        .replaceAll('／', '/')
        .replaceAll('∕', '/')
        .replaceAll('⁄', '/')
        .replaceAll('－', '-')
        .replaceAll('–', '-')
        .replaceAll('—', '-');
    // O/I confundidos con 0/1 dentro de tokens tipo fecha.
    text = text.replaceAllMapped(
      RegExp(r'(?<=[\d/\-. ])[Oo](?=[\d/\-. ])'),
      (_) => '0',
    );
    text = text.replaceAllMapped(
      RegExp(r'(?<=[\d/\-. ])[Il](?=[\d/\-. ])'),
      (_) => '1',
    );
    return text;
  }

  static ({int day, int month, int year, int yearDigits})? _parseNumericDateParts(
    String dayStr,
    String monthStr,
    String yearStr, {
    bool labeled = false,
  }) {
    final day = int.tryParse(dayStr);
    final month = int.tryParse(monthStr);
    var yearRaw = yearStr.replaceAll(RegExp(r'[^\d]'), '');
    // OCR a veces pega un dígito extra: 20261 → 2026
    if (yearRaw.length > 4 && yearRaw.startsWith('20')) {
      yearRaw = yearRaw.substring(0, 4);
    }
    var year = int.tryParse(yearRaw);
    if (day == null || month == null || year == null) return null;
    final yearDigits = yearRaw.length;
    if (year < 100) year += 2000;
    if (month < 1 ||
        month > 12 ||
        day < 1 ||
        day > 31 ||
        year < 2000 ||
        year > 2100) {
      return null;
    }
    // Sin etiqueta, no aceptar años muy lejanos (firmware 2006, etc.).
    if (!labeled) {
      final nowYear = DateTime.now().year;
      if ((year - nowYear).abs() > 5) return null;
    }
    return (day: day, month: month, year: year, yearDigits: yearDigits);
  }

  /// Firmware / software: "V 09.06.06", "V09.06.06", "Ver 1.2.3"
  static bool _looksLikeVersion(String text, int start, [String? token]) {
    final beforeStart = (start - 10).clamp(0, text.length);
    final prefix = text.substring(beforeStart, start).toLowerCase();
    if (RegExp(r'\bv\.?\s*$').hasMatch(prefix)) return true;
    if (RegExp(r'ver(?:sion)?\s*$').hasMatch(prefix)) return true;
    final after = text.substring(start, (start + 28).clamp(0, text.length));
    if (RegExp(r'platco', caseSensitive: false).hasMatch(after)) return true;
    // 09.06.06 / 09.06.06 — tres grupos de exactamente 2 dígitos con puntos.
    final t = token ?? '';
    if (RegExp(r'^\d{2}\.\d{2}\.\d{2}$').hasMatch(t.trim())) return true;
    return false;
  }

  static bool _hasDateLabelNear(String text, int around) {
    final start = (around - 24).clamp(0, text.length);
    final window = text.substring(start, around).toLowerCase();
    return RegExp(r'fech[ao]?').hasMatch(window);
  }

  static bool _hasHoraLabelNear(String text, int around) {
    final start = (around - 30).clamp(0, text.length);
    final end = (around + 40).clamp(0, text.length);
    final window = text.substring(start, end).toLowerCase();
    return window.contains('hora');
  }

  static double _yearRecencyScore(int year, DateTime now) {
    final delta = (year - now.year).abs();
    if (delta == 0) return 20;
    if (delta == 1) return 12;
    if (delta <= 3) return 5;
    if (delta <= 10) return -10;
    return -40; // p.ej. 2006 vs 2026
  }

  static ({int hour, int minute})? _extractLabeledTime(String text) {
    final match = RegExp(
      r'hora\s*[:\-]?\s*(\d{1,2}):(\d{2})(?::\d{2})?\s*(a\.?\s*m\.?|p\.?\s*m\.?)?',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) return null;
    return _parseClock(
      match.group(1)!,
      match.group(2)!,
      match.group(3),
    );
  }

  static ({int hour, int minute})? _extractTimeNear(String text, int around) {
    final windowStart = (around - 10).clamp(0, text.length);
    final windowEnd = (around + 50).clamp(0, text.length);
    final window = text.substring(windowStart, windowEnd);
    final match = RegExp(
      r'(\d{1,2}):(\d{2})(?::\d{2})?\s*(a\.?\s*m\.?|p\.?\s*m\.?)?',
      caseSensitive: false,
    ).firstMatch(window);
    if (match == null) return null;
    return _parseClock(
      match.group(1)!,
      match.group(2)!,
      match.group(3),
    );
  }

  static ({int hour, int minute})? _parseClock(
    String hourStr,
    String minuteStr,
    String? ampm,
  ) {
    var hour = int.tryParse(hourStr);
    final minute = int.tryParse(minuteStr);
    if (hour == null || minute == null) return null;
    if (minute > 59) return null;

    final marker = (ampm ?? '').toLowerCase().replaceAll(RegExp(r'[\s.]'), '');
    if (marker == 'pm' || marker == 'p') {
      if (hour < 12) hour += 12;
    } else if (marker == 'am' || marker == 'a') {
      if (hour == 12) hour = 0;
    }
    if (hour > 23) return null;
    return (hour: hour, minute: minute);
  }
}

class _DateCandidate {
  const _DateCandidate({
    required this.day,
    required this.month,
    required this.year,
    required this.start,
    required this.score,
    required this.yearDigits,
    required this.labeled,
  });

  final int day;
  final int month;
  final int year;
  final int start;
  final double score;
  final int yearDigits;
  final bool labeled;
}

class _RawNumberMatch {
  const _RawNumberMatch({
    required this.start,
    required this.end,
    required this.token,
  });

  final int start;
  final int end;
  final String token;

  int get length => end - start;
}
