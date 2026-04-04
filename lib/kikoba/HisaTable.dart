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

class HisaTable extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final Function(double totalDeni, double totalPenati, List<Map<String, dynamic>> monthlyDebts)? onTotalsCalculated;
  final VoidCallback? onDataLoaded; // Callback when control numbers are loaded
  final bool showLoadingIndicator; // Whether to show loading spinner (parent may show its own)

  const HisaTable({super.key, required this.data, this.onTotalsCalculated, this.onDataLoaded, this.showLoadingIndicator = true});

  @override
  State<HisaTable> createState() => _HisaTableState();
}

class _HisaTableState extends State<HisaTable> {
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
      debugPrint('HisaTable: Cannot fetch control numbers - kikobaId or userId is null');
      return;
    }

    setState(() => _isLoadingControlNumbers = true);

    try {
      final currentYear = DateTime.now().year;

      final controlNumbers = await HttpService.fetchControlNumbers(
        kikobaId: kikobaId,
        type: 'hisa',
        userId: userId,
        year: currentYear,
        status: 'all',
      );

      // Update DataStore with fetched control numbers
      DataStore.controlNumbersHisa = controlNumbers;
      debugPrint('HisaTable: Loaded ${controlNumbers.length} control numbers for hisa');

      // Notify parent that data is loaded
      if (widget.onDataLoaded != null) {
        widget.onDataLoaded!();
      }
    } catch (e) {
      debugPrint('HisaTable: Error fetching control numbers: $e');
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
                child: (_isLoadingControlNumbers && widget.showLoadingIndicator)
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.payment_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
              ),
            )
          : const SizedBox(width: 24, height: 24),
    );
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
  void _showBankDetailsDialog(BuildContext context, double amount, {String? controlNumber}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BankTransferScreen(
          amount: amount,
          recipientBankName: DataStore.payingBank ?? '',
          recipientAccountNumber: DataStore.payingAccount ?? '',
          recipientBankCode: DataStore.payingBIN ?? '',
          narration: 'Malipo ya Hisa - ${DataStore.currentUserName}',
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

  // Build table data from control numbers (shows all months from API)
  // Backend now returns pre-calculated values: mwezi, kiasi, deni, penati
  List<Map<String, dynamic>> _buildTableDataFromControlNumbers() {
    final controlNumbers = DataStore.getControlNumbers('hisa');

    debugPrint('📊 [HisaTable] ═══════════════════════════════════════════════════');
    debugPrint('📊 [HisaTable] Building table from ${controlNumbers.length} control numbers');

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

      debugPrint('📊 [HisaTable] Mwezi: $mwezi, Status: $status, Kiasi: $kiasi, Deni: $deni, Penati: $penati');
    }

    // Sort by month (oldest first - January to December)
    tableData.sort((a, b) {
      final aMonth = a['month']?.toString() ?? '';
      final bMonth = b['month']?.toString() ?? '';
      return aMonth.compareTo(bMonth); // Ascending order
    });

    debugPrint('📊 [HisaTable] Total rows: ${tableData.length}');
    debugPrint('📊 [HisaTable] ═══════════════════════════════════════════════════');

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

    // Show loading or empty state if no control numbers yet
    if (tableData.isEmpty && _isLoadingControlNumbers && widget.showLoadingIndicator) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (tableData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'Hakuna data ya Hisa',
            style: TextStyle(color: _secondaryText),
          ),
        ),
      );
    }

    return Table(
      border: TableBorder.all(color: _borderColor.withOpacity(0.3), width: 1),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
        4: FlexColumnWidth(1),
      },
      children: [
        _buildHeaderRow(),
        ...tableData.map((record) => _buildDataRow(record)),
        _buildTotalRow(kiasiSum, deniSum, penatiSum),
      ],
    );
  }
}
