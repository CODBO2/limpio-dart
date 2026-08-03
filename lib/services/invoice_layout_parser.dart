import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/invoice_scan_draft.dart';
import 'invoice_amount_utils.dart';
import 'invoice_text_parser.dart';

/// Parses invoice amounts using OCR bounding boxes (layout-aware).
class InvoiceLayoutParser {
  InvoiceLayoutParser({InvoiceTextParser? textParser})
      : _textParser = textParser ?? InvoiceTextParser();

  final InvoiceTextParser _textParser;

  /// Minimum confidence to prefer layout over plain-text fallback.
  static const double minLayoutConfidence = 0.45;

  InvoiceScanDraft parseRecognizedText(RecognizedText recognized) {
    final lines = _extractVisualLines(recognized);
    return parseVisualLines(lines, rawText: recognized.text);
  }

  /// Public for unit tests with synthetic geometry.
  InvoiceScanDraft parseVisualLines(
    List<OcrVisualLine> lines, {
    required String rawText,
  }) {
    if (lines.isEmpty) {
      return _textParser.parse(rawText);
    }

    final layoutResult = _extractAmountFromLayout(lines);
    final textDraft = _textParser.parse(rawText);
    final date = InvoiceAmountUtils.extractDate(rawText);

    if (layoutResult == null ||
        layoutResult.confidence < minLayoutConfidence) {
      final best = _pickBest(layoutResult, textDraft);
      return InvoiceScanDraft(
        rawText: rawText,
        monto: best.amount,
        currency: best.currency,
        date: date.value ?? textDraft.date,
        amountConfidence: best.amountConfidence,
        currencyConfidence: best.currencyConfidence,
        dateConfidence: date.confidence > 0
            ? date.confidence
            : textDraft.dateConfidence,
      );
    }

    final allTexts = lines.map((l) => l.text).toList();
    final currency = InvoiceAmountUtils.detectCurrency(
      allTexts,
      amountLineText: layoutResult.lineText,
    );

    // Prefer layout amount; if text parser has clearly higher confidence, use it.
    if (textDraft.amountConfidence > layoutResult.confidence + 0.15 &&
        textDraft.monto != null) {
      return InvoiceScanDraft(
        rawText: rawText,
        monto: textDraft.monto,
        currency: textDraft.currency ?? currency.value,
        date: date.value ?? textDraft.date,
        amountConfidence: textDraft.amountConfidence,
        currencyConfidence: textDraft.currencyConfidence,
        dateConfidence: date.confidence > 0
            ? date.confidence
            : textDraft.dateConfidence,
      );
    }

    return InvoiceScanDraft(
      rawText: rawText,
      monto: layoutResult.amount,
      currency: currency.value,
      date: date.value ?? textDraft.date,
      amountConfidence: layoutResult.confidence.clamp(0, 1),
      currencyConfidence: currency.confidence,
      dateConfidence: date.confidence > 0
          ? date.confidence
          : textDraft.dateConfidence,
    );
  }

  _PickResult _pickBest(_LayoutAmount? layout, InvoiceScanDraft text) {
    if (layout == null) {
      return _PickResult(
        amount: text.monto,
        currency: text.currency,
        amountConfidence: text.amountConfidence,
        currencyConfidence: text.currencyConfidence,
      );
    }
    if (text.monto == null || layout.confidence >= text.amountConfidence) {
      return _PickResult(
        amount: layout.amount,
        currency: null,
        amountConfidence: layout.confidence,
        currencyConfidence: 0,
      );
    }
    return _PickResult(
      amount: text.monto,
      currency: text.currency,
      amountConfidence: text.amountConfidence,
      currencyConfidence: text.currencyConfidence,
    );
  }

