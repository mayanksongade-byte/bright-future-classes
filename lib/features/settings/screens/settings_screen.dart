import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../auth/screens/login_screen.dart';
import '../view_models/settings_view_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SettingsViewModel();
    _viewModel.addListener(_onViewModelChange);
    _viewModel.loadSettingsData();
  }

  void _onViewModelChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChange);
    _viewModel.dispose();
    super.dispose();
  }

  void _showEditProfileDialog() {
    final profile = _viewModel.userProfile;
    final nameController = TextEditingController(text: profile?.name ?? '');
    final phoneController = TextEditingController(text: profile?.phone ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Name', style: AppTextStyles.inputLabel),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: nameController,
                    style: AppTextStyles.inputText,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryEmerald, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Phone (10 digits)', style: AppTextStyles.inputLabel),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: phoneController,
                    style: AppTextStyles.inputText,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    validator: (val) {
                      if (val == null || val.trim().length != 10 || int.tryParse(val.trim()) == null) {
                        return 'Phone must be exactly 10 digits';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryEmerald, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Email (Cannot be changed)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    profile?.email ?? FirebaseAuth.instance.currentUser?.email ?? '',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMain),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final success = await _viewModel.updateProfile(
                    name: nameController.text,
                    phone: phoneController.text,
                  );
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Profile updated successfully.' : (_viewModel.errorMessage ?? 'Failed to update profile.')),
                      backgroundColor: success ? AppColors.success : AppColors.error,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryEmerald,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showEditInstituteDialog() {
    final settings = _viewModel.instituteSettings;
    final nameController = TextEditingController(text: settings['instituteName'] ?? '');
    final addressController = TextEditingController(text: settings['address'] ?? '');
    final contactController = TextEditingController(text: settings['contactNumber'] ?? '');
    final emailController = TextEditingController(text: settings['email'] ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Institute Info', style: TextStyle(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Institute Name', style: AppTextStyles.inputLabel),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: nameController,
                    style: AppTextStyles.inputText,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Institute name is required' : null,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryEmerald, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Address', style: AppTextStyles.inputLabel),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: addressController,
                    style: AppTextStyles.inputText,
                    maxLines: 2,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Address is required' : null,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryEmerald, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Contact Number (10 digits)', style: AppTextStyles.inputLabel),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: contactController,
                    style: AppTextStyles.inputText,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    validator: (val) => val == null || val.trim().length != 10 || int.tryParse(val.trim()) == null ? 'Must be exactly 10 digits' : null,
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryEmerald, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Email', style: AppTextStyles.inputLabel),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: emailController,
                    style: AppTextStyles.inputText,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) => val == null || !val.contains('@') || !val.contains('.') ? 'Valid email required' : null,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryEmerald, width: 1.5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final success = await _viewModel.updateInstituteSettings(
                    instituteName: nameController.text,
                    address: addressController.text,
                    contactNumber: contactController.text,
                    email: emailController.text,
                  );
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Institute information updated.' : (_viewModel.errorMessage ?? 'Failed to update.')),
                      backgroundColor: success ? AppColors.success : AppColors.error,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryEmerald,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Sign Out?', style: TextStyle(fontWeight: FontWeight.w700)),
          content: const Text('Are you sure you want to sign out of Bright Future Classes?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await _viewModel.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _viewModel.userProfile;
    final inst = _viewModel.instituteSettings;

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
          'Settings',
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
        child: _viewModel.isLoading
            ? const Center(child: AppLoadingIndicator())
            : RefreshIndicator(
                onRefresh: _viewModel.loadSettingsData,
                color: AppColors.primaryEmerald,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. PROFILE SECTION
                          _buildSectionTitle('1. Profile'),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
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
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.lightEmerald,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.person_outline_rounded, color: AppColors.primaryEmerald, size: 24),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            profile?.name ?? 'Admin User',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            profile?.email ?? FirebaseAuth.instance.currentUser?.email ?? '',
                                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Divider(height: 1, color: AppColors.border),
                                const SizedBox(height: 16),
                                _buildInfoRow('Phone', profile?.phone ?? 'Not set'),
                                const SizedBox(height: 8),
                                _buildInfoRow('Role', profile?.role.toUpperCase() ?? 'ADMIN'),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _showEditProfileDialog,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primaryEmerald,
                                      side: const BorderSide(color: AppColors.primaryEmerald),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    icon: const Icon(Icons.edit_outlined, size: 16),
                                    label: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // 2. INSTITUTE INFORMATION
                          _buildSectionTitle('2. Institute Information'),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow('Institute Name', inst['instituteName'] ?? 'Bright Future Classes'),
                                const SizedBox(height: 10),
                                _buildInfoRow('Address', (inst['address'] ?? '').isNotEmpty ? inst['address'] : 'Not set'),
                                const SizedBox(height: 10),
                                _buildInfoRow('Contact Number', (inst['contactNumber'] ?? '').isNotEmpty ? inst['contactNumber'] : 'Not set'),
                                const SizedBox(height: 10),
                                _buildInfoRow('Email', (inst['email'] ?? '').isNotEmpty ? inst['email'] : 'Not set'),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _showEditInstituteDialog,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primaryEmerald,
                                      side: const BorderSide(color: AppColors.primaryEmerald),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    icon: const Icon(Icons.business_outlined, size: 16),
                                    label: const Text('Edit Institute Info', style: TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // 3. APP PREFERENCES
                          _buildSectionTitle('3. App Preferences'),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Text('In-App Notifications', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textMain)),
                                    Text('Enabled', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryEmerald)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text('Notifications center is active for Admin alerts.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // 4. SECURITY
                          _buildSectionTitle('4. Security'),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow('Account Status', profile?.isActive == true ? 'Active' : 'Inactive'),
                                const SizedBox(height: 10),
                                _buildInfoRow('Account Email', profile?.email ?? FirebaseAuth.instance.currentUser?.email ?? ''),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _confirmSignOut,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.error,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      elevation: 0,
                                    ),
                                    icon: const Icon(Icons.logout_rounded, size: 16),
                                    label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // 5. ABOUT
                          _buildSectionTitle('5. About'),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Bright Future Classes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain)),
                                SizedBox(height: 4),
                                Text('Tuition Management System', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                SizedBox(height: 12),
                                Text('App Version: 1.0.0', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryEmerald)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textMain,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMain)),
      ],
    );
  }
}
