import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; // For currency formatting
import 'package:url_launcher/url_launcher.dart';
import 'DataStore.dart';
import 'BankTransferScreen.dart';
import 'HttpService.dart';

final formatCurrency = NumberFormat.currency(symbol: 'Tsh ');

// Design Guidelines Colors (Monochrome)
const _primaryText = Color(0xFF1A1A1A);
const _secondaryText = Color(0xFF666666);
const _headerBg = Color(0xFF1A1A1A);
const _rowBg = Color(0xFFFFFFFF);
const _totalRowBg = Color(0xFFFAFAFA);
const _borderColor = Color(0xFF999999);

class AkibaTable extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final Function(double totalSaved, int transactionCount)? onTotalsCalculated;

  const AkibaTable({super.key, required this.data, this.onTotalsCalculated});

  @override
  State<AkibaTable> createState() => _AkibaTableState();
}

class _AkibaTableState extends State<AkibaTable> {
  bool _isLoadingControlNumbers = false;

  @override
  void initState() {
    super.initState();
    _fetchControlNumbers();
  }

  /// Fetch control numbers from backend when widget initializes
  Future<void> _fetchControlNumbers() async {
    final kikobaId = DataStore.currentKikobaId;
    final userId = DataStore.currentUserId;

    if (kikobaId == null || userId == null) {
      debugPrint('AkibaTable: Cannot fetch control numbers - kikobaId or userId is null');
      return;
    }

    setState(() => _isLoadingControlNumbers = true);

    try {
      final currentYear = DateTime.now().year;

      final controlNumbers = await HttpService.fetchControlNumbers(
        kikobaId: kikobaId,
        type: 'akiba',
        userId: userId,
        year: currentYear,
        status: 'all',
      );

      // Update DataStore with fetched control numbers
      DataStore.controlNumbersAkiba = controlNumbers;
      debugPrint('AkibaTable: Loaded ${controlNumbers.length} control numbers for akiba');
    } catch (e) {
      debugPrint('AkibaTable: Error fetching control numbers: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingControlNumbers = false);
      }
    }
  }

  // Helper to parse value (can be String or num) to double
  double _parseValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Format date from various formats to dd/mm
  String _formatDate(dynamic dateValue) {
    if (dateValue == null || dateValue.toString().isEmpty) return '';

    try {
      // Try parsing the date
      final dateStr = dateValue.toString();

      // Try parsing ISO format or other formats
      DateTime? parsedDate;

      // Try ISO format (2025-01-15)
      try {
        parsedDate = DateTime.parse(dateStr);
      } catch (e) {
        // If parsing fails, return original string
        return dateStr;
      }

      // Format as dd/mm (short format)
      return DateFormat('dd/MM').format(parsedDate);
    } catch (e) {
      return dateValue.toString();
    }
  }

  // Get description from record
  String _getDescription(Map<String, dynamic> record) {
    // Try to get description from various possible fields
    if (record['description'] != null && record['description'].toString().isNotEmpty) {
      return record['description'].toString();
    }
    if (record['narration'] != null && record['narration'].toString().isNotEmpty) {
      return record['narration'].toString();
    }
    if (record['remarks'] != null && record['remarks'].toString().isNotEmpty) {
      return record['remarks'].toString();
    }
    // Default description
    return 'Malipo ya Akiba';
  }

  // Function to build the header row
  TableRow _buildHeaderRow() {
    return TableRow(
      decoration: const BoxDecoration(color: _headerBg),
      children: [
        _buildHeaderCell("Tarehe"),
        _buildHeaderCell("Kutoa"),    // Debit (withdrawal)
        _buildHeaderCell("Kuweka"),   // Credit (deposit)
        _buildHeaderCell("Salio"),
        _buildHeaderCell(""), // Info icon column
      ],
    );
  }

