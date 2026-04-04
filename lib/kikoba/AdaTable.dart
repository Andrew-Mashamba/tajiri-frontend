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

class AdaTable extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final Function(double totalDeni, double totalPenati, List<Map<String, dynamic>> monthlyDebts)? onTotalsCalculated;
  final VoidCallback? onDataLoaded; // Callback when control numbers are loaded

  const AdaTable({super.key, required this.data, this.onTotalsCalculated, this.onDataLoaded});

  @override
  State<AdaTable> createState() => _AdaTableState();
}

class _AdaTableState extends State<AdaTable> {
  // Note: Data fetching is now handled by the parent AdaPage
  // This widget reads from DataStore which is populated by the parent

  // Helper to parse value (can be String or num) to double
  double _parseValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Convert "January 2025" to "01/25"
  String _formatMonth(String? month) {
    if (month == null || month.isEmpty) return '';
    final months = {
      'January': '01', 'February': '02', 'March': '03', 'April': '04',
      'May': '05', 'June': '06', 'July': '07', 'August': '08',
      'September': '09', 'October': '10', 'November': '11', 'December': '12'
    };
    final parts = month.split(' ');
    if (parts.length == 2) {
      final monthNum = months[parts[0]] ?? '00';
      final year = parts[1].length >= 2 ? parts[1].substring(parts[1].length - 2) : parts[1];
      return '$monthNum/$year';
    }
    return month;
  }

  // Function to build the header row
  TableRow _buildHeaderRow() {
    return TableRow(
      decoration: const BoxDecoration(color: _headerBg),
      children: [
        _buildHeaderCell("Mwezi"),
        _buildHeaderCell("Kiasi"),
        _buildHeaderCell("Deni"),
        _buildHeaderCell("Penati"),
        _buildHeaderCell(""),
      ],
    );
  }

  // Get monthly Ada requirement from katiba
  double get _monthlyAdaRequired => _parseValue(DataStore.ada);

  // Get penalty for Ada from katiba
  double get _adaPenalty => _parseValue(DataStore.faini_ada);

  // Function to build a data row
  TableRow _buildDataRow(Map<String, dynamic> record) {
    // Use pre-calculated values from backend
    final kiasi = _parseValue(record['kiasi']);
    final deni = _parseValue(record['deni']);
    final penati = _parseValue(record['penati']); // Now from backend
    final month = record['month']?.toString() ?? '';

    return TableRow(
      decoration: const BoxDecoration(color: _rowBg),
      children: [
        _buildDataCell(month), // Already formatted as "01/26"
        _buildDataCell(kiasi > 0 ? formatCurrency.format(kiasi).replaceAll("Tsh ", "") : "-"),
        _buildDataCell(deni > 0 ? formatCurrency.format(deni).replaceAll("Tsh ", "") : "-", isDebt: deni > 0),
        _buildDataCell(penati > 0 ? formatCurrency.format(penati).replaceAll("Tsh ", "") : "-", isDebt: penati > 0),
        _buildActionCell(record, deni),
      ],
    );
  }

