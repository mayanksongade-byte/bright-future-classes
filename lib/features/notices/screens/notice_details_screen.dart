import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/notice_model.dart';
import '../../../data/repositories/class_repository.dart';
import '../../../data/services/firestore_service.dart';
import '../view_models/notices_view_model.dart';
import 'add_edit_notice_screen.dart';

class NoticeDetailsScreen extends StatefulWidget {
  final NoticeModel notice;

  const NoticeDetailsScreen({super.key, required this.notice});

  @override
  State<NoticeDetailsScreen> createState() => _NoticeDetailsScreenState();
}

class _NoticeDetailsScreenState extends State<NoticeDetailsScreen> {
  late NoticeModel _notice;
  late final NoticesViewModel _viewModel;
  late final ClassRepository _classRepository;
  List<String> _classNames = [];
  bool _isLoadingClasses = true;
  bool _canEditOrDelete = false;
  String _userRole = 'teacher';
  String _currentUid = '';

  @override
  void initState() {
    super.initState();
    _notice = widget.notice;
    _viewModel = NoticesViewModel();
    _viewModel.addListener(_onViewModelChange);
    _classRepository = ClassRepository();
    _loadClassNames();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUid = user.uid;
      await _viewModel.markNoticeAsRead(_notice.noticeId, user.uid);

      final userDoc = await FirestoreService().getUserDocument(user.uid);
      final role = (userDoc?['role'] as String? ?? 'teacher').toLowerCase();
      _userRole = role;

      if (role == 'admin') {
        _canEditOrDelete = true;
      } else if (role == 'teacher') {
        _canEditOrDelete = _notice.createdBy == user.uid;
      }
      if (mounted) setState(() {});
    }
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

  Future<void> _loadClassNames() async {
    if (_notice.targetAudience == 'selected_classes' && _notice.classIds.isNotEmpty) {
      try {
        final allClasses = await _classRepository.getClasses();
        final classMap = {for (var c in allClasses) c.classId: c.className};

        final names = <String>[];
        for (var id in _notice.classIds) {
          if (classMap.containsKey(id)) {
            names.add(classMap[id]!);
          } else {
            names.add('Class unavailable');
          }
        }
        if (mounted) {
          setState(() {
            _classNames = names;
            _isLoadingClasses = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _classNames = _notice.classIds.map((_) => 'Class unavailable').toList();
            _isLoadingClasses = false;
          });
        }
      }
    } else {
      setState(() {
        _classNames = [];
        _isLoadingClasses = false;
      });
    }
  }

