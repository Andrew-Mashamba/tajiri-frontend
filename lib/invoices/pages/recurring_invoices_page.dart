// lib/invoices/pages/recurring_invoices_page.dart
// Recurring Invoices management.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../services/people_search_service.dart';
import '../../models/people_search_models.dart';
import '../../business/models/business_models.dart';
import '../../business/services/business_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class RecurringInvoicesPage extends StatefulWidget {
  final int businessId;
  const RecurringInvoicesPage({super.key, required this.businessId});

  @override
  State<RecurringInvoicesPage> createState() => _RecurringInvoicesPageState();
}

class _RecurringInvoicesPageState extends State<RecurringInvoicesPage> {
  String? _token;
  int? _currentUserId;
  bool _loading = true;
  String? _error;
  List<RecurringInvoice> _invoices = [];
  List<Customer> _customers = [];
  final _peopleSearch = PeopleSearchService();

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    _currentUserId = storage.getUser()?.userId;
    await _load();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    if (_token == null) return;
    try {
      final res = await BusinessService.getCustomers(
          _token!, widget.businessId);
      if (mounted && res.success) {
        setState(() => _customers = res.data);
      }
    } catch (_) {
      // Customers list is optional; manual entry still available.
    }
  }

  Future<void> _load() async {
    if (_token == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await BusinessService.getRecurringInvoices(
          _token!, widget.businessId);
      if (mounted) {
        setState(() {
          _loading = false;
          if (res.success) {
            _invoices = res.data;
          } else {
            _error = res.message ?? 'Failed to load';
          }
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

  // ---------------------------------------------------------------------------
  // Status helpers
  // ---------------------------------------------------------------------------

  /// Returns status: 'active', 'paused', or 'cancelled'.
  String _invoiceStatus(RecurringInvoice ri) {
    if (!ri.isActive) {
      // If endDate is in the past and it was deactivated, treat as cancelled.
      // Otherwise it's paused (can be resumed).
      if (ri.endDate != null && ri.endDate!.isBefore(DateTime.now())) {
        return 'cancelled';
      }
      return 'paused';
    }
    return 'active';
  }

  Color _statusDotColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'paused':
        return Colors.amber.shade700;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status, bool sw) {
    switch (status) {
      case 'active':
        return sw ? 'Hai' : 'Active';
      case 'paused':
        return sw ? 'Imesimamishwa' : 'Paused';
      default:
        return sw ? 'Imesitishwa' : 'Cancelled';
    }
  }

  // ---------------------------------------------------------------------------
  // Pause / Resume
  // ---------------------------------------------------------------------------

  Future<void> _togglePauseResume(RecurringInvoice ri) async {
    if (_token == null || ri.id == null) return;
    final sw = _sw;
    final messenger = ScaffoldMessenger.of(context);
    final newActive = !ri.isActive;
    try {
      final res = await BusinessService.updateRecurringInvoice(
          _token!, ri.id!, {'is_active': newActive});
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text(res.success
              ? (newActive
                  ? (sw ? 'Imeendelezwa' : 'Resumed')
                  : (sw ? 'Imesimamishwa' : 'Paused'))
              : (res.message ?? (sw ? 'Imeshindikana' : 'Failed'))),
        ));
        _load();
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
            SnackBar(content: Text(sw ? 'Imeshindikana' : 'Failed')));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Cancel
  // ---------------------------------------------------------------------------

  Future<void> _cancelRecurring(RecurringInvoice ri) async {
    if (_token == null || ri.id == null) return;
    final sw = _sw;
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Sitisha Ankara?' : 'Cancel Recurring Invoice?'),
        content: Text(sw
            ? 'Ankara hii haitaendelea kutolewa. Hatua hii haiwezi kurudishwa.'
            : 'This invoice will no longer be issued. This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(sw ? 'Hapana' : 'No')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(sw ? 'Ndio, Sitisha' : 'Yes, Cancel',
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final res = await BusinessService.cancelRecurringInvoice(_token!, ri.id!);
      if (mounted) {
        messenger.showSnackBar(SnackBar(
            content: Text(res.message ??
                (sw ? 'Imesitishwa' : 'Cancelled'))));
        _load();
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
            SnackBar(content: Text(sw ? 'Imeshindikana' : 'Failed')));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Detail Sheet
  // ---------------------------------------------------------------------------

  void _showDetailSheet(RecurringInvoice ri) {
    final sw = _sw;
    final nf = NumberFormat('#,###', 'en');
    final df = DateFormat('dd/MM/yyyy');
    final status = _invoiceStatus(ri);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  sw ? 'Maelezo ya Kiolezo' : 'Template Details',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: _kPrimary),
                ),
                const SizedBox(height: 14),

                // Customer
                _detailRow(
                  icon: Icons.person_rounded,
                  label: sw ? 'Mteja' : 'Customer',
                  value: ri.customerName ?? (sw ? 'Haijulikani' : 'Unknown'),
                ),
                const SizedBox(height: 10),

                // Frequency
                _detailRow(
                  icon: Icons.repeat_rounded,
                  label: sw ? 'Mzunguko' : 'Frequency',
                  value: recurringFrequencyLabel(ri.frequency, swahili: sw),
                ),
                const SizedBox(height: 10),

                // Total amount
                _detailRow(
                  icon: Icons.attach_money_rounded,
                  label: sw ? 'Jumla' : 'Total',
                  value: 'TZS ${nf.format(ri.totalAmount)}',
                ),
                const SizedBox(height: 10),

                // Start date
                if (ri.startDate != null) ...[
                  _detailRow(
                    icon: Icons.calendar_today_rounded,
                    label: sw ? 'Tarehe ya Kuanza' : 'Start Date',
                    value: df.format(ri.startDate!),
                  ),
                  const SizedBox(height: 10),
                ],

                // End date
                if (ri.endDate != null) ...[
                  _detailRow(
                    icon: Icons.event_rounded,
                    label: sw ? 'Tarehe ya Mwisho' : 'End Date',
                    value: df.format(ri.endDate!),
                  ),
                  const SizedBox(height: 10),
                ],

                // Next issue date
                if (ri.nextIssueDate != null && ri.isActive) ...[
                  _detailRow(
                    icon: Icons.schedule_rounded,
                    label: sw ? 'Ankara Inayofuata' : 'Next Issue Date',
                    value: df.format(ri.nextIssueDate!),
                  ),
                  const SizedBox(height: 10),
                ],

                // Generated count
                _detailRow(
                  icon: Icons.receipt_long_rounded,
                  label: sw ? 'Ankara Zilizotolewa' : 'Invoices Generated',
                  value: '${ri.totalIssued}',
                ),
                const SizedBox(height: 10),

                // Status
                _detailRow(
                  icon: Icons.info_outline_rounded,
                  label: sw ? 'Hali' : 'Status',
                  value: _statusLabel(status, sw),
                ),

                // Generated invoice history summary
                if (ri.totalIssued > 0) ...[
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.receipt_long_rounded,
                                size: 18, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              sw
                                  ? 'Ankara ${ri.totalIssued} zimetolewa'
                                  : '${ri.totalIssued} invoices generated',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700),
                            ),
                          ],
                        ),
                        if (ri.nextIssueDate != null && ri.isActive) ...[
                          const SizedBox(height: 6),
                          Text(
                            sw
                                ? 'Ankara inayofuata: ${df.format(ri.nextIssueDate!)}'
                                : 'Next invoice: ${df.format(ri.nextIssueDate!)}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.blue.shade600),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          sw
                              ? 'Angalia ankara zote kwenye orodha kuu'
                              : 'View all invoices in the main list',
                          style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: Colors.blue.shade400),
                        ),
                      ],
                    ),
                  ),
                  // TODO: Backend should include unpaid_count in recurring invoice response
                ],

                // Items
                if (ri.items.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    sw ? 'Bidhaa' : 'Items',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                  ),
                  const SizedBox(height: 6),
                  ...ri.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.description,
                            style: const TextStyle(fontSize: 13, color: _kPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          'TZS ${nf.format(item.totalPrice)}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500, color: _kPrimary),
                        ),
                      ],
                    ),
                  )),
                ],

                const SizedBox(height: 18),

                // Edit button
                if (status != 'cancelled')
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showEditSheet(ri);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: Text(
                        sw ? 'Hariri' : 'Edit',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _kSecondary),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(fontSize: 13, color: _kSecondary)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Edit Sheet (pre-filled create sheet)
  // ---------------------------------------------------------------------------

  void _showEditSheet(RecurringInvoice ri) {
    final customerNameCtrl = TextEditingController(text: ri.customerName ?? '');
    // Try to match existing customer by name
    int selectedCustomerId = -1;
    for (final c in _customers) {
      if (c.name == ri.customerName) {
        selectedCustomerId = c.id ?? -1;
        break;
      }
    }
    final nf = NumberFormat('#,###', 'en');
    RecurringFrequency freq = ri.frequency;
    bool isCustomFreq = false;
    final customDaysCtrl = TextEditingController(text: '14');
    bool includeVat = ri.vatAmount > 0;
    const double vatRate = 18.0;
    final items = <_QuickItem>[
      ...ri.items.map((item) => _QuickItem(
            description: item.description,
            unitPrice: item.unitPrice,
            qty: item.quantity,
          )),
    ];
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final sw = _sw;

    DateTime startDate = ri.startDate ?? DateTime.now();
    String endCondition = ri.endDate != null ? 'date' : 'none';
    DateTime? endDate = ri.endDate;

    bool autoSend = false;
    final autoSendChannels = <String>{};

    // TAJIRI search state
    bool showTajiriSearch = false;
    final tajiriSearchCtrl = TextEditingController();
    final tajiriSearchFocus = FocusNode();
    bool tajiriSearching = false;
    List<PersonSearchResult> tajiriUserResults = [];
    List<Business> tajiriBusinessResults = [];
    PersonSearchResult? tajiriSelectedUser;
    Business? tajiriSelectedBusiness;
    List<Business> tajiriUserBusinesses = [];
    bool tajiriLoadingBiz = false;
    Timer? tajiriDebounce;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          double subtotal =
              items.fold(0.0, (s, i) => s + i.unitPrice * i.quantity);
          double vatAmount = includeVat ? subtotal * (vatRate / 100) : 0;
          double total = subtotal + vatAmount;
          final df = DateFormat('dd/MM/yyyy');

          return Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                      sw
                          ? 'Hariri Ankara ya Kujirudia'
                          : 'Edit Recurring Invoice',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _kPrimary)),
                  const SizedBox(height: 14),
                  // Customer picker
                  _sheetSectionLabel(sw ? 'Mteja' : 'Customer'),
                  const SizedBox(height: 6),
                  if (_customers.isNotEmpty && !showTajiriSearch)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: _kBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedCustomerId,
                          hint: Text(sw ? 'Chagua Mteja' : 'Select Customer'),
                          isExpanded: true,
                          items: [
                            DropdownMenuItem<int>(
                                value: -1,
                                child: Text(
                                    sw ? 'Andika jina / Enter name' : 'Enter name manually',
                                    style: const TextStyle(color: _kSecondary))),
                            ..._customers.map((c) => DropdownMenuItem(
                                value: c.id, child: Text(c.name))),
                          ],
                          onChanged: (v) {
                            setSheetState(() {
                              if (v == null || v == -1) {
                                selectedCustomerId = -1;
                                customerNameCtrl.clear();
                              } else {
                                selectedCustomerId = v;
                                final cust = _customers.firstWhere((c) => c.id == v);
                                customerNameCtrl.text = cust.name;
                              }
                            });
                          },
                        ),
                      ),
                    ),
                  if (!showTajiriSearch && (selectedCustomerId == -1 || _customers.isEmpty)) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: customerNameCtrl,
                      decoration: InputDecoration(
                        hintText: sw ? 'Jina la Mteja' : 'Customer Name',
                        filled: true,
                        fillColor: _kBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                  // TAJIRI search
                  _buildTajiriSearchSection(
                    setSheetState: setSheetState,
                    sw: sw,
                    showTajiriSearch: showTajiriSearch,
                    searchCtrl: tajiriSearchCtrl,
                    searchFocusNode: tajiriSearchFocus,
                    searching: tajiriSearching,
                    userResults: tajiriUserResults,
                    businessResults: tajiriBusinessResults,
                    selectedUser: tajiriSelectedUser,
                    selectedBusiness: tajiriSelectedBusiness,
                    userBusinesses: tajiriUserBusinesses,
                    loadingBusinesses: tajiriLoadingBiz,
                    debounceTimer: tajiriDebounce,
                    customerNameCtrl: customerNameCtrl,
                    onToggleTajiri: (v) => setSheetState(() => showTajiriSearch = v),
                    onDebounceChanged: (t) => tajiriDebounce = t,
                    onUserSelected: (u) => setSheetState(() => tajiriSelectedUser = u),
                    onBusinessSelected: (b) => setSheetState(() => tajiriSelectedBusiness = b),
                    onUserBusinessesChanged: (l) => setSheetState(() => tajiriUserBusinesses = l),
                    onLoadingBusinessesChanged: (v) => setSheetState(() => tajiriLoadingBiz = v),
                    onUserResultsChanged: (l) => setSheetState(() => tajiriUserResults = l),
                    onBusinessResultsChanged: (l) => setSheetState(() => tajiriBusinessResults = l),
                    onSearchingChanged: (v) => setSheetState(() => tajiriSearching = v),
                  ),
                  const SizedBox(height: 10),

                  // ---- Frequency picker ----
                  _sheetSectionLabel(sw ? 'Mzunguko' : 'Frequency'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ...RecurringFrequency.values.map((f) => _freqChip(
                            label: recurringFrequencyLabel(f, swahili: sw),
                            selected: !isCustomFreq && freq == f,
                            onTap: () => setSheetState(() {
                              freq = f;
                              isCustomFreq = false;
                            }),
                          )),
                      _freqChip(
                        label: sw ? 'Desturi' : 'Custom',
                        selected: isCustomFreq,
                        onTap: () =>
                            setSheetState(() => isCustomFreq = true),
                      ),
                    ],
                  ),
                  if (isCustomFreq) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(sw ? 'Kila siku' : 'Every',
                            style: const TextStyle(
                                fontSize: 13, color: _kSecondary)),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 64,
                          child: TextField(
                            controller: customDaysCtrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: _kBackground,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(sw ? 'siku' : 'days',
                            style: const TextStyle(
                                fontSize: 13, color: _kSecondary)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),

                  // ---- Start date ----
                  _sheetSectionLabel(sw ? 'Tarehe ya Kuanza' : 'Start Date'),
                  const SizedBox(height: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: startDate,
                        firstDate: DateTime(2020),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365 * 5)),
                      );
                      if (picked != null) {
                        setSheetState(() => startDate = picked);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: _kBackground,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 16, color: _kSecondary),
                          const SizedBox(width: 8),
                          Text(df.format(startDate),
                              style: const TextStyle(
                                  fontSize: 14, color: _kPrimary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ---- End conditions ----
                  _sheetSectionLabel(
                      sw ? 'Masharti ya Mwisho' : 'End Condition'),
                  const SizedBox(height: 6),
                  _endConditionRadio(
                    value: 'none',
                    groupValue: endCondition,
                    label: sw ? 'Bila mwisho' : 'No end date',
                    onChanged: (v) =>
                        setSheetState(() => endCondition = v ?? 'none'),
                  ),
                  _endConditionRadio(
                    value: 'date',
                    groupValue: endCondition,
                    label: sw ? 'Hadi tarehe' : 'Until date',
                    onChanged: (v) =>
                        setSheetState(() => endCondition = v ?? 'none'),
                  ),
                  if (endCondition == 'date') ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 32, bottom: 4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: endDate ??
                                startDate.add(const Duration(days: 365)),
                            firstDate: startDate,
                            lastDate: startDate
                                .add(const Duration(days: 365 * 10)),
                          );
                          if (picked != null) {
                            setSheetState(() => endDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: _kBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  size: 14, color: _kSecondary),
                              const SizedBox(width: 6),
                              Text(
                                endDate != null
                                    ? df.format(endDate!)
                                    : (sw
                                        ? 'Chagua tarehe'
                                        : 'Pick a date'),
                                style: const TextStyle(
                                    fontSize: 13, color: _kPrimary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),

                  // VAT toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(sw ? 'Jumuisha VAT (18%)' : 'Include VAT (18%)',
                          style: const TextStyle(
                              fontSize: 14, color: _kPrimary)),
                      Switch(
                        value: includeVat,
                        onChanged: (v) => setSheetState(() => includeVat = v),
                        activeTrackColor: _kPrimary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ---- Items ----
                  if (items.isNotEmpty)
                    ...items.asMap().entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Expanded(
                                  child: Text(entry.value.description,
                                      style: const TextStyle(
                                          fontSize: 13, color: _kPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis)),
                              Text(
                                  'TZS ${nf.format(entry.value.unitPrice * entry.value.quantity)}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _kPrimary)),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () =>
                                    setSheetState(() => items.removeAt(entry.key)),
                                child: const Icon(Icons.close_rounded,
                                    size: 16, color: _kSecondary),
                              ),
                            ],
                          ),
                        )),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: descCtrl,
                          decoration: InputDecoration(
                            hintText: sw ? 'Bidhaa' : 'Item',
                            filled: true,
                            fillColor: _kBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: sw ? 'Bei' : 'Price',
                            filled: true,
                            fillColor: _kBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_rounded,
                            color: _kPrimary),
                        onPressed: () {
                          final d = descCtrl.text.trim();
                          final p = double.tryParse(
                                  priceCtrl.text.replaceAll(',', '')) ??
                              0;
                          if (d.isNotEmpty && p > 0) {
                            setSheetState(() {
                              items.add(
                                  _QuickItem(description: d, unitPrice: p));
                              descCtrl.clear();
                              priceCtrl.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  if (items.isNotEmpty) ...[
                    const Divider(),
                    if (includeVat) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(sw ? 'Jumla Ndogo' : 'Subtotal',
                              style: const TextStyle(
                                  fontSize: 13, color: _kSecondary)),
                          Text('TZS ${nf.format(subtotal)}',
                              style: const TextStyle(
                                  fontSize: 13, color: _kSecondary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('VAT (18%)',
                              style: TextStyle(
                                  fontSize: 13, color: _kSecondary)),
                          Text('TZS ${nf.format(vatAmount)}',
                              style: const TextStyle(
                                  fontSize: 13, color: _kSecondary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(sw ? 'JUMLA' : 'TOTAL',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _kPrimary)),
                        Text('TZS ${nf.format(total)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _kPrimary)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),

                  // ---- Auto-send toggle ----
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          sw ? 'Tuma moja kwa moja' : 'Auto-send',
                          style: const TextStyle(
                              fontSize: 14, color: _kPrimary)),
                      Switch(
                        value: autoSend,
                        onChanged: (v) => setSheetState(() => autoSend = v),
                        activeTrackColor: _kPrimary,
                      ),
                    ],
                  ),
                  if (autoSend) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        _channelChip(
                          label: 'WhatsApp',
                          icon: Icons.chat_rounded,
                          selected: autoSendChannels.contains('whatsapp'),
                          onTap: () => setSheetState(() {
                            if (!autoSendChannels.remove('whatsapp')) {
                              autoSendChannels.add('whatsapp');
                            }
                          }),
                        ),
                        _channelChip(
                          label: 'Email',
                          icon: Icons.email_rounded,
                          selected: autoSendChannels.contains('email'),
                          onTap: () => setSheetState(() {
                            if (!autoSendChannels.remove('email')) {
                              autoSendChannels.add('email');
                            }
                          }),
                        ),
                        _channelChip(
                          label: sw ? 'Ndani ya App' : 'In-App',
                          icon: Icons.notifications_rounded,
                          selected: autoSendChannels.contains('in_app'),
                          onTap: () => setSheetState(() {
                            if (!autoSendChannels.remove('in_app')) {
                              autoSendChannels.add('in_app');
                            }
                          }),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),

                  // ---- Submit (update) ----
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_token == null || ri.id == null) return;
                        if (customerNameCtrl.text.trim().isEmpty ||
                            items.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(sw
                                  ? 'Jaza jina la mteja na ongeza bidhaa'
                                  : 'Enter customer name and add items')));
                          return;
                        }
                        final messenger = ScaffoldMessenger.of(context);
                        final nav = Navigator.of(ctx);
                        final body = <String, dynamic>{
                          'customer_name': customerNameCtrl.text.trim(),
                          'items': items
                              .map((i) => {
                                    'description': i.description,
                                    'quantity': i.quantity,
                                    'unit_price': i.unitPrice,
                                    'total_price': i.unitPrice * i.quantity,
                                  })
                              .toList(),
                          'subtotal': subtotal,
                          'vat_rate': includeVat ? vatRate : 0,
                          'vat_amount': vatAmount,
                          'total_amount': total,
                          'frequency': isCustomFreq ? 'custom' : freq.name,
                          'start_date': startDate.toIso8601String(),
                        };
                        if (isCustomFreq) {
                          body['custom_interval_days'] =
                              int.tryParse(customDaysCtrl.text) ?? 14;
                        }
                        if (endCondition == 'date' && endDate != null) {
                          body['end_date'] = endDate!.toIso8601String();
                        }
                        if (autoSend) {
                          body['auto_send'] = true;
                          body['auto_send_channels'] =
                              autoSendChannels.toList();
                        }
                        try {
                          final res =
                              await BusinessService.updateRecurringInvoice(
                                  _token!, ri.id!, body);
                          if (mounted) {
                            nav.pop();
                            messenger.showSnackBar(
                                SnackBar(
                                    content: Text(res.message ??
                                        (sw ? 'Imesasishwa' : 'Updated'))));
                            _load();
                          }
                        } catch (e) {
                          if (mounted) {
                            messenger.showSnackBar(
                                SnackBar(
                                    content: Text(sw
                                        ? 'Imeshindikana'
                                        : 'Failed')));
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                          sw ? 'Sasisha Ankara' : 'Update Invoice',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Create Sheet (enhanced)
  // ---------------------------------------------------------------------------

  void _showCreateSheet() {
    final customerNameCtrl = TextEditingController();
    int selectedCustomerId = -1;
    final nf = NumberFormat('#,###', 'en');
    RecurringFrequency freq = RecurringFrequency.monthly;
    bool isCustomFreq = false;
    final customDaysCtrl = TextEditingController(text: '14');
    bool includeVat = true;
    const double vatRate = 18.0;
    final items = <_QuickItem>[];
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final sw = _sw;

    // Start date
    DateTime startDate = DateTime.now();

    // End conditions: 'none', 'date', 'count'
    String endCondition = 'none';
    DateTime? endDate;
    final maxCountCtrl = TextEditingController(text: '12');

    // Auto-send
    bool autoSend = false;
    final autoSendChannels = <String>{}; // 'whatsapp', 'email', 'in_app'

    // TAJIRI search state
    bool showTajiriSearch = false;
    final tajiriSearchCtrl = TextEditingController();
    final tajiriSearchFocus = FocusNode();
    bool tajiriSearching = false;
    List<PersonSearchResult> tajiriUserResults = [];
    List<Business> tajiriBusinessResults = [];
    PersonSearchResult? tajiriSelectedUser;
    Business? tajiriSelectedBusiness;
    List<Business> tajiriUserBusinesses = [];
    bool tajiriLoadingBiz = false;
    Timer? tajiriDebounce;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          double subtotal =
              items.fold(0.0, (s, i) => s + i.unitPrice * i.quantity);
          double vatAmount = includeVat ? subtotal * (vatRate / 100) : 0;
          double total = subtotal + vatAmount;
          final df = DateFormat('dd/MM/yyyy');

          return Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                      sw
                          ? 'Ankara Mpya ya Kujirudia'
                          : 'New Recurring Invoice',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _kPrimary)),
                  const SizedBox(height: 14),
                  // Customer picker
                  _sheetSectionLabel(sw ? 'Mteja' : 'Customer'),
                  const SizedBox(height: 6),
                  if (_customers.isNotEmpty && !showTajiriSearch)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: _kBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedCustomerId,
                          hint: Text(sw ? 'Chagua Mteja' : 'Select Customer'),
                          isExpanded: true,
                          items: [
                            DropdownMenuItem<int>(
                                value: -1,
                                child: Text(
                                    sw ? 'Andika jina / Enter name' : 'Enter name manually',
                                    style: const TextStyle(color: _kSecondary))),
                            ..._customers.map((c) => DropdownMenuItem(
                                value: c.id, child: Text(c.name))),
                          ],
                          onChanged: (v) {
                            setSheetState(() {
                              if (v == null || v == -1) {
                                selectedCustomerId = -1;
                                customerNameCtrl.clear();
                              } else {
                                selectedCustomerId = v;
                                final cust = _customers.firstWhere((c) => c.id == v);
                                customerNameCtrl.text = cust.name;
                              }
                            });
                          },
                        ),
                      ),
                    ),
                  if (!showTajiriSearch && (selectedCustomerId == -1 || _customers.isEmpty)) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: customerNameCtrl,
                      decoration: InputDecoration(
                        hintText: sw ? 'Jina la Mteja' : 'Customer Name',
                        filled: true,
                        fillColor: _kBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                  // TAJIRI search
                  _buildTajiriSearchSection(
                    setSheetState: setSheetState,
                    sw: sw,
                    showTajiriSearch: showTajiriSearch,
                    searchCtrl: tajiriSearchCtrl,
                    searchFocusNode: tajiriSearchFocus,
                    searching: tajiriSearching,
                    userResults: tajiriUserResults,
                    businessResults: tajiriBusinessResults,
                    selectedUser: tajiriSelectedUser,
                    selectedBusiness: tajiriSelectedBusiness,
                    userBusinesses: tajiriUserBusinesses,
                    loadingBusinesses: tajiriLoadingBiz,
                    debounceTimer: tajiriDebounce,
                    customerNameCtrl: customerNameCtrl,
                    onToggleTajiri: (v) => setSheetState(() => showTajiriSearch = v),
                    onDebounceChanged: (t) => tajiriDebounce = t,
                    onUserSelected: (u) => setSheetState(() => tajiriSelectedUser = u),
                    onBusinessSelected: (b) => setSheetState(() => tajiriSelectedBusiness = b),
                    onUserBusinessesChanged: (l) => setSheetState(() => tajiriUserBusinesses = l),
                    onLoadingBusinessesChanged: (v) => setSheetState(() => tajiriLoadingBiz = v),
                    onUserResultsChanged: (l) => setSheetState(() => tajiriUserResults = l),
                    onBusinessResultsChanged: (l) => setSheetState(() => tajiriBusinessResults = l),
                    onSearchingChanged: (v) => setSheetState(() => tajiriSearching = v),
                  ),
                  const SizedBox(height: 10),

                  // ---- Frequency picker ----
                  _sheetSectionLabel(sw ? 'Mzunguko' : 'Frequency'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ...RecurringFrequency.values.map((f) => _freqChip(
                            label: recurringFrequencyLabel(f, swahili: sw),
                            selected: !isCustomFreq && freq == f,
                            onTap: () => setSheetState(() {
                              freq = f;
                              isCustomFreq = false;
                            }),
                          )),
                      _freqChip(
                        label: sw ? 'Desturi' : 'Custom',
                        selected: isCustomFreq,
                        onTap: () =>
                            setSheetState(() => isCustomFreq = true),
                      ),
                    ],
                  ),
                  if (isCustomFreq) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(sw ? 'Kila siku' : 'Every',
                            style: const TextStyle(
                                fontSize: 13, color: _kSecondary)),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 64,
                          child: TextField(
                            controller: customDaysCtrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: _kBackground,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(sw ? 'siku' : 'days',
                            style: const TextStyle(
                                fontSize: 13, color: _kSecondary)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),

                  // ---- Start date ----
                  _sheetSectionLabel(sw ? 'Tarehe ya Kuanza' : 'Start Date'),
                  const SizedBox(height: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: startDate,
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365 * 5)),
                      );
                      if (picked != null) {
                        setSheetState(() => startDate = picked);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: _kBackground,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 16, color: _kSecondary),
                          const SizedBox(width: 8),
                          Text(df.format(startDate),
                              style: const TextStyle(
                                  fontSize: 14, color: _kPrimary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ---- End conditions ----
                  _sheetSectionLabel(
                      sw ? 'Masharti ya Mwisho' : 'End Condition'),
                  const SizedBox(height: 6),
                  _endConditionRadio(
                    value: 'none',
                    groupValue: endCondition,
                    label: sw ? 'Bila mwisho' : 'No end date',
                    onChanged: (v) =>
                        setSheetState(() => endCondition = v ?? 'none'),
                  ),
                  _endConditionRadio(
                    value: 'date',
                    groupValue: endCondition,
                    label: sw ? 'Hadi tarehe' : 'Until date',
                    onChanged: (v) =>
                        setSheetState(() => endCondition = v ?? 'none'),
                  ),
                  if (endCondition == 'date') ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 32, bottom: 4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: endDate ??
                                startDate.add(const Duration(days: 365)),
                            firstDate: startDate,
                            lastDate: startDate
                                .add(const Duration(days: 365 * 10)),
                          );
                          if (picked != null) {
                            setSheetState(() => endDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: _kBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  size: 14, color: _kSecondary),
                              const SizedBox(width: 6),
                              Text(
                                endDate != null
                                    ? df.format(endDate!)
                                    : (sw
                                        ? 'Chagua tarehe'
                                        : 'Pick a date'),
                                style: const TextStyle(
                                    fontSize: 13, color: _kPrimary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  _endConditionRadio(
                    value: 'count',
                    groupValue: endCondition,
                    label: sw ? 'Ankara kadhaa tu' : 'Only X invoices',
                    onChanged: (v) =>
                        setSheetState(() => endCondition = v ?? 'none'),
                  ),
                  if (endCondition == 'count') ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 32, bottom: 4),
                      child: Row(
                        children: [
                          Text(sw ? 'Ankara' : 'Invoices',
                              style: const TextStyle(
                                  fontSize: 13, color: _kSecondary)),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 64,
                            child: TextField(
                              controller: maxCountCtrl,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: _kBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(sw ? 'tu' : 'total',
                              style: const TextStyle(
                                  fontSize: 13, color: _kSecondary)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),

                  // VAT toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(sw ? 'Jumuisha VAT (18%)' : 'Include VAT (18%)',
                          style: const TextStyle(
                              fontSize: 14, color: _kPrimary)),
                      Switch(
                        value: includeVat,
                        onChanged: (v) => setSheetState(() => includeVat = v),
                        activeTrackColor: _kPrimary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ---- Items ----
                  if (items.isNotEmpty)
                    ...items.asMap().entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Expanded(
                                  child: Text(entry.value.description,
                                      style: const TextStyle(
                                          fontSize: 13, color: _kPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis)),
                              Text(
                                  'TZS ${nf.format(entry.value.unitPrice * entry.value.quantity)}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _kPrimary)),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () =>
                                    setSheetState(() => items.removeAt(entry.key)),
                                child: const Icon(Icons.close_rounded,
                                    size: 16, color: _kSecondary),
                              ),
                            ],
                          ),
                        )),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: descCtrl,
                          decoration: InputDecoration(
                            hintText: sw ? 'Bidhaa' : 'Item',
                            filled: true,
                            fillColor: _kBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: sw ? 'Bei' : 'Price',
                            filled: true,
                            fillColor: _kBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_rounded,
                            color: _kPrimary),
                        onPressed: () {
                          final d = descCtrl.text.trim();
                          final p = double.tryParse(
                                  priceCtrl.text.replaceAll(',', '')) ??
                              0;
                          if (d.isNotEmpty && p > 0) {
                            setSheetState(() {
                              items.add(
                                  _QuickItem(description: d, unitPrice: p));
                              descCtrl.clear();
                              priceCtrl.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  if (items.isNotEmpty) ...[
                    const Divider(),
                    if (includeVat) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(sw ? 'Jumla Ndogo' : 'Subtotal',
                              style: const TextStyle(
                                  fontSize: 13, color: _kSecondary)),
                          Text('TZS ${nf.format(subtotal)}',
                              style: const TextStyle(
                                  fontSize: 13, color: _kSecondary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('VAT (18%)',
                              style: TextStyle(
                                  fontSize: 13, color: _kSecondary)),
                          Text('TZS ${nf.format(vatAmount)}',
                              style: const TextStyle(
                                  fontSize: 13, color: _kSecondary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(sw ? 'JUMLA' : 'TOTAL',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _kPrimary)),
                        Text('TZS ${nf.format(total)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _kPrimary)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),

                  // ---- Auto-send toggle ----
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          sw
                              ? 'Tuma moja kwa moja'
                              : 'Auto-send',
                          style: const TextStyle(
                              fontSize: 14, color: _kPrimary)),
                      Switch(
                        value: autoSend,
                        onChanged: (v) => setSheetState(() => autoSend = v),
                        activeTrackColor: _kPrimary,
                      ),
                    ],
                  ),
                  if (autoSend) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        _channelChip(
                          label: 'WhatsApp',
                          icon: Icons.chat_rounded,
                          selected: autoSendChannels.contains('whatsapp'),
                          onTap: () => setSheetState(() {
                            if (!autoSendChannels.remove('whatsapp')) {
                              autoSendChannels.add('whatsapp');
                            }
                          }),
                        ),
                        _channelChip(
                          label: 'Email',
                          icon: Icons.email_rounded,
                          selected: autoSendChannels.contains('email'),
                          onTap: () => setSheetState(() {
                            if (!autoSendChannels.remove('email')) {
                              autoSendChannels.add('email');
                            }
                          }),
                        ),
                        _channelChip(
                          label: sw ? 'Ndani ya App' : 'In-App',
                          icon: Icons.notifications_rounded,
                          selected: autoSendChannels.contains('in_app'),
                          onTap: () => setSheetState(() {
                            if (!autoSendChannels.remove('in_app')) {
                              autoSendChannels.add('in_app');
                            }
                          }),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),

                  // ---- Submit ----
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_token == null) return;
                        if (customerNameCtrl.text.trim().isEmpty ||
                            items.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(sw
                                  ? 'Jaza jina la mteja na ongeza bidhaa'
                                  : 'Enter customer name and add items')));
                          return;
                        }
                        final messenger = ScaffoldMessenger.of(context);
                        final nav = Navigator.of(ctx);
                        final body = <String, dynamic>{
                          'user_business_id': widget.businessId,
                          'customer_name': customerNameCtrl.text.trim(),
                          'items': items
                              .map((i) => {
                                    'description': i.description,
                                    'quantity': i.quantity,
                                    'unit_price': i.unitPrice,
                                    'total_price': i.unitPrice * i.quantity,
                                  })
                              .toList(),
                          'subtotal': subtotal,
                          'vat_rate': includeVat ? vatRate : 0,
                          'vat_amount': vatAmount,
                          'total_amount': total,
                          'frequency': isCustomFreq ? 'custom' : freq.name,
                          'start_date': startDate.toIso8601String(),
                          'next_issue_date': startDate.toIso8601String(),
                        };
                        if (isCustomFreq) {
                          body['custom_interval_days'] =
                              int.tryParse(customDaysCtrl.text) ?? 14;
                        }
                        if (endCondition == 'date' && endDate != null) {
                          body['end_date'] = endDate!.toIso8601String();
                        } else if (endCondition == 'count') {
                          body['max_invoices'] =
                              int.tryParse(maxCountCtrl.text) ?? 12;
                        }
                        if (autoSend) {
                          body['auto_send'] = true;
                          body['auto_send_channels'] =
                              autoSendChannels.toList();
                        }
                        try {
                          final res =
                              await BusinessService.createRecurringInvoice(
                                  _token!, widget.businessId, body);
                          if (mounted) {
                            nav.pop();
                            messenger.showSnackBar(
                                SnackBar(
                                    content: Text(res.message ??
                                        (sw ? 'Imeundwa' : 'Created'))));
                            _load();
                          }
                        } catch (e) {
                          if (mounted) {
                            messenger.showSnackBar(
                                SnackBar(
                                    content: Text(sw
                                        ? 'Imeshindikana'
                                        : 'Failed')));
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                          sw ? 'Unda Ankara' : 'Create Invoice',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat('#,###', 'en');
    final df = DateFormat('dd/MM/yyyy');
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
              : _invoices.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.repeat_rounded,
                                size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                                sw
                                    ? 'Huna ankara za kujirudia'
                                    : 'No recurring invoices',
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 15)),
                            const SizedBox(height: 4),
                            Text(
                              sw
                                  ? 'Zinafaa kwa wateja wanaolipa kila mwezi!'
                                  : 'Great for customers who pay monthly!',
                              style: TextStyle(
                                  color: Colors.grey.shade400, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            _topPillActionButton(
                              label: sw ? 'Ankara Mpya' : 'New Recurring',
                              icon: Icons.add_rounded,
                              onTap: _showCreateSheet,
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: _kPrimary,
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Row(
                            children: [
                              const Spacer(),
                              _topPillActionButton(
                                label: sw ? 'Ankara Mpya' : 'New Recurring',
                                icon: Icons.add_rounded,
                                onTap: _showCreateSheet,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(_invoices.length, (i) {
                            final ri = _invoices[i];
                            return _buildInvoiceCard(ri, nf, df, sw);
                          }),
                        ],
                      ),
                    ),
    );
  }

  // ---------------------------------------------------------------------------
  // Invoice card (enhanced)
  // ---------------------------------------------------------------------------

  Widget _buildInvoiceCard(
      RecurringInvoice ri, NumberFormat nf, DateFormat df, bool sw) {
    final status = _invoiceStatus(ri);
    final dotColor = _statusDotColor(status);
    final label = _statusLabel(status, sw);

    return GestureDetector(
      onTap: () => _showDetailSheet(ri),
      child: Container(
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
          // Top row: icon + name/freq + amount/status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: status == 'active'
                      ? Colors.green.shade50
                      : status == 'paused'
                          ? Colors.amber.shade50
                          : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.repeat_rounded,
                    size: 18,
                    color: status == 'active'
                        ? Colors.green.shade700
                        : status == 'paused'
                            ? Colors.amber.shade700
                            : _kSecondary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        ri.customerName ?? (sw ? 'Mteja' : 'Customer'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _kPrimary,
                            fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(
                      recurringFrequencyLabel(ri.frequency, swahili: sw),
                      style: const TextStyle(
                          fontSize: 12, color: _kSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('TZS ${nf.format(ri.totalAmount)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _kPrimary,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: dotColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Info row: next date + total issued
          Row(
            children: [
              if (ri.nextIssueDate != null && ri.isActive) ...[
                const Icon(Icons.schedule_rounded,
                    size: 14, color: _kSecondary),
                const SizedBox(width: 4),
                Text(
                    '${sw ? 'Inayofuata' : 'Next'}: ${df.format(ri.nextIssueDate!)}',
                    style:
                        const TextStyle(fontSize: 11, color: _kSecondary)),
              ],
              const Spacer(),
              Icon(Icons.receipt_long_rounded,
                  size: 14, color: _kSecondary),
              const SizedBox(width: 4),
              Text(
                sw
                    ? 'Ankara ${ri.totalIssued} zimetolewa'
                    : '${ri.totalIssued} invoices generated',
                style: const TextStyle(fontSize: 11, color: _kSecondary),
              ),
            ],
          ),

          // Payment check nudge for active templates with generated invoices
          if (ri.totalIssued > 0 && ri.isActive) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 14, color: Colors.amber.shade800),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      sw
                          ? 'Angalia malipo ya ankara zilizotolewa'
                          : 'Check payments on generated invoices',
                      style: TextStyle(
                          fontSize: 10, color: Colors.amber.shade800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // End date info
          if (ri.endDate != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.event_rounded,
                    size: 14, color: _kSecondary),
                const SizedBox(width: 4),
                Text(
                    '${sw ? 'Inaisha' : 'Ends'}: ${df.format(ri.endDate!)}',
                    style:
                        const TextStyle(fontSize: 11, color: _kSecondary)),
              ],
            ),
          ],

          // Action buttons
          if (status != 'cancelled') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                // Pause / Resume button
                SizedBox(
                  height: 34,
                  child: OutlinedButton.icon(
                    onPressed: () => _togglePauseResume(ri),
                    icon: Icon(
                      ri.isActive
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 16,
                    ),
                    label: Text(
                      ri.isActive
                          ? (sw ? 'Simamisha' : 'Pause')
                          : (sw ? 'Endelea' : 'Resume'),
                      style: const TextStyle(fontSize: 11),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          ri.isActive ? Colors.amber.shade800 : Colors.green,
                      side: BorderSide(
                        color: ri.isActive
                            ? Colors.amber.shade800
                            : Colors.green,
                        width: 0.5,
                      ),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Cancel button
                SizedBox(
                  height: 34,
                  child: OutlinedButton.icon(
                    onPressed: () => _cancelRecurring(ri),
                    icon: const Icon(Icons.cancel_rounded, size: 16),
                    label: Text(
                      sw ? 'Sitisha' : 'Cancel',
                      style: const TextStyle(fontSize: 11),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(
                          color: Colors.red, width: 0.5),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAJIRI Search Helper (for use inside StatefulBuilder sheets)
  // ---------------------------------------------------------------------------

  Widget _buildTajiriSearchSection({
    required StateSetter setSheetState,
    required bool sw,
    required bool showTajiriSearch,
    required TextEditingController searchCtrl,
    required FocusNode searchFocusNode,
    required bool searching,
    required List<PersonSearchResult> userResults,
    required List<Business> businessResults,
    required PersonSearchResult? selectedUser,
    required Business? selectedBusiness,
    required List<Business> userBusinesses,
    required bool loadingBusinesses,
    required Timer? debounceTimer,
    required TextEditingController customerNameCtrl,
    required ValueChanged<bool> onToggleTajiri,
    required ValueChanged<Timer?> onDebounceChanged,
    required ValueChanged<PersonSearchResult?> onUserSelected,
    required ValueChanged<Business?> onBusinessSelected,
    required ValueChanged<List<Business>> onUserBusinessesChanged,
    required ValueChanged<bool> onLoadingBusinessesChanged,
    required ValueChanged<List<PersonSearchResult>> onUserResultsChanged,
    required ValueChanged<List<Business>> onBusinessResultsChanged,
    required ValueChanged<bool> onSearchingChanged,
  }) {
    if (!showTajiriSearch) {
      return TextButton.icon(
        onPressed: () => onToggleTajiri(true),
        icon: const Icon(Icons.search_rounded, size: 16),
        label: Text(
          sw ? 'Tafuta kwenye TAJIRI' : 'Search on TAJIRI',
          style: const TextStyle(fontSize: 12),
        ),
        style: TextButton.styleFrom(foregroundColor: _kPrimary),
      );
    }

    // Selected state
    if (selectedUser != null || selectedBusiness != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFF2F2F2),
                  child: Icon(Icons.person_rounded, size: 18, color: _kSecondary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerNameCtrl.text.isNotEmpty
                            ? customerNameCtrl.text
                            : (selectedBusiness?.name ?? selectedUser?.fullName ?? ''),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, color: _kPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setSheetState(() {
                      onUserSelected(null);
                      onBusinessSelected(null);
                      onUserBusinessesChanged([]);
                      searchCtrl.clear();
                      onUserResultsChanged([]);
                      onBusinessResultsChanged([]);
                      customerNameCtrl.clear();
                    });
                  },
                  child: Text(sw ? 'Badilisha' : 'Change',
                      style: const TextStyle(
                          color: _kPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ],
            ),
          ),
          if (userBusinesses.isNotEmpty && selectedBusiness == null) ...[
            const SizedBox(height: 10),
            Text(sw ? 'Chagua biashara' : 'Select business',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: null,
                  hint: Text(sw ? 'Biashara ya mteja' : 'Customer business'),
                  isExpanded: true,
                  items: userBusinesses
                      .where((b) => b.id != null)
                      .map((b) => DropdownMenuItem<int>(
                            value: b.id,
                            child: Text(b.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (id) {
                    if (id == null) return;
                    final b = userBusinesses.firstWhere((e) => e.id == id,
                        orElse: () => userBusinesses.first);
                    setSheetState(() {
                      onBusinessSelected(b);
                      customerNameCtrl.text = b.name;
                    });
                  },
                ),
              ),
            ),
          ],
          if (loadingBusinesses)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: LinearProgressIndicator(color: _kPrimary, minHeight: 2),
            ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () {
              setSheetState(() {
                onToggleTajiri(false);
                onUserSelected(null);
                onBusinessSelected(null);
                onUserBusinessesChanged([]);
                searchCtrl.clear();
                onUserResultsChanged([]);
                onBusinessResultsChanged([]);
                customerNameCtrl.clear();
              });
            },
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: Text(sw ? 'Rudi kwenye orodha' : 'Back to customer list',
                style: const TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(foregroundColor: _kSecondary),
          ),
        ],
      );
    }

    // Search field
    final showSuggestions = searchFocusNode.hasFocus &&
        searchCtrl.text.trim().length >= 2 &&
        (searching || userResults.isNotEmpty || businessResults.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: searchFocusNode.hasFocus
                  ? _kPrimary.withValues(alpha: 0.45)
                  : Colors.grey.shade200,
            ),
          ),
          child: Column(
            children: [
              TextField(
                controller: searchCtrl,
                focusNode: searchFocusNode,
                decoration: InputDecoration(
                  hintText: sw
                      ? 'Tafuta jina, @handle, au biashara'
                      : 'Search name, @handle, or business',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: _kSecondary),
                  suffixIcon: searching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
                          ),
                        )
                      : (searchCtrl.text.trim().isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                setSheetState(() {
                                  searchCtrl.clear();
                                  onUserResultsChanged([]);
                                  onBusinessResultsChanged([]);
                                });
                              },
                            )
                          : null),
                ),
                onChanged: (value) {
                  debounceTimer?.cancel();
                  final q = value.trim();
                  if (q.length < 2) {
                    setSheetState(() {
                      onSearchingChanged(false);
                      onUserResultsChanged([]);
                      onBusinessResultsChanged([]);
                    });
                    return;
                  }
                  final timer = Timer(const Duration(milliseconds: 320), () async {
                    if (_token == null || _currentUserId == null) return;
                    setSheetState(() => onSearchingChanged(true));
                    try {
                      final results = await Future.wait([
                        _peopleSearch.search(userId: _currentUserId!, query: q, perPage: 20),
                        BusinessService.searchBusinesses(_token!, q),
                      ]);
                      final peopleResult = results[0] as PeopleSearchResult;
                      final bizResult = results[1] as BusinessListResult<Business>;
                      setSheetState(() {
                        onSearchingChanged(false);
                        onUserResultsChanged(peopleResult.response?.people ?? []);
                        onBusinessResultsChanged(bizResult.success ? bizResult.data : []);
                      });
                    } catch (_) {
                      setSheetState(() => onSearchingChanged(false));
                    }
                  });
                  onDebounceChanged(timer);
                },
              ),
              if (showSuggestions)
                Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade100)),
                  ),
                  child: (userResults.isEmpty && businessResults.isEmpty && !searching)
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Text(
                              sw ? 'Hakuna matokeo.' : 'No results found.',
                              style: const TextStyle(color: _kSecondary, fontSize: 12),
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          shrinkWrap: true,
                          children: [
                            if (userResults.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
                                child: Text(sw ? 'Watumiaji' : 'Users',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: _kSecondary,
                                        fontWeight: FontWeight.w700)),
                              ),
                              ...userResults.take(6).map((u) => ListTile(
                                    dense: true,
                                    visualDensity: const VisualDensity(vertical: -2),
                                    leading: const CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Color(0xFFF2F2F2),
                                      child: Icon(Icons.person_rounded, size: 14, color: _kSecondary),
                                    ),
                                    title: Text(
                                      u.fullName.isEmpty ? (u.username ?? '-') : u.fullName,
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      u.username != null ? '@${u.username}' : '',
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                    ),
                                    onTap: () async {
                                      searchCtrl.text = u.fullName.isNotEmpty ? u.fullName : '@${u.username ?? ''}';
                                      searchFocusNode.unfocus();
                                      setSheetState(() {
                                        onUserSelected(u);
                                        onBusinessSelected(null);
                                        onUserBusinessesChanged([]);
                                        onLoadingBusinessesChanged(true);
                                      });
                                      if (_token != null) {
                                        final businesses = await BusinessService.getMyBusinesses(_token!, u.id);
                                        setSheetState(() {
                                          onLoadingBusinessesChanged(false);
                                          onUserBusinessesChanged(businesses.success ? businesses.data : []);
                                        });
                                      }
                                    },
                                  )),
                            ],
                            if (businessResults.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
                                child: Text(sw ? 'Biashara' : 'Businesses',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: _kSecondary,
                                        fontWeight: FontWeight.w700)),
                              ),
                              ...businessResults.take(6).map((b) => ListTile(
                                    dense: true,
                                    visualDensity: const VisualDensity(vertical: -2),
                                    leading: const CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Color(0xFFF2F2F2),
                                      child: Icon(Icons.store_rounded, size: 14, color: _kSecondary),
                                    ),
                                    title: Text(b.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    subtitle: Text(
                                      b.ownerHandle ?? b.handleDisplay ?? (b.handle != null ? '@${b.handle}' : (b.ownerName ?? b.sector ?? '')),
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                    ),
                                    onTap: () async {
                                      searchCtrl.text = b.name;
                                      searchFocusNode.unfocus();
                                      if (b.userId != null) {
                                        final pseudoUser = PersonSearchResult(
                                          id: b.userId!,
                                          firstName: '',
                                          lastName: '',
                                          username: null,
                                          friendsCount: 0,
                                          postsCount: 0,
                                          photosCount: 0,
                                          mutualFriendsCount: 0,
                                          friendshipStatus: 'none',
                                          inCommon: const [],
                                          isOnline: false,
                                        );
                                        setSheetState(() => onUserSelected(pseudoUser));
                                      }
                                      setSheetState(() {
                                        onBusinessSelected(b);
                                        customerNameCtrl.text = b.name;
                                      });
                                    },
                                  )),
                            ],
                          ],
                        ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: () {
            setSheetState(() {
              onToggleTajiri(false);
              onUserSelected(null);
              onBusinessSelected(null);
              onUserBusinessesChanged([]);
              searchCtrl.clear();
              onUserResultsChanged([]);
              onBusinessResultsChanged([]);
              customerNameCtrl.clear();
            });
          },
          icon: const Icon(Icons.arrow_back_rounded, size: 16),
          label: Text(sw ? 'Rudi kwenye orodha' : 'Back to customer list',
              style: const TextStyle(fontSize: 12)),
          style: TextButton.styleFrom(foregroundColor: _kSecondary),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Shared widgets
  // ---------------------------------------------------------------------------

  Widget _topPillActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 34,
      child: Material(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetSectionLabel(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary));
  }

  Widget _freqChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _kPrimary : _kBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? _kPrimary : Colors.grey.shade300, width: 0.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? Colors.white : _kSecondary,
          ),
        ),
      ),
    );
  }

  Widget _endConditionRadio({
    required String value,
    required String groupValue,
    required String label,
    required ValueChanged<String?> onChanged,
  }) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: SizedBox(
        height: 36,
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? _kPrimary : _kSecondary,
                  width: selected ? 2 : 1.5,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: _kPrimary,
                        ),
                      ),
                    )
                  : null,
            ),
            Text(label,
                style: const TextStyle(fontSize: 13, color: _kPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _channelChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _kPrimary : _kBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? _kPrimary : Colors.grey.shade300, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14, color: selected ? Colors.white : _kSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? Colors.white : _kSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickItem {
  final String description;
  final double unitPrice;
  final double quantity;
  _QuickItem(
      {required this.description, this.unitPrice = 0, double? qty})
      : quantity = qty ?? 1;
}
