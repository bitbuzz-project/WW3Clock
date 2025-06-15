// lib/widgets/enhanced_threat_gauge.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utils/colors.dart';
import '../models/threat_trend.dart';

class EnhancedThreatGauge extends StatefulWidget {
  final double threatLevel;
  final String threatDescription;
  final String primaryThreat;
  final ThreatTrend? threatTrend;

  const EnhancedThreatGauge({
    super.key,
    required this.threatLevel,
    required this.threatDescription,
    required this.primaryThreat,
    this.threatTrend,
  });

  @override
  State<EnhancedThreatGauge> createState() => _EnhancedThreatGaugeState();
}

class _EnhancedThreatGaugeState extends State<EnhancedThreatGauge>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _animation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseController = AnimationController(
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

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    
    // Start pulsing for high threat levels
    if (widget.threatLevel > 70) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background gauge
          CustomPaint(
            size: const Size(320, 320),
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
                size: const Size(320, 320),
                painter: GaugePainter(
                  threatLevel: _animation.value,
                  isBackground: false,
                ),
              );
            },
          ),

          // Pulse effect for high threats
          if (widget.threatLevel > 70)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 340,
                    height: 340,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.getThreatColor(widget.threatLevel).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  ),
                );
              },
            ),

          // Center content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Main threat level
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Text(
                    '${_animation.value.toInt()}',
                    style: TextStyle(
                      fontSize: 56,
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
              
              // Threat level label
              Text(
                'THREAT LEVEL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[400],
                  letterSpacing: 1.2,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Threat description with trend
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.getThreatColor(widget.threatLevel).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.getThreatColor(widget.threatLevel).withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  widget.threatDescription.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getThreatColor(widget.threatLevel),
                    letterSpacing: 0.8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Change percentage indicator
              if (widget.threatTrend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getChangeColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getChangeColor().withOpacity(0.6),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getChangeIcon(),
                        size: 16,
                        color: _getChangeColor(),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.threatTrend!.formattedChangePercent,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _getChangeColor(),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '30d',
                        style: TextStyle(
                          fontSize: 10,
                          color: _getChangeColor().withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Previous level indicator (small)
          if (widget.threatTrend != null)
            Positioned(
              bottom: 40,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[800]?.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Last month: ${widget.threatTrend!.previousLevel.toInt()}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getChangeColor() {
    if (widget.threatTrend == null) return Colors.grey;
    
    switch (widget.threatTrend!.changeDirection) {
      case 'up':
        return Colors.red[400]!;
      case 'down':
        return Colors.green[400]!;
      default:
        return Colors.grey[400]!;
    }
  }

  IconData _getChangeIcon() {
    if (widget.threatTrend == null) return Icons.remove;
    
    switch (widget.threatTrend!.changeDirection) {
      case 'up':
        return Icons.trending_up;
      case 'down':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }
}

class GaugePainter extends CustomPainter {
  final double threatLevel;
  final bool isBackground;

  GaugePainter({required this.threatLevel, required this.isBackground});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 30;
    final strokeWidth = 16.0;

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    if (isBackground) {
      // Draw background arc with segments
      paint.color = Colors.grey.withOpacity(0.15);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi * 0.75,
        math.pi * 1.5,
        false,
        paint,
      );

      // Draw segment markers
      paint.strokeWidth = 2;
      paint.color = Colors.grey.withOpacity(0.3);
      
      for (int i = 0; i <= 10; i++) {
        double angle = -math.pi * 0.75 + (math.pi * 1.5 * i / 10);
        double x1 = center.dx + (radius - 8) * math.cos(angle);
        double y1 = center.dy + (radius - 8) * math.sin(angle);
        double x2 = center.dx + (radius + 8) * math.cos(angle);
        double y2 = center.dy + (radius + 8) * math.sin(angle);
        
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
      }
    } else {
      // Draw threat level arc with gradient
      final sweepAngle = (threatLevel / 100) * math.pi * 1.5;
      
      // Create gradient shader
      final colors = _getGradientColors(threatLevel);
      final gradient = SweepGradient(
        startAngle: -math.pi * 0.75,
        endAngle: -math.pi * 0.75 + sweepAngle,
        colors: colors,
      );

      paint.strokeWidth = strokeWidth;
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

  List<Color> _getGradientColors(double threatLevel) {
    if (threatLevel < 30) {
      return [AppColors.lowThreat, AppColors.lowThreat.withOpacity(0.8)];
    } else if (threatLevel < 50) {
      return [AppColors.lowThreat, AppColors.mediumThreat];
    } else if (threatLevel < 70) {
      return [AppColors.mediumThreat, AppColors.highThreat];
    } else {
      return [AppColors.highThreat, AppColors.criticalThreat];
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}