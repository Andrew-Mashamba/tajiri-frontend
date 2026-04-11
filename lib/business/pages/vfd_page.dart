// lib/business/pages/vfd_page.dart
// TRA VFD Integration — registration, fiscal receipts.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/business_models.dart';
import '../services/business_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class VfdPage extends StatefulWidget {
  final int businessId;
  const VfdPage({super.key, required this.businessId});

  @override
  State<VfdPage> createState() => _VfdPageState();
}

class _VfdPageState extends State<VfdPage> {
  String? _token;
  bool _loading = true;
  bool _registering = false;
  String? _error;
  VfdConfig? _config;
  List<FiscalReceipt> _receipts = [];

  final _tinCtrl = TextEditingController();
  final _vrnCtrl = TextEditingController();
  final _serialCtrl = TextEditingController();

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

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
    if (_token == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final futures = await Future.wait([
        BusinessService.getVfdConfig(_token!, widget.businessId),
        BusinessService.getFiscalReceipts(_token!, widget.businessId),
      ]);

      final configRes = futures[0] as BusinessResult<VfdConfig>;
      final receiptsRes = futures[1] as BusinessListResult<FiscalReceipt>;

      if (mounted) {
        setState(() {
          _loading = false;
          if (configRes.success && configRes.data != null) {
            _config = configRes.data;
            _tinCtrl.text = _config?.tin ?? '';
            _vrnCtrl.text = _config?.vrn ?? '';
            _serialCtrl.text = _config?.serialNumber ?? '';
          }
          if (receiptsRes.success) _receipts = receiptsRes.data;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _registerVfd() async {
    if (_token == null) return;
    final sw = _sw;
    if (_tinCtrl.text.trim().isEmpty || _serialCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(sw
              ? 'Jaza TIN na Nambari ya Serial'
              : 'Enter TIN and Serial Number')));
      return;
    }

    setState(() => _registering = true);
    final body = {
      'tin': _tinCtrl.text.trim(),
      'vrn': _vrnCtrl.text.trim(),
      'serial_number': _serialCtrl.text.trim(),
    };
    try {
      final res =
          await BusinessService.registerVfd(_token!, widget.businessId, body);
      if (mounted) {
        setState(() => _registering = false);
        if (res.success) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  res.message ?? (sw ? 'VFD imesajiliwa' : 'VFD registered'))));
          _load();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  res.message ?? (sw ? 'Imeshindikana' : 'Failed'))));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _registering = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(sw ? 'Imeshindikana' : 'Failed')));
      }
    }
  }

  @override
  void dispose() {
    _tinCtrl.dispose();
    _vrnCtrl.dispose();
    _serialCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat('#,###', 'en');
    final df = DateFormat('dd/MM/yyyy HH:mm');
    final sw = _sw;

    return Scaffold(
      backgroundColor: _kBackground,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _kPrimary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        sw ? 'Imeshindikana kupakia' : 'Failed to load',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(sw ? 'Jaribu tena' : 'Retry'),
                        style:
                            TextButton.styleFrom(foregroundColor: _kPrimary),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: _kPrimary,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Registration status
                      _buildStatusCard(sw),
                      const SizedBox(height: 16),

                      // Registration form (if not registered)
                      if (_config == null || !_config!.isActive)
                        _buildRegistrationForm(sw),

                      // Recent fiscal receipts
                      if (_receipts.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                            sw
                                ? 'Risiti za Hivi Karibuni'
                                : 'Recent Receipts',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _kPrimary)),
                        const SizedBox(height: 12),
                        ..._receipts
                            .map((r) => _buildReceiptCard(r, nf, df)),
                      ],

                      if (_config != null &&
                          _config!.isActive &&
                          _receipts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.receipt_long_rounded,
                                    size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                    sw
                                        ? 'Hakuna risiti za hivi karibuni'
                                        : 'No recent receipts',
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 15)),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatusCard(bool sw) {
    final isRegistered = _config != null && _config!.isActive;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRegistered ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isRegistered
                ? Colors.green.shade200
                : Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isRegistered
                  ? Colors.green.shade100
                  : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isRegistered
                  ? Icons.verified_rounded
                  : Icons.pending_rounded,
              size: 28,
              color: isRegistered
                  ? Colors.green.shade700
                  : Colors.orange.shade700,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRegistered
                      ? (sw ? 'VFD Imesajiliwa' : 'VFD Registered')
                      : (sw ? 'VFD Haijasajiliwa' : 'VFD Not Registered'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isRegistered
                        ? Colors.green.shade800
                        : Colors.orange.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isRegistered
                      ? 'TIN: ${_config!.tin ?? "-"}\nVRN: ${_config!.vrn ?? "-"}\nS/N: ${_config!.serialNumber ?? "-"}'
                      : (sw
                          ? 'Sajili VFD yako na TRA ili kutoa risiti halali za kielektroniki.'
                          : 'Register your VFD with TRA to issue legal electronic receipts.'),
                  style: TextStyle(
                    fontSize: 12,
                    color: isRegistered
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm(bool sw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(sw ? 'Sajili VFD' : 'Register VFD',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: _kPrimary)),
        const SizedBox(height: 12),
        _textField(_tinCtrl, 'TIN (Taxpayer Identification Number)'),
        const SizedBox(height: 10),
        _textField(_vrnCtrl, 'VRN (VAT Registration Number)'),
        const SizedBox(height: 10),
        _textField(_serialCtrl,
            sw ? 'Nambari ya Serial ya VFD' : 'VFD Serial Number'),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _registering ? null : _registerVfd,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _registering
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(sw ? 'Sajili na TRA' : 'Register with TRA',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _textField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: _kCardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildReceiptCard(
      FiscalReceipt r, NumberFormat nf, DateFormat df) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.receipt_long_rounded,
                    size: 18, color: Colors.green.shade700),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        r.receiptNumber ??
                            (_sw ? 'Risiti' : 'Receipt'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _kPrimary,
                            fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (r.issuedAt != null)
                      Text(df.format(r.issuedAt!),
                          style: const TextStyle(
                              fontSize: 11, color: _kSecondary)),
                  ],
                ),
              ),
              Text('TZS ${nf.format(r.totalAmount)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _kPrimary,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          if (r.fiscalCode != null && r.fiscalCode!.isNotEmpty)
            Text('Fiscal Code: ${r.fiscalCode}',
                style: const TextStyle(fontSize: 11, color: _kSecondary)),
          if (r.verificationUrl != null && r.verificationUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.link_rounded,
                      size: 14, color: Colors.blue.shade700),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(r.verificationUrl!,
                        style: TextStyle(
                            fontSize: 11, color: Colors.blue.shade700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
