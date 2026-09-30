import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/fee_model.dart';
import '../view_models/fees_view_model.dart';

class FeeDetailsScreen extends StatefulWidget {
  final StudentFeeItem studentFeeItem;

  const FeeDetailsScreen({super.key, required this.studentFeeItem});

  @override
  State<FeeDetailsScreen> createState() => _FeeDetailsScreenState();
}

class _FeeDetailsScreenState extends State<FeeDetailsScreen> {
  late StudentFeeItem _item;
  late final FeesViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _item = widget.studentFeeItem;
    _viewModel = FeesViewModel();
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

  Future<void> _refreshItem() async {
    await _viewModel.fetchFeesData();
    final updated = _viewModel.allFeeItems.firstWhere(
      (i) => i.student.studentId == _item.student.studentId,
      orElse: () => _item,
    );
    if (mounted) {
      setState(() {
        _item = updated;
      });
    }
  }

  void _showEditFeeDialog() {
    final totalController =
        TextEditingController(text: _item.fee.totalAmount.toStringAsFixed(0));
    final discountController =
        TextEditingController(text: _item.fee.discountAmount.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Edit Fee Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: totalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Total Fees (₹)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: discountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Discount (₹)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final total = double.tryParse(totalController.text.trim()) ?? -1;
                final disc =
                    double.tryParse(discountController.text.trim()) ?? -1;

                if (total < 0 || disc < 0 || disc > total) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter valid amounts. Discount cannot exceed Total.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                Navigator.of(dialogContext).pop();
                final success = await _viewModel.updateFee(
                  feeId: _item.fee.feeId,
                  totalAmount: total,
                  discountAmount: disc,
                  alreadyPaid: _item.totalPaid,
                );

                if (!mounted) return;
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fee updated successfully.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  await _refreshItem();
                } else if (_viewModel.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_viewModel.errorMessage!),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryEmerald,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showAddPaymentDialog() {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String selectedMethod = 'Cash';
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (stContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Add Payment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pending Amount: ₹${_item.pending.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Amount (₹)'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedMethod,
                      decoration:
                          const InputDecoration(labelText: 'Payment Method'),
                      items: ['Cash', 'UPI', 'Bank Transfer', 'Other']
                          .map((m) =>
                              DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedMethod = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: stContext,
                          initialDate: selectedDate,
                          firstDate: DateTime(2025, 1, 1),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          if (!mounted) return;
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration:
                            const InputDecoration(labelText: 'Payment Date'),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                            ),
                            const Icon(Icons.calendar_today_rounded, size: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      decoration:
                          const InputDecoration(labelText: 'Note (Optional)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final amount =
                        double.tryParse(amountController.text.trim()) ?? -1;
                    if (amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Payment amount must be greater than 0.'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }
                    if (amount > _item.pending) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Payment amount cannot be greater than pending amount.'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }

                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    final chosen = DateTime(selectedDate.year,
                        selectedDate.month, selectedDate.day);
                    if (chosen.isAfter(today)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Payment date cannot be in the future.'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }

                    final dateStr =
                        '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

                    Navigator.of(dialogCtx).pop();

                    final success = await _viewModel.addPayment(
                      feeId: _item.fee.feeId,
                      studentId: _item.student.studentId,
                      classId: _item.student.classId ?? '',
                      amount: amount,
                      paymentDate: dateStr,
                      paymentMethod: selectedMethod,
                      note: noteController.text.trim(),
                      currentPending: _item.pending,
                    );

                    if (!mounted) return;
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Payment saved successfully.'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      await _refreshItem();
                    } else if (_viewModel.errorMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_viewModel.errorMessage!),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryEmerald,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add Payment'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showReceiptDialog(FeePaymentModel payment) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Column(
            children: const [
              Text('BRIGHT FUTURE CLASSES',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryEmerald)),
              SizedBox(height: 4),
              Text('Fee Payment Receipt',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Student Name: ${_item.student.name}'),
              Text('Student ID: ${_item.student.studentId}'),
              Text(
                  'Class: ${_item.classModel != null ? _item.classModel!.className : 'N/A'}'),
              Text('Academic Year: ${_item.fee.academicYear}'),
              const Divider(),
              Text('Payment Date: ${payment.paymentDate}'),
              Text('Payment Method: ${payment.paymentMethod}'),
              if (payment.note.isNotEmpty) Text('Note: ${payment.note}'),
              const Divider(),
              Text('Payment Amount: ₹${payment.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success)),
              Text('Total Paid: ₹${_item.totalPaid.toStringAsFixed(0)}'),
              Text('Pending: ₹${_item.pending.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.warning)),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryEmerald,
                foregroundColor: Colors.white,
              ),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePayment(FeePaymentModel payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete this payment?'),
          content: const Text(
              'This action will update the student\'s pending fee amount.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final success = await _viewModel.deletePayment(payment.paymentId);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment deleted successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        await _refreshItem();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor = AppColors.warning;
    if (_item.status == 'Paid') {
      statusColor = AppColors.success;
    } else if (_item.status == 'Partially Paid') {
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
        title: Text(
          _item.student.name,
          style: const TextStyle(
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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Student & Fee Summary Card
                  Container(
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _item.student.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textMain,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'ID: ${_item.student.studentId} • ${_item.classModel != null ? _item.classModel!.className : 'No Class'} • Academic Year: ${_item.fee.academicYear}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
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
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryTile(
                                label: 'Total Fees',
                                value:
                                    '₹${_item.fee.totalAmount.toStringAsFixed(0)}',
                              ),
                            ),
                            Expanded(
                              child: _buildSummaryTile(
                                label: 'Discount',
                                value:
                                    '₹${_item.fee.discountAmount.toStringAsFixed(0)}',
                              ),
                            ),
                            Expanded(
                              child: _buildSummaryTile(
                                label: 'Final Payable',
                                value:
                                    '₹${_item.fee.finalPayable.toStringAsFixed(0)}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryTile(
                                label: 'Total Paid',
                                value:
                                    '₹${_item.totalPaid.toStringAsFixed(0)}',
                                valueColor: AppColors.success,
                              ),
                            ),
                            Expanded(
                              child: _buildSummaryTile(
                                label: 'Pending',
                                value:
                                    '₹${_item.pending.toStringAsFixed(0)}',
                                valueColor: _item.pending > 0
                                    ? AppColors.warning
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _showEditFeeDialog,
                                icon: const Icon(Icons.edit_outlined,
                                    size: 16, color: AppColors.primaryEmerald),
                                label: const Text('Edit Fee',
                                    style: TextStyle(
                                        color: AppColors.primaryEmerald)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: AppColors.primaryEmerald),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PrimaryButton(
                                text: 'Add Payment',
                                onPressed: _showAddPaymentDialog,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Payment History Section
                  const Text(
                    'Payment History',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _item.payments.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Text(
                            'No payment records found.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _item.payments.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final payment = _item.payments[index];
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.lightEmerald,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.receipt_long_outlined,
                                      color: AppColors.primaryEmerald,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '₹${payment.amount.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.success,
                                              ),
                                            ),
                                            Text(
                                              payment.paymentDate,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Method: ${payment.paymentMethod}${payment.note.isNotEmpty ? ' • Note: ${payment.note}' : ''}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.receipt_rounded,
                                        color: AppColors.info, size: 20),
                                    onPressed: () =>
                                        _showReceiptDialog(payment),
                                    tooltip: 'View Receipt',
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: AppColors.error,
                                        size: 20),
                                    onPressed: () => _deletePayment(payment),
                                    tooltip: 'Delete Payment',
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

  Widget _buildSummaryTile({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
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
        const SizedBox(height: 4),
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
    );
  }
}
