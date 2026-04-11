// lib/business/pages/add_expense_page.dart
// Add new expense (Ongeza Matumizi).
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../services/local_storage_service.dart';
import '../models/business_models.dart';
import '../services/business_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class AddExpensePage extends StatefulWidget {
  final int businessId;
  const AddExpensePage({super.key, required this.businessId});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  String? _token;
  bool _saving = false;
  ExpenseCategory _category = ExpenseCategory.other;
  final _amountCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _vendorCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  String _paymentMethod = 'cash';
  File? _receiptPhoto;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
  }

  IconData _categoryIcon(ExpenseCategory c) {
    switch (c) {
      case ExpenseCategory.rent:
        return Icons.home_rounded;
      case ExpenseCategory.utilities:
        return Icons.bolt_rounded;
      case ExpenseCategory.supplies:
        return Icons.inventory_2_rounded;
      case ExpenseCategory.transport:
        return Icons.directions_car_rounded;
      case ExpenseCategory.salary:
        return Icons.people_rounded;
      case ExpenseCategory.marketing:
        return Icons.campaign_rounded;
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.communication:
        return Icons.phone_rounded;
      case ExpenseCategory.maintenance:
        return Icons.build_rounded;
      case ExpenseCategory.tax:
        return Icons.account_balance_rounded;
      case ExpenseCategory.insurance:
        return Icons.shield_rounded;
      case ExpenseCategory.other:
        return Icons.more_horiz_rounded;
    }
  }

  String _categoryLabel(ExpenseCategory c) {
    switch (c) {
      case ExpenseCategory.rent:
        return 'Rent';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.supplies:
        return 'Supplies';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.salary:
        return 'Salary';
      case ExpenseCategory.marketing:
        return 'Marketing';
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.communication:
        return 'Comms';
      case ExpenseCategory.maintenance:
        return 'Repairs';
      case ExpenseCategory.tax:
        return 'Tax';
      case ExpenseCategory.insurance:
        return 'Insurance';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  Future<void> _pickReceipt() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, maxWidth: 1200);
      if (picked != null) {
        setState(() => _receiptPhoto = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not pick image')));
      }
    }
  }

  Future<void> _save() async {
    if (_token == null) return;
    final amount =
        double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid amount')));
      return;
    }

    setState(() => _saving = true);

    try {
      final body = {
        'business_id': widget.businessId,
        'category': _category.name,
        'amount': amount,
        'description': _descriptionCtrl.text.trim(),
        'date': _date.toIso8601String(),
        'vendor_name': _vendorCtrl.text.trim(),
        'payment_method': _paymentMethod,
        'notes': _notesCtrl.text.trim(),
      };

      final res = await BusinessService.addExpense(
          _token!, widget.businessId, body);

      if (res.success && _receiptPhoto != null && res.data?.id != null) {
        await BusinessService.uploadReceipt(
            _token!, res.data!.id!, _receiptPhoto!);
      }

      if (mounted) {
        setState(() => _saving = false);
        if (res.success) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Expense added!')));
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(res.message ?? 'Failed')));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Connection error')));
      }
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
    _vendorCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add Expense',
            style: TextStyle(
                color: _kPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Amount
          const Text('Amount (TZS)',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, color: _kPrimary),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _kPrimary.withValues(alpha: 0.2)),
              filled: true,
              fillColor: _kCardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),

          const SizedBox(height: 20),

          // Category grid
          const Text('Category',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.9,
            children: ExpenseCategory.values.map((c) {
              final isSelected = _category == c;
              return GestureDetector(
                onTap: () => setState(() => _category = c),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? _kPrimary : _kCardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color:
                            isSelected ? _kPrimary : Colors.grey.shade200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_categoryIcon(c),
                          size: 22,
                          color:
                              isSelected ? Colors.white : _kPrimary),
                      const SizedBox(height: 4),
                      Text(
                        _categoryLabel(c),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : _kSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Description
          TextField(
            controller: _descriptionCtrl,
            decoration: InputDecoration(
              labelText: 'Description',
              filled: true,
              fillColor: _kCardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),

          const SizedBox(height: 12),

          // Date picker
          GestureDetector(
            onTap: () async {
              final dt = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate:
                    DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now(),
              );
              if (dt != null) setState(() => _date = dt);
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Date',
                filled: true,
                fillColor: _kCardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                suffixIcon: const Icon(Icons.calendar_today_rounded,
                    size: 18, color: _kSecondary),
              ),
              child: Text(df.format(_date)),
            ),
          ),

          const SizedBox(height: 12),

          // Receipt photo
          GestureDetector(
            onTap: _pickReceipt,
            child: Container(
              height: _receiptPhoto != null ? 180 : 80,
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: _receiptPhoto != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_receiptPhoto!,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _receiptPhoto = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt_rounded,
                              size: 28,
                              color:
                                  _kPrimary.withValues(alpha: 0.3)),
                          const SizedBox(height: 4),
                          const Text('Take a photo of the receipt',
                              style: TextStyle(
                                  color: _kSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 12),

          // Vendor
          TextField(
            controller: _vendorCtrl,
            decoration: InputDecoration(
              labelText: 'Vendor / Shop Name',
              filled: true,
              fillColor: _kCardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),

          const SizedBox(height: 12),

          // Payment method
          const Text('Payment Method',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary)),
          const SizedBox(height: 8),
          Row(
            children: [
              _paymentChip('cash', 'Cash', Icons.money_rounded),
              const SizedBox(width: 10),
              _paymentChip(
                  'mpesa', 'M-Pesa', Icons.phone_android_rounded),
              const SizedBox(width: 10),
              _paymentChip(
                  'bank', 'Bank', Icons.account_balance_rounded),
            ],
          ),

          const SizedBox(height: 12),

          // Notes
          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Additional notes',
              filled: true,
              fillColor: _kCardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Save',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _paymentChip(String value, String label, IconData icon) {
    final isSelected = _paymentMethod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentMethod = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? _kPrimary : _kCardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: isSelected ? _kPrimary : Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 20,
                  color: isSelected ? Colors.white : _kPrimary),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : _kPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}