  // Function to build the total row
  TableRow _buildTotalRow(double kiasiSumx, double deniSumx, double penatiSumx) {
    return TableRow(
      decoration: const BoxDecoration(color: _totalRowBg),
      children: [
        _buildDataCell("Jumla", fontWeight: FontWeight.w600),
        _buildDataCell(formatCurrency.format(kiasiSumx).replaceAll("Tsh ", ""), fontWeight: FontWeight.w600),
        _buildDataCell(formatCurrency.format(deniSumx).replaceAll("Tsh ", ""), fontWeight: FontWeight.w600, isDebt: deniSumx > 0),
        _buildDataCell(formatCurrency.format(penatiSumx).replaceAll("Tsh ", ""), fontWeight: FontWeight.w600, isDebt: penatiSumx > 0),
        _buildDataCell("", fontWeight: FontWeight.w600),
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
  Widget _buildDataCell(String text, {FontWeight fontWeight = FontWeight.normal, bool isDebt = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: fontWeight,
          color: isDebt ? _primaryText : _secondaryText,
          fontSize: 12,
        ),
      ),
    );
  }

  // Helper function to build the action cell with Pay icon
  Widget _buildActionCell(Map<String, dynamic> record, double deni) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
      child: deni > 0
          ? InkWell(
              onTap: () => _showPaymentOptionsDialog(context, record, deni),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _headerBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.payment_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            )
          : const SizedBox(width: 24, height: 24),
    );
  }

  // Parse month string "01/25" to month and year
  Map<String, int> _parseMonthString(String monthStr) {
    try {
      final parts = monthStr.split('/');
      if (parts.length == 2) {
        final month = int.tryParse(parts[0]) ?? 0;
        final yearShort = int.tryParse(parts[1]) ?? 0;
        final year = yearShort < 100 ? 2000 + yearShort : yearShort;
        return {'month': month, 'year': year};
      }
    } catch (e) {
      // Ignore parse errors
    }
    return {'month': 0, 'year': 0};
  }

  // Get payment link for a specific month
  Map<String, dynamic>? _getPaymentLinkForMonth(String monthStr) {
    final parsed = _parseMonthString(monthStr);
    final month = parsed['month'] ?? 0;
    final year = parsed['year'] ?? 0;

    if (month == 0 || year == 0) return null;

    final payments = DataStore.getControlNumbers('ada');
    try {
      return payments.firstWhere(
        (p) => p['month'] == month && p['year'] == year && p['status'] == 'pending',
        orElse: () => null,
      );
    } catch (e) {
      return null;
    }
  }

  // Show payment options dialog
  void _showPaymentOptionsDialog(BuildContext context, Map<String, dynamic> record, double deni) {
    final monthStr = record['month']?.toString() ?? ''; // Already formatted
    // Use control number and payment URL directly from record (now embedded from API)
    final controlNumber = record['control_number']?.toString();
    final paymentUrl = record['payment_url']?.toString();
    final status = record['status']?.toString();
    final hasPaymentLink = controlNumber != null && controlNumber.isNotEmpty && status == 'pending';

    final penati = _parseValue(record['penati']); // Now from backend
    final totalAmount = deni + penati;

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
                    color: _headerBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.payment_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chagua Njia ya Malipo',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _primaryText),
                      ),
                      Text(
                        'Mwezi: $monthStr',
                        style: const TextStyle(fontSize: 13, color: _secondaryText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _totalRowBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Jumla ya kulipa:', style: TextStyle(fontSize: 14, color: _secondaryText)),
                  Text(
                    formatCurrency.format(totalAmount),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _primaryText),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Payment Link Option
            if (hasPaymentLink) ...[
              _buildPaymentOption(
                context: context,
                icon: Icons.phone_android_rounded,
                title: 'Lipa kwa Simu',
                subtitle: 'Namba: $controlNumber',
                onTap: () {
                  Navigator.pop(context);
                  _launchPaymentUrl(context, paymentUrl ?? '');
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
                Navigator.pop(context);
                _showBankDetailsDialog(
                  context,
                  totalAmount,
                  controlNumber: controlNumber,
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
    );
  }

  // Build payment option item
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _headerBg.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: _headerBg, size: 24),
            ),
            const SizedBox(width: 16),
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
  void _showBankDetailsDialog(BuildContext context, double amount, {String? controlNumber}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BankTransferScreen(
          amount: amount,
          recipientBankName: DataStore.payingBank ?? '',
          recipientAccountNumber: DataStore.payingAccount ?? '',
          recipientBankCode: DataStore.payingBIN ?? '',
          narration: 'Malipo ya Ada - ${DataStore.currentUserName}',
          controlNumber: controlNumber,
        ),
      ),
    );
  }

  // Build info row
  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: _secondaryText)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _primaryText),
        ),
      ],
    );
  }

  // Build copyable info row
  Widget _buildCopyableInfoRow(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: _secondaryText)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _primaryText),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18, color: _secondaryText),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Namba ya akaunti imenakiliwa'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  // Launch payment URL
  Future<void> _launchPaymentUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);

      // Try to launch with platform default first
      bool launched = false;

      try {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      } catch (e) {
        // If platform default fails, try external application
        try {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        } catch (e2) {
          // If that fails too, try in-app browser
          launched = await launchUrl(
            uri,
            mode: LaunchMode.inAppWebView,
          );
        }
      }

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imeshindwa kufungua link ya malipo. Tafadhali jaribu tena.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kosa: Imeshindwa kufungua link'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Build table data from control numbers (shows all months from API)
  // Backend now returns pre-calculated values: mwezi, kiasi, deni, penati
  List<Map<String, dynamic>> _buildTableDataFromControlNumbers() {
    final controlNumbers = DataStore.getControlNumbers('ada');

    debugPrint('📊 [AdaTable] ═══════════════════════════════════════════════════');
    debugPrint('📊 [AdaTable] Building table from ${controlNumbers.length} control numbers');

    List<Map<String, dynamic>> tableData = [];

    for (var cn in controlNumbers) {
      // Use pre-calculated values from backend
      final mwezi = cn['mwezi']?.toString() ?? '';
      final kiasi = _parseValue(cn['kiasi']);
      final deni = _parseValue(cn['deni']);
      final penati = _parseValue(cn['penati']);
      final status = cn['status']?.toString() ?? 'pending';

      tableData.add({
        'month': mwezi,  // Already formatted as "01/26"
        'kiasi': kiasi,
        'deni': deni,
        'penati': penati,
        'control_number': cn['control_number'],
        'payment_url': cn['payment_url'],
        'status': status,
      });

      debugPrint('📊 [AdaTable] Mwezi: $mwezi, Status: $status, Kiasi: $kiasi, Deni: $deni, Penati: $penati');
    }

    // Sort by month (oldest first - January to December)
    tableData.sort((a, b) {
      final aMonth = a['month']?.toString() ?? '';
      final bMonth = b['month']?.toString() ?? '';
      return aMonth.compareTo(bMonth); // Ascending order
    });

    debugPrint('📊 [AdaTable] Total rows: ${tableData.length}');
    debugPrint('📊 [AdaTable] ═══════════════════════════════════════════════════');

    return tableData;
  }

  // Method to calculate totals and build monthly debt list
  Map<String, dynamic> _calculateSums(List<Map<String, dynamic>> filteredData) {
    double kiasiSum = 0.0;
    double deniSum = 0.0;
    double penatiSum = 0.0;
    List<Map<String, dynamic>> monthlyDebts = [];

    for (var record in filteredData) {
      // Use pre-calculated values from backend
      final kiasi = _parseValue(record['kiasi']);
      final deni = _parseValue(record['deni']);
      final penati = _parseValue(record['penati']); // Now from backend

      kiasiSum += kiasi;
      deniSum += deni;
      penatiSum += penati;

      // Add to monthly debts list if there's debt
      if (deni > 0) {
        monthlyDebts.add({
          'month': record['month'] ?? '',
          'monthFormatted': record['month'] ?? '', // Already formatted
          'deni': deni,
          'penati': penati,
          'control_number': record['control_number'],
          'payment_url': record['payment_url'],
        });
      }
    }

    // Call callback with totals if provided
    if (widget.onTotalsCalculated != null) {
      widget.onTotalsCalculated!(deniSum + penatiSum, penatiSum, monthlyDebts);
    }

    return {
      'kiasiSum': kiasiSum,
      'deniSum': deniSum,
      'penatiSum': penatiSum,
      'monthlyDebts': monthlyDebts,
    };
  }

  @override
  Widget build(BuildContext context) {
    // Build table data from control numbers (shows all months from API)
    final tableData = _buildTableDataFromControlNumbers();
    final sums = _calculateSums(tableData);
    final kiasiSum = (sums['kiasiSum'] as num).toDouble();
    final deniSum = (sums['deniSum'] as num).toDouble();
    final penatiSum = (sums['penatiSum'] as num).toDouble();

    // Show empty state if no data
    if (tableData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'Hakuna data ya Ada',
            style: TextStyle(color: _secondaryText),
          ),
        ),
      );
    }

    return Table(
      border: TableBorder.all(color: _borderColor.withOpacity(0.3), width: 0.5),
      columnWidths: const {
        0: FlexColumnWidth(1.0), // Mwezi
        1: FlexColumnWidth(2.0), // Kiasi
        2: FlexColumnWidth(2.0), // Deni
        3: FlexColumnWidth(1.5), // Penati
        4: FixedColumnWidth(42), // Action (icon only)
      },
      children: [
        _buildHeaderRow(),
        ...tableData.map((record) => _buildDataRow(record)),
        _buildTotalRow(kiasiSum, deniSum, penatiSum),
      ],
    );
  }
}

// This is how you can call the table function:
Widget adaTable(List<Map<String, dynamic>> data, {
  Function(double totalDeni, double totalPenati, List<Map<String, dynamic>> monthlyDebts)? onTotalsCalculated,
}) {
  return AdaTable(data: data, onTotalsCalculated: onTotalsCalculated);
}
