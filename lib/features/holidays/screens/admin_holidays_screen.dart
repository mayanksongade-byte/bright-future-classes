import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/holiday_model.dart';
import '../../../data/repositories/class_repository.dart';
import '../view_models/holidays_view_model.dart';

class AdminHolidaysScreen extends StatefulWidget {
  const AdminHolidaysScreen({super.key});

  @override
  State<AdminHolidaysScreen> createState() => _AdminHolidaysScreenState();
}

class _AdminHolidaysScreenState extends State<AdminHolidaysScreen> {
  late final HolidaysViewModel _viewModel;
  final ClassRepository _classRepository = ClassRepository();
  List<ClassModel> _allClasses = [];

  static const List<String> _holidayTypes = [
    'Festival',
    'Public Holiday',
    'Tuition Holiday',
    'Vacation',
    'Special Holiday',
  ];

  @override
  void initState() {
    super.initState();
    _viewModel = HolidaysViewModel();
    _viewModel.addListener(_onViewModelChange);
    _viewModel.loadHolidays();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      final list = await _classRepository.getClasses();
      if (mounted) {
        setState(() {
          _allClasses = list;
        });
      }
    } catch (_) {}
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

  void _showAddEditHolidayModal({HolidayModel? holiday}) {
    final titleController = TextEditingController(text: holiday?.title ?? '');
    final noteController = TextEditingController(text: holiday?.note ?? '');
    String selectedType = holiday?.type ?? _holidayTypes.first;
    DateTime startDate = holiday != null && holiday.startDate.isNotEmpty
        ? DateTime.tryParse(holiday.startDate) ?? DateTime.now()
        : DateTime.now();
    DateTime endDate = holiday != null && holiday.endDate.isNotEmpty
        ? DateTime.tryParse(holiday.endDate) ?? startDate
        : startDate;
    List<String> selectedClassIds = List<String>.from(holiday?.applicableClassIds ?? []);
    bool isAllClasses = selectedClassIds.isEmpty;

    String formatDateStr(DateTime d) {
      final y = d.year.toString().padLeft(4, '0');
      final m = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      return '$y-$m-$day';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
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
                    Text(
                      holiday == null ? 'Add New Holiday' : 'Edit Holiday',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Holiday Name *',
                        hintText: 'e.g. Diwali Holiday',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Type
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: _holidayTypes
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedType = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    // Date Range Pickers
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: startDate,
                                firstDate: DateTime(2025),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  startDate = picked;
                                  if (endDate.isBefore(startDate)) {
                                    endDate = startDate;
                                  }
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Start Date',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text(formatDateStr(startDate)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: endDate,
                                firstDate: startDate,
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setModalState(() => endDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'End Date',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text(formatDateStr(endDate)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Applicability Choice
                    const Text('Applicability', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('All Classes'),
                          selected: isAllClasses,
                          selectedColor: AppColors.lightEmerald,
                          onSelected: (sel) {
                            setModalState(() {
                              isAllClasses = true;
                              selectedClassIds.clear();
                            });
                          },
                        ),
                        const SizedBox(width: 12),
                        ChoiceChip(
                          label: const Text('Selected Classes'),
                          selected: !isAllClasses,
                          selectedColor: AppColors.lightEmerald,
                          onSelected: (sel) {
                            setModalState(() => isAllClasses = false);
                          },
                        ),
                      ],
                    ),

                    if (!isAllClasses && _allClasses.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: _allClasses.map((cls) {
                          final isSel = selectedClassIds.contains(cls.classId);
                          return FilterChip(
                            label: Text(cls.className),
                            selected: isSel,
                            selectedColor: AppColors.lightEmerald,
                            checkmarkColor: AppColors.darkEmerald,
                            onSelected: (sel) {
                              setModalState(() {
                                if (sel) {
                                  selectedClassIds.add(cls.classId);
                                } else {
                                  selectedClassIds.remove(cls.classId);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Note
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Note / Reason (Optional)',
                        hintText: 'e.g. Diwali celebration with family',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    PrimaryButton(
                      text: holiday == null ? 'Save Holiday' : 'Update Holiday',
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);

                        final success = await _viewModel.saveHoliday(
                          holidayId: holiday?.holidayId,
                          title: titleController.text,
                          type: selectedType,
                          startDate: formatDateStr(startDate),
                          endDate: formatDateStr(endDate),
                          applicableClassIds: isAllClasses ? [] : selectedClassIds,
                          note: noteController.text,
                        );

                        if (!mounted) return;
                        if (success) {
                          navigator.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Holiday saved successfully.'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } else if (_viewModel.errorMessage != null) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(_viewModel.errorMessage!),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteHoliday(HolidayModel holiday) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Holiday?'),
          content: Text('Are you sure you want to delete "${holiday.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(context).pop();
                final success = await _viewModel.deleteHoliday(holiday.holidayId);
                if (!mounted) return;
                if (success) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Holiday deleted.'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'Holiday & Academic Calendar',
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
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Holidays (${_viewModel.holidays.length})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMain,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _showAddEditHolidayModal(),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Add Holiday'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryEmerald,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _viewModel.holidays.isEmpty
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Text(
                                  'No holidays found. Tap "Add Holiday" to create one.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _viewModel.holidays.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final holiday = _viewModel.holidays[index];
                                  final bool isRange = holiday.startDate != holiday.endDate;

                                  return Container(
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                holiday.title,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textMain,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.background,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                    color: AppColors.border),
                                              ),
                                              child: Text(
                                                holiday.type,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.event_outlined,
                                                size: 16,
                                                color: AppColors.primaryEmerald),
                                            const SizedBox(width: 6),
                                            Text(
                                              isRange
                                                  ? '${holiday.startDate} to ${holiday.endDate}'
                                                  : holiday.startDate,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textMain,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.lightEmerald,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                holiday.isAllClasses
                                                    ? 'All Classes'
                                                    : '${holiday.applicableClassIds.length} Classes',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.darkEmerald,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (holiday.note.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            'Note: ${holiday.note}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            TextButton.icon(
                                              onPressed: () =>
                                                  _showAddEditHolidayModal(
                                                      holiday: holiday),
                                              icon: const Icon(Icons.edit_outlined,
                                                  size: 16),
                                              label: const Text('Edit'),
                                            ),
                                            const SizedBox(width: 8),
                                            TextButton.icon(
                                              onPressed: () =>
                                                  _confirmDeleteHoliday(holiday),
                                              icon: const Icon(
                                                  Icons.delete_outline_rounded,
                                                  size: 16,
                                                  color: AppColors.error),
                                              label: const Text('Delete',
                                                  style: TextStyle(
                                                      color: AppColors.error)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
