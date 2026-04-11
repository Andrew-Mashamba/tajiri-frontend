// lib/widgets/budget_context_banner.dart
import 'package:flutter/material.dart';
import '../budget/models/budget_models.dart';
import '../services/expenditure_service.dart';
import '../services/local_storage_service.dart';

/// Compact banner that shows budget envelope status before a payment.
///
/// Drop this into any payment dialog/sheet to give the user budget context
/// at the moment of decision. Gracefully degrades — shows nothing on error.
///
/// Usage:
/// ```dart
/// BudgetContextBanner(
///   category: 'chakula',
///   paymentAmount: 15000,
///   isSwahili: strings.isSwahili,
/// )
/// ```
class BudgetContextBanner extends StatefulWidget {
  final String category;
  final double paymentAmount;
  final bool isSwahili;

  const BudgetContextBanner({
    super.key,
    required this.category,
    required this.paymentAmount,
    this.isSwahili = false,
  });

  @override
  State<BudgetContextBanner> createState() => _BudgetContextBannerState();
}

class _BudgetContextBannerState extends State<BudgetContextBanner> {
  SpendingPace? _pace;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _loadPace();
  }

  @override
  void didUpdateWidget(BudgetContextBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category ||
        oldWidget.paymentAmount != widget.paymentAmount) {
      _loadPace();
    }
  }

  Future<void> _loadPace() async {
    setState(() {
      _loading = true;
      _error = false;
    });

    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) {
        if (mounted) setState(() => _error = true);
        return;
      }

      final now = DateTime.now();
      final pace = await ExpenditureService.getSpendingPace(
        token: token,
        category: widget.category,
        year: now.year,
        month: now.month,
      );

      if (!mounted) return;
      setState(() {
        _pace = pace;
        _loading = false;
        _error = pace == null;
      });
    } catch (e) {
      debugPrint('[BudgetContextBanner] load error: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Graceful degradation: show nothing on error
    if (_error) return const SizedBox.shrink();

    if (_loading) {
      return _buildShell(
        child: Text(
          '...',
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    final pace = _pace;
    if (pace == null) return const SizedBox.shrink();

    // No budget set for this category
    if (pace.allocated <= 0) {
      return _buildBanner(
        icon: Icons.info_outline,
        color: Colors.grey,
        text: widget.isSwahili
            ? 'Hakuna bajeti ya ${_categoryLabel(widget.category)}'
            : 'No budget set for ${_categoryLabel(widget.category)}',
      );
    }

    final label = _categoryLabel(widget.category);
    final remaining = pace.remaining;
    final fits = widget.paymentAmount <= remaining;

    if (fits) {
      return _buildBanner(
        icon: Icons.check_circle_outline_rounded,
        color: Colors.green,
        text: widget.isSwahili
            ? '$label: ${_formatAmount(remaining)} imebaki — inakutosha'
            : '$label: ${_formatAmount(remaining)} remaining — fits',
      );
    }

    // Over budget
    final overBy = widget.paymentAmount - remaining;
    return _buildBanner(
      icon: Icons.warning_amber_rounded,
      color: remaining > 0 ? Colors.amber.shade700 : Colors.red,
      text: widget.isSwahili
          ? '$label: ${_formatAmount(overBy)} zaidi ya bajeti'
          : '$label: ${_formatAmount(overBy)} over budget',
    );
  }

  Widget _buildBanner({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return _buildShell(
      color: color,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShell({required Widget child, Color? color}) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }

  String _categoryLabel(String category) {
    const labels = {
      'kodi': ['Rent', 'Kodi'],
      'chakula': ['Food', 'Chakula'],
      'usafiri': ['Transport', 'Usafiri'],
      'umeme_maji': ['Utilities', 'Umeme na Maji'],
      'simu_intaneti': ['Phone', 'Simu'],
      'afya': ['Health', 'Afya'],
      'ada_shule': ['Education', 'Ada/Shule'],
      'burudani': ['Entertainment', 'Burudani'],
      'ununuzi': ['Shopping', 'Ununuzi'],
      'mavazi': ['Clothing', 'Mavazi'],
      'urembo': ['Personal Care', 'Urembo'],
      'dini': ['Faith', 'Dini'],
      'michango': ['Contributions', 'Michango'],
      'hisa': ['Shares', 'Hisa'],
      'deni': ['Debt/Loans', 'Deni/Mikopo'],
      'akiba': ['Savings', 'Akiba'],
      'kikoba': ['Kikoba', 'Kikoba'],
      'bima': ['Insurance', 'Bima'],
      'biashara': ['Business', 'Biashara'],
    };
    final pair = labels[category];
    if (pair == null) return category;
    return widget.isSwahili ? pair[1] : pair[0];
  }

  static String _formatAmount(double amount) {
    if (amount >= 1000000) {
      final m = amount / 1000000;
      return 'TZS ${m.toStringAsFixed(m.truncateToDouble() == m ? 0 : 1)}M';
    }
    if (amount >= 1000) {
      final k = amount / 1000;
      return 'TZS ${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 1)}K';
    }
    return 'TZS ${amount.toStringAsFixed(0)}';
  }
}
