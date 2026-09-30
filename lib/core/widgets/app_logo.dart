import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppLogo extends StatelessWidget {
  final double iconSize;
  final bool isHorizontal;

  const AppLogo({
    super.key,
    this.iconSize = 42,
    this.isHorizontal = true,
  });

  @override
  Widget build(BuildContext context) {
    final logoIcon = Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color: AppColors.primaryEmerald,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryEmerald.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'BF',
          style: TextStyle(
            color: Colors.white,
            fontSize: iconSize * 0.45,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );

    final titleText = Column(
      crossAxisAlignment:
          isHorizontal ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: const [
        Text('Bright Future', style: AppTextStyles.brandTitle),
        SizedBox(height: 1),
        Text('TUITION CLASSES', style: AppTextStyles.brandSubtitle),
      ],
    );

    if (isHorizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          logoIcon,
          const SizedBox(width: 12),
          titleText,
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        logoIcon,
        const SizedBox(height: 8),
        titleText,
      ],
    );
  }
}
