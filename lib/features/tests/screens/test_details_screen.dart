import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/repositories/test_repository.dart';
import '../../../data/services/firestore_service.dart';
import '../view_models/tests_view_model.dart';
import 'add_edit_test_screen.dart';
import 'enter_marks_screen.dart';
import 'test_results_screen.dart';

class TestDetailsScreen extends StatefulWidget {
  final TestItem testItem;

  const TestDetailsScreen({super.key, required this.testItem});

  @override
  State<TestDetailsScreen> createState() => _TestDetailsScreenState();
}

class _TestDetailsScreenState extends State<TestDetailsScreen> {
  late TestItem _item;
  late final TestsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _item = widget.testItem;
    _viewModel = TestsViewModel();
    _viewModel.addListener(_onViewModelChange);
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

  Future<void> _refresh() async {
    await _viewModel.fetchTestsData();
    final updated = _viewModel.testItems.firstWhere(
      (i) => i.test.testId == _item.test.testId,
      orElse: () => _item,
    );
    if (mounted) {
      setState(() {
        _item = updated;
      });
    }
  }

  Future<void> _confirmToggleArchive() async {
    final willArchive = !_item.test.isArchived;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(willArchive ? 'Archive Test?' : 'Restore Test?'),
          content: Text(willArchive
              ? 'Are you sure you want to archive this test? It will be moved to the Archived list while preserving all student marks and audit history.'
              : 'Are you sure you want to restore this test?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: willArchive ? AppColors.warning : AppColors.primaryEmerald,
                foregroundColor: Colors.white,
              ),
              child: Text(willArchive ? 'Archive' : 'Restore'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final success = await _viewModel.archiveTest(_item.test.testId, willArchive);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(willArchive ? 'Test archived successfully.' : 'Test restored successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        await _refresh();
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

  bool _isDeleting = false;

  Future<void> _confirmDelete() async {
    final user = FirebaseAuth.instance.currentUser;
    bool isTeacher = false;
    if (user != null) {
      try {
        final userDoc = await FirestoreService().getUserDocument(user.uid);
        if (!mounted) return;
        final role = (userDoc?['role'] as String? ?? '').toLowerCase();
        isTeacher = role == 'teacher';
      } catch (_) {}
    }

    final TextEditingController reasonController = TextEditingController();
    String? validationError;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: !_isDeleting,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Delete Test?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Are you sure you want to delete this test? This action cannot be undone.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (isTeacher) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Deletion Reason (Required)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: reasonController,
                      style: AppTextStyles.inputText,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Enter reason for deleting this test...',
                        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        errorText: validationError,
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (_) {
                        if (validationError != null) {
                          setDialogState(() => validationError = null);
                        }
                      },
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isDeleting ? null : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: _isDeleting
                      ? null
                      : () async {
                          final reason = reasonController.text.trim();
                          if (isTeacher && reason.isEmpty) {
                            setDialogState(() {
                              validationError = 'Deletion reason is required.';
                            });
                            return;
                          }
                          Navigator.of(dialogContext).pop(true);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isDeleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true && mounted) {
      setState(() => _isDeleting = true);
      final reason = reasonController.text.trim();
      final success = await _viewModel.deleteTest(_item.test.testId, deletionReason: reason);
      if (!mounted) return;
      setState(() => _isDeleting = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test deleted successfully.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      } else if (_viewModel.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_viewModel.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAuditHistoryModal() async {
    final audits = await TestRepository().getMarkAuditsForTest(_item.test.testId, classId: _item.test.classId);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Marks Edit History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textMain),
              ),
              const SizedBox(height: 16),
              audits.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No edit history recorded for this test.', style: TextStyle(color: AppColors.textSecondary)),
                    )
                  : Expanded(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: audits.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
                        itemBuilder: (context, index) {
                          final audit = audits[index];
                          final oldM = audit.oldIsAbsent ? 'Absent' : (audit.oldMarks?.toStringAsFixed(1) ?? 'N/A');
                          final newM = audit.newIsAbsent ? 'Absent' : (audit.newMarks?.toStringAsFixed(1) ?? 'N/A');

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Student ID: ${audit.studentId}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                const SizedBox(height: 2),
                                Text('$oldM → $newM', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryEmerald)),
                                const SizedBox(height: 2),
                                Text('Edited by: ${audit.editedByName} (${audit.editedByRole})', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                if (audit.newRemarks != null && audit.newRemarks!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text('Remark: "${audit.newRemarks}"', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textMain)),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor = AppColors.warning;
    if (_item.test.isCancelled) {
      statusColor = AppColors.error;
    } else if (_item.status == 'Completed') {
      statusColor = AppColors.success;
    } else if (_item.status == 'Partially Entered') {
      statusColor = AppColors.info;
    }

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
          'Test Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _item.test.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
              color: AppColors.textMain,
            ),
            onPressed: _confirmToggleArchive,
            tooltip: _item.test.isArchived ? 'Restore Test' : 'Archive Test',
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: AppColors.primaryEmerald),
            onPressed: () async {
              final updated = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => AddEditTestScreen(
                    testToEdit: _item.test,
                    preloadedClasses: _viewModel.classes,
                  ),
                ),
              );
              if (updated == true) {
                await _refresh();
              }
            },
            tooltip: 'Edit Test',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.error),
            onPressed: _confirmDelete,
            tooltip: 'Delete Test',
          ),
          const SizedBox(width: 8),
        ],
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _item.test.testName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMain,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _item.status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.school_outlined,
                            size: 16, color: AppColors.primaryEmerald),
                        const SizedBox(width: 6),
                        Text(
                          '${_item.classModel != null ? _item.classModel!.className : 'Class'} • Subject: ${_item.test.subject}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMain,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 16),
                    if (_item.test.description.isNotEmpty) ...[
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _item.test.description,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textMain,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoBox(
                            label: 'Test Date',
                            value: _item.test.testDate,
                            icon: Icons.calendar_today_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoBox(
                            label: 'Total / Passing',
                            value:
                                '${_item.test.totalMarks.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}${_item.test.passingMarks != null ? ' (Pass: ${_item.test.passingMarks!.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')})' : ''}',
                            icon: Icons.military_tech_outlined,
                            valueColor: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoBox(
                            label: 'Marks Status',
                            value:
                                '${_item.marksEnteredCount} / ${_item.totalStudents} entered',
                            icon: Icons.assignment_turned_in_outlined,
                            valueColor: AppColors.primaryEmerald,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _showAuditHistoryModal,
                      icon: const Icon(Icons.history_rounded, size: 16),
                      label: const Text('View Change History'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textMain,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: (_item.test.isCancelled || _item.isFutureExamDate)
                                ? null
                                : () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EnterMarksScreen(testItem: _item),
                                      ),
                                    );
                                    await _refresh();
                                  },
                            icon: Icon(
                                _item.isFutureExamDate ? Icons.lock_clock_outlined : Icons.edit_note_rounded,
                                size: 16,
                                color: _item.isFutureExamDate ? AppColors.textSecondary : AppColors.primaryEmerald),
                            label: Text(
                              _item.isFutureExamDate
                                  ? 'Marks on ${_item.test.testDate}'
                                  : 'Enter Marks',
                              style: TextStyle(
                                color: _item.isFutureExamDate
                                    ? AppColors.textSecondary
                                    : AppColors.primaryEmerald,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: _item.isFutureExamDate
                                      ? AppColors.border
                                      : AppColors.primaryEmerald),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PrimaryButton(
                            text: 'View Results',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TestResultsScreen(testItem: _item),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
