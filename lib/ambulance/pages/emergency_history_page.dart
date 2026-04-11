// lib/ambulance/pages/emergency_history_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/ambulance_models.dart';
import '../services/ambulance_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kRed = Color(0xFFCC0000);
const Color _kGreen = Color(0xFF2E7D32);

class EmergencyHistoryPage extends StatefulWidget {
  const EmergencyHistoryPage({super.key});
  @override
  State<EmergencyHistoryPage> createState() => _EmergencyHistoryPageState();
}

class _EmergencyHistoryPageState extends State<EmergencyHistoryPage> {
  final AmbulanceService _service = AmbulanceService();
  List<Emergency> _history = [];
  bool _isLoading = true;
  bool _isPaying = false;
  int _page = 1;
  bool _hasMore = true;
  late final bool _isSwahili;

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _hasMore = true;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _service.getEmergencyHistory(page: _page);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (result.success) {
          if (refresh) {
            _history = result.items;
          } else {
            _history.addAll(result.items);
          }
          _hasMore = result.currentPage < result.lastPage;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Color _statusColor(EmergencyStatus status) {
    switch (status) {
      case EmergencyStatus.completed:
        return _kGreen;
      case EmergencyStatus.cancelled:
        return _kSecondary;
      case EmergencyStatus.dispatched:
      case EmergencyStatus.enRoute:
        return const Color(0xFFE65100);
      case EmergencyStatus.arrived:
        return const Color(0xFF1565C0);
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // FEATURE 47: Payment dialog for unpaid emergencies
  Future<void> _showPaymentDialog(Emergency emergency) async {
    final phoneController = TextEditingController();
    String selectedMethod = 'mpesa';

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isSwahili ? 'Lipa Dharura' : 'Pay Emergency',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary),
              ),
              const SizedBox(height: 4),
              if (emergency.cost != null)
                Text(
                  'TZS ${emergency.cost!.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _kPrimary),
                ),
              const SizedBox(height: 16),
              Text(
                _isSwahili
                    ? 'Chagua njia ya malipo'
                    : 'Select payment method',
                style: const TextStyle(fontSize: 13, color: _kSecondary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _PaymentChip(
                    label: 'M-Pesa',
                    selected: selectedMethod == 'mpesa',
                    onTap: () =>
                        setSheetState(() => selectedMethod = 'mpesa'),
                  ),
                  _PaymentChip(
                    label: 'Tigo Pesa',
                    selected: selectedMethod == 'tigopesa',
                    onTap: () =>
                        setSheetState(() => selectedMethod = 'tigopesa'),
                  ),
                  _PaymentChip(
                    label: 'Airtel Money',
                    selected: selectedMethod == 'airtel',
                    onTap: () =>
                        setSheetState(() => selectedMethod = 'airtel'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: _isSwahili
                      ? 'Nambari ya simu (mfano: 0712345678)'
                      : 'Phone number (e.g. 0712345678)',
                  hintStyle:
                      const TextStyle(fontSize: 13, color: _kSecondary),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _isPaying
                      ? null
                      : () async {
                          final phone = phoneController.text.trim();
                          if (phone.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(_isSwahili
                                    ? 'Tafadhali ingiza nambari ya simu'
                                    : 'Please enter phone number'),
                              ),
                            );
                            return;
                          }
                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(ctx);
                          setState(() => _isPaying = true);
                          try {
                            final payResult =
                                await _service.payEmergency(
                              emergencyId: emergency.id,
                              paymentMethod: selectedMethod,
                              phone: phone,
                            );
                            if (!mounted) return;
                            setState(() => _isPaying = false);
                            if (payResult.success) {
                              nav.pop(true);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(_isSwahili
                                      ? 'Malipo yametumwa! Angalia simu yako.'
                                      : 'Payment sent! Check your phone.'),
                                ),
                              );
                            } else {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(payResult.message ??
                                      (_isSwahili
                                          ? 'Malipo yameshindwa'
                                          : 'Payment failed')),
                                ),
                              );
                            }
                          } catch (e) {
                            if (!mounted) return;
                            setState(() => _isPaying = false);
                            messenger.showSnackBar(
                              SnackBar(content: Text('$e')),
                            );
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: _kPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isPaying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _isSwahili ? 'Lipa Sasa' : 'Pay Now',
                          style: const TextStyle(fontSize: 14),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result == true) {
      phoneController.dispose();
      _load(refresh: true);
    } else {
      phoneController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(
          _isSwahili ? 'Historia ya Dharura' : 'Emergency History',
          style:
              const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: _isLoading && _history.isEmpty
          ? const Center(
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history_rounded,
                          size: 48, color: _kSecondary),
                      const SizedBox(height: 12),
                      Text(
                        _isSwahili
                            ? 'Hakuna historia ya dharura'
                            : 'No emergency history',
                        style: const TextStyle(
                            color: _kSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _load(refresh: true),
                  color: _kPrimary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _history.length + (_hasMore ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      if (i >= _history.length) {
                        if (!_isLoading) {
                          _page++;
                          _load();
                        }
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _kPrimary),
                          ),
                        );
                      }

                      final e = _history[i];
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _kRed.withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                        Icons.emergency_rounded,
                                        color: _kRed,
                                        size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          e.type ??
                                              (_isSwahili
                                                  ? 'Dharura'
                                                  : 'Emergency'),
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: _kPrimary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          _formatDate(e.createdAt),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: _kSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _statusColor(e.status)
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _isSwahili
                                          ? e.status.label
                                          : e.status.labelEn,
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: _statusColor(e.status)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  if (e.address != null) ...[
                                    const Icon(Icons.place_rounded,
                                        size: 14, color: _kSecondary),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        e.address!,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: _kSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ] else
                                    const Spacer(),
                                  if (e.ambulance != null)
                                    Text(
                                      e.ambulance!.provider,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: _kSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                              if (e.hospitalName != null ||
                                  e.cost != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    if (e.hospitalName != null) ...[
                                      const Icon(
                                          Icons.local_hospital_rounded,
                                          size: 14,
                                          color: _kSecondary),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          e.hospitalName!,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: _kSecondary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ] else
                                      const Spacer(),
                                    if (e.cost != null)
                                      Text(
                                        'TZS ${e.cost!.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: _kPrimary),
                                      ),
                                  ],
                                ),
                              ],
                              // FEATURE 47: Pay button for unpaid emergencies
                              if (e.cost != null &&
                                  !e.isPaid &&
                                  e.status == EmergencyStatus.completed) ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  height: 36,
                                  child: FilledButton.icon(
                                    onPressed: () =>
                                        _showPaymentDialog(e),
                                    icon: const Icon(
                                        Icons.payments_rounded,
                                        size: 16),
                                    label: Text(
                                      _isSwahili ? 'Lipa' : 'Pay',
                                      style: const TextStyle(
                                          fontSize: 12),
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _kPrimary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ] else if (e.isPaid &&
                                  e.cost != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                        Icons.check_circle_rounded,
                                        size: 14,
                                        color: _kGreen),
                                    const SizedBox(width: 4),
                                    Text(
                                      _isSwahili
                                          ? 'Imelipwa'
                                          : 'Paid',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: _kGreen),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PaymentChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label,
          style: TextStyle(
              fontSize: 12,
              color: selected ? Colors.white : _kPrimary)),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: _kPrimary,
      backgroundColor: Colors.white,
      side: BorderSide(
          color: selected ? _kPrimary : const Color(0xFFE0E0E0)),
    );
  }
}
