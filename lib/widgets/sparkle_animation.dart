import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Sparkle animation widget that displays particle effects at a specific position
class SparkleAnimation extends StatefulWidget {
  final Offset position;
  final Color color;
  final VoidCallback? onComplete;

  const SparkleAnimation({
    super.key,
    required this.position,
    this.color = const Color(0xFFFFD700),
    this.onComplete,
  });

  @override
  State<SparkleAnimation> createState() => _SparkleAnimationState();
}

class _SparkleAnimationState extends State<SparkleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final int _particleCount = 12;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Create particles with random directions
    final random = math.Random();
    for (int i = 0; i < _particleCount; i++) {
      final angle = (i / _particleCount) * 2 * math.pi;
      final speed = 20.0 + random.nextDouble() * 30.0;
      final size = 3.0 + random.nextDouble() * 4.0;
      
      _particles.add(_Particle(
        angle: angle,
        speed: speed,
        size: size,
        delay: random.nextDouble() * 0.2,
      ));
    }

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
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
          painter: _SparklePainter(
            position: widget.position,
            particles: _particles,
            progress: _controller.value,
            color: widget.color,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final double delay;

  _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.delay,
  });
}

class _SparklePainter extends CustomPainter {
  final Offset position;
  final List<_Particle> particles;
  final double progress;
  final Color color;

  _SparklePainter({
    required this.position,
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      // Calculate particle-specific progress with delay
      final particleProgress = ((progress - particle.delay) / (1.0 - particle.delay))
          .clamp(0.0, 1.0);
      
      if (particleProgress <= 0) continue;

      // Calculate position
      final distance = particle.speed * particleProgress;
      final x = position.dx + math.cos(particle.angle) * distance;
      final y = position.dy + math.sin(particle.angle) * distance;

      // Calculate opacity (fade out)
      final opacity = (1.0 - particleProgress).clamp(0.0, 1.0);
      
      // Calculate size (shrink slightly)
      final currentSize = particle.size * (1.0 - particleProgress * 0.3);

      // Draw particle
      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      // Draw star shape
      _drawStar(canvas, Offset(x, y), currentSize, paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    const points = 5;
    final outerRadius = size;
    final innerRadius = size * 0.4;

    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points) - math.pi / 2;
      final radius = i.isEven ? outerRadius : innerRadius;
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
