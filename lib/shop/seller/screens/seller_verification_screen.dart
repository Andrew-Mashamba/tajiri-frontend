import 'package:flutter/material.dart';
import '../../../services/local_storage_service.dart';
import '../models/trust_models.dart';
import '../services/seller_verification_service.dart';

const Color _kBg = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kDivider = Color(0xFFE0E0E0);

/// Screen where a seller submits NIDA/BRELA verification.
class SellerVerificationScreen extends StatefulWidget {
  const SellerVerificationScreen({super.key});

  @override
  State<SellerVerificationScreen> createState() => _SellerVerificationScreenState();
}

class _SellerVerificationScreenState extends State<SellerVerificationScreen> {
  String? _token;
  SellerVerificationStatus? _status;
  bool _loadingStatus = true;

  // NIDA form
  final _nidaController = TextEditingController();
  bool _submittingNida = false;

  // BRELA form
  final _brelaController = TextEditingController();
  bool _submittingBrela = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _nidaController.dispose();
    _brelaController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    if (!mounted) return;
    setState(() => _token = token);
    if (token != null) {
      await _loadStatus(token);
    } else {
      setState(() => _loadingStatus = false);
    }
  }

  Future<void> _loadStatus(String token) async {
    setState(() => _loadingStatus = true);
    final status = await SellerVerificationService.getVerificationStatus(token);
    if (!mounted) return;
    setState(() {
      _status = status;
      _loadingStatus = false;
      if (status?.brelaNumber != null) {
        _brelaController.text = status!.brelaNumber!;
      }
    });
  }

  Future<void> _submitNida() async {
    if (_token == null || _nidaController.text.trim().isEmpty) return;
    setState(() => _submittingNida = true);
    final ok = await SellerVerificationService.submitVerification(
      _token!,
      type: 'nida',
      nidaNumber: _nidaController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submittingNida = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification request submitted. We\'ll review within 48 hours.'),
        ),
      );
      await _loadStatus(_token!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission failed. Please try again.')),
      );
    }
  }

  Future<void> _submitBrela() async {
    if (_token == null || _brelaController.text.trim().isEmpty) return;
    setState(() => _submittingBrela = true);
    final ok = await SellerVerificationService.submitVerification(
      _token!,
      type: 'brela',
      brelaNumber: _brelaController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submittingBrela = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification request submitted. We\'ll review within 48 hours.'),
        ),
      );
      await _loadStatus(_token!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        foregroundColor: _kPrimary,
        title: const Text(
          'Get Verified',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: _loadingStatus
            ? const Center(
                child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusCard(),
                    const SizedBox(height: 20),
                    _buildNidaSection(),
                    const SizedBox(height: 16),
                    _buildBrelaSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = _status?.verificationStatus ?? 'unverified';
    final icon = _statusIcon(status);
    final color = _statusColor(status);
    final label = _statusLabel(status);
    final subtitle = _statusSubtitle(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _kSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'verified':
        return Icons.verified_rounded;
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.shield_outlined;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'verified':
        return const Color(0xFF22C55E);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return _kSecondary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'verified':
        return 'Verified';
      case 'pending':
        return 'Under Review';
      case 'rejected':
        return 'Verification Rejected';
      default:
        return 'Not Verified';
    }
  }

  String _statusSubtitle(String status) {
    switch (status) {
      case 'verified':
        return 'Your account is verified. Trust badges are visible to buyers.';
      case 'pending':
        return 'We\'re reviewing your documents. This usually takes up to 48 hours.';
      case 'rejected':
        return 'Your request was rejected. Please resubmit with valid documents.';
      default:
        return 'Submit your documents to build buyer trust and increase sales.';
    }
  }

  Widget _buildNidaSection() {
    final isPending = _status?.verificationStatus == 'pending';
    final isVerified = _status?.nidaVerified == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_rounded, size: 20, color: _kPrimary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Individual (NIDA)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
              ),
              if (isVerified)
                const Icon(Icons.verified_rounded, size: 18, color: Color(0xFF22C55E)),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Verify your identity using your National ID (NIDA) number.',
            style: TextStyle(fontSize: 13, color: _kSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _nidaController,
            enabled: !isVerified && !isPending,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'NIDA Number',
              hintText: 'e.g. 19850101-12345-00001-6',
              hintStyle: const TextStyle(color: Color(0xFF999999), fontSize: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kDivider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kPrimary, width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kDivider),
              ),
            ),
          ),
          if (!isVerified && !isPending) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submittingNida ? null : _submitNida,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _kDivider,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submittingNida
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Submit NIDA Verification',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBrelaSection() {
    final isPending = _status?.verificationStatus == 'pending';
    final isVerified = _status?.brelaRegistered == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.business_rounded, size: 20, color: _kPrimary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Business (BRELA)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
              ),
              if (isVerified)
                const Icon(Icons.verified_rounded, size: 18, color: Color(0xFF22C55E)),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Register your business using your BRELA registration number.',
            style: TextStyle(fontSize: 13, color: _kSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _brelaController,
            enabled: !isVerified && !isPending,
            decoration: InputDecoration(
              labelText: 'BRELA Number',
              hintText: 'e.g. 123456789',
              hintStyle: const TextStyle(color: Color(0xFF999999), fontSize: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kDivider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kPrimary, width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kDivider),
              ),
            ),
          ),
          if (!isVerified && !isPending) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submittingBrela ? null : _submitBrela,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _kDivider,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submittingBrela
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Submit BRELA Verification',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
