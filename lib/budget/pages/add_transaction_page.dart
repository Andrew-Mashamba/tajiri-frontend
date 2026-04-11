// lib/budget/pages/add_transaction_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/budget_models.dart';
import '../services/budget_service.dart';
import '../../services/expenditure_service.dart';
import '../../services/income_service.dart';
import '../../services/local_storage_service.dart';

// DESIGN.md tokens
const Color _kBg = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kSuccess = Color(0xFF4CAF50);

/// Manual cash expense/income entry screen.
/// Pops with `true` on successful save.
class AddTransactionPage extends StatefulWidget {
  final int? preselectedEnvelopeId;

  const AddTransactionPage({super.key, this.preselectedEnvelopeId});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isExpense = true; // true = expense, false = income
  int? _selectedEnvelopeId;
  List<BudgetEnvelope> _envelopes = [];
  String _incomeSource = 'manual';
  DateTime _date = DateTime.now();
  bool _isSaving = false;
  bool _isLoadingEnvelopes = true;

  String? _token;
  int? _userId;

  // Income source options
  static const _incomeSources = [
    'top_up',
    'salary',
    'creator_earnings',
    'shop_sale',
    'tajirika',
    'michango',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedEnvelopeId = widget.preselectedEnvelopeId;
    _loadAuth();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadAuth() async {
    final storage = LocalStorageService.instanceSync;
    _token = storage?.getAuthToken();
    final user = storage?.getUser();
    _userId = user?.userId;
    if (_token != null && _userId != null) {
      _loadEnvelopes();
    } else {
      if (mounted) setState(() => _isLoadingEnvelopes = false);
    }
  }

  Future<void> _loadEnvelopes() async {
    try {
      final result =
          await BudgetService.getUserEnvelopes(_token!, _userId!);
      if (mounted) {
        setState(() {
          _envelopes =
              result.success ? result.envelopes : <BudgetEnvelope>[];
          _isLoadingEnvelopes = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingEnvelopes = false);
    }
  }

  Future<void> _save() async {
    final amountText = _amountController.text.replaceAll(',', '').trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showSnack(_isSw
          ? 'Tafadhali weka kiasi sahihi'
          : 'Please enter a valid amount');
      return;
    }

    final desc = _descriptionController.text.trim();
    if (desc.isEmpty) {
      _showSnack(_isSw ? 'Tafadhali weka maelezo' : 'Please add a description');
      return;
    }

    if (_isExpense && _envelopes.isNotEmpty && _selectedEnvelopeId == null) {
      _showSnack(
          _isSw ? 'Tafadhali chagua bahasha' : 'Please select an envelope');
      return;
    }

    if (_token == null) {
      _showSnack(_isSw ? 'Haijathibitishwa' : 'Not authenticated');
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (_isExpense) {
        // Find envelope tag from selected envelope
        String? envelopeTag;
        if (_selectedEnvelopeId != null) {
          final env = _envelopes.firstWhere(
            (e) => e.id == _selectedEnvelopeId,
            orElse: () => _envelopes.first,
          );
          envelopeTag = env.moduleTag ?? env.nameEn.toLowerCase();
        }

        final result = await ExpenditureService.recordExpenditure(
          token: _token!,
          amount: amount,
          category: envelopeTag ?? 'other',
          description: desc,
          sourceModule: 'manual',
          envelopeTag: envelopeTag,
          date: _date,
          metadata: {'entry_type': 'cash'},
        );

        if (!mounted) return;
        if (result != null) {
          Navigator.pop(context, true);
        } else {
          setState(() => _isSaving = false);
          _showSnack(_isSw ? 'Imeshindikana kuhifadhi' : 'Failed to save');
        }
      } else {
        final result = await IncomeService.recordIncome(
          token: _token!,
          amount: amount,
          source: _incomeSource,
          description: desc,
          sourceModule: 'manual',
          date: _date,
          metadata: {'entry_type': 'cash'},
        );

        if (!mounted) return;
        if (result != null) {
          Navigator.pop(context, true);
        } else {
          setState(() => _isSaving = false);
          _showSnack(_isSw ? 'Imeshindikana kuhifadhi' : 'Failed to save');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnack(_isSw ? 'Hitilafu imetokea' : 'An error occurred');
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: _kPrimary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _date = picked);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  bool get _isSw {
    final s = AppStringsScope.of(context);
    return s?.isSwahili ?? false;
  }

  String _incomeSourceLabel(String source) {
    final sw = _isSw;
    switch (source) {
      case 'top_up':
        return sw ? 'Jazia' : 'Top Up';
      case 'salary':
        return sw ? 'Mshahara' : 'Salary';
      case 'creator_earnings':
        return sw ? 'Mapato ya Muundaji' : 'Creator Earnings';
      case 'shop_sale':
        return sw ? 'Mauzo ya Duka' : 'Shop Sale';
      case 'tajirika':
        return sw ? 'Tajirika' : 'Tajirika';
      case 'michango':
        return sw ? 'Michango' : 'Contributions';
      case 'other':
        return sw ? 'Nyingine' : 'Other';
      default:
        return source;
    }
  }

  /// Resolve envelope icon string to IconData.
  static IconData _resolveIcon(String name) {
    const iconMap = <String, IconData>{
      'restaurant': Icons.restaurant_rounded,
      'directions_bus': Icons.directions_bus_rounded,
      'home': Icons.home_rounded,
      'school': Icons.school_rounded,
      'local_hospital': Icons.local_hospital_rounded,
      'checkroom': Icons.checkroom_rounded,
      'savings': Icons.savings_rounded,
      'shopping_bag': Icons.shopping_bag_rounded,
      'phone_android': Icons.phone_android_rounded,
      'bolt': Icons.bolt_rounded,
      'water_drop': Icons.water_drop_rounded,
      'movie': Icons.movie_rounded,
      'fitness_center': Icons.fitness_center_rounded,
      'pets': Icons.pets_rounded,
      'child_care': Icons.child_care_rounded,
      'church': Icons.church_rounded,
      'volunteer_activism': Icons.volunteer_activism_rounded,
      'flight': Icons.flight_rounded,
      'more_horiz': Icons.more_horiz_rounded,
      'category': Icons.category_rounded,
    };
    return iconMap[name] ?? Icons.category_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final sw = _isSw;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kSurface,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          title: Text(
            sw ? 'Ongeza Muamala' : 'Add Transaction',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _kPrimary,
            ),
          ),
          iconTheme: const IconThemeData(color: _kPrimary),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Cash badge
              _buildCashBadge(sw),
              const SizedBox(height: 16),

              // Type toggle (expense / income)
              _buildTypeToggle(sw),
              const SizedBox(height: 24),

              // Amount input
              _buildLabel(sw ? 'Kiasi' : 'Amount'),
              const SizedBox(height: 8),
              _buildAmountField(),
              const SizedBox(height: 16),

              // Description
              _buildLabel(sw ? 'Maelezo' : 'Description'),
              const SizedBox(height: 8),
              _buildDescriptionField(sw),
              const SizedBox(height: 16),

              // Envelope picker (expense) or Source picker (income)
              if (_isExpense) ...[
                _buildLabel(sw ? 'Bahasha' : 'Envelope'),
                const SizedBox(height: 8),
                _buildEnvelopePicker(sw),
                const SizedBox(height: 16),
              ] else ...[
                _buildLabel(sw ? 'Chanzo' : 'Source'),
                const SizedBox(height: 8),
                _buildSourcePicker(),
                const SizedBox(height: 16),
              ],

              // Date picker
              _buildLabel(sw ? 'Tarehe' : 'Date'),
              const SizedBox(height: 8),
              _buildDatePicker(sw),
              const SizedBox(height: 32),

              // Save button
              _buildSaveButton(sw),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCashBadge(bool sw) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _kPrimary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.money_rounded, size: 14, color: _kPrimary),
            const SizedBox(width: 4),
            Text(
              sw ? 'Taslimu' : 'Cash',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle(bool sw) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isExpense = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _isExpense ? _kPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    sw ? 'Matumizi' : 'Expense',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _isExpense ? Colors.white : _kSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isExpense = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: !_isExpense ? _kSuccess : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    sw ? 'Mapato' : 'Income',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: !_isExpense ? Colors.white : _kSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _kPrimary,
      ),
    );
  }

  Widget _buildAmountField() {
    return TextField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
      ],
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: _kPrimary,
      ),
      decoration: InputDecoration(
        prefixText: 'TZS ',
        prefixStyle: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: _kTertiary,
        ),
        filled: true,
        fillColor: _kSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      ),
    );
  }

  Widget _buildDescriptionField(bool sw) {
    return TextField(
      controller: _descriptionController,
      textCapitalization: TextCapitalization.sentences,
      maxLines: 1,
      decoration: InputDecoration(
        hintText: sw ? 'Mfano: Grocery za wiki' : 'E.g.: Weekly groceries',
        hintStyle: const TextStyle(color: _kTertiary),
        filled: true,
        fillColor: _kSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildEnvelopePicker(bool sw) {
    if (_isLoadingEnvelopes) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _kPrimary,
            ),
          ),
        ),
      );
    }

    if (_envelopes.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          sw ? 'Hakuna bahasha bado' : 'No envelopes yet',
          style: const TextStyle(color: _kTertiary, fontSize: 14),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _selectedEnvelopeId,
          isExpanded: true,
          hint: Text(
            sw ? 'Chagua bahasha' : 'Select envelope',
            style: const TextStyle(color: _kTertiary),
          ),
          icon: const Icon(Icons.expand_more_rounded, color: _kSecondary),
          items: _envelopes.map((e) {
            return DropdownMenuItem<int?>(
              value: e.id,
              child: Row(
                children: [
                  Icon(
                    _resolveIcon(e.icon),
                    size: 18,
                    color: _kSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.displayName(sw),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _kPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) => setState(() => _selectedEnvelopeId = v),
        ),
      ),
    );
  }

  Widget _buildSourcePicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _incomeSources.map((source) {
        final isSelected = _incomeSource == source;
        return GestureDetector(
          onTap: () => setState(() => _incomeSource = source),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? _kPrimary : _kSurface,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? null
                  : Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Text(
              _incomeSourceLabel(source),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : _kPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDatePicker(bool sw) {
    final months = sw
        ? [
            '',
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'Mei',
            'Jun',
            'Jul',
            'Ago',
            'Sep',
            'Okt',
            'Nov',
            'Des'
          ]
        : [
            '',
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec'
          ];
    final dateStr =
        '${_date.day} ${months[_date.month]} ${_date.year}';

    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, size: 20, color: _kSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                dateStr,
                style: const TextStyle(fontSize: 14, color: _kPrimary),
              ),
            ),
            const Icon(Icons.expand_more_rounded, size: 20, color: _kSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(bool sw) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: _isSaving ? null : _save,
        style: FilledButton.styleFrom(
          backgroundColor: _kPrimary,
          disabledBackgroundColor: _kPrimary.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                sw ? 'Hifadhi' : 'Save',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
