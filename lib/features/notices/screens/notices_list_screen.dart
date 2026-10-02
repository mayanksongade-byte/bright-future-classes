import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/notice_model.dart';
import '../view_models/notices_view_model.dart';
import 'add_edit_notice_screen.dart';
import 'notice_details_screen.dart';

class NoticesListScreen extends StatefulWidget {
  const NoticesListScreen({super.key});

  @override
  State<NoticesListScreen> createState() => _NoticesListScreenState();
}

class _NoticesListScreenState extends State<NoticesListScreen> {
  late final NoticesViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = NoticesViewModel();
    _viewModel.addListener(_onViewModelChange);
    _viewModel.fetchNoticesData();
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
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
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
    final notices = _viewModel.filteredNotices;

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
          'Notices',
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
                onRefresh: _viewModel.fetchNoticesData,
                color: AppColors.primaryEmerald,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // SECTION 1 — NOTICE SUMMARY
                          const Text(
                            'Notice Summary',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMain,
                            ),
                          ),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth > 600;
                              return GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: isWide ? 5 : 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: isWide ? 1.5 : 1.3,
                                children: [
                                  _buildSummaryCard(
                                      'Total', '${_viewModel.totalNotices}', AppColors.primaryEmerald, AppColors.lightEmerald),
                                  _buildSummaryCard(
                                      'Published', '${_viewModel.publishedCount}', AppColors.success, const Color(0xFFDCFCE7)),
                                  _buildSummaryCard(
                                      'Scheduled', '${_viewModel.scheduledCount}', AppColors.warning, const Color(0xFFFEF3C7)),
                                  _buildSummaryCard(
                                      'Draft', '${_viewModel.draftCount}', AppColors.textSecondary, AppColors.border),
                                  _buildSummaryCard(
                                      'Expired', '${_viewModel.expiredCount}', AppColors.error, const Color(0xFFFEE2E2)),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),

                          // CREATE NOTICE BUTTON
                          SizedBox(
                            width: double.infinity,
                            child: PrimaryButton(
                              text: '+ Create Notice',
                              onPressed: () async {
                                final created = await Navigator.of(context).push<bool>(
                                  MaterialPageRoute(
                                    builder: (context) => const AddEditNoticeScreen(),
                                  ),
                                );
                                if (created == true) {
                                  _viewModel.fetchNoticesData();
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 24),

                          // SEARCH & FILTER SECTION
                          const Text(
                            'Search & Filter',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMain,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _searchController,
                            style: AppTextStyles.inputText,
                            onChanged: (val) => _viewModel.setSearchQuery(val),
                            decoration: InputDecoration(
                              hintText: 'Search by notice title...',
                              hintStyle: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 14),
                              prefixIcon: const Icon(Icons.search_rounded,
                                  color: AppColors.textSecondary),
                              filled: true,
                              fillColor: AppColors.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppColors.primaryEmerald,
                                    width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              // Type filter (includes Event)
                              SizedBox(
                                width: 200,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _viewModel.selectedTypeFilter,
                                  isExpanded: true,
                                  style: AppTextStyles.inputText,
                                  decoration: InputDecoration(
                                    labelText: 'Notice Type',
                                    filled: true,
                                    fillColor: AppColors.surface,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          const BorderSide(color: AppColors.border),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: AppColors.primaryEmerald,
                                          width: 1.5),
                                    ),
                                  ),
                                  items: [
                                    'All',
                                    'General',
                                    'Academic',
                                    'Exam',
                                    'Holiday',
                                    'Fee',
                                    'Important',
                                    'Event'
                                  ]
                                      .map((t) => DropdownMenuItem(
                                            value: t,
                                            child: Text(t,
                                                overflow: TextOverflow.ellipsis),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      _viewModel.setTypeFilter(val);
                                    }
                                  },
                                ),
                              ),
                              // Status filter
                              SizedBox(
                                width: 200,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _viewModel.selectedStatusFilter,
                                  isExpanded: true,
                                  style: AppTextStyles.inputText,
                                  decoration: InputDecoration(
                                    labelText: 'Status',
                                    filled: true,
                                    fillColor: AppColors.surface,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          const BorderSide(color: AppColors.border),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: AppColors.primaryEmerald,
                                          width: 1.5),
                                    ),
                                  ),
                                  items: [
                                    'All',
                                    'Draft',
                                    'Scheduled',
                                    'Published',
                                    'Expired'
                                  ]
                                      .map((st) => DropdownMenuItem(
                                            value: st,
                                            child: Text(st,
                                                overflow: TextOverflow.ellipsis),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      _viewModel.setStatusFilter(val);
                                    }
                                  },
                                ),
                              ),
                              // Class filter
                              SizedBox(
                                width: 220,
                                child: DropdownButtonFormField<String?>(
                                  initialValue: _viewModel.selectedClassFilter,
                                  isExpanded: true,
                                  style: AppTextStyles.inputText,
                                  decoration: InputDecoration(
                                    labelText: 'Class Filter',
                                    filled: true,
                                    fillColor: AppColors.surface,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          const BorderSide(color: AppColors.border),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: AppColors.primaryEmerald,
                                          width: 1.5),
                                    ),
                                  ),
                                  items: [
                                    const DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text('All Classes',
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    ..._viewModel.classes.map((cls) {
                                      return DropdownMenuItem<String?>(
                                        value: cls.classId,
                                        child: Text(cls.className,
                                            overflow: TextOverflow.ellipsis),
                                      );
                                    }),
                                  ],
                                  onChanged: (val) =>
                                      _viewModel.setClassFilter(val),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // NOTICE LIST HEADER
                          Text(
                            'Notice List (${notices.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMain,
                            ),
                          ),
                          const SizedBox(height: 12),

                          notices.isEmpty
                              ? _buildEmptyState()
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  itemCount: notices.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final notice = notices[index];
                                    return _buildNoticeCard(notice);
                                  },
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

  Widget _buildSummaryCard(
      String label, String value, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasSearchOrFilter = _viewModel.searchQuery.isNotEmpty ||
        _viewModel.selectedTypeFilter != 'All' ||
        _viewModel.selectedStatusFilter != 'All' ||
        _viewModel.selectedClassFilter != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.notifications_off_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            hasSearchOrFilter ? 'No notices found.' : 'No notices yet.',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasSearchOrFilter
                ? 'Try changing your search or filters.'
                : 'Create your first notice to share important information with students.',
            style: AppTextStyles.subtitle,
            textAlign: TextAlign.center,
          ),
          if (!hasSearchOrFilter) ...[
            const SizedBox(height: 20),
            PrimaryButton(
              text: 'Create Notice',
              onPressed: () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (context) => const AddEditNoticeScreen(),
                  ),
                );
                if (created == true) {
                  _viewModel.fetchNoticesData();
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoticeCard(NoticeModel notice) {
    final status = notice.computedStatus;
    final statusColor = _getStatusColor(status);
    final isHighPriority = notice.priority.toLowerCase() == 'high';

    String audienceText = 'All Students';
    if (notice.targetAudience == 'selected_classes' && notice.classIds.isNotEmpty) {
      final classMap = {for (var c in _viewModel.classes) c.classId: c.className};
      final names = notice.classIds
          .map((id) => classMap[id] ?? 'Class')
          .toList();
      if (names.length == 1) {
        audienceText = names.first;
      } else if (names.length <= 2) {
        audienceText = names.join(', ');
      } else {
        audienceText = '${names[0]}, ${names[1]} +${names.length - 2}';
      }
    }

    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => NoticeDetailsScreen(notice: notice),
          ),
        );
        _viewModel.fetchNoticesData();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notice.isPinned
                ? AppColors.primaryEmerald.withValues(alpha: 0.6)
                : AppColors.border,
            width: notice.isPinned ? 1.5 : 1,
          ),
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
                  child: Row(
                    children: [
                      if (notice.isPinned) ...[
                        const Icon(Icons.push_pin_rounded,
                            size: 18, color: AppColors.primaryEmerald),
                        const SizedBox(width: 8),
                      ],
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.lightEmerald,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.notifications_active_outlined,
                          color: AppColors.primaryEmerald,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notice.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMain,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Wrap(
                              spacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  '${notice.type.toUpperCase()} • $audienceText',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (isHighPriority)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'HIGH',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Publish: ${_formatDate(notice.publishDate)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Expiry: ${_formatDate(notice.expiryDate)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
