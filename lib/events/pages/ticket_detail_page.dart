// lib/events/pages/ticket_detail_page.dart
import 'package:flutter/material.dart';
import '../models/event_enums.dart';
import '../models/event_strings.dart';
import '../models/event_ticket.dart';
import '../services/ticket_service.dart';
import '../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class TicketDetailPage extends StatefulWidget {
  final int userId;
  final EventTicket ticket;

  const TicketDetailPage({
    super.key,
    required this.userId,
    required this.ticket,
  });

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  final TicketService _service = TicketService();
  late EventStrings _strings;
  bool _isActing = false;

  @override
  void initState() {
    super.initState();
    final lang = LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw';
    _strings = EventStrings(isSwahili: lang == 'sw');
  }

  Color _statusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.active:
        return Colors.green.shade700;
      case TicketStatus.used:
        return Colors.blue.shade700;
      case TicketStatus.cancelled:
      case TicketStatus.expired:
        return Colors.red.shade700;
      case TicketStatus.transferred:
        return Colors.orange.shade700;
      case TicketStatus.refunded:
        return _kSecondary;
    }
  }

  Color _statusBg(TicketStatus status) {
    switch (status) {
      case TicketStatus.active:
        return Colors.green.shade50;
      case TicketStatus.used:
        return Colors.blue.shade50;
      case TicketStatus.cancelled:
      case TicketStatus.expired:
        return Colors.red.shade50;
      case TicketStatus.transferred:
        return Colors.orange.shade50;
      case TicketStatus.refunded:
        return Colors.grey.shade100;
    }
  }

  Future<void> _transfer() async {
    final controller = TextEditingController();
    final userId = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_strings.transferTicket,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: _strings.isSwahili ? 'User ID wa mpokeaji' : 'Recipient User ID',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_strings.back,
                style: const TextStyle(color: _kSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final id = int.tryParse(controller.text.trim());
              if (id != null) Navigator.pop(ctx, id);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary, elevation: 0),
            child: Text(_strings.transferTicket,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );
    controller.dispose();
    if (userId == null || !mounted) return;
    setState(() => _isActing = true);
    final result = await _service.transferTicket(
        ticketId: widget.ticket.id, toUserId: userId);
    if (!mounted) return;
    setState(() => _isActing = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.message ??
          (result.success ? (_strings.isSwahili ? 'Tiketi imehamishwa!' : 'Ticket transferred!') : _strings.loadError)),
      backgroundColor:
          result.success ? Colors.green.shade700 : Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
    ));
    if (result.success) Navigator.pop(context);
  }

  Future<void> _gift() async {
    final phoneCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_strings.giftTicket,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: _strings.isSwahili ? 'Nambari ya simu' : 'Phone number',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: msgCtrl,
              decoration: InputDecoration(
                hintText: _strings.isSwahili ? 'Ujumbe (si lazima)' : 'Message (optional)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_strings.back,
                style: const TextStyle(color: _kSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary, elevation: 0),
            child: Text(_strings.giftTicket,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );
    final phone = phoneCtrl.text.trim();
    final msg = msgCtrl.text.trim();
    phoneCtrl.dispose();
    msgCtrl.dispose();
    if (confirmed != true || phone.isEmpty || !mounted) return;
    setState(() => _isActing = true);
    final result = await _service.giftTicket(
        ticketId: widget.ticket.id,
        recipientPhone: phone,
        message: msg.isNotEmpty ? msg : null);
    if (!mounted) return;
    setState(() => _isActing = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.message ??
          (result.success ? (_strings.isSwahili ? 'Tiketi imetolewa zawadi!' : 'Ticket gifted!') : _strings.loadError)),
      backgroundColor:
          result.success ? Colors.green.shade700 : Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
    ));
    if (result.success) Navigator.pop(context);
  }

  Future<void> _requestRefund() async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_strings.requestRefund,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: _strings.isSwahili ? 'Sababu (si lazima)' : 'Reason (optional)',
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_strings.back,
                style: const TextStyle(color: _kSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700, elevation: 0),
            child: Text(_strings.requestRefund,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );
    final reason = reasonCtrl.text.trim();
    reasonCtrl.dispose();
    if (confirmed != true || !mounted) return;
    setState(() => _isActing = true);
    final result = await _service.requestRefund(
        ticketId: widget.ticket.id,
        reason: reason.isNotEmpty ? reason : null);
    if (!mounted) return;
    setState(() => _isActing = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.message ??
          (result.success ? (_strings.isSwahili ? 'Ombi limetumwa!' : 'Request submitted!') : _strings.loadError)),
      backgroundColor:
          result.success ? Colors.green.shade700 : Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
    ));
    if (result.success) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    final event = ticket.event;
    final tier = ticket.tier;
    final isActive = ticket.status == TicketStatus.active;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(_strings.myTickets,
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: _kPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── QR Card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  // QR Code placeholder
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Icon(Icons.qr_code_rounded,
                        size: 90, color: _kPrimary),
                  ),
                  const SizedBox(height: 16),
                  // Status badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _statusBg(ticket.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${ticket.status.displayName} · ${ticket.status.subtitle}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(ticket.status),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event?.name ?? (_strings.isSwahili ? 'Tukio' : 'Event'),
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (tier != null)
                    Text(tier.name,
                        style:
                            const TextStyle(fontSize: 14, color: _kSecondary)),
                  const SizedBox(height: 8),
                  Text(
                    '#${ticket.ticketNumber}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                      color: _kSecondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Details ──
            _detailsCard(ticket),
            const SizedBox(height: 20),

            // ── Actions ──
            if (isActive) ...[
              if (ticket.tier?.isTransferable == true) ...[
                _actionButton(
                  icon: Icons.swap_horiz_rounded,
                  label: _strings.transferTicket,
                  onTap: _isActing ? null : _transfer,
                ),
                const SizedBox(height: 10),
                _actionButton(
                  icon: Icons.card_giftcard_rounded,
                  label: _strings.giftTicket,
                  onTap: _isActing ? null : _gift,
                ),
                const SizedBox(height: 10),
              ],
              if (ticket.tier?.isRefundable == true) ...[
                _actionButton(
                  icon: Icons.undo_rounded,
                  label: _strings.requestRefund,
                  onTap: _isActing ? null : _requestRefund,
                  destructive: true,
                ),
              ],
              if (_isActing)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _kPrimary),
                ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _detailsCard(EventTicket ticket) {
    final strings = _strings;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _detailRow(strings.dateAndTime,
              _formatDate(ticket.purchaseDate)),
          _detailRow('Bei / Price',
              strings.formatPrice(ticket.pricePaid, ticket.currency)),
          _detailRow(strings.paymentMethod, ticket.paymentMethod.toUpperCase()),
          if (ticket.paymentReference != null)
            _detailRow('Ref', ticket.paymentReference!),
          if (ticket.checkedInAt != null)
            _detailRow('Check-in', _formatDate(ticket.checkedInAt!)),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: _kSecondary)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _kPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool destructive = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon,
            size: 18, color: destructive ? Colors.red.shade700 : _kPrimary),
        label: Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: destructive ? Colors.red.shade700 : _kPrimary)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
              color: destructive ? Colors.red.shade200 : Colors.grey.shade300),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return _strings.formatDateShort(date);
  }
}
