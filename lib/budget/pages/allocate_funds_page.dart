// lib/budget/pages/allocate_funds_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/budget_models.dart';
import '../services/budget_service.dart';
import '../../services/local_storage_service.dart';

// DESIGN.md tokens
const Color _kBg = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);
const Color _kError = Color(0xFFE53935);
const Color _kSuccess = Color(0xFF4CAF50);

/// Distribute unallocated funds across budget envelopes.
/// Pops with `true` on successful save.
class AllocateFundsPage extends StatefulWidget {
  /// Total unallocated amount available to distribute.
  final double unallocatedAmount;

  /// Current envelopes to allocate to.
  final List<BudgetEnvelope> envelopes;

  const AllocateFundsPage({
    super.key,
    required this.unallocatedAmount,
    required this.envelopes,
  });

  @override
  State<AllocateFundsPage> createState() => _AllocateFundsPageState();
}

class _AllocateFundsPageState extends State<AllocateFundsPage> {
  late List<TextEditingController> _controllers;
  late List<BudgetEnvelope> _envelopes;
  bool _isSaving = false;

  String? _token;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _envelopes = List.of(widget.envelopes);
    _controllers = List.generate(
      _envelopes.length,
      (_) => TextEditingController(),
    );
    _loadAuth();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAuth() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    final user = storage.getUser();
    _userId = user?.userId;
    if (mounted) setState(() {});
  }

  /// Sum of all amounts currently typed in.
  double get _totalAllocating {
    double sum = 0;
    for (final c in _controllers) {
      final val = double.tryParse(c.text.replaceAll(',', '').trim());
      if (val != null && val > 0) sum += val;
    }
    return sum;
  }

  /// Remaining unallocated after typed amounts.
  double get _remaining => widget.unallocatedAmount - _totalAllocating;

  /// Whether any envelope has a non-zero allocation.
  bool get _hasChanges {
    for (final c in _controllers) {
      final val = double.tryParse(c.text.replaceAll(',', '').trim());
      if (val != null && val > 0) return true;
    }
    return false;
  }

  bool get _isOverBudget => _totalAllocating > widget.unallocatedAmount;

  Future<void> _save() async {
    if (_token == null || _userId == null) {
      _showSnack(_isSw ? 'Haijathibitishwa' : 'Not authenticated');
      return;
    }
    if (!_hasChanges) {
      _showSnack(_isSw ? 'Hakuna mabadiliko' : 'No changes to save');
      return;
    }
    if (_isOverBudget) {
      _showSnack(_isSw
          ? 'Jumla inazidi kiasi kisichogawanywa'
          : 'Total exceeds unallocated amount');
      return;
    }

    setState(() => _isSaving = true);

    try {
      int successCount = 0;
      int totalChanges = 0;

      for (int i = 0; i < _envelopes.length; i++) {
        final val =
            double.tryParse(_controllers[i].text.replaceAll(',', '').trim());
        if (val == null || val <= 0) continue;

        totalChanges++;
        final envelope = _envelopes[i];
        final newAllocation = envelope.allocatedAmount + val;

        final result = await BudgetService.updateEnvelope(
          _token!,
          _userId!,
          envelope.id!,
          {'allocated_amount': newAllocation},
        );

        if (result != null) successCount++;
      }

      if (!mounted) return;

      if (successCount == totalChanges) {
        Navigator.pop(context, true);
      } else {
        setState(() => _isSaving = false);
        _showSnack(_isSw
            ? 'Bahasha $successCount/$totalChanges zimehifadhiwa'
            : '$successCount/$totalChanges envelopes saved');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnack(_isSw ? 'Hitilafu imetokea' : 'An error occurred');
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

  String _formatTZS(double amount) {
    if (amount == 0) return 'TZS 0';
    final isNegative = amount < 0;
    final abs = amount.abs();
    final parts = abs.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buffer.write(',');
      buffer.write(parts[i]);
    }
    return '${isNegative ? "-" : ""}TZS $buffer';
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
            sw ? 'Tenga Pesa' : 'Allocate Funds',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _kPrimary,
            ),
          ),
          iconTheme: const IconThemeData(color: _kPrimary),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Unallocated card
              _buildUnallocatedCard(sw),

              // Envelope list
              Expanded(
                child: _envelopes.isEmpty
                    ? Center(
                        child: Text(
                          sw
                              ? 'Hakuna bahasha za kugawanya'
                              : 'No envelopes to allocate to',
                          style: const TextStyle(
                            color: _kTertiary,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: _envelopes.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                          color: _kDivider,
                        ),
                        itemBuilder: (context, index) =>
                            _buildEnvelopeRow(index, sw),
                      ),
              ),

              // Bottom bar: totals + save
              _buildBottomBar(sw),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnallocatedCard(bool sw) {
    final remaining = _remaining;
    final isOver = remaining < 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: isOver
            ? Border.all(color: _kError.withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        children: [
          Text(
            sw ? 'Kiasi Kisichogawanywa' : 'Unallocated Amount',
            style: const TextStyle(
              fontSize: 13,
              color: _kSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatTZS(remaining),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isOver ? _kError : _kPrimary,
            ),
          ),
          if (isOver) ...[
            const SizedBox(height: 4),
            Text(
              sw
                  ? 'Umezidi kiasi kinachopatikana'
                  : 'Exceeds available amount',
              style: const TextStyle(
                fontSize: 12,
                color: _kError,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEnvelopeRow(int index, bool sw) {
    final envelope = _envelopes[index];
    final controller = _controllers[index];
    final addAmount =
        double.tryParse(controller.text.replaceAll(',', '').trim()) ?? 0;
    final newTotal = envelope.allocatedAmount + addAmount;
    final hasValue = addAmount > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _resolveIcon(envelope.icon),
              color: _kPrimary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          // Name + current allocation + new total
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  envelope.displayName(sw),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${sw ? "Sasa" : "Current"}: ${_formatTZS(envelope.allocatedAmount)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _kTertiary,
                  ),
                ),
                if (hasValue) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${_formatTZS(envelope.allocatedAmount)} → ${_formatTZS(newTotal)} (+${_formatTZS(addAmount)})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _kSuccess,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Amount input
          SizedBox(
            width: 110,
            child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
              ],
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: const TextStyle(color: _kTertiary),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 10),
                filled: true,
                fillColor: _kBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _kPrimary, width: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool sw) {
    final total = _totalAllocating;
    final isOver = _isOverBudget;
    final canSave = _hasChanges && !isOver && !_isSaving;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: _kSurface,
        border: Border(top: BorderSide(color: _kDivider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Summary row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sw ? 'Unagawanya:' : 'Allocating:',
                style: const TextStyle(
                  fontSize: 13,
                  color: _kSecondary,
                ),
              ),
              Text(
                _formatTZS(total),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isOver ? _kError : _kPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sw ? 'Itakayobaki:' : 'Will remain:',
                style: const TextStyle(
                  fontSize: 13,
                  color: _kSecondary,
                ),
              ),
              Text(
                _formatTZS(_remaining),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isOver ? _kError : _kSuccess,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: canSave ? _save : null,
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                disabledBackgroundColor: _kPrimary.withValues(alpha: 0.3),
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
                      sw ? 'Tenga Pesa' : 'Allocate Funds',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
