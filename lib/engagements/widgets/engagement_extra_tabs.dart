import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/http_retry.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/api_config.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/message_service.dart';
import '../../tajirika/services/partner_product_service.dart';
import '../models/engagement.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF9E9E9E);
const Color _kBorder = Color(0xFFEEEEEE);

/// Spec line 784 — Files tab on the engagement workspace. Both parties can
/// upload (reuses partner-products/photo as a generic uploader) and remove
/// only their own uploads. v1 stores `file_url` from the upload endpoint.
class EngagementFilesTab extends StatefulWidget {
  final int engagementId;
  final int userId;
  const EngagementFilesTab({
    super.key,
    required this.engagementId,
    required this.userId,
  });

  @override
  State<EngagementFilesTab> createState() => _EngagementFilesTabState();
}

class _EngagementFilesTabState extends State<EngagementFilesTab> {
  bool _loading = true;
  bool _uploading = false;
  List<Map<String, dynamic>> _files = const [];

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final uri = Uri.parse('${ApiConfig.baseUrl}/engagements/${widget.engagementId}/files')
        .replace(queryParameters: {'user_id': '${widget.userId}'});
    try {
      final res = await httpGetWithRetry(uri);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true) {
          if (!mounted) return;
          setState(() {
            _loading = false;
            _files = (body['data'] as List)
                .whereType<Map>()
                .map((m) => m.cast<String, dynamic>())
                .toList();
          });
          return;
        }
      }
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _upload() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2400,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() => _uploading = true);
    final upload = await PartnerProductService.uploadPhoto(
      userId: widget.userId,
      file: File(picked.path),
    );
    if (!upload.success || (upload.photoUrl ?? '').isEmpty) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(upload.message ?? 'Upload failed'),
      ));
      return;
    }
    final filename = picked.name;
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/engagements/${widget.engagementId}/files'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': widget.userId,
        'filename': filename,
        'file_url': upload.photoUrl,
      }),
    );
    if (!mounted) return;
    setState(() => _uploading = false);
    if (res.statusCode == 200) {
      _load();
    }
  }

  Future<void> _delete(int fileId) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/engagements/${widget.engagementId}/files/$fileId'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': widget.userId}),
    );
    if (!mounted) return;
    if (res.statusCode == 200) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    return Stack(
      children: [
        if (_files.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _isSwahili ? 'Hakuna faili bado' : 'No files yet',
                style: const TextStyle(color: _kMuted),
              ),
            ),
          )
        else
          ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _files.length,
            itemBuilder: (_, i) {
              final f = _files[i];
              final mine = f['uploaded_by_user_id'] == widget.userId;
              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: _kBorder),
                ),
                child: ListTile(
                  leading: const Icon(Icons.attach_file_rounded, color: _kPrimary),
                  title: Text(f['filename']?.toString() ?? '—',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    f['uploader_name']?.toString() ?? '—',
                    style: const TextStyle(fontSize: 11, color: _kMuted),
                  ),
                  trailing: mine
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: Color(0xFFB71C1C)),
                          onPressed: () => _delete(f['id'] as int),
                        )
                      : null,
                  onTap: () {
                    final url = f['file_url']?.toString() ?? '';
                    if (url.isNotEmpty) launchUrl(Uri.parse(url));
                  },
                ),
              );
            },
          ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: _uploading ? null : _upload,
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
            icon: _uploading
                ? const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.upload_file_rounded),
            label: Text(_isSwahili ? 'Pakia' : 'Upload'),
          ),
        ),
      ],
    );
  }
}

/// Spec line 783 — Invoices tab. Reads engagement_invoices; supports
/// "Generate" (auto-bill the period) and "Mark paid" actions.
class EngagementInvoicesTab extends StatefulWidget {
  final int engagementId;
  final int userId;
  final bool isPartner;
  const EngagementInvoicesTab({
    super.key,
    required this.engagementId,
    required this.userId,
    required this.isPartner,
  });

  @override
  State<EngagementInvoicesTab> createState() => _EngagementInvoicesTabState();
}

