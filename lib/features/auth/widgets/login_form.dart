import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../../teacher/screens/teacher_dashboard_screen.dart';
import '../view_models/auth_view_model.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthViewModel _authViewModel;
  bool _isPasswordObscured = true;

  @override
  void initState() {
    super.initState();
    _authViewModel = AuthViewModel();
    _authViewModel.addListener(_onAuthViewModelChanged);
  }

  void _onAuthViewModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _authViewModel.removeListener(_onAuthViewModelChanged);
    _authViewModel.dispose();
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_authViewModel.isLoading) return;

    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() ?? false) {
      final emailOrUserId = _userIdController.text.trim();
      final password = _passwordController.text;

      final success = await _authViewModel.loginWithEmail(emailOrUserId, password);

      if (!mounted) return;

      if (success) {
        final role = _authViewModel.userModel?.role.toLowerCase();
        Widget destination;
        if (role == 'teacher') {
          destination = const TeacherDashboardScreen();
        } else {
          destination = const AdminDashboardScreen();
        }

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => destination,
          ),
          (route) => false,
        );
      } else if (_authViewModel.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_authViewModel.errorMessage!),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            label: 'Email or User ID',
            hintText: 'Enter your email or User ID',
            controller: _userIdController,
            validator: Validators.validateEmailOrUserId,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(
              Icons.person_outline_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(height: 18),
          AppTextField(
            label: 'Password',
            hintText: 'Enter your password',
            controller: _passwordController,
            obscureText: _isPasswordObscured,
            validator: Validators.validatePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleLogin(),
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordObscured
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordObscured = !_isPasswordObscured;
                });
              },
            ),
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            text: 'Sign in',
            isLoading: _authViewModel.isLoading,
            onPressed: _authViewModel.isLoading ? null : _handleLogin,
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                const Text(
                  'Secure access for authorized users',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: AppTextStyles.caption,
                    children: [
                      TextSpan(text: 'By signing in, you agree to our\n'),
                      TextSpan(
                        text: 'Terms & Conditions',
                        style: TextStyle(
                          color: AppColors.primaryEmerald,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(text: ' & '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          color: AppColors.primaryEmerald,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
