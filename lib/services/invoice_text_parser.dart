import '../models/invoice_scan_draft.dart';
import 'invoice_amount_utils.dart';

class InvoiceTextParser {
  InvoiceScanDraft parse(String rawText) {
    final cleaned = InvoiceAmountUtils.cleanOcrText(rawText);
    final lines = cleaned
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final normalized = lines.map(InvoiceAmountUtils.normalize).toList();
    final mergedLines = _mergeTotalLines(lines, normalized);
    final amountResult = _extractAmount(
      mergedLines.lines,
      mergedLines.normalized,
      cleaned,
    );
    final currency = InvoiceAmountUtils.detectCurrency(
      mergedLines.lines,
      amountLineIndex: amountResult.lineIndex,
    );
    final date = InvoiceAmountUtils.extractDate(cleaned);

    return InvoiceScanDraft(
      rawText: rawText,
      monto: amountResult.amount,
      currency: currency.value,
      date: date.value,
      amountConfidence: amountResult.confidence,
      currencyConfidence: currency.confidence,
      dateConfidence: date.confidence,
    );
  }

  /// Refina un draft de captura (pago móvil / transferencia) priorizando
  /// montos etiquetados y descartando referencias bancarias.
  InvoiceScanDraft refinePagoMovil(InvoiceScanDraft draft) {
    final reparsed = parse(draft.rawText);
    final pagoHint = _looksLikePagoMovil(draft.rawText);
    final preferred = _extractPagoMovilAmount(draft.rawText);

    final monto = preferred?.amount ??
        (reparsed.amountConfidence >= draft.amountConfidence
            ? reparsed.monto
            : draft.monto) ??
        reparsed.monto ??
        draft.monto;

    final amountConfidence = preferred?.score.clamp(0.0, 1.0) ??
        (reparsed.amountConfidence >= draft.amountConfidence
            ? reparsed.amountConfidence
            : draft.amountConfidence);

    final currency = (pagoHint ||
            reparsed.currency == 'bolivares' ||
            draft.currency == 'bolivares')
        ? 'bolivares'
        : (reparsed.currency ?? draft.currency ?? 'bolivares');

    final date = reparsed.date ?? draft.date;
    final dateConfidence = reparsed.dateConfidence > 0
        ? reparsed.dateConfidence
        : draft.dateConfidence;

    return InvoiceScanDraft(
      rawText: draft.rawText,
      monto: monto,
      currency: currency,
      date: date,
      amountConfidence: amountConfidence,
      currencyConfidence: pagoHint
          ? 0.85
          : (reparsed.currencyConfidence > 0
              ? reparsed.currencyConfidence
              : draft.currencyConfidence),
      dateConfidence: dateConfidence,
    );
  }

  bool _looksLikePagoMovil(String raw) {
    final norm = InvoiceAmountUtils.normalize(raw);
    return InvoiceAmountUtils.containsAny(norm, [
      'pago movil',
      'transferencia',
      'monto debitado',
      'monto transferido',
      'operacion exitosa',
      'comprobante',
      'banco',
    ]);
  }

  _AmountCandidate? _extractPagoMovilAmount(String rawText) {
    final cleaned = InvoiceAmountUtils.cleanOcrText(rawText);
    final lines = cleaned
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    _AmountCandidate? best;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final norm = InvoiceAmountUtils.normalize(line);
      if (InvoiceAmountUtils.shouldSkipLine(line, norm)) continue;

      final labeled = InvoiceAmountUtils.containsAny(norm, [
        'monto',
        'total',
        'importe',
        'debitado',
        'transferido',
        'enviado',
        'abonado',
        'pagar',
      ]);
      final hasBs = norm.contains('bs') || line.toLowerCase().contains('ves');

      // Misma línea: "Monto Bs. 1.234,56"
      for (final n in InvoiceAmountUtils.extractNumbers(line)) {
        if (n.value <= 0) continue;
        var score = 0.2;
        if (labeled) score += 0.55;
        if (hasBs) score += 0.2;
        if (n.hasDecimals) score += 0.2;
        if (InvoiceAmountUtils.looksLikeTotalAmount(n.value)) score += 0.05;
        if (best == null || score > best.score) {
          best = _AmountCandidate(amount: n.value, score: score, lineIndex: i);
        }
      }

      // Línea siguiente al label "Monto"
      if (labeled &&
          InvoiceAmountUtils.extractNumbers(line).isEmpty &&
          i + 1 < lines.length) {
        final next = lines[i + 1];
        final nextNorm = InvoiceAmountUtils.normalize(next);
        if (InvoiceAmountUtils.shouldSkipLine(next, nextNorm)) continue;
        for (final n in InvoiceAmountUtils.extractNumbers(next)) {
          if (n.value <= 0) continue;
          var score = 0.7;
          if (n.hasDecimals) score += 0.18;
          if (nextNorm.contains('bs')) score += 0.12;
          if (best == null || score > best.score) {
            best = _AmountCandidate(
              amount: n.value,
              score: score,
              lineIndex: i + 1,
            );
          }
        }
      }
    }

