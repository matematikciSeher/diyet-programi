import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/models/progress_report.dart';

/// Zamana göre kilo çizgi grafiği. Hedef kilo grafiğin aralığına yakınsa
/// kesikli çizgiyle gösterilir.
class WeightChart extends StatelessWidget {
  const WeightChart({
    super.key,
    required this.points,
    required this.formatWeight,
    required this.formatDate,
    this.targetKg,
    this.targetLabel,
    this.height = 200,
  }) : assert(points.length >= 2);

  final List<WeightPoint> points;
  final double? targetKg;
  final String? targetLabel;
  final String Function(double kg) formatWeight;
  final String Function(DateTime date) formatDate;
  final double height;

  /// Hedef bu kadar kg'dan uzaktaysa grafiği sıkıştırmamak için çizilmez.
  static const _targetReachKg = 3.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kgs = points.map((p) => p.kg);
    var minKg = kgs.reduce(math.min);
    var maxKg = kgs.reduce(math.max);
    final target = targetKg;
    final showTarget =
        target != null &&
        target >= minKg - _targetReachKg &&
        target <= maxKg + _targetReachKg;
    if (showTarget) {
      minKg = math.min(minKg, target);
      maxKg = math.max(maxKg, target);
    }
    final pad = math.max(0.5, (maxKg - minKg) * 0.12);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _WeightChartPainter(
          points: points,
          minKg: minKg - pad,
          maxKg: maxKg + pad,
          targetKg: showTarget ? target : null,
          targetLabel: targetLabel,
          lineColor: theme.colorScheme.primary,
          targetColor: theme.colorScheme.tertiary,
          gridColor: theme.colorScheme.outlineVariant,
          labelStyle:
              theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ) ??
              const TextStyle(fontSize: 11),
          formatWeight: formatWeight,
          formatDate: formatDate,
          textDirection: Directionality.of(context),
        ),
      ),
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  _WeightChartPainter({
    required this.points,
    required this.minKg,
    required this.maxKg,
    required this.targetKg,
    required this.targetLabel,
    required this.lineColor,
    required this.targetColor,
    required this.gridColor,
    required this.labelStyle,
    required this.formatWeight,
    required this.formatDate,
    required this.textDirection,
  });

  final List<WeightPoint> points;
  final double minKg;
  final double maxKg;
  final double? targetKg;
  final String? targetLabel;
  final Color lineColor;
  final Color targetColor;
  final Color gridColor;
  final TextStyle labelStyle;
  final String Function(double) formatWeight;
  final String Function(DateTime) formatDate;
  final TextDirection textDirection;

  static const _gridLines = 3;
  static const _bottomLabelHeight = 20.0;
  static const _dotRadius = 3.5;

  TextPainter _text(String text, [TextStyle? style]) => TextPainter(
    text: TextSpan(text: text, style: style ?? labelStyle),
    textDirection: textDirection,
    maxLines: 1,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final yLabels = [
      for (var i = 0; i <= _gridLines; i++)
        _text(formatWeight(maxKg - (maxKg - minKg) * i / _gridLines)),
    ];
    final leftInset = yLabels.map((t) => t.width).reduce(math.max) + 8;
    final chart = Rect.fromLTRB(
      leftInset,
      8,
      size.width - 8,
      size.height - _bottomLabelHeight,
    );

    double yOf(double kg) =>
        chart.bottom - (kg - minKg) / (maxKg - minKg) * chart.height;
    final t0 = points.first.date.millisecondsSinceEpoch;
    final span = math.max(1, points.last.date.millisecondsSinceEpoch - t0);
    double xOf(DateTime d) =>
        chart.left + (d.millisecondsSinceEpoch - t0) / span * chart.width;

    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= _gridLines; i++) {
      final y = chart.top + chart.height * i / _gridLines;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), grid);
      final label = yLabels[i];
      label.paint(canvas, Offset(0, y - label.height / 2));
    }

    final first = _text(formatDate(points.first.date));
    final last = _text(formatDate(points.last.date));
    first.paint(canvas, Offset(chart.left, chart.bottom + 4));
    if (first.width + last.width + 16 < chart.width) {
      last.paint(canvas, Offset(chart.right - last.width, chart.bottom + 4));
    }

    final target = targetKg;
    if (target != null) {
      final y = yOf(target);
      final dash = Paint()
        ..color = targetColor
        ..strokeWidth = 1.5;
      for (var x = chart.left; x < chart.right; x += 10) {
        canvas.drawLine(
          Offset(x, y),
          Offset(math.min(x + 5, chart.right), y),
          dash,
        );
      }
      if (targetLabel case final text?) {
        final label = _text(
          text,
          labelStyle.copyWith(color: targetColor, fontWeight: FontWeight.w600),
        );
        final above = y - label.height - 2 >= chart.top;
        label.paint(
          canvas,
          Offset(
            chart.right - label.width,
            above ? y - label.height - 2 : y + 2,
          ),
        );
      }
    }

    final offsets = [for (final p in points) Offset(xOf(p.date), yOf(p.kg))];
    final line = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final o in offsets.skip(1)) {
      line.lineTo(o.dx, o.dy);
    }
    final fill = Path.from(line)
      ..lineTo(offsets.last.dx, chart.bottom)
      ..lineTo(offsets.first.dx, chart.bottom)
      ..close();
    canvas
      ..drawPath(
        fill,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, chart.top),
            Offset(0, chart.bottom),
            [lineColor.withValues(alpha: 0.25), lineColor.withValues(alpha: 0)],
          ),
      )
      ..drawPath(
        line,
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );

    // Çok sık noktada işaretler çizgiyi kalabalıklaştırır.
    final showDots = chart.width / offsets.length >= 8;
    final dot = Paint()..color = lineColor;
    for (final (i, o) in offsets.indexed) {
      if (showDots || i == offsets.length - 1) {
        canvas.drawCircle(o, i == offsets.length - 1 ? 5 : _dotRadius, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_WeightChartPainter old) =>
      old.points != points ||
      old.minKg != minKg ||
      old.maxKg != maxKg ||
      old.targetKg != targetKg ||
      old.targetLabel != targetLabel ||
      old.lineColor != lineColor ||
      old.targetColor != targetColor ||
      old.gridColor != gridColor ||
      old.labelStyle != labelStyle;
}
