import 'package:flutter/material.dart';
import '../../../services/local_storage_service.dart';
import '../models/escrow_models.dart';
import '../services/escrow_service.dart';

// DESIGN.md tokens
const Color _kBg = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);

const BoxShadow _kShadow = BoxShadow(
  color: Color(0x1A000000),
  blurRadius: 4,
  offset: Offset(0, 2),
);

/// Full dispute state screen — opened from order detail or dispute list.
class DisputeDetailScreen extends StatefulWidget {
  final int orderId;
  final EscrowDispute? initialDispute;
  final bool isSeller;

  const DisputeDetailScreen({
    super.key,
    required this.orderId,
    this.initialDispute,
    this.isSeller = false,
  });

  @override
  State<DisputeDetailScreen> createState() => _DisputeDetailScreenState();
}

class _DisputeDetailScreenState extends State<DisputeDetailScreen> {
  EscrowDispute? _dispute;
  bool _loading = true;
  String? _error;
  bool _responding = false;
  final TextEditingController _responseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialDispute != null) {
      _dispute = widget.initialDispute;
      _loading = false;
    } else {
      _loadDispute();
    }
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _loadDispute() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Not authenticated';
        });
        return;
      }
      final dispute = await EscrowService.getDispute(widget.orderId, token);
      if (mounted) {
        setState(() {
          _loading = false;
          if (dispute != null) {
            _dispute = dispute;
          } else {
            _error = 'Dispute not found';
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'Error: $e'; });
    }
  }

  Future<void> _showResponseSheet() async {
    _responseController.clear();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ResponseSheet(
        controller: _responseController,
        onSubmit: _submitResponse,
      ),
    );
  }

  Future<void> _submitResponse() async {
    final text = _responseController.text.trim();
    if (text.isEmpty) return;
    setState(() => _responding = true);

    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken() ?? '';
      final ok =
          await EscrowService.sellerRespondToDispute(widget.orderId, text, token);
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Response submitted. Our team will review both sides.'),
          ),
        );
        await _loadDispute();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit response. Try again.')),
        );
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _responding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text(
          'Dispute Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimary),
        ),
        backgroundColor: _kSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        actions: [
          if (!_loading && _dispute != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _StatusChip(status: _dispute!.status),
            ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _dispute == null
                    ? const SizedBox.shrink()
                    : _buildContent(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: _kTertiary),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: _kSecondary)),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: _loadDispute, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final d = _dispute!;
    return RefreshIndicator(
      onRefresh: _loadDispute,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDisputeInfoCard(d),
          const SizedBox(height: 16),
          _buildTimeline(d),
          if (d.evidenceUrls.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildEvidenceGrid(d),
          ],
          if (d.sellerResponse != null) ...[
            const SizedBox(height: 16),
            _buildSellerResponseCard(d),
          ],
          if (d.isResolved) ...[
            const SizedBox(height: 16),
            _buildResolutionCard(d),
          ],
          const SizedBox(height: 24),
          if (widget.isSeller && d.isOpen && d.sellerResponse == null)
            _buildRespondButton(),
          if (widget.isSeller && d.isUnderReview && d.sellerResponse == null)
            _buildRespondButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDisputeInfoCard(EscrowDispute d) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [_kShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.gavel_rounded,
                    size: 22, color: Color(0xFFD97706)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.reasonLabel,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _kPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Raised ${_formatDate(d.createdAt)}',
                      style: const TextStyle(fontSize: 12, color: _kTertiary),
                    ),
                  ],
                ),
              ),
              if (d.priority != 'normal')
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: d.priority == 'urgent'
                        ? const Color(0xFFFEE2E2)
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    d.priorityLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: d.priority == 'urgent'
                          ? const Color(0xFFDC2626)
                          : const Color(0xFFD97706),
                    ),
                  ),
                ),
            ],
          ),
          if (d.description != null && d.description!.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(color: _kDivider, height: 1),
            const SizedBox(height: 14),
            const Text(
              'Buyer\'s description',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              d.description!,
              style: const TextStyle(fontSize: 14, color: _kPrimary, height: 1.5),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeline(EscrowDispute d) {
    final steps = [
      _TimelineStep(
        label: 'Raised',
        done: true,
        date: d.createdAt,
      ),
      _TimelineStep(
        label: 'Seller Responded',
        done: d.sellerRespondedAt != null,
        date: d.sellerRespondedAt,
      ),
      _TimelineStep(
        label: 'Under Review',
        done: d.isUnderReview || d.isResolved,
        date: null,
      ),
      _TimelineStep(
        label: d.isResolved
            ? (d.resolvedInBuyerFavour
                ? 'Resolved — Buyer'
                : 'Resolved — Seller')
            : 'Resolved',
        done: d.isResolved,
        date: d.resolvedAt,
        isFinal: true,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [_kShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progress',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: _kPrimary),
          ),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((entry) {
            final i = entry.key;
            final step = entry.value;
            final isLast = i == steps.length - 1;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: step.done ? _kPrimary : _kDivider,
                          shape: BoxShape.circle,
                        ),
                        child: step.done
                            ? const Icon(Icons.check_rounded,
                                size: 12, color: Colors.white)
                            : null,
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 32,
                          color: step.done ? _kPrimary : _kDivider,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: step.done
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: step.done ? _kPrimary : _kTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (step.date != null)
                          Text(
                            _formatDate(step.date!),
                            style: const TextStyle(
                                fontSize: 11, color: _kTertiary),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEvidenceGrid(EscrowDispute d) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [_kShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Evidence (${d.evidenceUrls.length})',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: _kPrimary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: d.evidenceUrls.map((url) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      color: _kBg,
                      child: const Icon(Icons.broken_image_rounded,
                          color: _kTertiary),
                    ),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: _kBg,
                        child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerResponseCard(EscrowDispute d) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront_rounded,
                  size: 16, color: _kSecondary),
              const SizedBox(width: 8),
              const Text(
                'Seller\'s Response',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary),
              ),
              const Spacer(),
              if (d.sellerRespondedAt != null)
                Text(
                  _formatDate(d.sellerRespondedAt!),
                  style: const TextStyle(fontSize: 11, color: _kTertiary),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            d.sellerResponse!,
            style: const TextStyle(
                fontSize: 14, color: _kPrimary, height: 1.5),
            maxLines: 10,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionCard(EscrowDispute d) {
    final isSellerWon = d.resolvedInSellerFavour;
    final bg =
        isSellerWon ? const Color(0xFFD1FAE5) : const Color(0xFFDBEAFE);
    final iconColor =
        isSellerWon ? const Color(0xFF059669) : const Color(0xFF2563EB);
    final title =
        isSellerWon ? 'Resolved in Seller\'s Favour' : 'Resolved in Buyer\'s Favour';
    final subtitle = isSellerWon
        ? 'Seller has been credited. Escrow released.'
        : 'Buyer has been refunded.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isSellerWon
                ? Icons.check_circle_rounded
                : Icons.assignment_return_rounded,
            size: 32,
            color: iconColor,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: iconColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: iconColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (d.resolutionNotes != null &&
                    d.resolutionNotes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    d.resolutionNotes!,
                    style: TextStyle(
                        fontSize: 12,
                        color: iconColor.withValues(alpha: 0.8)),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRespondButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _responding ? null : _showResponseSheet,
        icon: _responding
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.reply_rounded, size: 18),
        label: const Text('Respond to Dispute',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }
}

class _TimelineStep {
  final String label;
  final bool done;
  final DateTime? date;
  final bool isFinal;

  const _TimelineStep({
    required this.label,
    required this.done,
    this.date,
    this.isFinal = false,
  });
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      'under_review' => (const Color(0xFFDBEAFE), const Color(0xFF2563EB), 'Under Review'),
      'resolved_seller' => (const Color(0xFFD1FAE5), const Color(0xFF059669), 'Resolved — Seller'),
      'resolved_buyer' => (const Color(0xFFD1FAE5), const Color(0xFF047857), 'Resolved — Buyer'),
      'closed' => (const Color(0xFFF3F4F6), const Color(0xFF6B7280), 'Closed'),
      _ => (const Color(0xFFFEF3C7), const Color(0xFFD97706), 'Open'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

// ─── Response Bottom Sheet ─────────────────────────────────────────────────

class _ResponseSheet extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const _ResponseSheet({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: _kDivider, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Respond to Dispute',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary)),
          const SizedBox(height: 6),
          const Text(
            'Explain your side of the story. Our team will review both sides.',
            style: TextStyle(fontSize: 13, color: _kSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            maxLines: 5,
            minLines: 4,
            maxLength: 2000,
            decoration: InputDecoration(
              hintText: 'Describe what happened from your perspective...',
              hintStyle: const TextStyle(fontSize: 13, color: _kTertiary),
              filled: true,
              fillColor: _kBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kDivider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kDivider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kPrimary),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onSubmit();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Submit Response',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