  Future<void> _confirmDelete() async {
    if (!_canEditOrDelete) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Notice?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this notice? This action cannot be undone.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final success = await _viewModel.deleteNotice(_notice.noticeId, userRole: _userRole, userId: _currentUid);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notice deleted successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      } else if (_viewModel.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_viewModel.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime d) {
    return AppDateFormatter.formatDate(d);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'published':
        return AppColors.success;
      case 'scheduled':
        return AppColors.warning;
      case 'draft':
        return AppColors.textSecondary;
      case 'expired':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _notice.computedStatus;
    final statusColor = _getStatusColor(status);
    final priority = _notice.priority.toLowerCase();
    final isUrgent = priority == 'urgent' || priority == 'high';
    final isImportant = priority == 'important';

    final isRead = _notice.isReadBy(_currentUid);

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
          'Notice Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        actions: _canEditOrDelete
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: AppColors.primaryEmerald),
                  onPressed: () async {
                    final updated = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (context) => AddEditNoticeScreen(noticeToEdit: _notice),
                      ),
                    );
                    if (updated == true) {
                      final fresh = await _viewModel.getNoticeById(_notice.noticeId);
                      if (fresh != null && mounted) {
                        setState(() {
                          _notice = fresh;
                        });
                        _loadClassNames();
                      }
                    }
                  },
                  tooltip: 'Edit Notice',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error),
                  onPressed: _confirmDelete,
                  tooltip: 'Delete Notice',
                ),
                const SizedBox(width: 8),
              ]
            : [],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_notice.isPinned) ...[
                                const Padding(
                                  padding: EdgeInsets.only(top: 3),
                                  child: Icon(Icons.push_pin_rounded,
                                      size: 20, color: AppColors.primaryEmerald),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  _notice.title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textMain,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Badges Row: Category, Priority, Read Status
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.lightEmerald,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _notice.type.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryEmerald,
                            ),
                          ),
                        ),
                        if (isUrgent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'URGENT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.error,
                              ),
                            ),
                          )
                        else if (isImportant)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'IMPORTANT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.warning,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Text(
                              'NORMAL PRIORITY',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),

                        // Read status badge
                        if (_userRole == 'admin')
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.visibility_outlined, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  '${_notice.readUserIds.length} readers',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isRead
                                  ? AppColors.lightEmerald
                                  : AppColors.primaryEmerald,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isRead ? 'READ' : 'UNREAD',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isRead ? AppColors.darkEmerald : Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Target Audience Section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.people_outline_rounded,
                            size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _notice.targetAudience == 'all_teachers'
                                    ? 'Target Audience: All Teachers'
                                    : 'Target Audience: Selected Classes (${_notice.classIds.length})',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMain,
                                ),
                              ),
                              if (_notice.targetAudience == 'selected_classes') ...[
                                const SizedBox(height: 6),
                                _isLoadingClasses
                                    ? const Text('Loading class details...',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary))
                                    : Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: _classNames
                                            .map((name) => Chip(
                                                  label: Text(name,
                                                      style: const TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w600)),
                                                  backgroundColor:
                                                      AppColors.lightEmerald,
                                                  padding: EdgeInsets.zero,
                                                  materialTapTargetSize:
                                                      MaterialTapTargetSize.shrinkWrap,
                                                ))
                                            .toList(),
                                      ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 16),

                    // Content / Description
                    const Text(
                      'Notice Content',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _notice.description,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textMain,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Schedule Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoBox(
                            label: 'Publish Date',
                            value: _formatDate(_notice.publishDate),
                            icon: Icons.calendar_today_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoBox(
                            label: 'Expiry Date',
                            value: _formatDate(_notice.expiryDate),
                            icon: Icons.event_available_rounded,
                            valueColor: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Metadata
                    Text(
                      'Author: ${_notice.createdByName.isNotEmpty ? _notice.createdByName : "Staff"} (${_notice.createdByRole.toUpperCase()})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Created: ${_notice.createdAt != null ? AppDateFormatter.formatDate(_notice.createdAt) : '-'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    if (_canEditOrDelete) ...[
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          if (status == 'draft')
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await _viewModel.publishNotice(_notice.noticeId);
                                  final fresh = await _viewModel.getNoticeById(_notice.noticeId);
                                  if (fresh != null && mounted) {
                                    setState(() {
                                      _notice = fresh;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.publish_rounded,
                                    size: 16, color: AppColors.success),
                                label: const Text('Publish',
                                    style: TextStyle(color: AppColors.success)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.success),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          if (status == 'published')
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await _viewModel.unpublishNotice(_notice.noticeId);
                                  final fresh = await _viewModel.getNoticeById(_notice.noticeId);
                                  if (fresh != null && mounted) {
                                    setState(() {
                                      _notice = fresh;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.undo_rounded,
                                    size: 16, color: AppColors.warning),
                                label: const Text('Unpublish',
                                    style: TextStyle(color: AppColors.warning)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.warning),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          if (status == 'draft' || status == 'published')
                            const SizedBox(width: 12),
                          Expanded(
                            child: PrimaryButton(
                              text: 'Delete Notice',
                              onPressed: _confirmDelete,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBox({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryEmerald),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? AppColors.textMain,
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
