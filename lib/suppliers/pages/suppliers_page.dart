// lib/suppliers/pages/suppliers_page.dart
// Supplier management (Wasambazaji / Suppliers).
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../business/models/business_models.dart';
import '../../business/services/business_service.dart';
import 'supplier_payables_page.dart';
import 'supplier_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class SuppliersPage extends StatefulWidget {
  final int businessId;
  /// Whether the current viewer owns this business. Non-owners (visitors)
  /// see the supplier list read-only (no add/edit/delete on catalog, no
  /// create PO).
  final bool isOwner;

  const SuppliersPage({
    super.key,
    required this.businessId,
    this.isOwner = true,
  });

  @override
  State<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> {
  String? _token;
  int _userId = 0;
  bool _loading = true;
  String? _error;
  List<Supplier> _suppliers = [];
  final _searchCtrl = TextEditingController();
  Timer? _searchDebounce;
  int _searchSeq = 0;
  bool _searching = false;
  double _outstandingAmount = 0;
  int _outstandingCount = 0;

  bool get _isSwahili =>
      AppStringsScope.of(context)?.isSwahili ?? false;

  Widget _buildMatchChip(String matchContext) {
    String label;
    if (matchContext.startsWith('sells:')) {
      final item = matchContext.substring(6);
      label = _isSwahili ? 'Inauza: $item' : 'Sells: $item';
    } else if (matchContext.startsWith('offers:')) {
      final item = matchContext.substring(7);
      label = _isSwahili ? 'Inatoa: $item' : 'Offers: $item';
    } else if (matchContext.startsWith('category:')) {
      final item = matchContext.substring(9);
      label = _isSwahili ? 'Jamii: $item' : 'Category: $item';
    } else {
      label = _isSwahili ? 'Inapatikana' : 'Matches search';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 10, color: Color(0xFFE65100), fontWeight: FontWeight.w500),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    _userId = storage.getUser()?.userId ?? 0;
    await Future.wait([_load(), _loadPayablesSummary()]);
  }

  Future<void> _loadPayablesSummary() async {
    if (_token == null) return;
    final res = await BusinessService.getPayables(_token!, widget.businessId,
        status: 'unpaid,partially_paid');
    if (mounted && res.success) {
      setState(() {
        _outstandingAmount =
            res.data.fold(0.0, (sum, p) => sum + p.remainingAmount);
        _outstandingCount = res.data.length;
      });
    }
  }

  Future<void> _load({String? search, bool isSearch = false}) async {
    if (_token == null) {
      debugPrint('[SuppliersPage] _load ABORT: token null');
      return;
    }
    final seq = ++_searchSeq;
    debugPrint('[SuppliersPage] _load search="${search ?? ""}" '
        'isSearch=$isSearch seq=$seq businessId=${widget.businessId}');
    setState(() {
      if (isSearch) {
        _searching = true;
      } else {
        _loading = true;
      }
      _error = null;
    });
    try {
      final res = await BusinessService.getSuppliers(
          _token!, widget.businessId,
          search: search);
      if (!mounted || seq != _searchSeq) {
        debugPrint('[SuppliersPage] stale/unmounted seq=$seq '
            'current=$_searchSeq mounted=$mounted');
        return;
      }
      debugPrint('[SuppliersPage] ← success=${res.success} '
          'count=${res.data.length} msg=${res.message}');
      setState(() {
        _loading = false;
        _searching = false;
        if (res.success) {
          _suppliers = res.data;
        } else {
          _error = res.message ??
              (_isSwahili ? 'Imeshindikana kupata wasambazaji' : 'Failed to load suppliers');
        }
      });
    } catch (e) {
      debugPrint('[SuppliersPage] _load ERROR: $e');
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _loading = false;
        _searching = false;
        _error = _isSwahili ? 'Tatizo la mtandao' : 'Network error';
      });
    }
  }

  void _onSearchChanged(String value) {
    debugPrint('[SuppliersPage] onChanged raw="$value"');
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      final q = value.trim();
      debugPrint('[SuppliersPage] debounce fired q="$q"');
      _load(search: q.isEmpty ? null : q, isSearch: true);
    });
  }

  Future<void> _deleteSupplier(Supplier s) async {
    if (_token == null || s.id == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isSwahili ? 'Futa Msambazaji?' : 'Delete Supplier?'),
        content: Text(_isSwahili
            ? 'Futa "${s.name}"? Hatua hii haiwezi kurudishwa.'
            : 'Delete "${s.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_isSwahili ? 'Hapana' : 'Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(_isSwahili ? 'Ndio, Futa' : 'Yes, Delete',
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    final res = await BusinessService.deleteSupplier(_token!, s.id!);
    if (mounted) {
      if (res.success) {
        messenger.showSnackBar(SnackBar(
            content: Text(
                _isSwahili ? 'Msambazaji amefutwa' : 'Supplier deleted')));
        _load();
      } else {
        messenger.showSnackBar(SnackBar(
            content: Text(res.message ??
                (_isSwahili ? 'Imeshindikana kufuta' : 'Failed to delete')),
            backgroundColor: Colors.red));
      }
    }
  }

  void _openSupplierDetail(Supplier s) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => SupplierDetailPage(
          businessId: widget.businessId,
          supplier: s,
          isOwner: widget.isOwner,
          currentUserId: _userId,
        ),
      ),
    );
    if (result == true && mounted) _load();
  }

  void _showAddEditSheet({Supplier? existing}) {
    if (existing == null) {
      _showBusinessPickerSheet();
    } else {
      _showEditSheet(existing);
    }
  }

  void _showBusinessPickerSheet() {
    debugPrint('[PickerSheet] open — token=${_token != null} userId=$_userId');
    if (_token == null || _userId == 0) {
      debugPrint('[PickerSheet] ABORT: missing token or userId=0');
      return;
    }
    final searchCtrl = TextEditingController();
    List<PlatformBusiness> results = [];
    bool searching = false;
    bool adding = false;
    Timer? debounce;
    int seq = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          Future<void> runSearch(String q, int mySeq) async {
            debugPrint('[PickerSheet] runSearch q="$q" seq=$mySeq userId=$_userId');
            final res = await BusinessService.searchPlatformBusinesses(
                _token!, _userId, q);
            debugPrint('[PickerSheet] ← success=${res.success} '
                'count=${res.data?.length ?? 0} msg=${res.message} '
                'staleSeq=${mySeq != seq}');
            if (mySeq != seq) return; // stale response — ignore
            setSt(() {
              searching = false;
              results = res.success ? (res.data ?? []) : [];
            });
            debugPrint('[PickerSheet] modal results=${results.length}');
            if (!res.success && ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                content: Text(_isSwahili
                    ? 'Imeshindikana kutafuta. Jaribu tena.'
                    : 'Search failed. Please try again.'),
                backgroundColor: Colors.red,
              ));
            }
          }

          void onChanged(String raw) {
            final q = raw.trim();
            debounce?.cancel();
            seq++;
            if (q.length < 2) {
              setSt(() { results = []; searching = false; });
              return;
            }
            setSt(() => searching = true);
            final mySeq = seq;
            debounce = Timer(const Duration(milliseconds: 350), () {
              runSearch(q, mySeq);
            });
          }

          Future<void> selectBusiness(PlatformBusiness biz) async {
            if (adding) return;
            if (_suppliers.any((s) => s.platformBusinessId == biz.id)) {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                content: Text(_isSwahili
                    ? 'Msambazaji tayari yupo'
                    : 'Already added as supplier'),
              ));
              return;
            }
            setSt(() => adding = true);
            final body = <String, dynamic>{
              'user_business_id': widget.businessId,
              'platform_business_id': biz.id,
              'name': biz.name,
            };
            try {
              final res = await BusinessService.addSupplier(
                  _token!, widget.businessId, body);
              if (!mounted) return;
              if (res.success) {
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(_isSwahili
                      ? 'Msambazaji ameongezwa'
                      : 'Supplier added'),
                ));
              } else {
                setSt(() => adding = false);
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    content: Text(res.message ??
                        (_isSwahili ? 'Imeshindikana' : 'Failed')),
                    backgroundColor: Colors.red,
                  ));
                }
              }
            } catch (e) {
              setSt(() => adding = false);
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text(_isSwahili
                      ? 'Imeshindikana. Jaribu tena.'
                      : 'Failed. Please try again.'),
                  backgroundColor: Colors.red,
                ));
              }
            }
          }

          return ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.85),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isSwahili ? 'Ongeza Msambazaji' : 'Add Supplier',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _kPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isSwahili
                            ? 'Tafuta biashara ya TAJIRI'
                            : 'Search a business on TAJIRI',
                        style: const TextStyle(
                            fontSize: 12, color: _kSecondary),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchCtrl,
                        autofocus: true,
                        onChanged: onChanged,
                        decoration: InputDecoration(
                          hintText: _isSwahili
                              ? 'Jina la biashara...'
                              : 'Business name...',
                          prefixIcon: const Icon(Icons.storefront_rounded,
                              color: _kSecondary),
                          suffixIcon: searching
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ))
                              : null,
                          filled: true,
                          fillColor: _kBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: results.isEmpty && !searching
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              searchCtrl.text.trim().length < 2
                                  ? (_isSwahili
                                      ? 'Andika angalau herufi 2 kutafuta'
                                      : 'Type at least 2 characters to search')
                                  : (_isSwahili
                                      ? 'Hakuna biashara iliyopatikana'
                                      : 'No businesses found'),
                              style: TextStyle(
                                  color: Colors.grey.shade400, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          shrinkWrap: true,
                          itemCount: results.length,
                          itemBuilder: (_, i) {
                            final biz = results[i];
                            return ListTile(
                              leading: CircleAvatar(
                                radius: 22,
                                backgroundColor:
                                    _kPrimary.withValues(alpha: 0.08),
                                backgroundImage: (biz.logoUrl != null &&
                                        biz.logoUrl!.isNotEmpty)
                                    ? NetworkImage(biz.logoUrl!)
                                    : null,
                                child: (biz.logoUrl == null ||
                                        biz.logoUrl!.isEmpty)
                                    ? Text(
                                        biz.name.isNotEmpty
                                            ? biz.name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _kPrimary),
                                      )
                                    : null,
                              ),
                              title: Text(biz.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _kPrimary,
                                      fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (biz.sector != null && biz.sector!.isNotEmpty)
                                    Text(biz.sector!,
                                        style: const TextStyle(
                                            fontSize: 12, color: _kSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  if (biz.matchContext != null) ...[
                                    const SizedBox(height: 3),
                                    _buildMatchChip(biz.matchContext!),
                                  ],
                                ],
                              ),
                              trailing: adding
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Icon(Icons.add_rounded,
                                      color: _kSecondary),
                              onTap: () => selectBusiness(biz),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() {
      debounce?.cancel();
      // Defer disposal past the modal exit animation — the TextField's
      // internal suffix-icon AnimatedSwitcher still calls addListener on
      // the controller for a frame or two after Navigator.pop.
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        searchCtrl.dispose();
      });
    });
  }

  void _showEditSheet(Supplier existing) {
    final nameCtrl = TextEditingController(text: existing.name);
    final phoneCtrl = TextEditingController(text: existing.phone ?? '');
    final emailCtrl = TextEditingController(text: existing.email ?? '');
    final addressCtrl = TextEditingController(text: existing.address ?? '');
    final tinCtrl = TextEditingController(text: existing.tinNumber ?? '');
    final notesCtrl = TextEditingController(text: existing.notes ?? '');
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
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
                    _isSwahili ? 'Hariri Msambazaji' : 'Edit Supplier',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _kPrimary)),
                const SizedBox(height: 14),
                _sheetField(nameCtrl, _isSwahili ? 'Jina *' : 'Name *'),
                const SizedBox(height: 10),
                _sheetField(phoneCtrl, _isSwahili ? 'Simu' : 'Phone',
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 10),
                _sheetField(emailCtrl, 'Email',
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 10),
                _sheetField(addressCtrl, _isSwahili ? 'Anwani' : 'Address'),
                const SizedBox(height: 10),
                _sheetField(tinCtrl, 'TIN'),
                const SizedBox(height: 10),
                _sheetField(notesCtrl, _isSwahili ? 'Maelezo' : 'Notes'),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: submitting
                        ? null
                        : () async {
                            final name = nameCtrl.text.trim();
                            if (name.isEmpty) return;
                            setSheetState(() => submitting = true);
                            final body = <String, dynamic>{
                              'business_id': widget.businessId,
                              'name': name,
                              'phone': phoneCtrl.text.trim(),
                              'email': emailCtrl.text.trim(),
                              'address': addressCtrl.text.trim(),
                              'tin_number': tinCtrl.text.trim(),
                              'notes': notesCtrl.text.trim(),
                              if (existing.platformBusinessId != null)
                                'platform_business_id': existing.platformBusinessId,
                            };
                            try {
                              final res = await BusinessService.updateSupplier(
                                  _token!, existing.id!, body);
                              if (!res.success) {
                                setSheetState(() => submitting = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                    content: Text(res.message ??
                                        (_isSwahili
                                            ? 'Imeshindikana. Jaribu tena.'
                                            : 'Failed. Please try again.')),
                                    backgroundColor: Colors.red,
                                  ));
                                }
                                return;
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) _load();
                            } catch (e) {
                              setSheetState(() => submitting = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                  content: Text(_isSwahili
                                      ? 'Imeshindikana. Jaribu tena.'
                                      : 'Failed. Please try again.'),
                                  backgroundColor: Colors.red,
                                ));
                              }
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: _kPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: submitting
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(_isSwahili ? 'Sasisha' : 'Update',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      nameCtrl.dispose();
      phoneCtrl.dispose();
      emailCtrl.dispose();
      addressCtrl.dispose();
      tinCtrl.dispose();
      notesCtrl.dispose();
    });
  }

  Widget _sheetField(TextEditingController ctrl, String label,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
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

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditSheet(),
        backgroundColor: _kPrimary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: (v) {
                _searchDebounce?.cancel();
                final q = v.trim();
                _load(search: q.isEmpty ? null : q, isSearch: true);
              },
              decoration: InputDecoration(
                hintText: _isSwahili
                    ? 'Tafuta msambazaji...'
                    : 'Search supplier...',
                prefixIcon:
                    const Icon(Icons.search_rounded, color: _kSecondary),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _kSecondary),
                        ),
                      )
                    : (_searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                size: 18, color: _kSecondary),
                            onPressed: () {
                              _searchDebounce?.cancel();
                              _searchCtrl.clear();
                              _load(isSearch: true);
                            },
                          )
                        : null),
                filled: true,
                fillColor: _kCardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),
          // Outstanding payables summary
          if (_outstandingCount > 0)
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SupplierPayablesPage(
                    businessId: widget.businessId,
                    isSwahili: _isSwahili,
                  ),
                ),
              ).then((_) => _loadPayablesSummary()),
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 18, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isSwahili
                            ? '$_outstandingCount ${_outstandingCount == 1 ? "deni" : "madeni"}  •  TZS ${NumberFormat('#,###').format(_outstandingAmount)}'
                            : '$_outstandingCount ${_outstandingCount == 1 ? "payable" : "payables"}  •  TZS ${NumberFormat('#,###').format(_outstandingAmount)}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.red),
                      ),
                    ),
                    Text(
                      _isSwahili ? 'Angalia' : 'View',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded,
                        size: 16, color: Colors.red),
                  ],
                ),
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
                                size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(_error!,
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 14)),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () => _load(),
                              style: FilledButton.styleFrom(
                                  backgroundColor: _kPrimary),
                              child: Text(_isSwahili
                                  ? 'Jaribu Tena'
                                  : 'Retry'),
                            ),
                          ],
                        ),
                      )
                    : _suppliers.isEmpty
                        ? Builder(builder: (_) {
                            final hasQuery =
                                _searchCtrl.text.trim().isNotEmpty;
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                      hasQuery
                                          ? Icons.search_off_rounded
                                          : Icons.local_shipping_rounded,
                                      size: 64,
                                      color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  Text(
                                      hasQuery
                                          ? (_isSwahili
                                              ? 'Hakuna matokeo'
                                              : 'No matches found')
                                          : (_isSwahili
                                              ? 'Hakuna wasambazaji bado'
                                              : 'No suppliers yet'),
                                      style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text(
                                      hasQuery
                                          ? (_isSwahili
                                              ? 'Jaribu neno tofauti'
                                              : 'Try a different search term')
                                          : (_isSwahili
                                              ? 'Bonyeza + kuongeza msambazaji'
                                              : 'Tap + to add a supplier'),
                                      style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 13)),
                                ],
                              ),
                            );
                          })
                        : RefreshIndicator(
                            color: _kPrimary,
                            onRefresh: () async {
                              _searchDebounce?.cancel();
                              _searchCtrl.clear();
                              await _load();
                            },
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _suppliers.length,
                              itemBuilder: (_, i) {
                                final s = _suppliers[i];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: _kCardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.grey.shade100),
                                  ),
                                  child: ListTile(
                                    onTap: () => _openSupplierDetail(s),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 4),
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          _kPrimary.withValues(alpha: 0.08),
                                      backgroundImage: (s.logoUrl !=
                                                  null &&
                                              s.logoUrl!.isNotEmpty)
                                          ? NetworkImage(s.logoUrl!)
                                          : null,
                                      child: (s.logoUrl == null ||
                                              s.logoUrl!.isEmpty)
                                          ? Text(
                                              s.name.isNotEmpty
                                                  ? s.name[0].toUpperCase()
                                                  : '?',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: _kPrimary),
                                            )
                                          : null,
                                    ),
                                    title: Text(s.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: _kPrimary,
                                            fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    subtitle: _SupplierCardSubtitle(
                                      supplier: s,
                                      isSwahili: _isSwahili,
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert_rounded,
                                          color: _kSecondary),
                                      onSelected: (v) {
                                        if (v == 'edit') {
                                          _showAddEditSheet(existing: s);
                                        } else if (v == 'delete') {
                                          _deleteSupplier(s);
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        PopupMenuItem(
                                            value: 'edit',
                                            child: Text(_isSwahili
                                                ? 'Hariri'
                                                : 'Edit')),
                                        PopupMenuItem(
                                            value: 'delete',
                                            child: Text(
                                                _isSwahili
                                                    ? 'Futa'
                                                    : 'Delete',
                                                style: const TextStyle(
                                                    color: Colors.red))),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

/// Two-section subtitle for a supplier card: business info + owner/user info.
class _SupplierCardSubtitle extends StatelessWidget {
  final Supplier supplier;
  final bool isSwahili;

  const _SupplierCardSubtitle({
    required this.supplier,
    required this.isSwahili,
  });

  @override
  Widget build(BuildContext context) {
    final s = supplier;

    // Business line: phone | email
    final businessContact = [s.phone, s.email]
        .where((x) => x != null && x.isNotEmpty)
        .join(' • ');

    // Owner: show only when we actually have owner data and it differs from
    // what's already shown on the business line.
    final hasOwnerData = (s.ownerName != null && s.ownerName!.isNotEmpty) ||
        (s.ownerUsername != null && s.ownerUsername!.isNotEmpty) ||
        (s.ownerPhone != null && s.ownerPhone!.isNotEmpty) ||
        (s.ownerEmail != null && s.ownerEmail!.isNotEmpty);

    final ownerContact = [s.ownerPhone, s.ownerEmail]
        .where((x) => x != null && x.isNotEmpty)
        .join(' • ');

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Business section ────────────────────────────────────────────
          if (s.handle != null && s.handle!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '@${s.handle}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (businessContact.isNotEmpty)
            Text(
              businessContact,
              style: const TextStyle(fontSize: 12, color: _kSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (s.tinNumber != null && s.tinNumber!.isNotEmpty)
            Text(
              'TIN: ${s.tinNumber}',
              style: TextStyle(
                fontSize: 11,
                color: _kSecondary.withValues(alpha: 0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

          // ── Owner section (only for platform-linked suppliers with data) ─
          if (s.isPlatformLinked && hasOwnerData) ...[
            const SizedBox(height: 6),
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        isSwahili ? 'MMILIKI' : 'OWNER',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (s.ownerName != null && s.ownerName!.isNotEmpty)
                    Text(
                      s.ownerUsername != null && s.ownerUsername!.isNotEmpty
                          ? '${s.ownerName}  @${s.ownerUsername}'
                          : s.ownerName!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else if (s.ownerUsername != null &&
                      s.ownerUsername!.isNotEmpty)
                    Text(
                      '@${s.ownerUsername}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (ownerContact.isNotEmpty)
                    Text(
                      ownerContact,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _kSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
