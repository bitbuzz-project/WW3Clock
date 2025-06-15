import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utils/colors.dart';

class ThreatGauge extends StatefulWidget {
  final double threatLevel;
  final String threatDescription;
  final String primaryThreat;

  const ThreatGauge({
    super.key,
    required this.threatLevel,
    required this.threatDescription,
    required this.primaryThreat,
  });

  @override
  State<ThreatGauge> createState() => _ThreatGaugeState();
}

class _ThreatGaugeState extends State<ThreatGauge>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.threatLevel,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background gauge
          CustomPaint(
            size: const Size(280, 280),
            painter: GaugePainter(
              threatLevel: 100,
              isBackground: true,
            ),
          ),
          // Animated threat level gauge
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(280, 280),
                painter: GaugePainter(
                  threatLevel: _animation.value,
                  isBackground: false,
                ),
              );
            },
          ),
          // Center content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Text(
                    '${_animation.value.toInt()}',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getThreatColor(_animation.value),
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: AppColors.getThreatColor(_animation.value).withOpacity(0.5),
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              Text(
                'THREAT LEVEL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[400],
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.getThreatColor(widget.threatLevel).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.getThreatColor(widget.threatLevel).withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  widget.threatDescription.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getThreatColor(widget.threatLevel),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          // Pulse effect for high threats
          if (widget.threatLevel > 70)
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  width: 300 + (math.sin(_animationController.value * 2 * math.pi) * 20),
                  height: 300 + (math.sin(_animationController.value * 2 * math.pi) * 20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.getThreatColor(widget.threatLevel).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class GaugePainter extends CustomPainter {
  final double threatLevel;
  final bool isBackground;

  GaugePainter({required this.threatLevel, required this.isBackground});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    final strokeWidth = 12.0;

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    if (isBackground) {
      // Draw background arc
      paint.color = Colors.grey.withOpacity(0.2);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi * 0.75, // Start angle
        math.pi * 1.5,   // Sweep angle
        false,
        paint,
      );
    } else {
      // Draw threat level arc with gradient effect
      final sweepAngle = (threatLevel / 100) * math.pi * 1.5;
      
      // Create gradient colors based on threat level
      Color startColor = AppColors.lowThreat;
      Color endColor = AppColors.getThreatColor(threatLevel);
      
      if (threatLevel > 50) {
        startColor = AppColors.mediumThreat;
      }
      if (threatLevel > 70) {
        startColor = AppColors.highThreat;
      }

      final gradient = SweepGradient(
        startAngle: -math.pi * 0.75,
        endAngle: -math.pi * 0.75 + sweepAngle,
        colors: [startColor, endColor],
      );

      paint.shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi * 0.75,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}