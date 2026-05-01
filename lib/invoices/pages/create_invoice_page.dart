// lib/business/pages/create_invoice_page.dart
// Invoice creation with TAJIRI user/business search, line items, per-item VAT,
// discount, payment terms, and quote conversion.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import '../../models/people_search_models.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../services/people_search_service.dart';
import '../../business/models/business_models.dart';
import '../../business/services/business_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

const List<String> _kUnitLabels = ['pcs', 'hrs', 'kg', 'm²', 'liters'];

class CreateInvoicePage extends StatefulWidget {
  final int businessId;
  final Invoice? editInvoice;
  final Quote? sourceQuote;
  final int? sourceRfqResponseId;
  const CreateInvoicePage({
    super.key,
    required this.businessId,
    this.editInvoice,
    this.sourceQuote,
    this.sourceRfqResponseId,
  });

  @override
  State<CreateInvoicePage> createState() => _CreateInvoicePageState();
}

class _CreateInvoicePageState extends State<CreateInvoicePage> {
  String? _token;
  int? _currentUserId;
  bool _saving = false;
  bool _loading = true;
  String? _businessName;

  // Customer selection (existing)
  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  final _customerNameCtrl = TextEditingController();
  String? _customerPhone;
  String? _customerEmail;
  String? _customerTin;

  // TAJIRI search
  bool _showTajiriSearch = false;
  final _targetSearchCtrl = TextEditingController();
  final _targetSearchFocusNode = FocusNode();
  bool _searchingTargets = false;
  List<PersonSearchResult> _targetUsers = [];
  List<Business> _targetBusinessMatches = [];
  PersonSearchResult? _selectedTargetUser;
  Business? _selectedTargetBusiness;
  List<Business> _selectedUserBusinesses = [];
  bool _loadingBusinesses = false;
  Timer? _targetSearchDebounce;
  final _peopleSearch = PeopleSearchService();

  // Line items
  final List<_LineItem> _items = [];

  // Discount
  bool _showDiscount = false;
  String _discountType = 'percentage'; // percentage | fixed
  final _discountValueCtrl = TextEditingController();

  // Payment
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  final _paymentTermsCtrl = TextEditingController();
  final _paymentInstructionsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // Recurring
  bool _setAsRecurring = false;
  String _recurringFreq = 'monthly'; // weekly, monthly, quarterly, yearly
  DateTime _recurringStartDate = DateTime.now();
  String _recurringEndCondition = 'none'; // none, date, count
  DateTime? _recurringEndDate;
  final _recurringMaxCountCtrl = TextEditingController();

  static const double _vatRate = 18.0;

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;
  bool get _isEditing => widget.editInvoice != null;

  @override
  void initState() {
    super.initState();
    _targetSearchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _init();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    _currentUserId = storage.getUser()?.userId;
    if (_token != null && _currentUserId != null) {
      try {
        final customersFuture =
            BusinessService.getCustomers(_token!, widget.businessId);
        final businessesFuture =
            BusinessService.getMyBusinesses(_token!, _currentUserId!);
        final results =
            await Future.wait([customersFuture, businessesFuture]);
        final customersRes =
            results[0] as BusinessListResult<Customer>;
        final bizRes = results[1] as BusinessListResult<Business>;
        if (mounted) {
          final match = bizRes.success
              ? bizRes.data
                  .where((b) => b.id == widget.businessId)
                  .toList()
              : <Business>[];
          setState(() {
            _loading = false;
            if (customersRes.success) _customers = customersRes.data;
            if (match.isNotEmpty) _businessName = match.first.name;
          });
        }
        // Auto-populate payment instructions from invoice settings
        if (!_isEditing && widget.sourceQuote == null) {
          try {
            final settingsRes = await BusinessService.getInvoiceSettings(
                _token!, widget.businessId);
            if (mounted && settingsRes.success && settingsRes.data != null) {
              final settings = settingsRes.data!;
              if (_paymentInstructionsCtrl.text.isEmpty &&
                  settings.defaultPaymentInstructions != null &&
                  settings.defaultPaymentInstructions!.isNotEmpty) {
                _paymentInstructionsCtrl.text =
                    settings.defaultPaymentInstructions!;
              }
              if (_notesCtrl.text.isEmpty &&
                  settings.defaultNotes != null &&
                  settings.defaultNotes!.isNotEmpty) {
                _notesCtrl.text = settings.defaultNotes!;
              }
            }
          } catch (_) {
            // Settings load failure is non-critical
          }
        }
      } catch (_) {
        if (mounted) setState(() => _loading = false);
      }
    } else {
      if (mounted) setState(() => _loading = false);
    }
    _prefillFromEdit();
    _prefillFromQuote();
  }

  void _prefillFromEdit() {
    final inv = widget.editInvoice;
    if (inv == null) return;
    _customerNameCtrl.text = inv.customerName ?? '';
    _customerPhone = inv.customerPhone;
    _customerEmail = inv.customerEmail;
    _customerTin = inv.customerTin;
    if (inv.customerId != null) {
      final match = _customers.where((c) => c.id == inv.customerId);
      if (match.isNotEmpty) _selectedCustomer = match.first;
    }
    for (final item in inv.items) {
      _items.add(_LineItem(
        description: item.description,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        unitLabel: item.unitLabel ?? 'pcs',
        vatApplicable: !item.isVatExempt,
      ));
    }
    if (inv.discountType != null && inv.discountValue > 0) {
      _showDiscount = true;
      _discountType = inv.discountType!;
      _discountValueCtrl.text = inv.discountValue.toStringAsFixed(
          inv.discountType == 'percentage' ? 0 : 0);
    }
    if (inv.dueDate != null) _dueDate = inv.dueDate!;
    _paymentTermsCtrl.text = inv.paymentTerms ?? '';
    _paymentInstructionsCtrl.text = inv.paymentInstructions ?? '';
    _notesCtrl.text = inv.notes ?? '';
  }

  void _prefillFromQuote() {
    final quote = widget.sourceQuote;
    if (quote == null) return;
    if (_customerNameCtrl.text.isEmpty) {
      _customerNameCtrl.text = quote.customerName ?? '';
    }
    if (_items.isEmpty) {
      for (final item in quote.items) {
        _items.add(_LineItem(
          description: item.description,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          unitLabel: item.unitLabel ?? 'pcs',
          vatApplicable: !item.isVatExempt,
        ));
      }
    }
    if (_notesCtrl.text.isEmpty && quote.notes != null) {
      _notesCtrl.text = quote.notes!;
    }
  }

