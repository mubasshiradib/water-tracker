import 'dart:math' as math;
import 'package:flutter/material.dart';

class WaveEmptyState extends StatefulWidget {
  final double size;
  const WaveEmptyState({super.key, this.size = 120});

  @override
  State<WaveEmptyState> createState() => _WaveEmptyStateState();
}

class _WaveEmptyStateState extends State<WaveEmptyState> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
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
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                blurRadius: 16,
                spreadRadius: 2,
              )
            ],
            color: Colors.white.withValues(alpha: 0.2),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.size / 2),
            child: Stack(
              children: [
                // Waves Painter
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _WavePainter(
                        animationValue: _controller.value,
                        waveColor1: const Color(0xFFFF6B6B).withValues(alpha: 0.35),
                        waveColor2: const Color(0xFFFF4D4D).withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                ),
                // Droplet/Calming Icon floating in center
                Center(
                  child: Transform.translate(
                    offset: Offset(0, 4 * math.sin(_controller.value * 2 * math.pi)),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.2),
                            blurRadius: 8,
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.water_drop_rounded,
                        size: 32,
                        color: Color(0xFFFF6B6B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double animationValue;
  final Color waveColor1;
  final Color waveColor2;

  _WavePainter({
    required this.animationValue,
    required this.waveColor1,
    required this.waveColor2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = waveColor1
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = waveColor2
      ..style = PaintingStyle.fill;

    final path1 = Path();
    final path2 = Path();

    // Wave parameters
    final double waveHeight = size.height * 0.08; // Height of wave crest/trough
    final double baseHeight = size.height * 0.65; // Base water level (filled from bottom)
    final double waveLength = size.width;

    path1.moveTo(0, size.height);
    path2.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x++) {
      // First wave: shifts right to left
      final double y1 = baseHeight +
          waveHeight * math.sin((x / waveLength) * 2 * math.pi + (animationValue * 2 * math.pi));
      path1.lineTo(x, y1);

      // Second wave: out of phase, shifts left to right
      final double y2 = baseHeight + 5 +
          (waveHeight * 0.8) *
              math.sin((x / waveLength) * 2 * math.pi - (animationValue * 2 * math.pi) + math.pi / 2);
      path2.lineTo(x, y2);
    }

    path1.lineTo(size.width, size.height);
    path1.close();

    path2.lineTo(size.width, size.height);
    path2.close();

    // Draw secondary first, then primary on top
    canvas.drawPath(path2, paint2);
    canvas.drawPath(path1, paint1);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
