import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_logo.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        AppLogo(isHorizontal: true),
        SizedBox(height: 36),
        Text(
          "Let's Sign in",
          style: AppTextStyles.heading,
        ),
        SizedBox(height: 8),
        Text(
          "Welcome back,\nYou've been missed!",
          style: AppTextStyles.subtitle,
        ),
      ],
    );
  }
}