    if (best == null || best.score < 0.45) return null;
    return best;
  }

  _MergedLines _mergeTotalLines(List<String> lines, List<String> normalized) {
    final merged = <String>[];
    final mergedNorm = <String>[];

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      var norm = normalized[i];

      if (InvoiceAmountUtils.containsAny(norm, InvoiceAmountUtils.totalKeywords) &&
          InvoiceAmountUtils.extractNumbers(line).isEmpty &&
          i + 1 < lines.length) {
        final next = lines[i + 1];
        final nextNorm = normalized[i + 1];
        if (InvoiceAmountUtils.extractNumbers(next).isNotEmpty &&
            !InvoiceAmountUtils.containsAny(
              nextNorm,
              InvoiceAmountUtils.negativeKeywords,
            )) {
          line = '$line $next';
          norm = '$norm $nextNorm';
        }
      }

      merged.add(line);
      mergedNorm.add(norm);
    }

    return _MergedLines(lines: merged, normalized: mergedNorm);
  }

  _AmountResult _extractAmount(
    List<String> lines,
    List<String> normalized,
    String rawText,
  ) {
    final candidates = <_AmountCandidate>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final norm = normalized[i];
      if (InvoiceAmountUtils.shouldSkipLine(line, norm)) continue;

      final numbers = InvoiceAmountUtils.extractNumbers(line);
      if (numbers.isEmpty) continue;

      var lineScore = 0.0;
      if (InvoiceAmountUtils.containsAny(norm, InvoiceAmountUtils.totalKeywords)) {
        lineScore += 0.55;
      }
      if (InvoiceAmountUtils.containsAny(
        norm,
        InvoiceAmountUtils.strongTotalKeywords,
      )) {
        lineScore += 0.15;
      }
      if (InvoiceAmountUtils.containsAny(
        norm,
        InvoiceAmountUtils.weakTotalKeywords,
      )) {
        lineScore -= 0.2;
      }
      if (norm.contains('bs') || norm.contains('usd') || line.contains('\$')) {
        lineScore += 0.12;
      }
      // Etiqueta explícita de monto en voucher POS.
      if (RegExp(r'\bmonto\b').hasMatch(norm)) {
        lineScore += 0.2;
      }
      if (i >= (lines.length * 0.45).floor()) lineScore += 0.08;

      for (var j = 0; j < numbers.length; j++) {
        final n = numbers[j].value;
        if (n <= 0) continue;

        var score = lineScore;
        if (numbers[j].hasDecimals) score += 0.18;
        if (j == numbers.length - 1) score += 0.08;
        if (InvoiceAmountUtils.looksLikeTotalAmount(n)) score += 0.05;
        // Enteros sueltos (ticket, lote, autorización) sin decimales.
        if (!numbers[j].hasDecimals && n >= 100) score -= 0.25;
        if (InvoiceAmountUtils.containsAny(
          norm,
          InvoiceAmountUtils.negativeKeywords,
        )) {
          score -= 0.35;
        }
        if (InvoiceAmountUtils.rifPattern.hasMatch(line)) score -= 0.5;

        candidates.add(_AmountCandidate(amount: n, score: score, lineIndex: i));
      }
    }

    for (final match in InvoiceAmountUtils.inlineTotalPattern.allMatches(rawText)) {
      final token = match.group(2);
      if (token == null) continue;
      final parsed = InvoiceAmountUtils.parseNumberToken(
        InvoiceAmountUtils.normalizeSpacedAmounts(token),
      );
      if (parsed == null || parsed <= 0) continue;
      var score = 0.82;
      if (RegExp(r'[.,]\d{1,2}\s*$').hasMatch(token.trim())) score += 0.08;
      if (match.group(0)!.toLowerCase().contains('monto')) score += 0.06;
      candidates.add(
        _AmountCandidate(
          amount: parsed,
          score: score,
          lineIndex: _lineIndexForMatch(rawText, match.start, lines),
        ),
      );
    }

    if (candidates.isEmpty) {
      final fallback = _fallbackAmount(lines);
      if (fallback != null) {
        return _AmountResult(
          amount: fallback.amount,
          confidence: fallback.score.clamp(0, 1),
          lineIndex: fallback.lineIndex,
        );
      }
      return const _AmountResult(amount: null, confidence: 0, lineIndex: -1);
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));
    final best = candidates.first;
    return _AmountResult(
      amount: best.amount,
      confidence: best.score.clamp(0, 1),
      lineIndex: best.lineIndex,
    );
  }

  int _lineIndexForMatch(String rawText, int offset, List<String> lines) {
    var cursor = 0;
    for (var i = 0; i < lines.length; i++) {
      final start = rawText.indexOf(lines[i], cursor);
      if (start == -1) continue;
      final end = start + lines[i].length;
      if (offset >= start && offset <= end) return i;
      cursor = end;
    }
    return lines.isEmpty ? -1 : lines.length - 1;
  }

  _AmountCandidate? _fallbackAmount(List<String> lines) {
    _AmountCandidate? best;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final norm = InvoiceAmountUtils.normalize(line);
      if (InvoiceAmountUtils.shouldSkipLine(line, norm)) continue;

      for (final parsed in InvoiceAmountUtils.extractNumbers(line)) {
        final n = parsed.value;
        if (n <= 0 || !InvoiceAmountUtils.looksLikeTotalAmount(n)) continue;

        var score = 0.22;
        if (parsed.hasDecimals) score += 0.12;
        if (line.contains('\$') || norm.contains('bs')) score += 0.08;
        if (i >= (lines.length * 0.5).floor()) score += 0.06;

        if (best == null || score > best.score) {
          best = _AmountCandidate(amount: n, score: score, lineIndex: i);
        }
      }
    }
    return best;
  }
}

class _MergedLines {
  const _MergedLines({required this.lines, required this.normalized});

  final List<String> lines;
  final List<String> normalized;
}

class _AmountCandidate {
  const _AmountCandidate({
    required this.amount,
    required this.score,
    required this.lineIndex,
  });

  final double amount;
  final double score;
  final int lineIndex;
}

class _AmountResult {
  const _AmountResult({
    required this.amount,
    required this.confidence,
    required this.lineIndex,
  });

  final double? amount;
  final double confidence;
  final int lineIndex;
}