  // ---------------------------------------------------------------------------
  // Calculations
  // ---------------------------------------------------------------------------
  double get _subtotal =>
      _items.fold(0.0, (sum, item) => sum + item.total);

  double get _discountValue =>
      double.tryParse(_discountValueCtrl.text.replaceAll(',', '')) ?? 0;

  double get _discountAmount {
    if (!_showDiscount || _discountValue <= 0) return 0;
    if (_discountType == 'percentage') {
      return _subtotal * (_discountValue / 100);
    }
    return _discountValue;
  }

  double get _vatableSubtotal {
    final afterDiscount = _subtotal - _discountAmount;
    if (afterDiscount <= 0) return 0;
    final vatableItemsTotal = _items
        .where((i) => i.vatApplicable)
        .fold(0.0, (sum, i) => sum + i.total);
    if (_subtotal <= 0) return 0;
    // Pro-rate discount across vatable items
    final ratio = vatableItemsTotal / _subtotal;
    return afterDiscount * ratio;
  }

  double get _vatAmount => _vatableSubtotal * (_vatRate / 100);

  double get _totalAmount => _subtotal - _discountAmount + _vatAmount;

  // ---------------------------------------------------------------------------
  // TAJIRI search
  // ---------------------------------------------------------------------------
  bool get _showTargetSuggestions {
    if (!_targetSearchFocusNode.hasFocus) return false;
    final q = _targetSearchCtrl.text.trim();
    if (q.length < 2) return false;
    return _searchingTargets ||
        _targetUsers.isNotEmpty ||
        _targetBusinessMatches.isNotEmpty;
  }

  void _onTargetQueryChanged(String value) {
    _targetSearchDebounce?.cancel();
    final q = value.trim();
    if (q.length < 2) {
      setState(() {
        _searchingTargets = false;
        _targetUsers = [];
        _targetBusinessMatches = [];
      });
      return;
    }
    _targetSearchDebounce = Timer(const Duration(milliseconds: 320), () {
      _searchRequestTargets();
    });
  }

