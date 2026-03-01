import 'package:flutter/material.dart';
import '../../models/subscription_models.dart';
import '../../services/subscription_service.dart';

/// Creator subscription tiers setup (Story 64).
/// Navigation: Creator profile → Tajiri Pay (Wallet) → Viwango vya Usajili.
class SubscriptionTiersSetupScreen extends StatefulWidget {
  final int creatorId;

  const SubscriptionTiersSetupScreen({super.key, required this.creatorId});

  @override
  State<SubscriptionTiersSetupScreen> createState() =>
      _SubscriptionTiersSetupScreenState();
}

class _SubscriptionTiersSetupScreenState
    extends State<SubscriptionTiersSetupScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  List<SubscriptionTier> _tiers = [];
  bool _isLoading = true;
  String? _errorMessage;

  static const Color _bg = Color(0xFFFAFAFA);
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondary = Color(0xFF666666);
  static const Color _accent = Color(0xFF999999);

  @override
  void initState() {
    super.initState();
    _loadTiers();
  }

  Future<void> _loadTiers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result =
        await _subscriptionService.getCreatorTiers(widget.creatorId);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) {
        _tiers = result.tiers;
      } else {
        _errorMessage = result.message ?? 'Imeshindwa kupakia viwango';
      }
    });
  }

  void _openCreateTier() {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _CreateEditTierScreen(
          creatorId: widget.creatorId,
          tier: null,
        ),
      ),
    ).then((refreshed) {
      if (refreshed == true) _loadTiers();
    });
  }

  void _openEditTier(SubscriptionTier tier) {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _CreateEditTierScreen(
          creatorId: widget.creatorId,
          tier: tier,
        ),
      ),
    ).then((refreshed) {
      if (refreshed == true) _loadTiers();
    });
  }

  Future<void> _deleteTier(SubscriptionTier tier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Futa Kiwango'),
        content: Text(
          'Una uhakika unataka kufuta kiwango "${tier.name}"? Wasajili waliopo hawatakiwa tena.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ghairi'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Futa'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await _subscriptionService.deleteTier(
      userId: widget.creatorId,
      tierId: tier.id,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kiwango kimefutwa')),
      );
      _loadTiers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imeshindwa kufuta kiwango')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Viwango vya Usajili',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _primary,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadTiers,
            tooltip: 'Onyesha upya',
            style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : _errorMessage != null
                ? _buildErrorState()
                : RefreshIndicator(
                    onRefresh: _loadTiers,
                    color: _primary,
                    child: _tiers.isEmpty
                        ? _buildEmptyState()
                        : _buildTiersList(),
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'subscription_tiers_fab',
        onPressed: _openCreateTier,
        backgroundColor: _primary,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: _accent),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: _primary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: TextButton(
                onPressed: _loadTiers,
                child: const Text('Jaribu tena'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 48),
            Icon(Icons.star_outline, size: 64, color: _accent),
            const SizedBox(height: 16),
            const Text(
              'Hakuna viwango bado',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ongeza viwango vya usajili na faida kwa wafuasi wako.',
              style: const TextStyle(fontSize: 12, color: _secondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildPrimaryButton(
              label: 'Ongeza Kiwango cha Kwanza',
              onPressed: _openCreateTier,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTiersList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: _tiers.length,
      itemBuilder: (context, index) {
        final tier = _tiers[index];
        return _TierCard(
          tier: tier,
          onTap: () => _openEditTier(tier),
          onDelete: () => _deleteTier(tier),
        );
      },
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 72, maxHeight: 80),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  final SubscriptionTier tier;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TierCard({
    required this.tier,
    required this.onTap,
    required this.onDelete,
  });

  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondary = Color(0xFF666666);
  static const Color _accent = Color(0xFF999999);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tier.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    Text(
                      tier.priceFormatted,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tier.periodLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _secondary,
                      ),
                    ),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.more_vert, color: _primary),
                      onSelected: (value) {
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Futa kiwango'),
                        ),
                      ],
                    ),
                  ],
                ),
                if (tier.description != null &&
                    tier.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    tier.description!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _secondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
                if (tier.benefits != null && tier.benefits!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: tier.benefits!
                        .take(3)
                        .map(
                          (b) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _accent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              b,
                              style: const TextStyle(
                                fontSize: 11,
                                color: _primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (tier.subscriberCount > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Wasajili: ${tier.subscriberCount}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: _secondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Create or edit a subscription tier.
class _CreateEditTierScreen extends StatefulWidget {
  final int creatorId;
  final SubscriptionTier? tier;

  const _CreateEditTierScreen({
    required this.creatorId,
    this.tier,
  });

  @override
  State<_CreateEditTierScreen> createState() => _CreateEditTierScreenState();
}

class _CreateEditTierScreenState extends State<_CreateEditTierScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final List<TextEditingController> _benefitControllers = [];
  final SubscriptionService _subscriptionService = SubscriptionService();

  String _billingPeriod = 'monthly';
  bool _isLoading = false;

  static const Color _bg = Color(0xFFFAFAFA);
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondary = Color(0xFF666666);
  static const Color _accent = Color(0xFF999999);

  bool get _isEdit => widget.tier != null;

  @override
  void initState() {
    super.initState();
    if (widget.tier != null) {
      final t = widget.tier!;
      _nameController.text = t.name;
      _descriptionController.text = t.description ?? '';
      _priceController.text = t.price.toStringAsFixed(0);
      _billingPeriod = t.billingPeriod;
      for (final b in t.benefits ?? []) {
        final c = TextEditingController(text: b);
        _benefitControllers.add(c);
      }
    }
    if (_benefitControllers.isEmpty) {
      _benefitControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    for (final c in _benefitControllers) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _getBenefits() {
    return _benefitControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceController.text);
    if (price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingiza bei sahihi')),
      );
      return;
    }

    setState(() => _isLoading = true);

    if (_isEdit) {
      final result = await _subscriptionService.updateTier(
        userId: widget.creatorId,
        tierId: widget.tier!.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        price: price,
        benefits: _getBenefits(),
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kiwango kimebadilishwa')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Imeshindwa')),
        );
      }
    } else {
      final result = await _subscriptionService.createTier(
        userId: widget.creatorId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        price: price,
        billingPeriod: _billingPeriod,
        benefits: _getBenefits().isEmpty ? null : _getBenefits(),
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kiwango kimeundwa')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Imeshindwa')),
        );
      }
    }
  }

  void _addBenefit() {
    setState(() => _benefitControllers.add(TextEditingController()));
  }

  void _removeBenefit(int index) {
    if (_benefitControllers.length <= 1) return;
    setState(() {
      _benefitControllers[index].dispose();
      _benefitControllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Hariri Kiwango' : 'Ongeza Kiwango',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _primary,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Jina la kiwango',
                    hintText: 'mf. Mwanachama wa Kawaida',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  style: const TextStyle(fontSize: 14, color: _primary),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Ingiza jina';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Maelezo (hiari)',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  style: const TextStyle(fontSize: 14, color: _primary),
                  maxLines: 2,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Bei (TZS)',
                    border: OutlineInputBorder(),
                    prefixText: 'TZS ',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  style: const TextStyle(fontSize: 14, color: _primary),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Ingiza bei';
                    }
                    final n = double.tryParse(v);
                    if (n == null || n < 0) return 'Ingiza nambari sahihi';
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _billingPeriod,
                  decoration: const InputDecoration(
                    labelText: 'Muda wa malipo',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'monthly',
                      child: Text('Kwa mwezi'),
                    ),
                    DropdownMenuItem(
                      value: 'yearly',
                      child: Text('Kwa mwaka'),
                    ),
                  ],
                  onChanged: _isEdit
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _billingPeriod = value);
                          }
                        },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text(
                      'Faida',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(hiari)',
                      style: TextStyle(
                        fontSize: 12,
                        color: _secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...List.generate(
                  _benefitControllers.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _benefitControllers[index],
                            decoration: const InputDecoration(
                              hintText: 'Faida',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            style: const TextStyle(fontSize: 14, color: _primary),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _removeBenefit(index),
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: Icon(
                                Icons.remove_circle_outline,
                                color: _accent,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 2,
                  shadowColor: Colors.black.withOpacity(0.1),
                  child: InkWell(
                    onTap: _addBenefit,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.add, color: _primary, size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            'Ongeza faida',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 72, maxHeight: 80),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    elevation: 2,
                    shadowColor: Colors.black.withOpacity(0.1),
                    child: InkWell(
                      onTap: _isLoading ? null : _submit,
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _primary,
                                ),
                              )
                            : Text(
                                _isEdit ? 'Hifadhi' : 'Undwa Kiwango',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _primary,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
