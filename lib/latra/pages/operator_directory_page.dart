// lib/latra/pages/operator_directory_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/latra_models.dart';
import '../services/latra_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class OperatorDirectoryPage extends StatefulWidget {
  const OperatorDirectoryPage({super.key});
  @override
  State<OperatorDirectoryPage> createState() => _OperatorDirectoryPageState();
}

class _OperatorDirectoryPageState extends State<OperatorDirectoryPage> {
  List<TransportOperator> _operators = [];
  bool _isLoading = true;
  bool _isSwahili = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load([String? query]) async {
    setState(() => _isLoading = true);
    final r = await LatraService.searchOperators(query: query);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (r.success) _operators = r.items;
    });
    if (!r.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(r.message ??
            (_isSwahili
                ? 'Imeshindwa kupakia waendeshaji'
                : 'Failed to load operators')),
      ));
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'suspended':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(_isSwahili ? 'Waendeshaji' : 'Operators',
            style: const TextStyle(
                color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (q) => _load(q.isNotEmpty ? q : null),
              decoration: InputDecoration(
                hintText: _isSwahili
                    ? 'Tafuta kwa jina au namba...'
                    : 'Search by name or licence...',
                hintStyle: const TextStyle(color: _kSecondary, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: _kSecondary, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _kPrimary))
                : RefreshIndicator(
                    onRefresh: () => _load(),
                    color: _kPrimary,
                    child: _operators.isEmpty
                        ? ListView(children: [
                            const SizedBox(height: 80),
                            Center(
                              child: Text(
                                _isSwahili
                                    ? 'Hakuna waendeshaji'
                                    : 'No operators found',
                                style: const TextStyle(
                                    fontSize: 14, color: _kSecondary),
                              ),
                            ),
                          ])
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _operators.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final op = _operators[i];
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color:
                                            _kPrimary.withValues(alpha: 0.06),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                          Icons.badge_rounded,
                                          color: _kPrimary,
                                          size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(op.name,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: _kPrimary),
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis),
                                          Text(op.licenceNumber,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: _kSecondary)),
                                          if (op.route != null)
                                            Text(op.route!,
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: _kSecondary),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _statusColor(op.status)
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        op.status.toUpperCase(),
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                _statusColor(op.status)),
                                      ),
                                    ),
                                  ],
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
