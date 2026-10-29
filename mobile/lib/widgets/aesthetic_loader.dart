import 'package:flutter/material.dart';
import 'package:flutter_app/config/theme_extension.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AestheticLoader extends StatelessWidget {
  final double size;
  
  const AestheticLoader({
    super.key,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    final color = context.colors.primary;
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer Ring - Thin, slow, clockwise
            _ArcRing(
              size: size,
              color: color,
              strokeWidth: 2.0,
              duration: 2.seconds,
              reverse: false,
              arcLength: 0.6, 
            ),
            // Outer Ring Glow
            _ArcRing(
              size: size,
              color: color.withValues(alpha: 0.3),
              strokeWidth: 6.0,
              duration: 2.seconds,
              reverse: false,
              arcLength: 0.6,
            ),
            
            // Middle Ring - Medium, counter-clockwise
            _ArcRing(
              size: size * 0.75,
              color: color.withValues(alpha: 0.8),
              strokeWidth: 2.5,
              duration: 1.5.seconds,
              reverse: true,
              arcLength: 0.4,
            ),
            
            // Inner Ring - Fast, clockwise
            _ArcRing(
              size: size * 0.5,
              color: color.withValues(alpha: 0.6),
              strokeWidth: 3.0,
              duration: 1.seconds,
              reverse: false,
              arcLength: 0.75,
            ),

            // Center Pulsing Core
            Container(
              width: size * 0.15,
              height: size * 0.15,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.8),
                    blurRadius: 8,
                    spreadRadius: 2,
                  )
                ],
              ),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.3, 1.3), duration: 600.ms, curve: Curves.easeInOut)
            .fade(begin: 0.6, end: 1.0, duration: 600.ms),
          ],
        ),
      ),
    );
  }
}

class _ArcRing extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;
  final Duration duration;
  final bool reverse;
  final double arcLength;
  
  const _ArcRing({
    required this.size,
    required this.color,
    required this.strokeWidth,
    required this.duration,
    required this.reverse,
    required this.arcLength,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        value: arcLength,
        strokeWidth: strokeWidth,
        color: color,
        backgroundColor: Colors.transparent,
        strokeCap: StrokeCap.round,
      ),
    )
    .animate(onPlay: (controller) => controller.repeat())
    .rotate(
       duration: duration,
       begin: reverse ? 1 : 0,
       end: reverse ? 0 : 1,
       curve: Curves.linear,
    );
  }
}
