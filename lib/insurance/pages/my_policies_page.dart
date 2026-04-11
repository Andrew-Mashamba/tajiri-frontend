// lib/insurance/pages/my_policies_page.dart
import 'package:flutter/material.dart';
import '../models/insurance_models.dart';
import '../services/insurance_service.dart';
import '../widgets/policy_card.dart';
import 'policy_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);

class MyPoliciesPage extends StatefulWidget {
  final int userId;
  const MyPoliciesPage({super.key, required this.userId});
  @override
  State<MyPoliciesPage> createState() => _MyPoliciesPageState();
}

class _MyPoliciesPageState extends State<MyPoliciesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final InsuranceService _service = InsuranceService();
  List<InsurancePolicy> _all = [];
  bool _isLoading = true;

  List<InsurancePolicy> get _active => _all.where((p) => p.isActive).toList();
  List<InsurancePolicy> get _inactive => _all.where((p) => !p.isActive).toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final result = await _service.getMyPolicies(widget.userId);
    if (mounted) setState(() { _isLoading = false; if (result.success) _all = result.items; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, scrolledUnderElevation: 1,
        title: const Text('Bima Zangu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController, labelColor: _kPrimary, unselectedLabelColor: _kSecondary, indicatorColor: _kPrimary,
          tabs: [Tab(text: 'Hai (${_active.length})'), Tab(text: 'Zingine (${_inactive.length})')],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : TabBarView(controller: _tabController, children: [_buildList(_active), _buildList(_inactive)]),
    );
  }

  Widget _buildList(List<InsurancePolicy> policies) {
    if (policies.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Hakuna bima', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
        ],
      ));
    }
    return RefreshIndicator(
      onRefresh: _load, color: _kPrimary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16), itemCount: policies.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: PolicyCard(
            policy: policies[i],
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => PolicyDetailPage(userId: widget.userId, policy: policies[i]),
            )).then((_) { if (mounted) _load(); }),
          ),
        ),
      ),
    );
  }
}
