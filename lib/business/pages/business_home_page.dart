// lib/business/pages/business_home_page.dart
// "My Businesses" — simple list of registered businesses.
// Tap to view/edit. Add new via AddBusinessPage flow.
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/business_models.dart';
import '../services/business_service.dart';
import '../business_notifier.dart';
import 'business_profile_page.dart';
import 'add_business_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class BusinessHomePage extends StatefulWidget {
  final int userId;
  const BusinessHomePage({super.key, required this.userId});

  @override
  State<BusinessHomePage> createState() => _BusinessHomePageState();
}

class _BusinessHomePageState extends State<BusinessHomePage> {
  bool _loading = true;
  List<Business> _businesses = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    if (token == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final res = await BusinessService.getMyBusinesses(token, widget.userId);
    if (mounted) {
      setState(() {
        _loading = false;
        if (res.success) {
          _businesses = res.data;
          // Update notifier
          BusinessNotifier.instance.refresh(widget.userId);
        }
      });
    }
  }

  void _addBusiness() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddBusinessPage(userId: widget.userId)),
    );
    if (result == true && mounted) _loadData();
  }

  void _editBusiness(Business business) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BusinessProfilePage(userId: widget.userId, business: business),
      ),
    );
    if (result == true && mounted) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _businesses.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: _kPrimary,
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _businesses.length + 1, // +1 for add button
                    itemBuilder: (context, index) {
                      if (index == _businesses.length) {
                        return _buildAddButton();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _BusinessCard(
                          business: _businesses[index],
                          onTap: () => _editBusiness(_businesses[index]),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.store_rounded, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'No businesses yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _kPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Register your first business to start managing invoices, customers, payroll, and more.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _kSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _addBusiness,
                icon: const Icon(Icons.add_business_rounded),
                label: const Text('Add Business', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _addBusiness,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE0E0E0), style: BorderStyle.solid),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, color: Colors.grey.shade400, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Add another business',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Business card showing name, type, TIN, license status.
class _BusinessCard extends StatelessWidget {
  final Business business;
  final VoidCallback onTap;

  const _BusinessCard({required this.business, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final b = business;
    final hasLicenseWarning = b.isLicenseExpiringSoon || b.isLicenseExpired;

    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Logo / Initial
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: b.logoUrl != null && b.logoUrl!.isNotEmpty
                    ? Image.network(b.logoUrl!, width: 52, height: 52, fit: BoxFit.cover)
                    : Center(
                        child: Text(
                          b.name.isNotEmpty ? b.name[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _kPrimary),
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      businessTypeLabel(b.type),
                      style: const TextStyle(fontSize: 12, color: _kSecondary),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (b.tinNumber != null && b.tinNumber!.isNotEmpty) ...[
                          Text(
                            'TIN: ${b.tinNumber}',
                            style: const TextStyle(fontSize: 11, color: _kSecondary),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (hasLicenseWarning)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: b.isLicenseExpired
                                  ? Colors.red.withValues(alpha: 0.1)
                                  : Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              b.isLicenseExpired ? 'License expired' : 'License expiring',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: b.isLicenseExpired ? Colors.red : Colors.orange.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _kSecondary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
