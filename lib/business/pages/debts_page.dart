// lib/business/pages/debts_page.dart
// Deni Zangu — THE most critical feature for Tanzanian shopkeepers.
// Full debt tracking with partial payments, reminders, and overdue management.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/local_storage_service.dart';
import '../models/business_models.dart';
import '../services/business_service.dart';
import '../widgets/debt_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class DebtsPage extends StatefulWidget {
  final int businessId;
  const DebtsPage({super.key, required this.businessId});

  @override
  State<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<DebtsPage>
    with SingleTickerProviderStateMixin {
  String? _token;
  bool _loading = true;
  String? _error;
  List<Debt> _allDebts = [];
  DebtSummary? _summary;
  late TabController _tabCtrl;
  List<Customer> _customers = [];

  final _tabs = const ['All', 'Pending', 'Overdue', 'Paid'];
  final _statusFilters = const [null, 'pending', 'overdue', 'paid'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) setState(() {});
    });
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
      final results = await Future.wait([
        BusinessService.getDebts(_token!, widget.businessId),
        BusinessService.getDebtSummary(_token!, widget.businessId),
        BusinessService.getCustomers(_token!, widget.businessId),
      ]);

      final debtsRes = results[0] as BusinessListResult<Debt>;
      final summaryRes = results[1] as BusinessResult<DebtSummary>;
      final custRes = results[2] as BusinessListResult<Customer>;

      if (mounted) {
        setState(() {
          _loading = false;
          if (debtsRes.success) {
            _allDebts = debtsRes.data;
          } else {
            _error = debtsRes.message ?? 'Failed to load debts';
          }
          if (summaryRes.success && summaryRes.data != null) {
            _summary = summaryRes.data;
          }
          if (custRes.success) _customers = custRes.data;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Connection error. Pull to retry.';
        });
      }
    }
  }

  List<Debt> get _filteredDebts {
    final filter = _statusFilters[_tabCtrl.index];
    if (filter == null) return _allDebts;
    return _allDebts.where((d) => d.status.name == filter).toList();
  }

  void _showPaymentDialog(Debt debt) {
    final amountCtrl = TextEditingController();
    final remaining = debt.remainingAmount;
    final nf = NumberFormat('#,###', 'en');
    bool processing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Record Payment',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _kPrimary)),
              const SizedBox(height: 4),
              Text(
                  '${debt.customerName} -- Balance: TZS ${nf.format(remaining)}',
                  style: const TextStyle(fontSize: 13, color: _kSecondary)),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Payment Amount (TZS)',
                  prefixIcon:
                      const Icon(Icons.payment_rounded, color: _kSecondary),
                  filled: true,
                  fillColor: _kBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Quick amount buttons
              Wrap(
                spacing: 8,
                children: [
                  _quickAmountChip(amountCtrl, remaining, 'Full'),
                  if (remaining > 10000)
                    _quickAmountChip(amountCtrl, remaining / 2, 'Half'),
                  if (remaining > 20000)
                    _quickAmountChip(amountCtrl, 10000, '10,000'),
                  if (remaining > 50000)
                    _quickAmountChip(amountCtrl, 50000, '50,000'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: processing
                      ? null
                      : () async {
                          final amount = double.tryParse(
                              amountCtrl.text.replaceAll(',', ''));
                          if (amount == null || amount <= 0) return;
                          if (amount > remaining) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Amount exceeds balance')));
                            return;
                          }
                          setLocal(() => processing = true);
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            final res =
                                await BusinessService.recordDebtPayment(
                                    _token!, debt.id!, amount);
                            if (ctx.mounted) Navigator.pop(ctx);
                            messenger.showSnackBar(SnackBar(
                                content: Text(res.success
                                    ? 'Payment of TZS ${nf.format(amount)} recorded!'
                                    : res.message ?? 'Failed')));
                          } catch (e) {
                            setLocal(() => processing = false);
                            messenger.showSnackBar(const SnackBar(
                                content: Text('Connection error')));
                            return;
                          }
                          _load();
                        },
                  icon: processing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_circle_rounded, size: 20),
                  label: Text(processing ? 'Processing...' : 'Record Payment',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickAmountChip(
      TextEditingController ctrl, double amount, String label) {
    final nf = NumberFormat('#,###', 'en');
    return ActionChip(
      label: Text(label == 'Full' || label == 'Half'
          ? '$label (${nf.format(amount)})'
          : label),
      onPressed: () => ctrl.text = amount.toStringAsFixed(0),
      backgroundColor: _kPrimary.withValues(alpha: 0.06),
      labelStyle: const TextStyle(fontSize: 12, color: _kPrimary),
      side: BorderSide.none,
    );
  }

  void _showAddDebtDialog() {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    Customer? selectedCustomer;
    DateTime dueDate = DateTime.now().add(const Duration(days: 30));
    bool useExisting = _customers.isNotEmpty;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Add New Debt',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _kPrimary)),
                const SizedBox(height: 16),

                // Toggle: existing customer vs new
                if (_customers.isNotEmpty)
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Existing Customer'),
                        selected: useExisting,
                        onSelected: (v) =>
                            setLocal(() => useExisting = true),
                        selectedColor: _kPrimary.withValues(alpha: 0.1),
                        labelStyle: TextStyle(
                            color:
                                useExisting ? _kPrimary : _kSecondary),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('New Customer'),
                        selected: !useExisting,
                        onSelected: (v) =>
                            setLocal(() => useExisting = false),
                        selectedColor: _kPrimary.withValues(alpha: 0.1),
                        labelStyle: TextStyle(
                            color:
                                !useExisting ? _kPrimary : _kSecondary),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),

                // Customer selection
                if (useExisting && _customers.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _kBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: selectedCustomer?.id,
                        hint: const Text('Select Customer'),
                        isExpanded: true,
                        items: _customers
                            .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (v) {
                          setLocal(() {
                            selectedCustomer =
                                _customers.firstWhere((c) => c.id == v);
                          });
                        },
                      ),
                    ),
                  ),
                ] else ...[
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Customer Name',
                      prefixIcon: const Icon(Icons.person_rounded,
                          size: 20, color: _kSecondary),
                      filled: true,
                      fillColor: _kBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: const Icon(Icons.phone_rounded,
                          size: 20, color: _kSecondary),
                      filled: true,
                      fillColor: _kBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Debt Amount (TZS)',
                    prefixIcon: const Icon(Icons.money_rounded,
                        size: 20, color: _kSecondary),
                    filled: true,
                    fillColor: _kBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Description (items taken, etc.)',
                    prefixIcon: const Icon(Icons.note_rounded,
                        size: 20, color: _kSecondary),
                    filled: true,
                    fillColor: _kBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Due date
                GestureDetector(
                  onTap: () async {
                    final dt = await showDatePicker(
                      context: ctx,
                      initialDate: dueDate,
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365)),
                    );
                    if (dt != null) setLocal(() => dueDate = dt);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Due Date',
                      prefixIcon: const Icon(
                          Icons.calendar_today_rounded,
                          size: 20,
                          color: _kSecondary),
                      filled: true,
                      fillColor: _kBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    child:
                        Text(DateFormat('dd/MM/yyyy').format(dueDate)),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: saving
                        ? null
                        : () async {
                            final amount = double.tryParse(
                                amountCtrl.text.replaceAll(',', ''));
                            if (amount == null || amount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Enter a valid amount')));
                              return;
                            }

                            final customerName = useExisting
                                ? selectedCustomer?.name
                                : nameCtrl.text.trim();
                            final customerPhone = useExisting
                                ? selectedCustomer?.phone
                                : phoneCtrl.text.trim();

                            if (customerName == null ||
                                customerName.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Select or enter customer name')));
                              return;
                            }

                            setLocal(() => saving = true);
                            final messenger =
                                ScaffoldMessenger.of(context);
                            try {
                              final body = {
                                'business_id': widget.businessId,
                                'customer_id': selectedCustomer?.id,
                                'customer_name': customerName,
                                'customer_phone': customerPhone,
                                'amount': amount,
                                'description': descCtrl.text.trim(),
                                'due_date': dueDate.toIso8601String(),
                                'status': 'pending',
                              };
                              final res =
                                  await BusinessService.createDebt(
                                      _token!, body);
                              if (ctx.mounted) Navigator.pop(ctx);
                              messenger.showSnackBar(SnackBar(
                                  content: Text(res.success
                                      ? 'Debt added!'
                                      : res.message ?? 'Failed')));
                            } catch (e) {
                              setLocal(() => saving = false);
                              messenger.showSnackBar(const SnackBar(
                                  content: Text('Connection error')));
                              return;
                            }
                            _load();
                          },
                    icon: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.add_circle_rounded, size: 20),
                    label: Text(saving ? 'Saving...' : 'Add Debt',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _sendReminder(Debt debt) {
    final nf = NumberFormat('#,###', 'en');
    final msg =
        'Hello ${debt.customerName}, this is a reminder about your outstanding debt of TZS ${nf.format(debt.remainingAmount)}. '
        'Please pay before ${debt.dueDate != null ? DateFormat('dd/MM/yyyy').format(debt.dueDate!) : "the due date"}. Thank you!';

    final phone = debt.customerPhone;

    showModalBottomSheet(
      context: context,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Send Reminder',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _kPrimary)),
              const SizedBox(height: 4),
              Text('To: ${debt.customerName}',
                  style:
                      const TextStyle(fontSize: 13, color: _kSecondary)),
              const SizedBox(height: 16),
              if (phone != null && phone.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.sms_rounded, color: _kPrimary),
                  title: const Text('SMS'),
                  subtitle:
                      Text(phone, style: const TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    launchUrl(Uri.parse(
                        'sms:$phone?body=${Uri.encodeComponent(msg)}'));
                  },
                ),
              if (phone != null && phone.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.chat_bubble_rounded,
                      color: _kPrimary),
                  title: const Text('WhatsApp'),
                  subtitle:
                      Text(phone, style: const TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    final cleanPhone = phone.replaceAll('+', '');
                    launchUrl(Uri.parse(
                        'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(msg)}'));
                  },
                ),
              if (phone == null || phone.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No phone number on file for this customer.',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 13),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat('#,###', 'en');
    final debts = _filteredDebts;

    return Scaffold(
      backgroundColor: _kBackground,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDebtDialog,
        backgroundColor: _kPrimary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Debt',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          Material(
            color: _kCardBg,
            child: TabBar(
              controller: _tabCtrl,
              labelColor: _kPrimary,
              unselectedLabelColor: _kSecondary,
              indicatorColor: _kPrimary,
              indicatorWeight: 2,
              labelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
          Expanded(
            child: _loading
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
                      Text(_error!,
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 14)),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Retry'),
                        style:
                            TextButton.styleFrom(foregroundColor: _kPrimary),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Summary card
                    if (_summary != null)
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _kCardBg,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _summaryItem(
                                'Total Outstanding',
                                'TZS ${nf.format(_summary!.totalOutstanding)}',
                                Colors.red.shade50,
                                Colors.red.shade700,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _summaryItem(
                                'Overdue',
                                '${_summary!.overdueCount}',
                                Colors.orange.shade50,
                                Colors.orange.shade700,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _summaryItem(
                                'Pending',
                                '${_summary!.pendingCount + _summary!.partialCount}',
                                Colors.blue.shade50,
                                Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Debt list
                    Expanded(
                      child: debts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                      Icons
                                          .check_circle_outline_rounded,
                                      size: 64,
                                      color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  Text('No debts',
                                      style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text(
                                      'All clear! Tap + to track a new debt.',
                                      style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 13)),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              color: _kPrimary,
                              onRefresh: _load,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16),
                                itemCount: debts.length,
                                itemBuilder: (_, i) {
                                  final d = debts[i];
                                  return DebtCard(
                                    debt: d,
                                    onPayTap: d.id != null
                                        ? () => _showPaymentDialog(d)
                                        : null,
                                    onRemindTap: () => _sendReminder(d),
                                  );
                                },
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

  Widget _summaryItem(String label, String value, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: fg),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: fg.withValues(alpha: 0.8)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
