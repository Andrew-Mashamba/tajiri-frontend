// lib/business/pages/business_card_page.dart
// Digital Business Card / QR Code (Kadi ya Biashara).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/local_storage_service.dart';
import '../models/business_models.dart';
import '../services/business_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class BusinessCardPage extends StatefulWidget {
  final Business business;
  const BusinessCardPage({super.key, required this.business});

  @override
  State<BusinessCardPage> createState() => _BusinessCardPageState();
}

class _BusinessCardPageState extends State<BusinessCardPage> {
  String? _token;
  bool _loading = true;
  Map<String, dynamic>? _cardData;
  String? _qrCodeUrl;
  String? _shareUrl;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    await _load();
  }

  Future<void> _load() async {
    if (_token == null || widget.business.id == null) return;
    setState(() => _loading = true);
    final res =
        await BusinessService.getBusinessCard(_token!, widget.business.id!);
    if (mounted) {
      setState(() {
        _loading = false;
        if (res.success && res.data != null) {
          _cardData = res.data;
          _qrCodeUrl = _cardData?['qr_code_url']?.toString();
        }
      });
    }
  }

  Future<void> _share() async {
    if (_token == null || widget.business.id == null) return;
    final res =
        await BusinessService.shareBusinessCard(_token!, widget.business.id!);
    if (res.success && res.data != null && res.data!.isNotEmpty) {
      _shareUrl = res.data;
      SharePlus.instance.share(ShareParams(
        text: 'Check out my business: ${widget.business.name}\n$_shareUrl',
        subject: 'Business Card - ${widget.business.name}',
      ));
    } else {
      // Fallback: share basic info
      SharePlus.instance.share(ShareParams(
        text: '${widget.business.name}\n'
            '${widget.business.phone ?? ""}\n'
            '${widget.business.email ?? ""}\n'
            '${widget.business.address ?? ""}',
        subject: 'Business Card - ${widget.business.name}',
      ));
    }
  }

  Future<void> _copyLink() async {
    if (_token == null || widget.business.id == null) return;
    if (_shareUrl == null) {
      final res =
          await BusinessService.shareBusinessCard(_token!, widget.business.id!);
      if (res.success && res.data != null) {
        _shareUrl = res.data;
      }
    }
    if (_shareUrl != null) {
      await Clipboard.setData(ClipboardData(text: _shareUrl!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Link copied')));
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not generate link')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.business;

    return Scaffold(
      backgroundColor: _kBackground,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Visual business card
                _buildCard(b),

                const SizedBox(height: 24),

                // QR Code
                _buildQrSection(),

                const SizedBox(height: 24),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _share,
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: const Text('Share'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _copyLink,
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: const Text('Copy Link'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _kPrimary,
                            side: const BorderSide(color: _kPrimary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 80),
              ],
            ),
    );
  }

  Widget _buildCard(Business b) {
    return Container(
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top section
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: b.logoUrl != null && b.logoUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(b.logoUrl!,
                              width: 56, height: 56, fit: BoxFit.cover),
                        )
                      : Center(
                          child: Text(
                            b.name.isNotEmpty ? b.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(businessTypeLabel(b.type),
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12)),
                      if (b.sector != null && b.sector!.isNotEmpty)
                        Text(b.sector!,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Divider(color: Colors.white.withValues(alpha: 0.1)),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              children: [
                if (b.tinNumber != null && b.tinNumber!.isNotEmpty)
                  _cardDetail(Icons.badge_rounded, 'TIN: ${b.tinNumber}'),
                if (b.vrn != null && b.vrn!.isNotEmpty)
                  _cardDetail(
                      Icons.verified_rounded, 'VRN: ${b.vrn}'),
                if (b.phone != null && b.phone!.isNotEmpty)
                  _cardDetail(Icons.phone_rounded, b.phone!),
                if (b.email != null && b.email!.isNotEmpty)
                  _cardDetail(Icons.email_rounded, b.email!),
                if (b.address != null && b.address!.isNotEmpty)
                  _cardDetail(Icons.location_on_rounded, b.address!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardDetail(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.5)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildQrSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          const Text('QR Code',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _kPrimary)),
          const SizedBox(height: 4),
          const Text('Scan to get business details',
              style: TextStyle(fontSize: 12, color: _kSecondary)),
          const SizedBox(height: 16),
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: _qrCodeUrl != null && _qrCodeUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(_qrCodeUrl!,
                        width: 200, height: 200, fit: BoxFit.contain),
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code_2_rounded,
                            size: 80, color: _kPrimary.withValues(alpha: 0.3)),
                        const SizedBox(height: 8),
                        const Text('QR Code',
                            style: TextStyle(
                                color: _kSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