  List<OcrVisualLine> _extractVisualLines(RecognizedText recognized) {
    final raw = <OcrVisualLine>[];
    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.isEmpty) continue;
        raw.add(
          OcrVisualLine(
            text: text,
            box: line.boundingBox,
            elements: line.elements
                .map(
                  (e) => OcrVisualElement(
                    text: e.text,
                    box: e.boundingBox,
                  ),
                )
                .toList(),
          ),
        );
      }
    }

    if (raw.isEmpty) return raw;
    raw.sort((a, b) {
      final dy = a.box.top.compareTo(b.box.top);
      if (dy != 0) return dy;
      return a.box.left.compareTo(b.box.left);
    });

    // Merge lines that sit on roughly the same horizontal band.
    final merged = <OcrVisualLine>[];
    for (final line in raw) {
      if (merged.isEmpty) {
        merged.add(line);
        continue;
      }
      final last = merged.last;
      final height = (last.box.height + line.box.height) / 2;
      final threshold = height * 0.55;
      if ((line.box.top - last.box.top).abs() <= threshold) {
        merged[merged.length - 1] = _mergeLines(last, line);
      } else {
        merged.add(line);
      }
    }
    return merged;
  }

  OcrVisualLine _mergeLines(OcrVisualLine a, OcrVisualLine b) {
    final left = a.box.left <= b.box.left ? a : b;
    final right = a.box.left <= b.box.left ? b : a;
    final elements = [...left.elements, ...right.elements]
      ..sort((x, y) => x.box.left.compareTo(y.box.left));
    final text = elements.map((e) => e.text).join(' ');
    final box = Rect.fromLTRB(
      a.box.left < b.box.left ? a.box.left : b.box.left,
      a.box.top < b.box.top ? a.box.top : b.box.top,
      a.box.right > b.box.right ? a.box.right : b.box.right,
      a.box.bottom > b.box.bottom ? a.box.bottom : b.box.bottom,
    );
    return OcrVisualLine(text: text, box: box, elements: elements);
  }

  _LayoutAmount? _extractAmountFromLayout(List<OcrVisualLine> lines) {
    final candidates = <_LayoutAmount>[];
    final pageBottom = lines.map((l) => l.box.bottom).fold<double>(0, (m, v) {
      return v > m ? v : m;
    });
    final pageTop = lines.map((l) => l.box.top).fold<double>(
      double.infinity,
      (m, v) => v < m ? v : m,
    );
    final pageHeight =
        (pageBottom - pageTop).clamp(1.0, double.infinity).toDouble();

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final norm = InvoiceAmountUtils.normalize(line.text);
      if (!InvoiceAmountUtils.containsAny(
        norm,
        InvoiceAmountUtils.totalKeywords,
      )) {
        continue;
      }

      final labelBoost = InvoiceAmountUtils.containsAny(
            norm,
            InvoiceAmountUtils.strongTotalKeywords,
          )
          ? 0.2
          : 0.0;
      final weakPenalty = InvoiceAmountUtils.containsAny(
            norm,
            InvoiceAmountUtils.weakTotalKeywords,
          )
          ? 0.25
          : 0.0;

      // Same-line amount to the right of label.
      final sameLine = _amountsOnLine(line);
      final acceptedSameLine = <_LineAmount>[];
      for (final amount in sameLine) {
        // Acepta si está a la derecha de la etiqueta, o si es el único
        // monto de una línea ya etiquetada (OCR junta MONTOBs.+cifra).
        if (amount.box.left + 4 >= _labelRight(line) ||
            (sameLine.length == 1 &&
                InvoiceAmountUtils.containsAny(
                  norm,
                  InvoiceAmountUtils.totalKeywords,
                ))) {
          acceptedSameLine.add(amount);
        }
      }
      if (acceptedSameLine.isEmpty &&
          sameLine.isNotEmpty &&
          InvoiceAmountUtils.containsAny(
            norm,
            InvoiceAmountUtils.totalKeywords,
          )) {
        acceptedSameLine.add(sameLine.last);
      }

      for (final amount in acceptedSameLine) {
        var score = 0.55 + labelBoost - weakPenalty;
        score += _verticalPositionScore(line.box.top, pageTop, pageHeight);
        if (amount.hasDecimals) score += 0.18;
        if (InvoiceAmountUtils.looksLikeTotalAmount(amount.value)) score += 0.05;
        if (InvoiceAmountUtils.shouldSkipLine(line.text, norm)) score -= 0.4;
        if (RegExp(r'\bmonto\b').hasMatch(norm)) score += 0.15;
        candidates.add(
          _LayoutAmount(
            amount: amount.value,
            confidence: score,
            lineText: line.text,
          ),
        );
      }

      // Next visual line (label alone, amount below/right).
      if (acceptedSameLine.isEmpty && i + 1 < lines.length) {
        final next = lines[i + 1];
        final nextNorm = InvoiceAmountUtils.normalize(next.text);
        if (InvoiceAmountUtils.containsAny(
          nextNorm,
          InvoiceAmountUtils.negativeKeywords,
        )) {
          continue;
        }
        final nextAmounts = _amountsOnLine(next);
        if (nextAmounts.isEmpty) continue;

        // Prefer rightmost amount on next line.
        final amount = nextAmounts.last;
        var score = 0.5 + labelBoost - weakPenalty;
        score += _verticalPositionScore(next.box.top, pageTop, pageHeight);
        if (amount.hasDecimals) score += 0.18;
        if (InvoiceAmountUtils.looksLikeTotalAmount(amount.value)) score += 0.05;
        // Prefer amount roughly aligned right of label.
        if (amount.box.left >= line.box.left - 20) score += 0.08;
        candidates.add(
          _LayoutAmount(
            amount: amount.value,
            confidence: score,
            lineText: '${line.text} ${next.text}',
          ),
        );
      }
    }

    // Also score rightmost decimal amounts in bottom third without label.
    for (final line in lines) {
      final relativeY = (line.box.top - pageTop) / pageHeight;
      if (relativeY < 0.55) continue;
      final norm = InvoiceAmountUtils.normalize(line.text);
      if (InvoiceAmountUtils.shouldSkipLine(line.text, norm)) continue;
      final amounts = _amountsOnLine(line);
      if (amounts.isEmpty) continue;
      final amount = amounts.last;
      if (!amount.hasDecimals) continue;
      var score = 0.28 + _verticalPositionScore(line.box.top, pageTop, pageHeight);
      if (InvoiceAmountUtils.containsAny(norm, InvoiceAmountUtils.totalKeywords)) {
        score += 0.25;
      }
      candidates.add(
        _LayoutAmount(
          amount: amount.value,
          confidence: score,
          lineText: line.text,
        ),
      );
    }

    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.confidence.compareTo(a.confidence));
    return candidates.first;
  }

  double _labelRight(OcrVisualLine line) {
    for (final el in line.elements) {
      final norm = InvoiceAmountUtils.normalize(el.text);
      if (InvoiceAmountUtils.containsAny(norm, InvoiceAmountUtils.totalKeywords) ||
          InvoiceAmountUtils.containsAny(
            norm,
            ['total', 'monto', 'importe', 'pagar', 'saldo', 'neto'],
          )) {
        return el.box.right;
      }
    }
    // Fallback: left half of line is "label zone".
    return line.box.left + line.box.width * 0.45;
  }

  double _verticalPositionScore(double top, double pageTop, double pageHeight) {
    final relative = ((top - pageTop) / pageHeight).clamp(0.0, 1.0);
    if (relative >= 0.65) return 0.12;
    if (relative >= 0.45) return 0.06;
    return 0;
  }

  List<_LineAmount> _amountsOnLine(OcrVisualLine line) {
    final fromText = InvoiceAmountUtils.extractNumbers(line.text);
    if (fromText.isEmpty) return const [];

    // Map parsed numbers to rightmost elements that look numeric.
    final numericElements = line.elements.where((e) {
      final t = e.text.replaceAll(RegExp(r'[^\d.,]'), '');
      return t.contains(RegExp(r'\d'));
    }).toList();

    final results = <_LineAmount>[];
    for (final parsed in fromText) {
      Rect box = line.box;
      if (numericElements.isNotEmpty) {
        // Prefer element whose token parses to same value, else rightmost.
        OcrVisualElement? match;
        for (final el in numericElements) {
          final v = InvoiceAmountUtils.parseNumberToken(el.text);
          if (v != null && (v - parsed.value).abs() < 0.001) {
            match = el;
            break;
          }
        }
        match ??= numericElements.last;
        box = match.box;
      }
      results.add(
        _LineAmount(
          value: parsed.value,
          hasDecimals: parsed.hasDecimals,
          box: box,
        ),
      );
    }
    results.sort((a, b) => a.box.left.compareTo(b.box.left));
    return results;
  }
}

class OcrVisualLine {
  const OcrVisualLine({
    required this.text,
    required this.box,
    required this.elements,
  });

  final String text;
  final Rect box;
  final List<OcrVisualElement> elements;
}

class OcrVisualElement {
  const OcrVisualElement({
    required this.text,
    required this.box,
  });

  final String text;
  final Rect box;
}

class _LineAmount {
  const _LineAmount({
    required this.value,
    required this.hasDecimals,
    required this.box,
  });

  final double value;
  final bool hasDecimals;
  final Rect box;
}

class _LayoutAmount {
  const _LayoutAmount({
    required this.amount,
    required this.confidence,
    required this.lineText,
  });

  final double amount;
  final double confidence;
  final String lineText;
}

class _PickResult {
  const _PickResult({
    required this.amount,
    required this.currency,
    required this.amountConfidence,
    required this.currencyConfidence,
  });

  final double? amount;
  final String? currency;
  final double amountConfidence;
  final double currencyConfidence;
}
