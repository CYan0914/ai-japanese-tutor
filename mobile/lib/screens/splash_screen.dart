/// Splash screen — quiet, considered entry into the app.
import 'package:flutter/material.dart';
import '../config/tokens.dart';
import '../services/api_service.dart';
import '../services/subscription_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 800));
    try {
      final token = await ApiService.ensureToken();
      try {
        final userId = token.length > 16 ? token.substring(0, 16) : token;
        await SubscriptionService.init(userId);
      } catch (_) {
        // RevenueCat not configured — continue
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Subtle kanji watermark — "はる" (haru, spring)
          Positioned(
            top: -40,
            right: -40,
            child: Text(
              'はる',
              style: SakuraType.display(
                color: SakuraColors.sakuraSoft,
                size: 320,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Cherry blossom emblem — five-petal SVG-style mark
                const _SakuraEmblem(size: 88),
                const SizedBox(height: SakuraSpace.l),
                Text(
                  'Sakura',
                  style: SakuraType.display(size: 36),
                ),
                const SizedBox(height: SakuraSpace.xs),
                Text(
                  'AI Japanese Tutor',
                  style: SakuraType.label(color: SakuraColors.mist, size: 13),
                ),
                const SizedBox(height: SakuraSpace.xxxl),
                const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: SakuraColors.sakura,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom five-petal sakura emblem — distinctive signature mark.
class _SakuraEmblem extends StatelessWidget {
  final double size;
  const _SakuraEmblem({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _SakuraPainter()),
    );
  }
}

class _SakuraPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final petalLength = size.width * 0.36;
    final petalWidth = size.width * 0.22;

    final petalPaint = Paint()..color = SakuraColors.sakura;
    final stamenPaint = Paint()..color = SakuraColors.sakuraDeep;

    // Five petals, rotated 72° apart
    for (int i = 0; i < 5; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * (2 * 3.14159265 / 5));
      canvas.translate(0, -petalLength * 0.5);

      final path = Path()
        ..moveTo(0, -petalLength * 0.4)
        ..quadraticBezierTo(
          petalWidth / 2, -petalLength * 0.2,
          0, petalLength * 0.4,
        )
        ..quadraticBezierTo(
          -petalWidth / 2, -petalLength * 0.2,
          0, -petalLength * 0.4,
        );
      canvas.drawPath(path, petalPaint);
      canvas.restore();
    }

    // Center stamen
    canvas.drawCircle(center, size.width * 0.06, stamenPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