  // Function to build a data row
  TableRow _buildDataRow(Map<String, dynamic> record, BuildContext context) {
    // Get credit (deposit) and debit (withdrawal) amounts
    final credit = _parseValue(record['credit']);
    final debit = _parseValue(record['debit']);

    // Get date and description from new fields
    final date = _formatDate(record['reg_date'] ?? record['date']); // Fallback to 'date' if needed
    final description = record['description']?.toString() ?? _getDescription(record);

    // Use backend-provided running balance
    final balance = _parseValue(record['balance']);

    return TableRow(
      decoration: const BoxDecoration(color: _rowBg),
      children: [
        _buildDataCell(date),
        _buildDataCell(debit > 0 ? formatCurrency.format(debit).replaceAll("Tsh ", "") : "-", isAmount: true),
        _buildDataCell(credit > 0 ? formatCurrency.format(credit).replaceAll("Tsh ", "") : "-", isAmount: true),
        _buildDataCell(formatCurrency.format(balance).replaceAll("Tsh ", ""), isBold: true),
        _buildInfoIconCell(context, description, record),
      ],
    );
  }

  // Build info icon cell
  Widget _buildInfoIconCell(BuildContext context, String description, Map<String, dynamic> record) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: Center(
        child: IconButton(
          icon: const Icon(Icons.info_outline, size: 18),
          color: _secondaryText,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => _showTransactionDetails(context, record, description),
        ),
      ),
    );
  }

  // Show transaction details dialog
  void _showTransactionDetails(BuildContext context, Map<String, dynamic> record, String description) {
    final credit = _parseValue(record['credit']);
    final debit = _parseValue(record['debit']);
    final balance = _parseValue(record['balance']);
    final date = _formatDate(record['reg_date'] ?? record['date']);
    final name = record['name']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Maelezo ya Muamala'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Tarehe:', date),
            const SizedBox(height: 8),
            _buildDetailRow('Jina:', name),
            const SizedBox(height: 8),
            _buildDetailRow('Maelezo:', description),
            const SizedBox(height: 8),
            if (debit > 0) _buildDetailRow('Kutoa:', formatCurrency.format(debit)),
            if (credit > 0) _buildDetailRow('Kuweka:', formatCurrency.format(credit)),
            const SizedBox(height: 8),
            _buildDetailRow('Salio:', formatCurrency.format(balance), isBold: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Funga'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: _secondaryText,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: _primaryText,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // Function to build the total row
  TableRow _buildTotalRow(double totalDebit, double totalCredit, int transactionCount) {
    return TableRow(
      decoration: const BoxDecoration(color: _totalRowBg),
      children: [
        _buildDataCell("Jumla", fontWeight: FontWeight.w600),
        _buildDataCell(formatCurrency.format(totalDebit).replaceAll("Tsh ", ""), fontWeight: FontWeight.w600),
        _buildDataCell(formatCurrency.format(totalCredit).replaceAll("Tsh ", ""), fontWeight: FontWeight.w600),
        _buildDataCell("", fontWeight: FontWeight.w600),
        _buildDataCell("$transactionCount", fontWeight: FontWeight.w600, fontSize: 11),
      ],
    );
  }

  // Helper function to build the header cells
  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontSize: 12,
        ),
      ),
    );
  }

  // Helper function to build the data cells
  Widget _buildDataCell(
    String text, {
    FontWeight fontWeight = FontWeight.normal,
    bool isDescription = false,
    bool isAmount = false,
    bool isBold = false,
    double? fontSize,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.w600 : fontWeight,
          color: isAmount ? _primaryText : _secondaryText,
          fontSize: fontSize ?? (isDescription ? 11 : 12),
        ),
        maxLines: isDescription ? 2 : 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sort data by date (oldest first like bank statement)
    final sortedData = List<Map<String, dynamic>>.from(widget.data);
    sortedData.sort((a, b) {
      try {
        final dateA = DateTime.parse(a['reg_date']?.toString() ?? a['date']?.toString() ?? '');
        final dateB = DateTime.parse(b['reg_date']?.toString() ?? b['date']?.toString() ?? '');
        return dateA.compareTo(dateB); // Oldest first
      } catch (e) {
        return 0;
      }
    });

    // Build table rows using backend-provided balance
    List<TableRow> rows = [_buildHeaderRow()];
    double totalDeposits = 0.0;
    double totalWithdrawals = 0.0;

    for (var record in sortedData) {
      final credit = _parseValue(record['credit']);
      final debit = _parseValue(record['debit']);
      totalDeposits += credit;
      totalWithdrawals += debit;

      rows.add(_buildDataRow(record, context));
    }

    rows.add(_buildTotalRow(totalWithdrawals, totalDeposits, sortedData.length));

    // Get current balance from last transaction (backend provides running balance)
    final currentBalance = sortedData.isNotEmpty
        ? _parseValue(sortedData.last['balance'])
        : 0.0;

    // Notify parent about totals
    if (widget.onTotalsCalculated != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onTotalsCalculated!(currentBalance, sortedData.length);
      });
    }

    return Column(
      children: [
        // Action Buttons at top
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _headerBg,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _showAddSavingsDialog(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _isLoadingControlNumbers
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.add_rounded, size: 16),
                        const SizedBox(width: 4),
                        const Flexible(
                          child: Text(
                            'Weka Akiba',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _headerBg,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: _headerBg, width: 1),
                      ),
                    ),
                    onPressed: () => _showWithdrawDialog(context),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.remove_rounded, size: 16),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Toa Akiba',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _headerBg,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: _borderColor, width: 1),
                      ),
                    ),
                    onPressed: () => _showOtherServicesDialog(context),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.more_horiz_rounded, size: 16),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Huduma nyingine',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Statement Table or Empty State
        if (sortedData.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.savings_outlined, size: 48, color: _borderColor),
                  const SizedBox(height: 8),
                  Text(
                    'Hakuna muamala wa akiba',
                    style: TextStyle(color: _secondaryText, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bonyeza "Weka Akiba" kuanza kuweka',
                    style: TextStyle(color: _borderColor, fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          Table(
            border: TableBorder.all(color: _borderColor.withOpacity(0.3), width: 1),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: FlexColumnWidth(1.5), // Date (dd/mm)
              1: FlexColumnWidth(2),   // Debit (Kutoa)
              2: FlexColumnWidth(2),   // Credit (Kuweka)
              3: FlexColumnWidth(2),   // Balance (Salio)
              4: FixedColumnWidth(40), // Info icon (small)
            },
            children: rows,
          ),
      ],
    );
  }

  // Show add savings dialog
  void _showAddSavingsDialog(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController(
      text: 'Malipo ya Akiba',
    );

    // Check for any pending control number
    Map<String, dynamic>? paymentLink;
    try {
      final payments = DataStore.getControlNumbers('akiba');
      paymentLink = payments.firstWhere(
        (p) => p['status'] == 'pending',
        orElse: () => null,
      );
    } catch (e) {
      paymentLink = null;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _headerBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.savings_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Weka Akiba',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _primaryText),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Kiasi cha Akiba *',
                    hintText: 'Ingiza kiasi unachotaka kuweka',
                    prefixIcon: const Icon(Icons.money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Maelezo (Optional)',
                    hintText: 'Eleza malipo yako',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Payment Link Option
                if (paymentLink != null) ...[
                  _buildPaymentOption(
                    context: context,
                    icon: Icons.phone_android_rounded,
                    title: 'Lipa kwa Simu',
                    subtitle: 'Namba: ${paymentLink!['control_number']}',
                    onTap: () {
                      Navigator.pop(context);
                      _launchPaymentUrl(context, paymentLink!['payment_url']);
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                // Bank Transfer Option
                _buildPaymentOption(
                  context: context,
                  icon: Icons.account_balance_rounded,
                  title: 'Lipa kwa Benki',
                  subtitle: 'Hamisha fedha kwenda akaunti ya kikundi',
                  onTap: () {
                    final amount = double.tryParse(amountController.text.trim());
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tafadhali ingiza kiasi sahihi')),
                      );
                      return;
                    }

                    final description = descriptionController.text.trim().isEmpty
                        ? 'Malipo ya Akiba - ${DataStore.currentUserName}'
                        : descriptionController.text.trim();

                    Navigator.pop(context);
                    _showBankDetailsDialog(
                      context,
                      amount,
                      description: description,
                      controlNumber: paymentLink?['control_number']?.toString(),
                    );
                  },
                ),

                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Center(
                    child: Text('Sitisha', style: TextStyle(color: _secondaryText)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build payment option
  Widget _buildPaymentOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: _borderColor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _headerBg.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: _headerBg, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _primaryText),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: _secondaryText),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _secondaryText),
          ],
        ),
      ),
    );
  }

  // Show bank transfer flow using Letshego API
  void _showBankDetailsDialog(
    BuildContext context,
    double amount, {
    String? description,
    String? controlNumber,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BankTransferScreen(
          amount: amount,
          recipientBankName: DataStore.payingBank ?? '',
          recipientAccountNumber: DataStore.payingAccount ?? '',
          recipientBankCode: DataStore.payingBIN ?? '',
          narration: description ?? 'Malipo ya Akiba - ${DataStore.currentUserName}',
          controlNumber: controlNumber,
        ),
      ),
    );
  }

  // Launch payment URL
  Future<void> _launchPaymentUrl(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link ya malipo haipatikani')),
      );
      return;
    }

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Imeshindwa kufungua link')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kosa: $e')),
        );
      }
    }
  }

  // Show withdraw dialog
  void _showWithdrawDialog(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController(
      text: 'Uondoaji wa Akiba',
    );
    String selectedDestination = 'account'; // Default to bank account

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.remove_rounded, color: Colors.red.shade700, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Toa Akiba',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _primaryText),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Kiasi cha Kutoa *',
                      hintText: 'Ingiza kiasi unachotaka kutoa',
                      prefixIcon: const Icon(Icons.money),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Destination Selection
                  const Text(
                    'Peleka Fedha:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _primaryText,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Bank Account Option
                  InkWell(
                    onTap: () {
                      setState(() {
                        selectedDestination = 'account';
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selectedDestination == 'account'
                              ? _headerBg
                              : _borderColor.withOpacity(0.3),
                          width: selectedDestination == 'account' ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: selectedDestination == 'account'
                            ? _headerBg.withOpacity(0.05)
                            : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedDestination == 'account'
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: selectedDestination == 'account' ? _headerBg : _secondaryText,
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.account_balance, color: _headerBg, size: 24),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Akaunti Yangu ya Benki',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: _primaryText,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Peleka kwenda akaunti yako ya benki',
                                  style: TextStyle(fontSize: 12, color: _secondaryText),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Mobile Wallet Option
                  InkWell(
                    onTap: () {
                      setState(() {
                        selectedDestination = 'wallet';
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selectedDestination == 'wallet'
                              ? _headerBg
                              : _borderColor.withOpacity(0.3),
                          width: selectedDestination == 'wallet' ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: selectedDestination == 'wallet'
                            ? _headerBg.withOpacity(0.05)
                            : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedDestination == 'wallet'
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: selectedDestination == 'wallet' ? _headerBg : _secondaryText,
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.phone_android, color: _headerBg, size: 24),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kwenye Simu',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: _primaryText,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Peleka kwenye mkoba wa simu yangu',
                                  style: TextStyle(fontSize: 12, color: _secondaryText),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Maelezo (Optional)',
                      hintText: 'Eleza sababu ya kuondoa',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final amount = double.tryParse(amountController.text.trim());
                      if (amount == null || amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tafadhali ingiza kiasi sahihi')),
                        );
                        return;
                      }
                      Navigator.pop(context);

                      // Show destination details dialog
                      _showDestinationDetailsDialog(
                        context,
                        amount,
                        selectedDestination,
                        descriptionController.text.trim(),
                      );
                    },
                    child: const Text('Toa Akiba', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Center(
                    child: Text('Sitisha', style: TextStyle(color: _secondaryText)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  // Show other services dialog
  void _showOtherServicesDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _headerBg.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.more_horiz_rounded, color: _headerBg, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Huduma Nyingine',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _primaryText),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.history_rounded, color: _headerBg),
                title: const Text('Historia Kamili'),
                subtitle: const Text('Angalia taarifa zote za akiba'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to full history
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Huduma hii itapatikana hivi karibuni')),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.download_rounded, color: _headerBg),
                title: const Text('Pakua Taarifa'),
                subtitle: const Text('Export statement as PDF'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Export statement
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Huduma hii itapatikana hivi karibuni')),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded, color: _headerBg),
                title: const Text('Maelezo ya Akiba'),
                subtitle: const Text('Soma kuhusu akiba na faida zake'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Show info dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Huduma hii itapatikana hivi karibuni')),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Center(
                  child: Text('Funga', style: TextStyle(color: _secondaryText)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show destination details dialog (bank or mobile wallet)
  void _showDestinationDetailsDialog(
    BuildContext context,
    double amount,
    String destinationType,
    String description,
  ) {
    // Get current member's bank details from membersList
    Map<String, dynamic>? currentMember;
    String memberBankAccount = '';
    String memberBankName = '';
    String memberBankCode = '';

    try {
      if (DataStore.membersList != null && DataStore.currentUserId != null) {
        currentMember = DataStore.membersList.firstWhere(
          (member) => member['userId']?.toString() == DataStore.currentUserId,
          orElse: () => null,
        );

        if (currentMember != null) {
          memberBankAccount = currentMember['bank_account']?.toString() ?? '';
          memberBankName = currentMember['bank_name']?.toString() ?? 'Letshego Faidika Bank';
          memberBankCode = currentMember['bank_code']?.toString() ?? '044';
        }
      }
    } catch (e) {
      // Error loading member bank details - use defaults
    }

    // Auto-populate from member data
    final String defaultAccount = destinationType == 'account'
        ? memberBankAccount
        : (DataStore.userNumber ?? '');

    final TextEditingController accountController = TextEditingController(
      text: defaultAccount,
    );

    // Map MNO to provider code
    final Map<String, String> mnoToProvider = {
      'VODACOM': '503',  // M-Pesa
      'TIGO': '501',     // TigoPesa
      'AIRTEL': '504',   // Airtel Money
      'TTCL': '505',     // T-Pesa
      'HALOTEL': '506',  // HaloPesa
      'AZAM': '511',     // AZAMPESA
    };

    // Auto-detect provider from user's MNO
    String selectedProvider = '503'; // Default to M-Pesa
    if (destinationType == 'wallet' && DataStore.userNumberMNO != null) {
      final mno = DataStore.userNumberMNO!.toUpperCase();
      selectedProvider = mnoToProvider[mno] ?? '503';
    }

    final Map<String, String> mobileProviders = {
      '501': 'TigoPesa',
      '502': 'EasyPesa',
      '503': 'M-Pesa (Vodacom)',
      '504': 'Airtel Money',
      '505': 'T-Pesa (TTCL)',
      '506': 'HaloPesa',
      '511': 'AZAMPESA',
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _headerBg.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          destinationType == 'account'
                              ? Icons.account_balance
                              : Icons.phone_android,
                          color: _headerBg,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          destinationType == 'account'
                              ? 'Taarifa za Akaunti'
                              : 'Taarifa za Mkoba',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _primaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Amount display
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _totalRowBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _borderColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Kiasi:',
                          style: TextStyle(
                            fontSize: 14,
                            color: _secondaryText,
                          ),
                        ),
                        Text(
                          formatCurrency.format(amount),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _primaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mobile provider selection (only for mobile wallet)
                  if (destinationType == 'wallet') ...[
                    const Text(
                      'Chagua Huduma:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _primaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedProvider,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.mobile_friendly),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: mobileProviders.entries
                          .map((entry) => DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(entry.value),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedProvider = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Account/Phone number input
                  TextField(
                    controller: accountController,
                    keyboardType: destinationType == 'wallet'
                        ? TextInputType.phone
                        : TextInputType.number,
                    decoration: InputDecoration(
                      labelText: destinationType == 'account'
                          ? 'Namba ya Akaunti *'
                          : 'Namba ya Simu *',
                      hintText: destinationType == 'account'
                          ? 'Ingiza namba ya akaunti yako'
                          : '0712345678',
                      helperText: destinationType == 'account'
                          ? 'Benki: ${memberBankName.isEmpty ? "Letshego Faidika Bank" : memberBankName}'
                          : null,
                      prefixIcon: Icon(
                        destinationType == 'account'
                            ? Icons.account_balance_wallet
                            : Icons.phone,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSubmitting ? Colors.grey : _headerBg,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isSubmitting ? null : () async {
                        final account = accountController.text.trim();
                        if (account.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                destinationType == 'account'
                                    ? 'Tafadhali ingiza namba ya akaunti'
                                    : 'Tafadhali ingiza namba ya simu',
                              ),
                            ),
                          );
                          return;
                        }

                        // Set loading state
                        setState(() {
                          isSubmitting = true;
                        });

                        // Submit withdrawal request
                        final success = await _submitWithdrawalRequest(
                          context,
                          amount,
                          destinationType,
                          account,
                          destinationType == 'wallet' ? selectedProvider : (memberBankCode.isEmpty ? '044' : memberBankCode),
                          description,
                          destinationType == 'account' ? (memberBankName.isEmpty ? 'Letshego Faidika Bank' : memberBankName) : null,
                        );

                        // Reset loading state
                        if (context.mounted) {
                          setState(() {
                            isSubmitting = false;
                          });

                          // Only close dialog on success
                          if (success) {
                            Navigator.pop(context);
                          }
                        }
                      },
                      child: isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Tuma Ombi',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Center(
                      child: Text(
                        'Rudi Nyuma',
                        style: TextStyle(color: _secondaryText),
                      ),
                    ),
                  ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Submit withdrawal request to API using voting flow
  // Returns true if successful, false otherwise
  Future<bool> _submitWithdrawalRequest(
    BuildContext context,
    double amount,
    String destinationType,
    String account,
    String fspId,
    String description,
    String? bankName,
  ) async {
    try {
      // Use the new voting-enabled API endpoint
      final response = await HttpService.createAkibaWithdrawalRequest(
        amount: amount,
        reason: description.isEmpty ? 'Uondoaji wa Akiba' : description,
        destinationType: destinationType == 'account' ? 'bank' : 'mobile_money',
        destinationAccount: account,
        destinationName: DataStore.currentUserName ?? '',
        destinationFspId: fspId,
        destinationBankName: bankName,
      );

      if (response['success'] == true) {
        final data = response['data'] ?? {};
        final requiresApproval = response['requires_approval'] ?? data['requires_approval'] ?? true;
        final status = data['status'] ?? 'pending';

        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(
                    requiresApproval ? Icons.schedule : Icons.check_circle,
                    color: requiresApproval ? Colors.orange : Colors.green,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Ombi Limetumwa'),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    requiresApproval
                        ? 'Ombi lako la kutoa akiba limetumwa kwa viongozi wa kikundi kuidhinisha.'
                        : 'Ombi lako la kutoa akiba limeanza kuchakatwa.',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Kiasi:', formatCurrency.format(amount)),
                  _buildDetailRow('Hali:', _getStatusText(status)),
                  if (data['request_id'] != null)
                    _buildDetailRow('Namba ya Ombi:', data['request_id']),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Sawa'),
                ),
              ],
            ),
          );
        }
        return true; // Success
      } else {
        // Show error - handle both old and new API response formats
        final error = response['message'] ?? response['error'] ?? 'Imeshindwa kutuma ombi';
        final errors = response['errors'];
        final balance = response['balance'];

        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 28),
                  SizedBox(width: 12),
                  Text('Kosa'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    error.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (errors != null) ...[
                    const SizedBox(height: 12),
                    ...List<Widget>.from(
                      (errors as List).map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• ${e.toString()}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      )),
                    ),
                  ],
                  if (balance != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _totalRowBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _borderColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Salio Lako la Akiba:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            formatCurrency.format(double.tryParse(balance.toString()) ?? 0),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _primaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Sawa'),
                ),
              ],
            ),
          );
        }
        return false; // Error
      }
    } catch (e) {
      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kosa: $e')),
        );
      }
      return false; // Exception
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'pending_approval':
        return 'Inasubiri Idhini';
      case 'processing':
        return 'Inachakatwa';
      case 'completed':
        return 'Imekamilika';
      case 'rejected':
        return 'Imekataliwa';
      case 'failed':
        return 'Imeshindwa';
      default:
        return status ?? 'Haijulikani';
    }
  }
}
