import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/teacher_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/firestore_service.dart';
import '../../auth/screens/login_screen.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  TeacherModel? _teacher;
  String _loginUserId = '';

  @override
  void initState() {
    super.initState();
    _loadTeacherProfile();
  }

  Future<void> _loadTeacherProfile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final userDoc = await _firestoreService.getUserDocument(currentUser.uid);
        _loginUserId = userDoc?['userId'] as String? ?? 'N/A';
        final teacherId = userDoc?['teacherId'] as String? ?? currentUser.uid;

        final teacherData = await _firestoreService.getTeacherDocument(teacherId);
        if (teacherData != null) {
          _teacher = TeacherModel.fromMap(teacherData, teacherId);
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _teacher;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textMain),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: const Text(
          'Profile & Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Header Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: const Color(0xFFF3E8FF),
                                child: Text(
                                  (t?.name.isNotEmpty == true)
                                      ? t!.name[0].toUpperCase()
                                      : 'T',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.teacherAccent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t?.name ?? 'Teacher',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textMain,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Subject: ${t?.subject ?? 'Mathematics'}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.teacherAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Personal Information
                        _buildSectionCard(
                          title: 'Personal Information',
                          icon: Icons.person_outline_rounded,
                          children: [
                            _buildInfoRow('Full Name', t?.name ?? '-'),
                            _buildInfoRow('Teacher ID', t?.teacherId ?? '-'),
                            _buildInfoRow('Subject', t?.subject ?? 'Mathematics'),
                            _buildInfoRow('Status', t?.status ?? 'Active'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Contact Information
                        _buildSectionCard(
                          title: 'Contact Information',
                          icon: Icons.phone_outlined,
                          children: [
                            _buildInfoRow('Email', t?.email ?? '-'),
                            _buildInfoRow('Phone', t?.phone ?? '-'),
                            _buildInfoRow('Address', t?.address.isNotEmpty == true ? t!.address : '-'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Account Information
                        _buildSectionCard(
                          title: 'Account Information',
                          icon: Icons.badge_outlined,
                          children: [
                            _buildInfoRow('User ID', _loginUserId),
                            _buildInfoRow('Account Status', 'Active'),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Sign Out Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await AuthRepository().signOut();
                              if (context.mounted) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                      builder: (context) => const LoginScreen()),
                                  (route) => false,
                                );
                              }
                            },
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Sign Out'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primaryEmerald),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
