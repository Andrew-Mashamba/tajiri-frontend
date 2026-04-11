// lib/business/pages/suppliers_page.dart
// Supplier management (Wasambazaji / Suppliers).
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/business_models.dart';
import '../services/business_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class SuppliersPage extends StatefulWidget {
  final int businessId;
  const SuppliersPage({super.key, required this.businessId});

  @override
  State<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> {
  String? _token;
  bool _loading = true;
  String? _error;
  List<Supplier> _suppliers = [];
  final _searchCtrl = TextEditingController();

  bool get _isSwahili =>
      AppStringsScope.of(context)?.isSwahili ?? false;

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

  Future<void> _load({String? search}) async {
    if (_token == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await BusinessService.getSuppliers(
          _token!, widget.businessId,
          search: search);
      if (mounted) {
        setState(() {
          _loading = false;
          if (res.success) {
            _suppliers = res.data;
          } else {
            _error = res.message ??
                (_isSwahili ? 'Imeshindikana kupata wasambazaji' : 'Failed to load suppliers');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = _isSwahili ? 'Tatizo la mtandao' : 'Network error';
        });
      }
    }
  }

  Future<void> _deleteSupplier(Supplier s) async {
    if (_token == null || s.id == null) return;
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
    final messenger = ScaffoldMessenger.of(context);
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

  void _showAddEditSheet({Supplier? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    final tinCtrl = TextEditingController(text: existing?.tinNumber ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
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
                // Drag handle
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
                    existing != null
                        ? (_isSwahili ? 'Hariri Msambazaji' : 'Edit Supplier')
                        : (_isSwahili ? 'Ongeza Msambazaji' : 'Add Supplier'),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _kPrimary)),
                const SizedBox(height: 14),
                _sheetField(nameCtrl,
                    _isSwahili ? 'Jina *' : 'Name *'),
                const SizedBox(height: 10),
                _sheetField(phoneCtrl,
                    _isSwahili ? 'Simu' : 'Phone',
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 10),
                _sheetField(emailCtrl, 'Email',
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 10),
                _sheetField(addressCtrl,
                    _isSwahili ? 'Anwani' : 'Address'),
                const SizedBox(height: 10),
                _sheetField(tinCtrl, 'TIN'),
                const SizedBox(height: 10),
                _sheetField(notesCtrl,
                    _isSwahili ? 'Maelezo' : 'Notes'),
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
                            final body = {
                              'business_id': widget.businessId,
                              'name': name,
                              'phone': phoneCtrl.text.trim(),
                              'email': emailCtrl.text.trim(),
                              'address': addressCtrl.text.trim(),
                              'tin_number': tinCtrl.text.trim(),
                              'notes': notesCtrl.text.trim(),
                            };
                            try {
                              if (existing != null && existing.id != null) {
                                await BusinessService.updateSupplier(
                                    _token!, existing.id!, body);
                              } else {
                                await BusinessService.addSupplier(
                                    _token!, widget.businessId, body);
                              }
                              if (mounted) {
                                Navigator.pop(ctx);
                                _load();
                              }
                            } catch (e) {
                              setSheetState(() => submitting = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(_isSwahili
                                        ? 'Imeshindikana. Jaribu tena.'
                                        : 'Failed. Please try again.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
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
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(
                            existing != null
                                ? (_isSwahili ? 'Sasisha' : 'Update')
                                : (_isSwahili ? 'Ongeza' : 'Add'),
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
              onChanged: (v) => _load(search: v),
              decoration: InputDecoration(
                hintText: _isSwahili
                    ? 'Tafuta msambazaji...'
                    : 'Search supplier...',
                prefixIcon:
                    const Icon(Icons.search_rounded, color: _kSecondary),
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
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.local_shipping_rounded,
                                    size: 64,
                                    color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                    _isSwahili
                                        ? 'Hakuna wasambazaji bado'
                                        : 'No suppliers yet',
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 15)),
                                const SizedBox(height: 4),
                                Text(
                                    _isSwahili
                                        ? 'Bonyeza + kuongeza msambazaji'
                                        : 'Tap + to add a supplier',
                                    style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 13)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: _kPrimary,
                            onRefresh: () => _load(),
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
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 4),
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          _kPrimary.withValues(alpha: 0.08),
                                      child: Text(
                                        s.name.isNotEmpty
                                            ? s.name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _kPrimary),
                                      ),
                                    ),
                                    title: Text(s.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: _kPrimary,
                                            fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          [s.phone, s.email]
                                              .where((x) =>
                                                  x != null && x.isNotEmpty)
                                              .join(' | '),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: _kSecondary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (s.tinNumber != null &&
                                            s.tinNumber!.isNotEmpty)
                                          Text(
                                            'TIN: ${s.tinNumber}',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: _kSecondary
                                                    .withValues(alpha: 0.7)),
                                          ),
                                      ],
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