  Future<void> _searchRequestTargets() async {
    if (_token == null || _currentUserId == null) return;
    final query = _targetSearchCtrl.text.trim();
    if (query.length < 2) return;
    setState(() {
      _searchingTargets = true;
      _targetUsers = [];
      _targetBusinessMatches = [];
    });
    try {
      final peopleFuture = _peopleSearch.search(
        userId: _currentUserId!,
        query: query,
        perPage: 20,
      );
      final businessesFuture =
          BusinessService.searchBusinesses(_token!, query);
      final results = await Future.wait([peopleFuture, businessesFuture]);
      final peopleResult = results[0] as PeopleSearchResult;
      final businessResult = results[1] as BusinessListResult<Business>;
      if (!mounted) return;
      setState(() {
        _searchingTargets = false;
        _targetUsers = peopleResult.response?.people ?? [];
        _targetBusinessMatches =
            businessResult.success ? businessResult.data : [];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _searchingTargets = false);
    }
  }

  Future<void> _selectTargetUser(PersonSearchResult user) async {
    if (_token == null) return;
    setState(() {
      _selectedTargetUser = user;
      _selectedTargetBusiness = null;
      _selectedUserBusinesses = [];
      _loadingBusinesses = true;
    });
    final businesses =
        await BusinessService.getMyBusinesses(_token!, user.id);
    if (!mounted) return;
    final bizList = businesses.success ? businesses.data : <Business>[];
    setState(() {
      _loadingBusinesses = false;
      _selectedUserBusinesses = bizList;
    });
    // If user has no businesses, auto-fill from user profile
    if (bizList.isEmpty) {
      setState(() {
        _customerNameCtrl.text = user.fullName.isNotEmpty
            ? user.fullName
            : (user.username ?? '');
        // Create a pseudo-business selection so the "selected" card shows
        _selectedTargetBusiness = Business(
          id: null,
          userId: user.id,
          name: user.fullName.isNotEmpty ? user.fullName : (user.username ?? ''),
          type: BusinessType.sole_proprietor,
        );
      });
    } else if (bizList.length == 1) {
      // Auto-select the only business
      await _selectTargetBusiness(bizList.first);
    }
  }

  Future<void> _selectTargetBusiness(Business business) async {
    setState(() {
      _selectedTargetBusiness = business;
      _customerNameCtrl.text = business.name;
      _customerTin = business.tinNumber;
      _customerPhone = business.phone;
      _customerEmail = business.email;
    });
  }

  void _clearTajiriSelection() {
    setState(() {
      _selectedTargetUser = null;
      _selectedTargetBusiness = null;
      _selectedUserBusinesses = [];
      _targetSearchCtrl.clear();
      _targetUsers = [];
      _targetBusinessMatches = [];
      _customerNameCtrl.clear();
      _customerPhone = null;
      _customerEmail = null;
      _customerTin = null;
    });
  }

  String get _resolvedCustomerName {
    if (_selectedCustomer != null) return _selectedCustomer!.name;
    return _customerNameCtrl.text.trim();
  }

  // ---------------------------------------------------------------------------
  // Add line item bottom sheet
  // ---------------------------------------------------------------------------
  void _addLineItem() {
    final descCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController();
    String unitLabel = 'pcs';
    bool vatApplicable = true;
    final sw = _sw;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final qty = double.tryParse(qtyCtrl.text) ?? 0;
            final price = double.tryParse(
                    priceCtrl.text.replaceAll(',', '')) ??
                0;
            final lineTotal = qty * price;
            final nf = NumberFormat('#,###', 'en');

            return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
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
                      sw ? 'Ongeza Bidhaa/Huduma' : 'Add Item/Service',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _kPrimary)),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(sw
                                ? 'Itakuja hivi karibuni'
                                : 'Coming soon'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.search_rounded, size: 16),
                      label: Text(
                        sw ? 'Tafuta bidhaa' : 'Search catalog',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: _kSecondary,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _inputField(descCtrl,
                      sw ? 'Maelezo ya Bidhaa/Huduma' : 'Item/Service description'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _inputField(
                            qtyCtrl, sw ? 'Kiasi' : 'Quantity',
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            onChanged: (_) => setSheetState(() {})),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 90,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10),
                          decoration: BoxDecoration(
                            color: _kBackground,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: unitLabel,
                              isExpanded: true,
                              style: const TextStyle(
                                  fontSize: 14, color: _kPrimary),
                              items: _kUnitLabels
                                  .map((u) => DropdownMenuItem(
                                      value: u, child: Text(u)))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setSheetState(
                                      () => unitLabel = v);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _inputField(
                      priceCtrl, sw ? 'Bei (TZS)' : 'Unit Price (TZS)',
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setSheetState(() {})),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          sw
                              ? 'VAT inajumuishwa'
                              : 'VAT applicable',
                          style: const TextStyle(
                              fontSize: 14, color: _kPrimary)),
                      Switch(
                        value: vatApplicable,
                        onChanged: (v) =>
                            setSheetState(() => vatApplicable = v),
                        activeTrackColor: _kPrimary,
                      ),
                    ],
                  ),
                  if (lineTotal > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${sw ? 'Jumla' : 'Total'}: TZS ${nf.format(lineTotal)}',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary),
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        final desc = descCtrl.text.trim();
                        final qtyVal =
                            double.tryParse(qtyCtrl.text) ?? 1;
                        final priceVal = double.tryParse(priceCtrl
                                .text
                                .replaceAll(',', '')) ??
                            0;
                        if (desc.isEmpty || priceVal <= 0) return;
                        setState(() {
                          _items.add(_LineItem(
                            description: desc,
                            quantity: qtyVal,
                            unitPrice: priceVal,
                            unitLabel: unitLabel,
                            vatApplicable: vatApplicable,
                          ));
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(sw ? 'Ongeza' : 'Add',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _freqChip(String value, String label) {
    final selected = _recurringFreq == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
          color: selected ? Colors.white : _kPrimary)),
      selected: selected,
      onSelected: (_) => setState(() => _recurringFreq = value),
      selectedColor: _kPrimary,
      backgroundColor: _kBackground,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _endChip(String value, String label) {
    final selected = _recurringEndCondition == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
          color: selected ? Colors.white : _kPrimary)),
      selected: selected,
      onSelected: (_) => setState(() => _recurringEndCondition = value),
      selectedColor: _kPrimary,
      backgroundColor: _kBackground,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _inputField(TextEditingController ctrl, String label,
      {TextInputType keyboardType = TextInputType.text,
      int maxLines = 1,
      ValueChanged<String>? onChanged}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: _kBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Validation & Save
  // ---------------------------------------------------------------------------
  Future<void> _save({String status = 'draft'}) async {
    if (_token == null) return;
    final sw = _sw;
    final messenger = ScaffoldMessenger.of(context);

    final customerName = _resolvedCustomerName;
    if (customerName.isEmpty) {
      messenger.showSnackBar(SnackBar(
          content: Text(sw
              ? 'Tafadhali chagua mteja'
              : 'Please select a customer')));
      return;
    }
    if (_items.isEmpty) {
      messenger.showSnackBar(SnackBar(
          content: Text(sw
              ? 'Ongeza bidhaa angalau moja'
              : 'Add at least one item')));
      return;
    }
    if (_totalAmount <= 0) {
      messenger.showSnackBar(SnackBar(
          content: Text(sw
              ? 'Jumla ya ankara haiwezi kuwa sifuri'
              : 'Invoice total cannot be zero')));
      return;
    }
    if (_dueDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      messenger.showSnackBar(SnackBar(
          content: Text(sw
              ? 'Tarehe ya mwisho haiwezi kuwa zamani'
              : 'Due date cannot be in the past')));
      return;
    }

    setState(() => _saving = true);

    final body = <String, dynamic>{
      if (_currentUserId != null) 'user_id': _currentUserId,
      'business_id': widget.businessId,
      'customer_id': _selectedCustomer?.id,
      'customer_name': customerName,
      'customer_phone': _customerPhone ?? _selectedCustomer?.phone,
      'customer_email': _customerEmail ?? _selectedCustomer?.email,
      'customer_tin': _customerTin,
      'items': _items
          .map((i) => {
                'description': i.description,
                'quantity': i.quantity,
                'unit_label': i.unitLabel,
                'unit_price': i.unitPrice,
                'total_price': i.total,
                'is_vat_exempt': !i.vatApplicable,
              })
          .toList(),
      'subtotal': _subtotal,
      'discount_type': _showDiscount ? _discountType : null,
      'discount_value': _showDiscount ? _discountValue : 0,
      'discount_amount': _discountAmount,
      'vat_rate': _vatRate,
      'vat_amount': _vatAmount,
      'total_amount': _totalAmount,
      'due_date': _dueDate.toIso8601String(),
      'payment_terms': _paymentTermsCtrl.text.trim().isNotEmpty
          ? _paymentTermsCtrl.text.trim()
          : null,
      'payment_instructions':
          _paymentInstructionsCtrl.text.trim().isNotEmpty
              ? _paymentInstructionsCtrl.text.trim()
              : null,
      'notes': _notesCtrl.text.trim().isNotEmpty
          ? _notesCtrl.text.trim()
          : null,
      'source_quote_id': widget.sourceQuote?.id,
      if (widget.sourceRfqResponseId != null) 'source_rfq_response_id': widget.sourceRfqResponseId,
      'status': status,
    };

    try {
      debugPrint('[CreateInvoice] Saving invoice (status=$status, editing=$_isEditing)');
      debugPrint('[CreateInvoice] Body keys: ${body.keys.toList()}');
      debugPrint('[CreateInvoice] Items count: ${_items.length}, total: $_totalAmount');

      final BusinessResult<Invoice> res;
      if (_isEditing) {
        res = await BusinessService.updateInvoice(
            _token!, widget.editInvoice!.id!, body);
      } else {
        res = await BusinessService.createInvoice(_token!, body);
      }
      if (!mounted) return;
      setState(() => _saving = false);
      if (res.success) {
        debugPrint('[CreateInvoice] Success! Invoice ID: ${res.data?.id}');

        // Create recurring template if toggle is on
        if (_setAsRecurring && !_isEditing) {
          try {
            final recurringBody = <String, dynamic>{
              'user_business_id': widget.businessId,
              'customer_name': customerName,
              'customer_id': _selectedCustomer?.id,
              'items': body['items'],
              'subtotal': _subtotal,
              'vat_rate': _vatRate,
              'vat_amount': _vatAmount,
              'total_amount': _totalAmount,
              'frequency': _recurringFreq,
              'start_date': _recurringStartDate.toIso8601String(),
              'next_issue_date': _recurringStartDate.toIso8601String(),
              'is_active': true,
              if (_recurringEndCondition == 'date' && _recurringEndDate != null)
                'end_date': _recurringEndDate!.toIso8601String(),
              if (_recurringEndCondition == 'count' && _recurringMaxCountCtrl.text.isNotEmpty)
                'max_invoices': int.tryParse(_recurringMaxCountCtrl.text),
              'auto_send': true,
              'auto_send_channels': ['in_app', 'email'],
              'payment_terms': _paymentTermsCtrl.text.trim().isNotEmpty
                  ? _paymentTermsCtrl.text.trim() : null,
              'notes': _notesCtrl.text.trim().isNotEmpty
                  ? _notesCtrl.text.trim() : null,
            };
            await BusinessService.createRecurringInvoice(
                _token!, widget.businessId, recurringBody);
            debugPrint('[CreateInvoice] Recurring template also created');
          } catch (e) {
            debugPrint('[CreateInvoice] Recurring creation failed: $e');
          }
        }

        messenger.showSnackBar(SnackBar(
            content: Text(_setAsRecurring
                ? (sw ? 'Ankara + kiolezo cha kujirudia vimeundwa!' : 'Invoice + recurring template created!')
                : status == 'draft'
                    ? (sw ? 'Rasimu imehifadhiwa!' : 'Draft saved!')
                    : (sw ? 'Ankara imeundwa!' : 'Invoice created!'))));
        Navigator.pop(context, true);
      } else {
        debugPrint('[CreateInvoice] Failed: ${res.message}');
        messenger.showSnackBar(SnackBar(
            content: Text(res.message ?? (sw ? 'Imeshindikana' : 'Failed')),
            duration: const Duration(seconds: 5)));
      }
    } catch (e, stackTrace) {
      debugPrint('[CreateInvoice] Exception: $e');
      debugPrint('[CreateInvoice] Stack: $stackTrace');
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(
          content: Text('${sw ? 'Imeshindikana' : 'Failed'}: $e'),
          duration: const Duration(seconds: 5)));
    }
  }

  // ---------------------------------------------------------------------------
  // Preview
  // ---------------------------------------------------------------------------
  void _showPreview() {
    final nf = NumberFormat('#,###', 'en');
    final df = DateFormat('dd/MM/yyyy');
    final customerName = _resolvedCustomerName;
    final sw = _sw;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 20),
            Center(
              child: Text(sw ? 'ANKARA / INVOICE' : 'INVOICE',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _kPrimary,
                      letterSpacing: 2)),
            ),
            const SizedBox(height: 24),
            // Source quote reference
            if (widget.sourceQuote != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  sw
                      ? 'Kutoka Nukuu #${widget.sourceQuote!.quoteNumber}'
                      : 'From Quote #${widget.sourceQuote!.quoteNumber}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sw ? 'Kutoka:' : 'From:',
                          style: const TextStyle(
                              fontSize: 11, color: _kSecondary)),
                      Text(
                          _businessName ??
                              (sw ? 'Biashara Yako' : 'Your Business'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _kPrimary)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(sw ? 'Kwa:' : 'To:',
                          style: const TextStyle(
                              fontSize: 11, color: _kSecondary)),
                      Text(
                          customerName.isNotEmpty ? customerName : '-',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _kPrimary)),
                      if (_customerPhone != null &&
                          _customerPhone!.isNotEmpty)
                        Text(_customerPhone!,
                            style: const TextStyle(
                                fontSize: 11, color: _kSecondary)),
                      if (_customerEmail != null &&
                          _customerEmail!.isNotEmpty)
                        Text(_customerEmail!,
                            style: const TextStyle(
                                fontSize: 11, color: _kSecondary)),
                      if (_customerTin != null &&
                          _customerTin!.isNotEmpty)
                        Text('TIN: $_customerTin',
                            style: const TextStyle(
                                fontSize: 11, color: _kSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
                '${sw ? 'Tarehe ya Mwisho' : 'Due Date'}: ${df.format(_dueDate)}',
                style:
                    const TextStyle(fontSize: 12, color: _kSecondary)),
            const Divider(height: 24),
            ...List.generate(_items.length, (i) {
              final item = _items[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.description,
                              style: const TextStyle(
                                  fontSize: 13, color: _kPrimary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          if (!item.vatApplicable)
                            Text(
                                sw
                                    ? 'VAT haijumuishwi'
                                    : 'VAT exempt',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: _kSecondary,
                                    fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(
                          'x${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 1)} ${item.unitLabel}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12, color: _kSecondary)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('TZS ${nf.format(item.total)}',
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary)),
                    ),
                  ],
                ),
              );
            }),
            const Divider(height: 20),
            _previewTotalRow(
                sw ? 'Jumla Ndogo' : 'Subtotal',
                'TZS ${nf.format(_subtotal)}'),
            if (_discountAmount > 0)
              _previewTotalRow(
                  '${sw ? 'Punguzo' : 'Discount'} ${_discountType == 'percentage' ? '(${_discountValue.toStringAsFixed(0)}%)' : ''}',
                  '- TZS ${nf.format(_discountAmount)}'),
            if (_vatAmount > 0)
              _previewTotalRow(
                  'VAT (${_vatRate.toStringAsFixed(0)}%)',
                  'TZS ${nf.format(_vatAmount)}'),
            const SizedBox(height: 4),
            _previewTotalRow(
                sw ? 'JUMLA' : 'TOTAL',
                'TZS ${nf.format(_totalAmount)}',
                isBold: true,
                fontSize: 16),
            if (_paymentTermsCtrl.text.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                  '${sw ? 'Masharti ya Malipo' : 'Payment Terms'}: ${_paymentTermsCtrl.text.trim()}',
                  style: const TextStyle(
                      fontSize: 12, color: _kSecondary)),
            ],
            if (_paymentInstructionsCtrl.text.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                  '${sw ? 'Maelekezo ya Malipo' : 'Payment Instructions'}:',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kSecondary)),
              const SizedBox(height: 2),
              Text(
                  _paymentInstructionsCtrl.text.trim(),
                  style: const TextStyle(
                      fontSize: 12, color: _kSecondary)),
            ],
            if (_notesCtrl.text.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                  '${sw ? 'Maelezo' : 'Notes'}: ${_notesCtrl.text.trim()}',
                  style: const TextStyle(
                      fontSize: 12, color: _kSecondary)),
            ],
            const SizedBox(height: 16),
            // Share / Print / Download actions
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.share_rounded, size: 22, color: _kPrimary),
                  tooltip: sw ? 'Shiriki' : 'Share',
                  onPressed: () {
                    final summary = StringBuffer();
                    summary.writeln(sw ? 'ANKARA / INVOICE' : 'INVOICE');
                    summary.writeln('${sw ? 'Kutoka' : 'From'}: ${_businessName ?? (sw ? 'Biashara Yako' : 'Your Business')}');
                    summary.writeln('${sw ? 'Kwa' : 'To'}: ${customerName.isNotEmpty ? customerName : '-'}');
                    summary.writeln('${sw ? 'Tarehe ya Mwisho' : 'Due Date'}: ${df.format(_dueDate)}');
                    summary.writeln('');
                    for (final item in _items) {
                      summary.writeln('${item.description} x${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 1)} ${item.unitLabel} = TZS ${nf.format(item.total)}');
                    }
                    summary.writeln('');
                    summary.writeln('${sw ? 'JUMLA' : 'TOTAL'}: TZS ${nf.format(_totalAmount)}');
                    SharePlus.instance.share(ShareParams(text: summary.toString()));
                  },
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.print_rounded, size: 22, color: _kPrimary),
                  tooltip: sw ? 'Chapisha' : 'Print',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(sw
                          ? 'Hifadhi kwanza kisha chapisha kutoka ankara'
                          : 'Save first then print from invoice detail'),
                    ));
                  },
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.download_rounded, size: 22, color: _kPrimary),
                  tooltip: sw ? 'Pakua PDF' : 'Download PDF',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(sw
                          ? 'Hifadhi kwanza kisha pakua PDF'
                          : 'Save first then download PDF'),
                    ));
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kPrimary,
                        side: const BorderSide(color: _kPrimary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                          sw ? 'Rudi Kuhariri' : 'Back to Edit',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _save(status: 'sent');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                          sw ? 'Hifadhi na Tuma' : 'Save & Send',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewTotalRow(String label, String value,
      {bool isBold = false, double fontSize = 13}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: fontSize,
                  color: isBold ? _kPrimary : _kSecondary,
                  fontWeight:
                      isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: fontSize,
                  color: _kPrimary,
                  fontWeight:
                      isBold ? FontWeight.bold : FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _targetSearchDebounce?.cancel();
    _targetSearchFocusNode.dispose();
    _customerNameCtrl.dispose();
    _targetSearchCtrl.dispose();
    _notesCtrl.dispose();
    _paymentTermsCtrl.dispose();
    _paymentInstructionsCtrl.dispose();
    _discountValueCtrl.dispose();
    _recurringMaxCountCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat('#,###', 'en');
    final df = DateFormat('dd/MM/yyyy');
    final sw = _sw;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
            _isEditing
                ? (sw ? 'Hariri Ankara' : 'Edit Invoice')
                : (sw ? 'Unda Ankara' : 'Create Invoice'),
            style: const TextStyle(
                color: _kPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        actions: [
          if (_items.isNotEmpty)
            TextButton(
              onPressed: _showPreview,
              child: Text(sw ? 'Angalia' : 'Preview',
                  style: const TextStyle(
                      color: _kPrimary, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _kPrimary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // === Quote conversion banner ===
                if (widget.sourceQuote != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color:
                              Colors.blueGrey.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 18, color: Colors.blueGrey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sw
                                ? 'Kutoka Nukuu #${widget.sourceQuote!.quoteNumber}'
                                : 'From Quote #${widget.sourceQuote!.quoteNumber}',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueGrey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // === Customer section ===
                Text(sw ? 'Mteja' : 'Customer',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary)),
                const SizedBox(height: 8),

                if (!_showTajiriSearch) ...[
                  // Option A: Existing customer dropdown
                  if (_customers.isNotEmpty)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedCustomer?.id,
                          hint: Text(sw
                              ? 'Chagua Mteja'
                              : 'Select Customer'),
                          isExpanded: true,
                          items: [
                            ..._customers.map((c) =>
                                DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name,
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow.ellipsis))),
                            DropdownMenuItem<int>(
                              value: -1,
                              child: Row(
                                children: [
                                  const Icon(Icons.search_rounded,
                                      size: 16,
                                      color: _kSecondary),
                                  const SizedBox(width: 8),
                                  Text(
                                      sw
                                          ? 'Tafuta kwenye TAJIRI'
                                          : 'Search on TAJIRI',
                                      style: const TextStyle(
                                          color: _kSecondary,
                                          fontWeight:
                                              FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (v) {
                            if (v == -1) {
                              setState(() {
                                _selectedCustomer = null;
                                _showTajiriSearch = true;
                              });
                              return;
                            }
                            setState(() {
                              _selectedCustomer = _customers
                                  .firstWhere((c) => c.id == v);
                              _customerNameCtrl.text =
                                  _selectedCustomer!.name;
                              _customerPhone =
                                  _selectedCustomer!.phone;
                              _customerEmail =
                                  _selectedCustomer!.email;
                            });
                          },
                        ),
                      ),
                    ),
                  // "Search on TAJIRI" button — always visible when no customer selected
                  if (_selectedCustomer == null &&
                      !_showTajiriSearch) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            setState(() => _showTajiriSearch = true),
                        icon: const Icon(Icons.search_rounded, size: 16),
                        label: Text(
                            sw
                                ? 'Tafuta kwenye TAJIRI'
                                : 'Search on TAJIRI',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kPrimary,
                          side: const BorderSide(color: _kPrimary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ] else ...[
                  // Option B: TAJIRI search
                  if (_selectedTargetBusiness != null) ...[
                    // Customer selected card — only show when a BUSINESS is selected
                    // (not just a user, since user may have multiple businesses to pick from)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: Color(0xFFF2F2F2),
                            child: Icon(
                              Icons.person_rounded,
                              size: 18,
                              color: _kSecondary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _customerNameCtrl.text.isNotEmpty
                                      ? _customerNameCtrl.text
                                      : (_selectedTargetBusiness
                                              ?.name ??
                                          _selectedTargetUser
                                              ?.fullName ??
                                          ''),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _kPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_customerTin != null &&
                                    _customerTin!.isNotEmpty)
                                  Text('TIN: $_customerTin',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: _kSecondary)),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _clearTajiriSelection,
                            child: Text(
                                sw ? 'Badilisha' : 'Change',
                                style: const TextStyle(
                                    color: _kPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Search box
                    Container(
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _targetSearchFocusNode.hasFocus
                              ? _kPrimary.withValues(alpha: 0.45)
                              : Colors.grey.shade200,
                        ),
                        boxShadow: _targetSearchFocusNode.hasFocus
                            ? [
                                BoxShadow(
                                  color: _kPrimary.withValues(
                                      alpha: 0.06),
                                  blurRadius: 14,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : const [],
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _targetSearchCtrl,
                            focusNode: _targetSearchFocusNode,
                            decoration: InputDecoration(
                              hintText: sw
                                  ? 'Tafuta jina, @handle, au biashara'
                                  : 'Search name, @handle, or business',
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 13),
                              prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  size: 18,
                                  color: _kSecondary),
                              suffixIcon: _searchingTargets
                                  ? const Padding(
                                      padding:
                                          EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child:
                                            CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color:
                                                    _kPrimary),
                                      ),
                                    )
                                  : (_targetSearchCtrl.text
                                          .trim()
                                          .isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(
                                              Icons
                                                  .close_rounded,
                                              size: 18),
                                          onPressed: () {
                                            setState(() {
                                              _targetSearchCtrl
                                                  .clear();
                                              _targetUsers = [];
                                              _targetBusinessMatches =
                                                  [];
                                            });
                                          },
                                        )
                                      : null),
                            ),
                            onChanged: _onTargetQueryChanged,
                          ),
                          if (_showTargetSuggestions)
                            Container(
                              constraints:
                                  const BoxConstraints(
                                      maxHeight: 260),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                      color: Colors
                                          .grey.shade100),
                                ),
                              ),
                              child: (_targetUsers.isEmpty &&
                                      _targetBusinessMatches
                                          .isEmpty &&
                                      !_searchingTargets)
                                  ? Center(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets
                                                .all(14),
                                        child: Text(
                                          sw
                                              ? 'Hakuna matokeo. Endelea kuandika...'
                                              : 'No results found. Keep typing...',
                                          style: const TextStyle(
                                              color:
                                                  _kSecondary,
                                              fontSize: 12),
                                        ),
                                      ),
                                    )
                                  : ListView(
                                      padding: const EdgeInsets
                                          .symmetric(
                                          vertical: 6),
                                      shrinkWrap: true,
                                      children: [
                                        if (_targetUsers
                                            .isNotEmpty) ...[
                                          Padding(
                                            padding:
                                                const EdgeInsets
                                                    .fromLTRB(
                                                    12,
                                                    2,
                                                    12,
                                                    4),
                                            child: Text(
                                              sw
                                                  ? 'Watumiaji'
                                                  : 'Users',
                                              style:
                                                  const TextStyle(
                                                fontSize: 11,
                                                color:
                                                    _kSecondary,
                                                fontWeight:
                                                    FontWeight
                                                        .w700,
                                              ),
                                            ),
                                          ),
                                          ..._targetUsers
                                              .take(6)
                                              .map(
                                                  (u) =>
                                                      ListTile(
                                                        dense:
                                                            true,
                                                        visualDensity:
                                                            const VisualDensity(vertical: -2),
                                                        leading:
                                                            const CircleAvatar(
                                                          radius:
                                                              14,
                                                          backgroundColor:
                                                              Color(0xFFF2F2F2),
                                                          child:
                                                              Icon(Icons.person_rounded, size: 14, color: _kSecondary),
                                                        ),
                                                        title:
                                                            Text(
                                                          u.fullName.isEmpty ? (u.username ?? '-') : u.fullName,
                                                          maxLines:
                                                              1,
                                                          overflow:
                                                              TextOverflow.ellipsis,
                                                        ),
                                                        subtitle:
                                                            Text(
                                                          u.username != null ? '@${u.username}' : '',
                                                          maxLines:
                                                              1,
                                                          overflow:
                                                              TextOverflow.ellipsis,
                                                        ),
                                                        onTap:
                                                            () async {
                                                          _targetSearchCtrl.text = u.fullName.isNotEmpty ? u.fullName : '@${u.username ?? ''}';
                                                          await _selectTargetUser(u);
                                                          _targetSearchFocusNode.unfocus();
                                                        },
                                                      )),
                                        ],
                                        if (_targetBusinessMatches
                                            .isNotEmpty) ...[
                                          Padding(
                                            padding:
                                                const EdgeInsets
                                                    .fromLTRB(
                                                    12,
                                                    6,
                                                    12,
                                                    4),
                                            child: Text(
                                              sw
                                                  ? 'Biashara'
                                                  : 'Businesses',
                                              style:
                                                  const TextStyle(
                                                fontSize: 11,
                                                color:
                                                    _kSecondary,
                                                fontWeight:
                                                    FontWeight
                                                        .w700,
                                              ),
                                            ),
                                          ),
                                          ..._targetBusinessMatches
                                              .take(6)
                                              .map(
                                                  (b) =>
                                                      ListTile(
                                                        dense:
                                                            true,
                                                        visualDensity:
                                                            const VisualDensity(vertical: -2),
                                                        leading:
                                                            const CircleAvatar(
                                                          radius:
                                                              14,
                                                          backgroundColor:
                                                              Color(0xFFF2F2F2),
                                                          child:
                                                              Icon(Icons.store_rounded, size: 14, color: _kSecondary),
                                                        ),
                                                        title:
                                                            Text(
                                                          b.name,
                                                          maxLines:
                                                              1,
                                                          overflow:
                                                              TextOverflow.ellipsis,
                                                        ),
                                                        subtitle:
                                                            Text(
                                                          b.ownerHandle ?? b.handleDisplay ?? (b.handle != null ? '@${b.handle}' : (b.ownerName ?? b.ownerUsername ?? b.sector ?? (sw ? 'Biashara' : 'Business'))),
                                                          maxLines:
                                                              1,
                                                          overflow:
                                                              TextOverflow.ellipsis,
                                                        ),
                                                        onTap:
                                                            () async {
                                                          _targetSearchCtrl.text = b.name;
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
                                                            await _selectTargetUser(pseudoUser);
                                                          }
                                                          await _selectTargetBusiness(b);
                                                          _targetSearchFocusNode.unfocus();
                                                        },
                                                      )),
                                        ],
                                      ],
                                    ),
                            ),
                        ],
                      ),
                    ),
                    if (_loadingBusinesses)
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: LinearProgressIndicator(
                            color: _kPrimary, minHeight: 2),
                      ),
                    if (_selectedUserBusinesses.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                          sw
                              ? 'Chagua biashara'
                              : 'Select business',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12),
                        decoration: BoxDecoration(
                          color: _kCardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.grey.shade200),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value:
                                _selectedTargetBusiness?.id,
                            hint: Text(sw
                                ? 'Biashara ya mteja'
                                : 'Customer business'),
                            isExpanded: true,
                            items: _selectedUserBusinesses
                                .where((b) => b.id != null)
                                .map((b) =>
                                    DropdownMenuItem<int>(
                                      value: b.id,
                                      child: Text(b.name,
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow
                                                  .ellipsis),
                                    ))
                                .toList(),
                            onChanged: (id) {
                              final b =
                                  _selectedUserBusinesses
                                      .firstWhere(
                                          (e) => e.id == id,
                                          orElse: () =>
                                              _selectedUserBusinesses
                                                  .first);
                              _selectTargetBusiness(b);
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        _clearTajiriSelection();
                        setState(() => _showTajiriSearch = false);
                      },
                      icon: const Icon(Icons.arrow_back_rounded,
                          size: 16),
                      label: Text(
                          sw
                              ? 'Rudi kwenye orodha'
                              : 'Back to customer list',
                          style: const TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                          foregroundColor: _kSecondary),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // === Line items ===
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        sw
                            ? 'Bidhaa / Huduma'
                            : 'Items / Services',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary)),
                    TextButton.icon(
                      onPressed: _addLineItem,
                      icon: const Icon(
                          Icons.add_circle_rounded,
                          size: 18),
                      label: Text(
                          sw ? 'Ongeza Bidhaa' : 'Add Item'),
                      style: TextButton.styleFrom(
                          foregroundColor: _kPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_items.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _kCardBg,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.grey.shade100),
                    ),
                    child: Center(
                      child: Text(
                          sw
                              ? 'Bonyeza "Ongeza Bidhaa" kuongeza bidhaa'
                              : 'Tap "Add Item" to add items',
                          style: const TextStyle(
                              color: _kSecondary,
                              fontSize: 13)),
                    ),
                  )
                else
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _items.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final item = _items.removeAt(oldIndex);
                        _items.insert(newIndex, item);
                      });
                    },
                    proxyDecorator: (child, index, animation) {
                      return Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(10),
                        child: child,
                      );
                    },
                    itemBuilder: (context, i) {
                      final item = _items[i];
                      return Dismissible(
                        key: ValueKey('item_${item.description}_${item.unitPrice}_$i'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding:
                              const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                          child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.red),
                        ),
                        onDismissed: (_) =>
                            setState(() => _items.removeAt(i)),
                        child: Container(
                          margin:
                              const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _kCardBg,
                            borderRadius:
                                BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.grey.shade100),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.drag_handle_rounded,
                                  size: 18, color: Colors.grey.shade400),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(item.description,
                                        style: const TextStyle(
                                            fontWeight:
                                                FontWeight.w600,
                                            color: _kPrimary,
                                            fontSize: 13),
                                        maxLines: 2,
                                        overflow: TextOverflow
                                            .ellipsis),
                                    Text(
                                      '${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 1)} ${item.unitLabel} x TZS ${nf.format(item.unitPrice)} = TZS ${nf.format(item.total)}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: _kSecondary),
                                    ),
                                    if (!item.vatApplicable)
                                      Text(
                                          sw
                                              ? 'VAT haijumuishwi'
                                              : 'VAT exempt',
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color:
                                                  _kSecondary,
                                              fontStyle:
                                                  FontStyle
                                                      .italic)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: Colors.red),
                                onPressed: () => setState(
                                    () => _items.removeAt(i)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 16),

                // === Totals section ===
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _previewTotalRow(
                          sw ? 'Jumla Ndogo' : 'Subtotal',
                          'TZS ${nf.format(_subtotal)}'),

                      // Discount toggle
                      const SizedBox(height: 8),
                      if (!_showDiscount)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => setState(
                                () => _showDiscount = true),
                            icon: const Icon(
                                Icons.add_rounded,
                                size: 16),
                            label: Text(
                                sw
                                    ? 'Ongeza Punguzo'
                                    : 'Add Discount',
                                style: const TextStyle(
                                    fontSize: 12)),
                            style: TextButton.styleFrom(
                                foregroundColor: _kPrimary),
                          ),
                        )
                      else ...[
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 10),
                                decoration: BoxDecoration(
                                  color: _kCardBg,
                                  borderRadius:
                                      BorderRadius.circular(
                                          8),
                                ),
                                child:
                                    DropdownButtonHideUnderline(
                                  child: DropdownButton<
                                      String>(
                                    value: _discountType,
                                    isExpanded: true,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: _kPrimary),
                                    items: [
                                      DropdownMenuItem(
                                        value: 'percentage',
                                        child: Text(sw
                                            ? 'Asilimia (%)'
                                            : 'Percentage (%)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'fixed',
                                        child: Text(sw
                                            ? 'Kiasi (TZS)'
                                            : 'Fixed (TZS)'),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() =>
                                            _discountType =
                                                v);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller:
                                    _discountValueCtrl,
                                keyboardType:
                                    TextInputType.number,
                                onChanged: (_) =>
                                    setState(() {}),
                                decoration: InputDecoration(
                                  hintText: _discountType ==
                                          'percentage'
                                      ? '%'
                                      : 'TZS',
                                  filled: true,
                                  fillColor: _kCardBg,
                                  border:
                                      OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(8),
                                    borderSide:
                                        BorderSide.none,
                                  ),
                                  contentPadding:
                                      const EdgeInsets
                                          .symmetric(
                                          horizontal: 10,
                                          vertical: 10),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: _kSecondary),
                              onPressed: () {
                                setState(() {
                                  _showDiscount = false;
                                  _discountValueCtrl
                                      .clear();
                                });
                              },
                            ),
                          ],
                        ),
                        if (_discountAmount > 0) ...[
                          const SizedBox(height: 4),
                          _previewTotalRow(
                              sw ? 'Punguzo' : 'Discount',
                              '- TZS ${nf.format(_discountAmount)}'),
                        ],
                      ],

                      if (_vatAmount > 0) ...[
                        const SizedBox(height: 4),
                        _previewTotalRow(
                            'VAT (${_vatRate.toStringAsFixed(0)}%)',
                            'TZS ${nf.format(_vatAmount)}'),
                      ],

                      const Divider(),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(sw ? 'JUMLA' : 'TOTAL',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _kPrimary)),
                          Text(
                              'TZS ${nf.format(_totalAmount)}',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _kPrimary)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // === Due date with quick presets ===
                Text(
                    sw
                        ? 'Tarehe ya Mwisho wa Malipo'
                        : 'Payment Due Date',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [7, 14, 30, 60].map((days) {
                    final isSelected = _dueDate
                            .difference(DateTime.now())
                            .inDays
                            .abs() ==
                        days;
                    return ChoiceChip(
                      label: Text('Net $days'),
                      selected: isSelected,
                      onSelected: (_) => setState(() =>
                          _dueDate = DateTime.now()
                              .add(Duration(days: days))),
                      selectedColor:
                          _kPrimary.withValues(alpha: 0.12),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? _kPrimary
                            : _kSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                          color: isSelected
                              ? _kPrimary
                              : Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(20)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final dt = await showDatePicker(
                      context: context,
                      initialDate: _dueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now()
                          .add(const Duration(days: 365)),
                    );
                    if (dt != null) setState(() => _dueDate = dt);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText:
                          sw ? 'Tarehe ya Mwisho' : 'Due Date',
                      filled: true,
                      fillColor: _kCardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: Colors.grey.shade200),
                      ),
                      suffixIcon: const Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                          color: _kSecondary),
                    ),
                    child: Text(df.format(_dueDate)),
                  ),
                ),

                const SizedBox(height: 16),

                // === Payment details ===
                Text(
                    sw
                        ? 'Maelezo ya Malipo'
                        : 'Payment Details',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary)),
                const SizedBox(height: 8),
                TextField(
                  controller: _paymentTermsCtrl,
                  decoration: InputDecoration(
                    labelText: sw
                        ? 'Masharti ya malipo'
                        : 'Payment terms',
                    hintText: sw
                        ? 'Mf. Malipo ndani ya siku 30'
                        : 'e.g. Payment within 30 days',
                    filled: true,
                    fillColor: _kCardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Colors.grey.shade200),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _paymentInstructionsCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: sw
                        ? 'Maelekezo ya malipo'
                        : 'Payment instructions',
                    hintText: sw
                        ? 'Mf. Lipa kupitia M-Pesa...'
                        : 'e.g. Pay via M-Pesa...',
                    filled: true,
                    fillColor: _kCardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Colors.grey.shade200),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),

                const SizedBox(height: 16),

                // === Notes ===
                TextField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText:
                        sw ? 'Maelezo ya ziada' : 'Additional notes',
                    filled: true,
                    fillColor: _kCardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Colors.grey.shade200),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // === Set as Recurring ===
                if (!_isEditing) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _kCardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _setAsRecurring ? _kPrimary.withValues(alpha: 0.3) : Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.repeat_rounded, size: 18,
                                    color: _setAsRecurring ? _kPrimary : _kSecondary),
                                const SizedBox(width: 8),
                                Text(
                                  sw ? 'Ankara ya kujirudia' : 'Set as recurring',
                                  style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600,
                                    color: _setAsRecurring ? _kPrimary : _kSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: _setAsRecurring,
                              onChanged: (v) => setState(() => _setAsRecurring = v),
                              activeTrackColor: _kPrimary,
                            ),
                          ],
                        ),
                        if (_setAsRecurring) ...[
                          const SizedBox(height: 12),
                          // Frequency
                          Text(sw ? 'Mzunguko' : 'Frequency',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            children: [
                              _freqChip('weekly', sw ? 'Kila Wiki' : 'Weekly'),
                              _freqChip('monthly', sw ? 'Kila Mwezi' : 'Monthly'),
                              _freqChip('quarterly', sw ? 'Kila Robo' : 'Quarterly'),
                              _freqChip('yearly', sw ? 'Kila Mwaka' : 'Yearly'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Start date
                          GestureDetector(
                            onTap: () async {
                              final dt = await showDatePicker(
                                context: context,
                                initialDate: _recurringStartDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (dt != null) setState(() => _recurringStartDate = dt);
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: sw ? 'Tarehe ya kuanza' : 'Start date',
                                filled: true, fillColor: _kBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                suffixIcon: const Icon(Icons.calendar_today_rounded, size: 16, color: _kSecondary),
                              ),
                              child: Text(DateFormat('dd/MM/yyyy').format(_recurringStartDate)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // End condition
                          Text(sw ? 'Masharti ya mwisho' : 'End condition',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            children: [
                              _endChip('none', sw ? 'Bila mwisho' : 'No end'),
                              _endChip('date', sw ? 'Hadi tarehe' : 'Until date'),
                              _endChip('count', sw ? 'Idadi' : 'Count'),
                            ],
                          ),
                          if (_recurringEndCondition == 'date') ...[
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                final dt = await showDatePicker(
                                  context: context,
                                  initialDate: _recurringEndDate ?? DateTime.now().add(const Duration(days: 365)),
                                  firstDate: _recurringStartDate,
                                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                                );
                                if (dt != null) setState(() => _recurringEndDate = dt);
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: sw ? 'Tarehe ya mwisho' : 'End date',
                                  filled: true, fillColor: _kBackground,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                  suffixIcon: const Icon(Icons.event_rounded, size: 16, color: _kSecondary),
                                ),
                                child: Text(_recurringEndDate != null
                                    ? DateFormat('dd/MM/yyyy').format(_recurringEndDate!)
                                    : (sw ? 'Chagua tarehe' : 'Select date')),
                              ),
                            ),
                          ],
                          if (_recurringEndCondition == 'count') ...[
                            const SizedBox(height: 8),
                            TextField(
                              controller: _recurringMaxCountCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: sw ? 'Ankara ngapi?' : 'How many invoices?',
                                filled: true, fillColor: _kBackground,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // === Bottom actions ===
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () => _save(status: 'draft'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _kPrimary,
                            side: const BorderSide(
                                color: _kPrimary),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                          ),
                          child: Text(
                              sw
                                  ? 'Hifadhi Rasimu'
                                  : 'Save Draft',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saving
                              ? null
                              : () {
                                  if (_items.isNotEmpty) {
                                    _showPreview();
                                  } else {
                                    _save(status: 'sent');
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child:
                                      CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2))
                              : Text(
                                  sw
                                      ? 'Hakiki na Tuma'
                                      : 'Preview & Send',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight:
                                          FontWeight.w600)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(sw
                              ? 'Itakuja hivi karibuni'
                              : 'Coming soon'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.save_as_rounded, size: 16),
                    label: Text(
                      sw
                          ? 'Hifadhi kama Kiolezo'
                          : 'Save as Template',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: _kSecondary,
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
    );
  }
}

class _LineItem {
  final String description;
  final double quantity;
  final double unitPrice;
  final String unitLabel;
  final bool vatApplicable;
  double get total => quantity * unitPrice;

  _LineItem({
    required this.description,
    this.quantity = 1,
    this.unitPrice = 0,
    this.unitLabel = 'pcs',
    this.vatApplicable = true,
  });
}
