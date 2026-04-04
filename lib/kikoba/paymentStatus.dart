import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'DataStore.dart';

// Design Guidelines Colors (Monochrome)
const _primaryBg = Color(0xFFFAFAFA);
const _cardBg = Color(0xFFFFFFFF);
const _primaryText = Color(0xFF1A1A1A);
const _secondaryText = Color(0xFF666666);
const _iconBg = Color(0xFF1A1A1A);
const _accentColor = Color(0xFF999999);

class paymentStatus extends StatefulWidget {
  const paymentStatus({super.key});

  @override
  State<paymentStatus> createState() => _paymentStatusState();
}

class _paymentStatusState extends State<paymentStatus> {
  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(symbol: 'Tsh ');
    final paymentAmount = double.tryParse(DataStore.paymentAmount.toString()) ?? 0;

    return Scaffold(
      backgroundColor: _primaryBg,
      appBar: AppBar(
        backgroundColor: _iconBg,
        elevation: 0,
        title: const Text(
          'Taarifa za malipo',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Success Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _cardBg,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: _iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Success Message
              const Text(
                "Malipo yamekamilika",
                style: TextStyle(
                  color: _primaryText,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 16),

              // Amount
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  formatCurrency.format(paymentAmount),
                  style: const TextStyle(
                    color: _primaryText,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      "Kikundi",
                      DataStore.currentKikobaName ?? '-',
                    ),
                    const Divider(height: 24, color: _accentColor),
                    _buildDetailRow(
                      "Aina ya malipo",
                      DataStore.paymentService ?? '-',
                    ),
                    const Divider(height: 24, color: _accentColor),
                    _buildDetailRow(
                      "Njia ya malipo",
                      DataStore.paymentChanel ?? '-',
                    ),
                    const Divider(height: 24, color: _accentColor),
                    _buildDetailRow(
                      "Taasisi",
                      DataStore.paymentInstitution ?? '-',
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => _showReceipt(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _iconBg, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Risiti',
                          style: TextStyle(
                            color: _primaryText,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          // Pop paymentStatus and selectPaymentMethod
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _iconBg,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Maliza',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _secondaryText,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              color: _primaryText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showReceipt(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ReceiptBottomSheet(),
    );
  }
}

class _ReceiptBottomSheet extends StatefulWidget {
  const _ReceiptBottomSheet();

  @override
  State<_ReceiptBottomSheet> createState() => _ReceiptBottomSheetState();
}

class _ReceiptBottomSheetState extends State<_ReceiptBottomSheet> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSaving = false;

  Future<void> _saveReceipt() async {
    setState(() => _isSaving = true);

    try {
      // Small delay to ensure the widget is fully rendered
      await Future.delayed(const Duration(milliseconds: 200));

      final Uint8List? imageBytes = await _screenshotController.capture(
        delay: const Duration(milliseconds: 100),
        pixelRatio: 3.0,
      );

      if (imageBytes != null) {
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filePath = '${directory.path}/risiti_$timestamp.png';
        final file = File(filePath);
        await file.writeAsBytes(imageBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Risiti imehifadhiwa kikamilifu!'),
              backgroundColor: _iconBg,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imeshindikana kuhifadhi: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _shareReceipt() async {
    setState(() => _isSaving = true);

    try {
      // Small delay to ensure the widget is fully rendered
      await Future.delayed(const Duration(milliseconds: 200));

      final Uint8List? imageBytes = await _screenshotController.capture(
        delay: const Duration(milliseconds: 100),
        pixelRatio: 3.0,
      );

      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filePath = '${directory.path}/risiti_$timestamp.png';
        final file = File(filePath);
        await file.writeAsBytes(imageBytes);

        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'Risiti ya Malipo - VICOBA',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imeshindikana kushiriki: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: _primaryBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Risiti ya Malipo',
                  style: TextStyle(
                    color: _primaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _accentColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: _secondaryText, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // Receipt Content (Scrollable & Screenshot-able)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Screenshot(
                controller: _screenshotController,
                child: const _ProfessionalReceipt(),
              ),
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _cardBg,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _isSaving ? null : _saveReceipt,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _iconBg,
                              ),
                            )
                          : const Icon(Icons.download_rounded),
                      label: const Text('Hifadhi'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryText,
                        side: const BorderSide(color: _iconBg, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _shareReceipt,
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Shiriki'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _iconBg,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfessionalReceipt extends StatelessWidget {
  const _ProfessionalReceipt();

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(symbol: 'Tsh ');
    final paymentAmount = double.tryParse(DataStore.paymentAmount.toString()) ?? 0;
    final dateFormat = DateFormat('dd MMMM yyyy');
    final timeFormat = DateFormat('HH:mm');
    final now = DateTime.now();
    final receiptNo = 'RCP${now.millisecondsSinceEpoch.toString().substring(5)}';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with Logo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'V',
                      style: TextStyle(
                        color: _iconBg,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VICOBA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'Risiti ya Malipo',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Success Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 18),
                SizedBox(width: 8),
                Text(
                  'MALIPO YAMEKAMILIKA',
                  style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Amount Section
          Text(
            formatCurrency.format(paymentAmount),
            style: const TextStyle(
              color: _primaryText,
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${dateFormat.format(now)} • ${timeFormat.format(now)}',
            style: const TextStyle(
              color: _secondaryText,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 24),

          // Divider with receipt number
          Row(
            children: [
              Expanded(child: Container(height: 1, color: _accentColor.withValues(alpha: 0.3))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  receiptNo,
                  style: TextStyle(
                    color: _accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(child: Container(height: 1, color: _accentColor.withValues(alpha: 0.3))),
            ],
          ),

          const SizedBox(height: 24),

          // Transaction Details
          _buildReceiptItem(
            icon: Icons.person_rounded,
            label: 'Jina la Mwanachama',
            value: DataStore.currentUserName ?? '-',
          ),
          _buildReceiptItem(
            icon: Icons.phone_rounded,
            label: 'Namba ya Simu',
            value: DataStore.userNumber ?? '-',
          ),
          _buildReceiptItem(
            icon: Icons.groups_rounded,
            label: 'Kikundi',
            value: DataStore.currentKikobaName ?? '-',
          ),
          _buildReceiptItem(
            icon: Icons.category_rounded,
            label: 'Aina ya Malipo',
            value: _formatPaymentType(DataStore.paymentService),
          ),
          _buildReceiptItem(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Njia ya Malipo',
            value: DataStore.paymentChanel ?? '-',
          ),
          _buildReceiptItem(
            icon: Icons.business_rounded,
            label: 'Taasisi',
            value: DataStore.paymentInstitution ?? '-',
            isLast: true,
          ),

          const SizedBox(height: 24),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primaryBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Asante kwa kutumia VICOBA',
                  style: TextStyle(
                    color: _primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hifadhi risiti hii kwa kumbukumbu',
                  style: TextStyle(
                    color: _secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // QR Code Placeholder (for future implementation)
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _primaryBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _accentColor.withValues(alpha: 0.3)),
            ),
            child: const Center(
              child: Icon(Icons.qr_code_2_rounded, color: _accentColor, size: 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptItem({
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _primaryBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: _secondaryText, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: _secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        color: _primaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            color: _accentColor.withValues(alpha: 0.2),
          ),
      ],
    );
  }

  String _formatPaymentType(String? type) {
    if (type == null) return '-';
    switch (type.toLowerCase()) {
      case 'ada':
        return 'Ada ya Mwezi';
      case 'hisa':
        return 'Hisa';
      case 'rejesho':
        return 'Rejesho la Mkopo';
      case 'closeloan':
        return 'Kufunga Mkopo';
      case 'topup':
        return 'Top-up Mkopo';
      default:
        return type;
    }
  }
}
