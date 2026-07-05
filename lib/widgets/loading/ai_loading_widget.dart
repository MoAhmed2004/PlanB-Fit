import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

/// The centrepiece demo animation.
///
/// Three concentric dashed rings spin at different speeds and directions.
/// A neon-green core pulses with a BoxShadow glow.
/// Analysis messages cycle every 1.8 seconds via AnimatedSwitcher.
/// A fake-but-smooth LinearProgressIndicator fills over ~10 s.
class AILoadingWidget extends StatefulWidget {
  const AILoadingWidget({super.key});

  @override
  State<AILoadingWidget> createState() => _AILoadingWidgetState();
}

class _AILoadingWidgetState extends State<AILoadingWidget>
    with TickerProviderStateMixin {
  late final AnimationController _spinController;
  late final AnimationController _pulseController;
  late final AnimationController _progressController;

  int _msgIndex = 0;
  Timer? _msgTimer;

  static const _messages = [
    'Scanning muscle activation patterns...',
    'Analyzing biomechanics data...',
    'Checking injury constraints...',
    'Calculating load equivalency...',
    'Evaluating equipment availability...',
    'Finding perfect alternative...',
    'Optimising volume for your level...',
    'Almost there...',
  ];

  @override
  void initState() {
    super.initState();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // Progress eases in over ~10 s, stops at 0.92 — snaps to 1 on success
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..animateTo(0.92, curve: Curves.easeInOut);

    _msgTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (mounted) {
        setState(() => _msgIndex = (_msgIndex + 1) % _messages.length);
      }
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    _msgTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _spinController,
        _pulseController,
        _progressController,
      ]),
      builder: (context, _) {
        final spin = _spinController.value;
        final pulse = _pulseController.value;
        final prog = _progressController.value;

        final coreSize = 76.0 + pulse * 8;
        final glowSpread = 4.0 + pulse * 10;
        final glowBlur = 18.0 + pulse * 24;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Ring stack
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer dashed ring — clockwise
                  _DashedRingRotator(
                    size: 200,
                    turns: spin,
                    color: AppTheme.accentGreen.withOpacity(0.35),
                    dashCount: 12,
                    strokeWidth: 2,
                  ),
                  // Middle dashed ring — counter-clockwise, faster
                  _DashedRingRotator(
                    size: 150,
                    turns: -spin * 1.6,
                    color: AppTheme.accentPurple.withOpacity(0.55),
                    dashCount: 8,
                    strokeWidth: 1.5,
                  ),
                  // Inner dashed ring — clockwise, slowest
                  _DashedRingRotator(
                    size: 104,
                    turns: spin * 0.7,
                    color: AppTheme.accentOrange.withOpacity(0.4),
                    dashCount: 5,
                    strokeWidth: 1.5,
                  ),
                  // Pulsing neon core
                  Container(
                    width: coreSize,
                    height: coreSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.cardColor,
                          AppTheme.surface,
                        ],
                      ),
                      border: Border.all(
                        color: AppTheme.accentGreen.withOpacity(0.8),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentGreen
                              .withOpacity(0.3 + pulse * 0.3),
                          blurRadius: glowBlur,
                          spreadRadius: glowSpread,
                        ),
                        BoxShadow(
                          color: AppTheme.accentPurple
                              .withOpacity(0.1 + pulse * 0.1),
                          blurRadius: glowBlur * 0.6,
                          spreadRadius: glowSpread * 0.3,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'AI',
                          style: GoogleFonts.orbitron(
                            color: AppTheme.accentGreen,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'MANUS',
                          style: GoogleFonts.poppins(
                            color: AppTheme.accentGreen.withOpacity(0.6),
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),

            // ── Cycling message
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                _messages[_msgIndex],
                key: ValueKey(_msgIndex),
                style: GoogleFonts.poppins(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  letterSpacing: 0.3,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 28),

            // ── Progress bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: AppTheme.surface,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      widthFactor: prog,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.planBGradient,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppTheme.accentGreen.withOpacity(0.4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            Text(
              'Manus AI is analyzing your biomechanics & profile',
              style: GoogleFonts.poppins(
                color: AppTheme.accentGreen.withOpacity(0.8),
                fontSize: 11,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _DashedRingRotator extends StatelessWidget {
  final double size;
  final double turns;
  final Color color;
  final int dashCount;
  final double strokeWidth;

  const _DashedRingRotator({
    required this.size,
    required this.turns,
    required this.color,
    required this.dashCount,
    required this.strokeWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: turns * 2 * pi,
      child: CustomPaint(
        size: Size(size, size),
        painter: _DashedRingPainter(
          color: color,
          dashCount: dashCount,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  final Color color;
  final int dashCount;
  final double strokeWidth;

  const _DashedRingPainter({
    required this.color,
    required this.dashCount,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;
    final gap = (2 * pi) / dashCount;
    final dashArc = gap * 0.5;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = gap * i;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashArc,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter old) =>
      old.color != color ||
      old.dashCount != dashCount ||
      old.strokeWidth != strokeWidth;
}
