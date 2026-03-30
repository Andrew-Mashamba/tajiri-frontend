import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/subscription_models.dart';
import '../../models/wallet_models.dart';
import '../../services/biometric_service.dart';
import '../../services/subscription_service.dart';
import '../../services/wallet_service.dart';

class SubscribeToCreatorScreen extends StatefulWidget {
  final int creatorId;
  final int currentUserId;
  final String? creatorDisplayName;

  const SubscribeToCreatorScreen({
    super.key,
    required this.creatorId,
    required this.currentUserId,
    this.creatorDisplayName,
  });

  @override
  State<SubscribeToCreatorScreen> createState() =>
      _SubscribeToCreatorScreenState();
}

class _SubscribeToCreatorScreenState extends State<SubscribeToCreatorScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final WalletService _walletService = WalletService();

  List<SubscriptionTier> _tiers = [];
  Wallet? _wallet;
  bool _isLoading = true;
  bool _isSubscribed = false;
  String? _error;
  SubscriptionTier? _selectedTier;
  final TextEditingController _pinController = TextEditingController();
  bool _isSubmitting = false;

  static const Color _bg = Color(0xFFFAFAFA);
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondary = Color(0xFF666666);
  static const Color _accent = Color(0xFF999999);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final tierResult =
        await _subscriptionService.getCreatorTiers(widget.creatorId);
    final walletResult = await _walletService.getWallet(widget.currentUserId);
    final subscribed =
        await _subscriptionService.isSubscribed(
            userId: widget.currentUserId, creatorId: widget.creatorId);

    if (!mounted) return;
    final s = AppStringsScope.of(context);
    setState(() {
      _isLoading = false;
      if (tierResult.success) {
        _tiers = tierResult.tiers.where((t) => t.isActive).toList();
      } else {
        _error = tierResult.message ?? s?.loadingTiersFailed ?? 'Failed to load tiers';
      }
      if (walletResult.success) _wallet = walletResult.wallet;
      _isSubscribed = subscribed;
    });
  }

  Future<void> _subscribe() async {
    final authorized = await BiometricService.authenticate(
      reason: 'Thibitisha ili kujisajili',
    );
    if (!authorized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uthibitisho umeshindwa')),
        );
      }
      return;
    }

    final s = AppStringsScope.of(context);
    if (_selectedTier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s?.chooseTier ?? 'Choose subscription tier')),
      );
      return;
    }

    final pin = _pinController.text.trim();
    if (pin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s?.enterWalletPin ?? 'Enter wallet PIN (4 digits)')),
      );
      return;
    }

    final balance = _wallet?.balance ?? 0;
    if (balance < _selectedTier!.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s?.insufficientBalance ?? 'Insufficient wallet balance. Top up first.')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isSubmitting = true);

    final result = await _subscriptionService.subscribe(
      userId: widget.currentUserId,
      tierId: _selectedTier!.id,
      paymentMethod: 'wallet',
      pin: pin,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      if (mounted) {
        final successS = AppStringsScope.of(context);
        final creatorName = widget.creatorDisplayName ?? (successS?.creator ?? 'creator');
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              successS?.subscriptionSuccessMessage(creatorName) ??
                  'Successfully subscribed. You now have access to exclusive content from $creatorName.',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } else {
      if (mounted) {
        final failS = AppStringsScope.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? failS?.subscriptionFailed ?? 'Failed to subscribe')),
        );
      }
    }
  }

  void _showPinDialog() {
    _pinController.clear();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final dialogS = AppStringsScope.of(ctx);
        return SafeArea(
          child: Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  dialogS?.confirmWithPin ?? 'Confirm with PIN',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'TZS ${_selectedTier!.price.toStringAsFixed(0)} ${_selectedTier!.periodLabel}',
                  style: const TextStyle(fontSize: 14, color: _secondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: dialogS?.pinFourDigits ?? 'PIN (4 digits)',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 56,
                  child: Material(
                    color: _primary,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _subscribe();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                dialogS?.payWithWallet ?? 'Pay with Wallet',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
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

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final name =
        widget.creatorDisplayName?.isNotEmpty == true
            ? widget.creatorDisplayName!
            : (s?.creator ?? 'Creator');

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(s?.subscribeToCreator ?? 'Subscribe to Creator'),
        backgroundColor: Colors.white,
        foregroundColor: _primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: _primary),
              )
            : _error != null
                ? _buildErrorState()
                : _isSubscribed
                    ? _buildAlreadySubscribed()
                    : _tiers.isEmpty
                        ? _buildNoTiers(name)
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            color: _primary,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: _primary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    s?.chooseTierAndPay ?? 'Choose a tier and pay with wallet. You will access exclusive content.',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: _secondary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (_wallet != null) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      '${s?.balance ?? 'Balance'}: ${_wallet!.balanceFormatted}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: _secondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ],
                                  const SizedBox(height: 24),
                                  ..._tiers.map((tier) => _buildTierCard(tier)),
                                  if (_selectedTier != null) ...[
                                    const SizedBox(height: 16),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        minHeight: 72,
                                        maxHeight: 80,
                                      ),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: Material(
                                        color: _primary,
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        child: InkWell(
                                          onTap: (_wallet?.balance ?? 0) >=
                                                  _selectedTier!.price
                                              ? _showPinDialog
                                              : null,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: Center(
                                            child: Text(
                                              s?.payWithWallet ?? 'Pay with Wallet',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    ),
                                  ],
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
      ),
    );
  }

  Widget _buildErrorState() {
    final s = AppStringsScope.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: _accent),
            const SizedBox(height: 16),
            Text(
              _error ?? s?.loadingFailed ?? 'Failed to load',
              style: const TextStyle(color: _primary, fontSize: 14),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: TextButton(
                onPressed: _loadData,
                child: Text(s?.retry ?? 'Try again'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlreadySubscribed() {
    final s = AppStringsScope.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, size: 40, color: _primary),
            ),
            const SizedBox(height: 16),
            Text(
              s?.alreadySubscribed ?? 'Already subscribed',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              s?.alreadySubscribedMessage ?? 'You have access to this creator\'s exclusive content.',
              style: const TextStyle(fontSize: 12, color: _secondary),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoTiers(String name) {
    final s = AppStringsScope.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_membership, size: 48, color: _accent),
            const SizedBox(height: 16),
            Text(
              s?.noTiersYet(name) ?? '$name hasn\'t set up subscription tiers yet.',
              style: const TextStyle(color: _primary, fontSize: 14),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard(SubscriptionTier tier) {
    final s = AppStringsScope.of(context);
    final isSelected = _selectedTier?.id == tier.id;
    final canAfford = (_wallet?.balance ?? 0) >= tier.price;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          onTap: tier.isActive
              ? () => setState(() => _selectedTier = tier)
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: _primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tier.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (tier.description != null &&
                          tier.description!.isNotEmpty)
                        Text(
                          tier.description!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _secondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        '${tier.priceFormatted} ${tier.periodLabel}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: _primary, size: 24),
                if (!canAfford && !isSelected)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      s?.balanceInsufficient ?? 'Insufficient balance',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red.shade700,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