class _EngagementInvoicesTabState extends State<EngagementInvoicesTab> {
  bool _loading = true;
  bool _busy = false;
  List<Map<String, dynamic>> _invoices = const [];

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final uri = Uri.parse('${ApiConfig.baseUrl}/engagements/${widget.engagementId}/invoices')
        .replace(queryParameters: {'user_id': '${widget.userId}'});
    try {
      final res = await httpGetWithRetry(uri);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true) {
          if (!mounted) return;
          setState(() {
            _loading = false;
            _invoices = (body['data'] as List)
                .whereType<Map>()
                .map((m) => m.cast<String, dynamic>())
                .toList();
          });
          return;
        }
      }
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generate() async {
    setState(() => _busy = true);
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/engagements/${widget.engagementId}/invoices/generate'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': widget.userId}),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.statusCode == 200) _load();
  }

  Future<void> _markPaid(int invoiceId) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/engagements/${widget.engagementId}/invoices/$invoiceId/mark-paid'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': widget.userId}),
    );
    if (!mounted) return;
    if (res.statusCode == 200) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    return Stack(
      children: [
        if (_invoices.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _isSwahili ? 'Hakuna ankara bado' : 'No invoices yet',
                style: const TextStyle(color: _kMuted),
              ),
            ),
          )
        else
          ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _invoices.length,
            itemBuilder: (_, i) {
              final inv = _invoices[i];
              final amount = inv['amount_tzs'] as int? ?? 0;
              final status = inv['status']?.toString() ?? 'draft';
              final isPaid = status == 'paid';
              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: _kBorder),
                ),
                child: ListTile(
                  title: Text(inv['invoice_number']?.toString() ?? '—',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    [
                      'TZS ${NumberFormat('#,##0').format(amount)}',
                      if (inv['period_start'] != null && inv['period_end'] != null)
                        '${inv['period_start']} → ${inv['period_end']}',
                    ].join(' • '),
                    style: const TextStyle(fontSize: 11, color: _kMuted),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPaid
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isPaid
                            ? const Color(0xFF1B5E20)
                            : const Color(0xFFE65100),
                      ),
                    ),
                  ),
                  onTap: !widget.isPartner && !isPaid
                      ? () => _markPaid(inv['id'] as int)
                      : null,
                ),
              );
            },
          ),
        if (widget.isPartner)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: _busy ? null : _generate,
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              icon: _busy
                  ? const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.receipt_long_rounded),
              label: Text(_isSwahili ? 'Tengeneza' : 'Generate'),
            ),
          ),
      ],
    );
  }
}

/// Spec line 785 — Chat tab. Resolves the private conversation between
/// customer + partner and renders an "Open chat" CTA. Once chat is embedded
/// inline (post-MVP), this widget will host the thread directly.
class EngagementChatTab extends StatelessWidget {
  final Engagement engagement;
  final int userId;
  final bool isPartner;
  const EngagementChatTab({
    super.key,
    required this.engagement,
    required this.userId,
    required this.isPartner,
  });

  Future<void> _openChat(BuildContext context) async {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final otherUserId = isPartner
        ? engagement.customerUserId
        : engagement.partnerUserId;
    final res = await MessageService().getPrivateConversation(userId, otherUserId);
    if (!context.mounted) return;
    if (res.success && res.conversation != null) {
      Navigator.of(context).pushNamed(
        '/chat/${res.conversation!.id}',
        arguments: res.conversation,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.message ?? (isSw ? 'Imeshindikana' : 'Failed')),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final counterparty = isPartner ? engagement.customerName : engagement.partnerName;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.forum_rounded, size: 56, color: _kMuted),
            const SizedBox(height: 12),
            Text(
              isSw
                  ? 'Maongezi na ${counterparty ?? "mshirika"}'
                  : 'Conversation with ${counterparty ?? "the counterparty"}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSw
                  ? 'Bonyeza kufungua mazungumzo katika ujumbe.'
                  : 'Tap to open the thread in messages.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: _kMuted),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openChat(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.chat_rounded),
              label: Text(isSw ? 'Fungua maongezi' : 'Open chat'),
            ),
          ],
        ),
      ),
    );
  }
}
