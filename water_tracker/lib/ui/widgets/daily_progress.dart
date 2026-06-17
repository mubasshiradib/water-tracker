import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DailyProgress extends StatelessWidget {
  final int currentIntake;
  final int dailyGoal;

  const DailyProgress({
    super.key,
    required this.currentIntake,
    required this.dailyGoal,
  });

  @override
  Widget build(BuildContext context) {
    final double percentage = dailyGoal > 0 ? (currentIntake / dailyGoal).clamp(0.0, 1.0) : 0.0;
    
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: percentage),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Inner Text Data
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$currentIntake',
                        style: GoogleFonts.inter(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xff331A1A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextSpan(
                        text: ' ml',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xff331A1A).withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 2,
                  width: 64,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xff331A1A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  '${dailyGoal}ml',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff331A1A).withValues(alpha: 0.8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'TODAY\'S GOAL: ${(value * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFF6B6B),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            // Animated Progress Arc around the circle
            SizedBox(
              width: 240,
              height: 240,
              child: CustomPaint(
                painter: ProgressPainter(
                  progress: value,
                  trackColor: Colors.white.withValues(alpha: 0.8),
                  progressColor: const Color(0xFFFF6B6B),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ProgressPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  ProgressPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;

    // Background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16.0;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Radial shadow (ambient glow) behind the progress line
    final shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16.0
      ..strokeCap = StrokeCap.round
      ..color = progressColor.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      shadowPaint,
    );

    // Core progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
