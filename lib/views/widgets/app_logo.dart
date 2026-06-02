import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:expense_tracker/core/theme.dart';

class ExpenseTrackerLogo extends StatelessWidget {
  final double size;
  final double progress;

  const ExpenseTrackerLogo({
    super.key,
    required this.size,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _LogoPainter(progress: progress),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final double progress;

  _LogoPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    if (w <= 0 || h <= 0) return;

    // Define the vertical stem representing the spine of the 'E'
    final Path stemPath = Path()
      ..moveTo(w * 0.32, h * 0.74)
      ..lineTo(w * 0.32, h * 0.26);

    // Define top bar with an elegant upward curve (representing growth)
    final Path topPath = Path()
      ..moveTo(w * 0.32, h * 0.26)
      ..quadraticBezierTo(
        w * 0.52, h * 0.24,
        w * 0.72, h * 0.18,
      );

    // Define middle bar showing balance
    final Path middlePath = Path()
      ..moveTo(w * 0.32, h * 0.50)
      ..lineTo(w * 0.62, h * 0.50);

    // Define bottom bar showing base/savings/foundation
    final Path bottomPath = Path()
      ..moveTo(w * 0.32, h * 0.74)
      ..quadraticBezierTo(
        w * 0.50, h * 0.74,
        w * 0.68, h * 0.74,
      );

    // 1. Draw Stem (Progress 0.0 -> 0.35)
    final double stemProgress = (progress / 0.35).clamp(0.0, 1.0);
    final stemPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        colors: [AppTheme.primary, AppTheme.accentSavings],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    _drawAnimatedPath(canvas, stemPath, stemProgress, stemPaint);

    // 2. Draw Top Bar (Progress 0.35 -> 0.65)
    final double topProgress = ((progress - 0.35) / 0.30).clamp(0.0, 1.0);
    final topPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        colors: [AppTheme.accentSavings, AppTheme.accentIncome],
        begin: Alignment.centerLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    _drawAnimatedPath(canvas, topPath, topProgress, topPaint);

    // 3. Draw Middle Bar (Progress 0.65 -> 0.82)
    final double middleProgress = ((progress - 0.65) / 0.17).clamp(0.0, 1.0);
    final middlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.07
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        colors: [AppTheme.primary, AppTheme.accentWarning],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    _drawAnimatedPath(canvas, middlePath, middleProgress, middlePaint);

    // 4. Draw Bottom Bar (Progress 0.82 -> 0.95)
    final double bottomProgress = ((progress - 0.82) / 0.13).clamp(0.0, 1.0);
    final bottomPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        colors: [AppTheme.primary, AppTheme.accentExpense],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    _drawAnimatedPath(canvas, bottomPath, bottomProgress, bottomPaint);

    // 5. Draw Goal Orb at end of top bar (Progress 0.92 -> 1.0)
    final double orbProgress = ((progress - 0.92) / 0.08).clamp(0.0, 1.0);
    if (orbProgress > 0.0) {
      final double orbRadius = (w * 0.07) * orbProgress;
      final Offset orbCenter = Offset(w * 0.72, h * 0.18);

      // Outer radial glow
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            AppTheme.accentIncome.withOpacity(0.8),
            AppTheme.accentIncome.withOpacity(0.3),
            AppTheme.accentIncome.withOpacity(0.0),
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(Rect.fromCircle(center: orbCenter, radius: orbRadius * 2.8));
      canvas.drawCircle(orbCenter, orbRadius * 2.8, glowPaint);

      // Inner white/emerald core
      final corePaint = Paint()..color = Colors.white;
      canvas.drawCircle(orbCenter, orbRadius * 0.8, corePaint);
    }
  }

  void _drawAnimatedPath(Canvas canvas, Path path, double progress, Paint paint) {
    if (progress <= 0.0) return;
    if (progress >= 1.0) {
      canvas.drawPath(path, paint);
      return;
    }

    final Path extract = Path();
    for (final PathMetric metric in path.computeMetrics()) {
      extract.addPath(metric.extractPath(0, metric.length * progress), Offset.zero);
    }
    canvas.drawPath(extract, paint);
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
