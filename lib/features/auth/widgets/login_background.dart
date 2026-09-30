import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class LoginBackground extends StatelessWidget {
  final Widget child;

  const LoginBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Top-right decorative shape
          Positioned(
            top: 0,
            right: 0,
            width: screenSize.width,
            height: screenSize.height * 0.22,
            child: IgnorePointer(
              child: CustomPaint(
                painter: TopRightShapePainter(),
              ),
            ),
          ),

          // Bottom decorative shape
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: screenSize.height * 0.12,
            child: IgnorePointer(
              child: CustomPaint(
                painter: BottomShapePainter(),
              ),
            ),
          ),

          // Foreground scrollable content
          SafeArea(
            child: child,
          ),
        ],
      ),
    );
  }
}

class TopRightShapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryEmerald
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width * 0.50, 0);
    path.cubicTo(
      size.width * 0.58,
      size.height * 0.50,
      size.width * 0.68,
      size.height * 0.80,
      size.width * 0.85,
      size.height * 0.65,
    );
    path.cubicTo(
      size.width * 0.95,
      size.height * 0.55,
      size.width * 0.92,
      size.height * 0.20,
      size.width,
      size.height * 0.30,
    );
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BottomShapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryEmerald
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.35);
    path.cubicTo(
      size.width * 0.20,
      size.height * 0.15,
      size.width * 0.35,
      size.height * 0.85,
      size.width * 0.65,
      size.height * 0.70,
    );
    path.cubicTo(
      size.width * 0.80,
      size.height * 0.60,
      size.width * 0.90,
      size.height * 0.90,
      size.width,
      size.height,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
