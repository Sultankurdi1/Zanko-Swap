import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedSplashScreen extends StatefulWidget {
  final VoidCallback onFinished;
  final Function(Locale)? onLanguageChanged;
  final VoidCallback? onOpenSettings;
  final Function(int)? onNavigateToTab;

  const AnimatedSplashScreen({
    super.key,
    required this.onFinished,
    this.onLanguageChanged,
    this.onOpenSettings,
    this.onNavigateToTab,
  });

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2900),
    )..forward();
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: _ZankoSplashAnimation(animation: controller));
}

class _ZankoSplashAnimation extends AnimatedWidget {
  final Animation<double> animation;

  const _ZankoSplashAnimation({required this.animation})
    : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final value = animation.value;
    final fade = Curves.easeOut.transform(
      (value * 1.35).clamp(0.0, 1.0).toDouble(),
    );
    final exitFade = value > .84
        ? (1 - ((value - .84) / .16)).clamp(0.0, 1.0).toDouble()
        : 1.0;
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _SplashBackdrop(progress: value)),
        Center(
          child: Opacity(
            opacity: fade * exitFade,
            child: Transform.scale(
              scale:
                  .94 +
                  .06 *
                      Curves.easeOutBack.transform(
                        (value * 1.3).clamp(0.0, 1.0).toDouble(),
                      ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate('ZankoSwap'.length, (index) {
                      final progress = Curves.easeOutBack.transform(
                        ((value - index * .055) / .48)
                            .clamp(0.0, 1.0)
                            .toDouble(),
                      );
                      return Opacity(
                        opacity: progress.clamp(0.0, 1.0).toDouble(),
                        child: Transform.translate(
                          offset: Offset(0, 18 * (1 - progress)),
                          child: Text(
                            'ZankoSwap'[index],
                            style: TextStyle(
                              color: index < 5
                                  ? Colors.white
                                  : const Color(0xFF69F0D1),
                              fontSize: 40,
                              letterSpacing: index == 8 ? 0 : -1.2,
                              fontWeight: FontWeight.w900,
                              height: 1,
                              shadows: [
                                Shadow(
                                  color: const Color(
                                    0xFF39E6C0,
                                  ).withValues(alpha: .28),
                                  blurRadius: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: 58,
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF69F0D1), Color(0xFF8B9BFF)],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Opacity(
                    opacity: ((value - .34) / .38).clamp(0.0, 1.0).toDouble(),
                    child: const Text(
                      'LEARN  ·  SHARE  ·  SWAP',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 34,
          child: Opacity(
            opacity: fade * exitFade,
            child: const Text(
              'A community built to move ideas forward',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                letterSpacing: .4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SplashBackdrop extends CustomPainter {
  final double progress;
  const _SplashBackdrop({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF080D22), Color(0xFF101638), Color(0xFF092C35)],
          stops: [0, .58, 1],
        ).createShader(rect),
    );

    final glow = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70);
    canvas.drawCircle(
      Offset(size.width * .14, size.height * .3),
      size.width * .32,
      glow..color = const Color(0x333C72FF),
    );
    canvas.drawCircle(
      Offset(size.width * .9, size.height * .72),
      size.width * .34,
      glow..color = const Color(0x3322D6B0),
    );

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x14FFFFFF);
    for (var i = 0; i < 7; i++) {
      final y =
          size.height * (.12 + i * .13) + math.sin(progress * math.pi + i) * 8;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y - size.width * .14),
        linePaint,
      );
    }

    final random = math.Random(27);
    for (var i = 0; i < 38; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final y = baseY - progress * (22 + random.nextDouble() * 80);
      final radius = .7 + random.nextDouble() * 2.2;
      final opacity = (.12 + random.nextDouble() * .35) * (1 - progress * .3);
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..color = Colors.white.withValues(
            alpha: opacity.clamp(0.0, 1.0).toDouble(),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SplashBackdrop oldDelegate) =>
      oldDelegate.progress != progress;
}
