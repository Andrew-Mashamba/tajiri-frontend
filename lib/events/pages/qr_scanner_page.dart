// lib/events/pages/qr_scanner_page.dart
// QR check-in page for organizers. Uses manual code entry.
// To enable camera scanning, add `mobile_scanner` to pubspec.yaml.
import 'package:flutter/material.dart';
import '../models/event_ticket.dart';
import '../models/event_strings.dart';
import '../services/ticket_service.dart';
import '../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class QrScannerPage extends StatefulWidget {
  final int eventId;
  const QrScannerPage({super.key, required this.eventId});
  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final TicketService _ticketService = TicketService();
  final TextEditingController _codeController = TextEditingController();
  late EventStrings _strings;

  bool _isProcessing = false;
  CheckInResult? _lastResult;
  int _totalCheckedIn = 0;

  @override
  void initState() {
    super.initState();
    final lang = LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw';
    _strings = EventStrings(isSwahili: lang == 'sw');
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _checkIn(String qrData) async {
    if (qrData.trim().isEmpty || _isProcessing) return;
    setState(() { _isProcessing = true; _lastResult = null; });

    final result = await _ticketService.checkInTicket(qrData: qrData.trim());
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _lastResult = result;
        if (result.success) {
          _totalCheckedIn++;
          _codeController.clear();
        }
      });
    }
  }

  Future<void> _manualCheckIn() async {
    final ticketIdStr = _codeController.text.trim();
    final ticketId = int.tryParse(ticketIdStr);
    if (ticketId == null) {
      // Try as QR data
      await _checkIn(ticketIdStr);
      return;
    }
    setState(() { _isProcessing = true; _lastResult = null; });
    final result = await _ticketService.manualCheckIn(ticketId: ticketId);
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _lastResult = result;
        if (result.success) {
          _totalCheckedIn++;
          _codeController.clear();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_strings.checkIn, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text('$_totalCheckedIn ${_strings.isSwahili ? "wamesajiliwa" : "checked in"}', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Scanner placeholder
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner_rounded, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    _strings.isSwahili ? 'Ongeza mobile_scanner kwa kamera' : 'Add mobile_scanner for camera scan',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Manual entry
            Text(
              _strings.isSwahili ? 'Au ingiza msimbo wa tiketi' : 'Or enter ticket code manually',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      hintText: _strings.isSwahili ? 'Msimbo wa tiketi au QR...' : 'Ticket code or QR data...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onSubmitted: (_) => _manualCheckIn(),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _manualCheckIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isProcessing
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_strings.checkIn),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Result
            if (_lastResult != null) _buildResult(_lastResult!),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(CheckInResult result) {
    final isSuccess = result.success && !result.alreadyCheckedIn;
    final isAlready = result.alreadyCheckedIn;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green.shade50 : isAlready ? Colors.orange.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_rounded : isAlready ? Icons.warning_rounded : Icons.cancel_rounded,
            size: 56,
            color: isSuccess ? Colors.green : isAlready ? Colors.orange : Colors.red,
          ),
          const SizedBox(height: 12),
          Text(
            isSuccess
                ? (_strings.isSwahili ? 'Umesajiliwa!' : 'Checked In!')
                : isAlready
                    ? (_strings.isSwahili ? 'Tayari amesajiliwa' : 'Already checked in')
                    : (_strings.isSwahili ? 'Tiketi batili' : 'Invalid ticket'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isSuccess ? Colors.green.shade700 : isAlready ? Colors.orange.shade700 : Colors.red.shade700,
            ),
          ),
          if (result.attendeeName != null) ...[
            const SizedBox(height: 4),
            Text(result.attendeeName!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
          ],
          if (result.tierName != null) ...[
            const SizedBox(height: 2),
            Text(result.tierName!, style: const TextStyle(fontSize: 14, color: _kSecondary)),
          ],
          if (result.guestCount != null && result.guestCount! > 0) ...[
            const SizedBox(height: 2),
            Text('+${result.guestCount} ${_strings.isSwahili ? "wageni" : "guests"}', style: const TextStyle(fontSize: 13, color: _kSecondary)),
          ],
          if (result.message != null && !result.success) ...[
            const SizedBox(height: 4),
            Text(result.message!, style: TextStyle(fontSize: 13, color: Colors.red.shade600)),
          ],
        ],
      ),
    );
  }
}
