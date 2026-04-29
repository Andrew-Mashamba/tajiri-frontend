import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_strings_scope.dart';
import '../models/shared_cart.dart';
import '../services/shared_cart_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBorder = Color(0xFFEEEEEE);

/// Spec line 234 — group / shared cart for office lunches and family compounds.
/// One owner creates a cart, peers add items via the shareable link, owner pays
/// the lump sum. Settlement among friends is intentionally out of scope.
class SharedCartPage extends StatefulWidget {
  /// Pass an existing token to view a cart, or null to auto-create one.
  final String? token;
  final int currentUserId;
  const SharedCartPage({
    super.key,
    required this.currentUserId,
    this.token,
  });

  @override
  State<SharedCartPage> createState() => _SharedCartPageState();
}

class _SharedCartPageState extends State<SharedCartPage> {
  bool _loading = true;
  String? _error;
  SharedCart? _cart;
  List<SharedCartItem> _items = const [];

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;
  bool get _isOwner =>
      _cart != null && _cart!.ownerUserId == widget.currentUserId;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (widget.token != null) {
      await _load(widget.token!);
      return;
    }
    final created = await SharedCartService.create(
      ownerUserId: widget.currentUserId,
    );
    if (!mounted) return;
    if (created == null) {
      setState(() {
        _loading = false;
        _error = _isSwahili ? 'Imeshindikana kutengeneza' : 'Could not create cart';
      });
      return;
    }
    await _load(created.token);
  }

  Future<void> _load(String token) async {
    setState(() => _loading = true);
    final res = await SharedCartService.show(token);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res == null) {
        _error = _isSwahili ? 'Cart haijapatikana' : 'Cart not found';
      } else {
        _cart = res.cart;
        _items = res.items;
        _error = null;
      }
    });
  }

  Future<void> _shareLink() async {
    if (_cart == null) return;
    final isSw = _isSwahili;
    await SharePlus.instance.share(
      ShareParams(
        text: isSw
            ? 'Jiunge kwenye agizo letu la pamoja: ${_cart!.shareUrl}'
            : 'Join our shared order: ${_cart!.shareUrl}',
        subject: isSw ? 'Agizo la pamoja la TAJIRI' : 'TAJIRI shared order',
      ),
    );
  }

  Future<void> _copyLink() async {
    if (_cart == null) return;
    await Clipboard.setData(ClipboardData(text: _cart!.shareUrl));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_isSwahili ? 'Imenakiliwa' : 'Link copied'),
    ));
  }

  Future<void> _removeItem(SharedCartItem item) async {
    if (_cart == null) return;
    final ok = await SharedCartService.removeItem(
      token: _cart!.token,
      itemId: item.id,
    );
    if (!mounted) return;
    if (ok) {
      _load(_cart!.token);
    }
  }

  Future<void> _settle() async {
    if (_cart == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await SharedCartService.settle(_cart!.token);
    if (!mounted) return;
    if (ok) {
      messenger.showSnackBar(SnackBar(
        content: Text(_isSwahili
            ? 'Imehitimishwa. Lipa kupitia M-Pesa.'
            : 'Settled. Pay via M-Pesa.'),
      ));
      _load(_cart!.token);
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(_isSwahili ? 'Imeshindikana' : 'Failed'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    return Scaffold(
      appBar: AppBar(
        title: Text(isSw ? 'Cart ya Pamoja' : 'Shared Cart'),
        actions: [
          if (_cart != null) ...[
            IconButton(
              tooltip: isSw ? 'Nakili kiungo' : 'Copy link',
              icon: const Icon(Icons.link_rounded),
              onPressed: _copyLink,
            ),
            IconButton(
              tooltip: isSw ? 'Shiriki' : 'Share',
              icon: const Icon(Icons.share_rounded),
              onPressed: _shareLink,
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _error != null
              ? Center(child: Text(_error!))
              : _buildBody(),
      bottomNavigationBar: _cart == null ? null : _bottomBar(),
    );
  }

  Widget _buildBody() {
    final cart = _cart!;
    final fmt = NumberFormat('#,##0');
    return RefreshIndicator(
      onRefresh: () => _load(cart.token),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFF0D47A1).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSwahili ? 'Kiungo cha kushiriki' : 'Share link',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D47A1),
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  cart.shareUrl,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isSwahili
                      ? 'Tuma kwa marafiki ili waongeze vitu vyao.'
                      : 'Send to friends so they can add their items.',
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xFF666666)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  _isSwahili ? 'Hakuna vitu bado' : 'No items yet',
                  style: const TextStyle(color: _kSecondary),
                ),
              ),
            )
          else
            ..._items.map((i) => _itemRow(i, fmt)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _kBorder),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _isSwahili ? 'Jumla' : 'Total',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _kPrimary,
                    ),
                  ),
                ),
                Text(
                  'TZS ${fmt.format(cart.totalTzs)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemRow(SharedCartItem item, NumberFormat fmt) {
    final canRemove =
        item.userId == widget.currentUserId || _isOwner;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.quantity} × ${item.productTitle ?? '—'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.userName != null && item.userName!.isNotEmpty)
                  Text(
                    _isSwahili
                        ? 'Ameongezwa na ${item.userName}'
                        : 'Added by ${item.userName}',
                    style:
                        const TextStyle(fontSize: 10, color: _kSecondary),
                  ),
                if (item.notes != null && item.notes!.isNotEmpty)
                  Text(
                    item.notes!,
                    style: const TextStyle(
                        fontSize: 10, color: _kSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            'TZS ${fmt.format(item.lineTotal)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _kPrimary,
            ),
          ),
          if (canRemove)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline_rounded,
                  size: 18, color: Color(0xFFB71C1C)),
              onPressed: () => _removeItem(item),
              tooltip: _isSwahili ? 'Toa' : 'Remove',
            ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    final isSw = _isSwahili;
    final canSettle = _isOwner && _cart!.status == 'open' && _items.isNotEmpty;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ElevatedButton.icon(
          onPressed: canSettle ? _settle : null,
          icon: const Icon(Icons.payments_rounded, size: 18),
          label: Text(
            _cart!.status == 'settled'
                ? (isSw ? 'Imelipwa' : 'Settled')
                : (isSw ? 'Maliza & lipa' : 'Settle & pay'),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ),
    );
  }
}
