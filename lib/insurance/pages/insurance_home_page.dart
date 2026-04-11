// lib/insurance/pages/insurance_home_page.dart
import 'package:flutter/material.dart';
import '../models/insurance_models.dart';
import '../services/insurance_service.dart';
import '../widgets/policy_card.dart';
import '../widgets/product_card.dart';
import 'browse_products_page.dart';
import 'my_policies_page.dart';
import 'my_claims_page.dart';
import 'product_detail_page.dart';
import 'policy_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class InsuranceHomePage extends StatefulWidget {
  final int userId;
  const InsuranceHomePage({super.key, required this.userId});
  @override
  State<InsuranceHomePage> createState() => _InsuranceHomePageState();
}

class _InsuranceHomePageState extends State<InsuranceHomePage> {
  final InsuranceService _service = InsuranceService();

  List<InsurancePolicy> _activePolicies = [];
  List<InsuranceProduct> _recommendations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _service.getMyPolicies(widget.userId),
      _service.getRecommendations(widget.userId),
    ]);
    if (mounted) {
      final policiesResult = results[0] as InsuranceListResult<InsurancePolicy>;
      final recsResult = results[1] as InsuranceListResult<InsuranceProduct>;
      setState(() {
        _isLoading = false;
        if (policiesResult.success) _activePolicies = policiesResult.items.where((p) => p.isActive).toList();
        if (recsResult.success) _recommendations = recsResult.items;
      });
    }
  }

  void _nav(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kPrimary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 10),
                    Text('Tajiri Insurance', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Protect your life, family, assets, and business.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _HeaderStat(value: '${_activePolicies.length}', label: 'Active Policies'),
                    const SizedBox(width: 20),
                    _HeaderStat(
                      value: _activePolicies.where((p) => p.isExpiringSoon).length.toString(),
                      label: 'Expiring Soon',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick actions
          Row(
            children: [
              Expanded(child: _QuickAction(icon: Icons.search_rounded, label: 'Find Insurance', onTap: () => _nav(BrowseProductsPage(userId: widget.userId)))),
              const SizedBox(width: 10),
              Expanded(child: _QuickAction(icon: Icons.shield_rounded, label: 'My Policies', onTap: () => _nav(MyPoliciesPage(userId: widget.userId)))),
              const SizedBox(width: 10),
              Expanded(child: _QuickAction(icon: Icons.receipt_long_rounded, label: 'Claims', onTap: () => _nav(MyClaimsPage(userId: widget.userId)))),
            ],
          ),
          const SizedBox(height: 20),

          // Insurance categories grid
          const Text('Insurance Types', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 8, crossAxisSpacing: 8,
            childAspectRatio: 0.85,
            children: [
              _CategoryTile(cat: InsuranceCategory.health, onTap: () => _nav(BrowseProductsPage(userId: widget.userId, initialCategory: InsuranceCategory.health))),
              _CategoryTile(cat: InsuranceCategory.life, onTap: () => _nav(BrowseProductsPage(userId: widget.userId, initialCategory: InsuranceCategory.life))),
              _CategoryTile(cat: InsuranceCategory.motor, onTap: () => _nav(BrowseProductsPage(userId: widget.userId, initialCategory: InsuranceCategory.motor))),
              _CategoryTile(cat: InsuranceCategory.property, onTap: () => _nav(BrowseProductsPage(userId: widget.userId, initialCategory: InsuranceCategory.property))),
              _CategoryTile(cat: InsuranceCategory.travel, onTap: () => _nav(BrowseProductsPage(userId: widget.userId, initialCategory: InsuranceCategory.travel))),
              _CategoryTile(cat: InsuranceCategory.micro, onTap: () => _nav(BrowseProductsPage(userId: widget.userId, initialCategory: InsuranceCategory.micro))),
              _CategoryTile(cat: InsuranceCategory.device, onTap: () => _nav(BrowseProductsPage(userId: widget.userId, initialCategory: InsuranceCategory.device))),
              _CategoryTile(cat: InsuranceCategory.business, onTap: () => _nav(BrowseProductsPage(userId: widget.userId, initialCategory: InsuranceCategory.business))),
            ],
          ),
          const SizedBox(height: 20),

          // Active policies
          if (_activePolicies.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('My Policies', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                GestureDetector(
                  onTap: () => _nav(MyPoliciesPage(userId: widget.userId)),
                  child: const Text('All', style: TextStyle(fontSize: 13, color: _kSecondary)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._activePolicies.take(3).map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PolicyCard(policy: p, onTap: () => _nav(PolicyDetailPage(userId: widget.userId, policy: p))),
                )),
            const SizedBox(height: 16),
          ],

          // Cross-module recommendations
          if (_recommendations.isNotEmpty) ...[
            const Text('Recommended for You', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 4),
            const Text(
              'Based on your activity on Tajiri',
              style: TextStyle(fontSize: 12, color: _kSecondary),
            ),
            const SizedBox(height: 10),
            ..._recommendations.take(3).map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InsuranceProductCard(product: p, onTap: () => _nav(ProductDetailPage(userId: widget.userId, product: p))),
                )),
          ],

          // Cross-module links
          const SizedBox(height: 16),
          const Text('Insurance for Tajiri Services', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
          const SizedBox(height: 10),
          _CrossModuleLink(
            icon: Icons.medical_services_rounded,
            label: 'Health Insurance',
            description: 'Cover doctor consultations and medicine — from TZS 5,000/month',
            module: 'Doctor',
            onTap: () => _nav(BrowseProductsPage(userId: widget.userId, initialCategory: InsuranceCategory.health)),
          ),
          _CrossModuleLink(
            icon: Icons.shield_rounded,
            label: 'Loan Insurance',
            description: 'Protect your TAJIRI Boost loan — payments with coverage',
            module: 'Loans',
            onTap: () => _nav(BrowseProductsPage(userId: widget.userId, initialCategory: InsuranceCategory.creditLife)),
          ),
          _CrossModuleLink(
            icon: Icons.shopping_bag_rounded,
            label: 'Buyer Protection',
            description: 'Insurance for products purchased on Tajiri Shop',
            module: 'Shop',
            onTap: () => _nav(BrowseProductsPage(userId: widget.userId, initialCategory: InsuranceCategory.buyerProtection)),
          ),
          _CrossModuleLink(
            icon: Icons.savings_rounded,
            label: 'Kikoba Insurance',
            description: 'Cover all members of your savings group — group insurance',
            module: 'Kikoba',
            onTap: () => _nav(BrowseProductsPage(userId: widget.userId, initialCategory: InsuranceCategory.life)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String value;
  final String label;
  const _HeaderStat({required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg, borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.08), shape: BoxShape.circle),
                child: Icon(icon, size: 22, color: _kPrimary),
              ),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final InsuranceCategory cat;
  final VoidCallback onTap;
  const _CategoryTile({required this.cat, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg, borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(cat.icon, size: 28, color: _kPrimary),
            const SizedBox(height: 6),
            Text(cat.displayName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _kPrimary)),
          ],
        ),
      ),
    );
  }
}

class _CrossModuleLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final String module;
  final VoidCallback onTap;
  const _CrossModuleLink({required this.icon, required this.label, required this.description, required this.module, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: _kCardBg, borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap, borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, size: 20, color: _kPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                      Text(description, style: const TextStyle(fontSize: 11, color: _kSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(6)),
                  child: Text(module, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kPrimary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
