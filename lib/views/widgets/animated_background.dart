import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:expense_tracker/core/theme.dart';

class AnimatedMeshBackground extends StatefulWidget {
  final Widget child;
  const AnimatedMeshBackground({super.key, required this.child});

  @override
  State<AnimatedMeshBackground> createState() => _AnimatedMeshBackgroundState();
}

class _AnimatedMeshBackgroundState extends State<AnimatedMeshBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<BackgroundParticle> _particles = [];
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Create 24 floating particles with random offsets for a richer network
    for (int i = 0; i < 24; i++) {
      _particles.add(BackgroundParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 10 + 4,
        speedX: (_random.nextDouble() - 0.5) * 0.04,
        speedY: (_random.nextDouble() - 0.5) * 0.04,
        opacity: _random.nextDouble() * 0.12 + 0.04,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: MeshBackgroundPainter(
            time: _controller.value,
            particles: _particles,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class BackgroundParticle {
  double x;
  double y;
  final double size;
  final double speedX;
  final double speedY;
  final double opacity;

  BackgroundParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.opacity,
  });

  void update() {
    x += speedX * 0.04;
    y += speedY * 0.04;

    // Wrap around boundaries
    if (x < 0) x = 1.0;
    if (x > 1.0) x = 0.0;
    if (y < 0) y = 1.0;
    if (y > 1.0) y = 0.0;
  }
}

class MeshBackgroundPainter extends CustomPainter {
  final double time;
  final List<BackgroundParticle> particles;

  MeshBackgroundPainter({required this.time, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    // Fill deep dark background base
    final basePaint = Paint()..color = AppTheme.bgDark;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    // --- Paint Moving Color Blobs (Fluid Dynamic Lights) ---
    final double angle = time * 2 * math.pi;

    // Blob 1: Indigo primary top-right moving blob
    final double b1X = size.width * 0.75 + math.sin(angle) * (size.width * 0.15);
    final double b1Y = size.height * 0.25 + math.cos(angle) * (size.height * 0.1);
    final Offset blob1Pos = Offset(b1X, b1Y);
    final double radius1 = size.width * 0.6;
    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.primary.withOpacity(0.12),
          AppTheme.primary.withOpacity(0.04),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: blob1Pos, radius: radius1));
    canvas.drawCircle(blob1Pos, radius1, paint1);

    // Blob 2: Violet savings bottom-left moving blob
    final double b2X = size.width * 0.2 + math.cos(angle + math.pi / 2) * (size.width * 0.12);
    final double b2Y = size.height * 0.85 + math.sin(angle + math.pi / 2) * (size.height * 0.08);
    final Offset blob2Pos = Offset(b2X, b2Y);
    final double radius2 = size.width * 0.7;
    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.accentSavings.withOpacity(0.09),
          AppTheme.accentSavings.withOpacity(0.02),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: blob2Pos, radius: radius2));
    canvas.drawCircle(blob2Pos, radius2, paint2);

    // Blob 3: Emerald income floating center blob
    final double b3X = size.width * 0.5 + math.sin(angle * 1.5) * (size.width * 0.12);
    final double b3Y = size.height * 0.55 + math.cos(angle * 1.2) * (size.height * 0.1);
    final Offset blob3Pos = Offset(b3X, b3Y);
    final double radius3 = size.width * 0.5;
    final paint3 = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.accentIncome.withOpacity(0.06),
          AppTheme.accentIncome.withOpacity(0.01),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: blob3Pos, radius: radius3));
    canvas.drawCircle(blob3Pos, radius3, paint3);

    // --- Paint Flowing Cybernetic Grid Mesh ---
    final gridPaint = Paint()
      ..color = AppTheme.borderDark.withOpacity(0.07)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const int gridCountX = 14;
    const int gridCountY = 22;

    // Draw horizontal grid lines bent by wave
    for (int i = 0; i <= gridCountY; i++) {
      final double yRatio = i / gridCountY;
      final Path path = Path();
      for (int j = 0; j <= 30; j++) {
        final double xRatio = j / 30;
        final double x = xRatio * size.width;
        // Wave formula shifting horizontal lines
        final double wave = math.sin(xRatio * 3 + time * 2 * math.pi) * 12.0 * math.sin(yRatio * math.pi);
        final double y = yRatio * size.height + wave;
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, gridPaint);
    }

    // Draw vertical grid lines bent by wave
    for (int i = 0; i <= gridCountX; i++) {
      final double xRatio = i / gridCountX;
      final Path path = Path();
      for (int j = 0; j <= 30; j++) {
        final double yRatio = j / 30;
        final double y = yRatio * size.height;
        // Wave formula shifting vertical lines
        final double wave = math.cos(yRatio * 3 + time * 2 * math.pi) * 12.0 * math.sin(xRatio * math.pi);
        final double x = xRatio * size.width + wave;
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, gridPaint);
    }

    // --- Paint Particle Network/Constellation ---
    final linePaint = Paint()..style = PaintingStyle.stroke;
    for (int i = 0; i < particles.length; i++) {
      for (int j = i + 1; j < particles.length; j++) {
        final p1 = particles[i];
        final p2 = particles[j];
        final dx = p1.x - p2.x;
        final dy = p1.y - p2.y;
        final dist = math.sqrt(dx * dx + dy * dy);
        // Connect nodes if they are close
        if (dist < 0.16) {
          final double opacity = (1.0 - (dist / 0.16)) * 0.12;
          linePaint.color = AppTheme.primary.withOpacity(opacity);
          linePaint.strokeWidth = (1.0 - (dist / 0.16)) * 1.2;
          canvas.drawLine(
            Offset(p1.x * size.width, p1.y * size.height),
            Offset(p2.x * size.width, p2.y * size.height),
            linePaint,
          );
        }
      }
    }

    // --- Paint Floating Particles/Nodes ---
    for (var p in particles) {
      p.update();
      final Offset pos = Offset(p.x * size.width, p.y * size.height);
      final double waveSize = p.size + math.sin(angle * 2.5 + p.x * 8) * 1.5;
      
      final pPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            AppTheme.textPrimary.withOpacity(p.opacity),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: pos, radius: waveSize));
        
      canvas.drawCircle(pos, waveSize, pPaint);
    }
  }

  @override
  bool shouldRepaint(covariant MeshBackgroundPainter oldDelegate) {
    return true; // Continuously animate
  }
}
