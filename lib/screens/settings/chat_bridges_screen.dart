// Chat Bridges settings screen — manage connections to external chat platforms
// (Matrix, RCS, SMS, Email). Design: monochromatic (#1A1A1A primary, #FAFAFA bg).

import 'package:flutter/material.dart';
import '../../services/chat_interop_service.dart';
import '../../widgets/tajiri_app_bar.dart';

class ChatBridgesScreen extends StatefulWidget {
  final int currentUserId;
  const ChatBridgesScreen({super.key, required this.currentUserId});

  @override
  State<ChatBridgesScreen> createState() => _ChatBridgesScreenState();
}

class _ChatBridgesScreenState extends State<ChatBridgesScreen> {
  static const _primaryText = Color(0xFF1A1A1A);
  static const _secondaryText = Color(0xFF666666);
  static const _backgroundColor = Color(0xFFFAFAFA);
  static const _cardBackground = Color(0xFFFFFFFF);
  static const _iconBackground = Color(0xFF1A1A1A);

  List<BridgeInfo> _bridges = [];
  bool _isLoading = true;
  String? _error;

  /// Local toggle state tracking while API calls are in flight.
  final Map<String, bool> _connectingBridges = {};

  @override
  void initState() {
    super.initState();
    _loadBridges();
  }

  Future<void> _loadBridges() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final bridges = await ChatInteropService.getAvailableBridges();
      if (mounted) {
        setState(() {
          _bridges = bridges;
          _isLoading = false;
          // If backend returned no bridges, show the default set as unconnected
          if (_bridges.isEmpty) {
            _bridges = _defaultBridges();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Imeshindwa kupakia madaraja';
          _bridges = _defaultBridges();
        });
      }
    }
  }

  List<BridgeInfo> _defaultBridges() {
    return [
      BridgeInfo(bridgeType: 'matrix', displayName: 'Matrix Protocol', isConnected: false, status: 'available'),
      BridgeInfo(bridgeType: 'rcs', displayName: 'RCS Messaging', isConnected: false, status: 'available'),
      BridgeInfo(bridgeType: 'sms', displayName: 'SMS', isConnected: false, status: 'available'),
      BridgeInfo(bridgeType: 'email', displayName: 'Barua pepe', isConnected: false, status: 'available'),
    ];
  }

  IconData _bridgeIcon(String bridgeType) {
    switch (bridgeType) {
      case 'matrix':
        return Icons.grid_view_rounded;
      case 'rcs':
        return Icons.sms_rounded;
      case 'sms':
        return Icons.message_rounded;
      case 'email':
        return Icons.email_rounded;
      default:
        return Icons.link_rounded;
    }
  }

  String _bridgeDisplayName(BridgeInfo bridge) {
    if (bridge.displayName.isNotEmpty) return bridge.displayName;
    switch (bridge.bridgeType) {
      case 'matrix':
        return 'Matrix Protocol';
      case 'rcs':
        return 'RCS Messaging';
      case 'sms':
        return 'SMS';
      case 'email':
        return 'Barua pepe';
      default:
        return bridge.bridgeType;
    }
  }

  Future<void> _toggleBridge(BridgeInfo bridge) async {
    if (_connectingBridges[bridge.bridgeType] == true) return;

    if (bridge.isConnected) {
      // Disconnect
      setState(() => _connectingBridges[bridge.bridgeType] = true);
      final ok = await ChatInteropService.disconnectBridge(bridge.bridgeType);
      if (mounted) {
        setState(() => _connectingBridges.remove(bridge.bridgeType));
        if (ok) {
          await _loadBridges();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Imeshindwa kukata muunganisho')),
          );
        }
      }
    } else {
      // Connect — show credentials dialog based on bridge type
      _showConnectSheet(bridge);
    }
  }

  void _showConnectSheet(BridgeInfo bridge) {
    switch (bridge.bridgeType) {
      case 'matrix':
        _showMatrixConnectSheet(bridge);
        break;
      case 'rcs':
        _showGenericConnectSheet(bridge, fields: ['Nambari ya simu']);
        break;
      case 'sms':
        _showGenericConnectSheet(bridge, fields: ['Nambari ya simu']);
        break;
      case 'email':
        _showGenericConnectSheet(bridge, fields: ['Barua pepe', 'Nenosiri']);
        break;
      default:
        _showGenericConnectSheet(bridge, fields: ['ID']);
    }
  }

  void _showMatrixConnectSheet(BridgeInfo bridge) {
    final homeserverController = TextEditingController(text: 'https://matrix.org');
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    bool connecting = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _secondaryText.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _iconBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Unganisha Matrix',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: homeserverController,
                label: 'Homeserver URL',
                hint: 'https://matrix.org',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: usernameController,
                label: 'Jina la mtumiaji',
                hint: '@mtumiaji:matrix.org',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: passwordController,
                label: 'Nenosiri',
                hint: 'Nenosiri lako',
                obscure: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: connecting
                      ? null
                      : () async {
                          if (usernameController.text.trim().isEmpty ||
                              passwordController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Jaza sehemu zote')),
                            );
                            return;
                          }
                          setSheetState(() => connecting = true);
                          final ok = await ChatInteropService.connectBridge(
                            bridgeType: 'matrix',
                            credentials: {
                              'homeserver': homeserverController.text.trim(),
                              'username': usernameController.text.trim(),
                              'password': passwordController.text.trim(),
                            },
                          );
                          setSheetState(() => connecting = false);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            if (ok) {
                              _loadBridges();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Matrix imeunganishwa')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Imeshindwa kuunganisha Matrix')),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryText,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: connecting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Unganisha',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGenericConnectSheet(BridgeInfo bridge, {required List<String> fields}) {
    final controllers = List.generate(fields.length, (_) => TextEditingController());
    bool connecting = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _secondaryText.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _iconBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_bridgeIcon(bridge.bridgeType), color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Unganisha ${_bridgeDisplayName(bridge)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              for (int i = 0; i < fields.length; i++) ...[
                _buildTextField(
                  controller: controllers[i],
                  label: fields[i],
                  hint: fields[i],
                  obscure: fields[i].toLowerCase().contains('nenosiri') ||
                      fields[i].toLowerCase().contains('password'),
                ),
                if (i < fields.length - 1) const SizedBox(height: 12),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: connecting
                      ? null
                      : () async {
                          final allFilled = controllers.every(
                            (c) => c.text.trim().isNotEmpty,
                          );
                          if (!allFilled) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Jaza sehemu zote')),
                            );
                            return;
                          }
                          setSheetState(() => connecting = true);
                          final creds = <String, dynamic>{};
                          for (int i = 0; i < fields.length; i++) {
                            creds[fields[i].toLowerCase().replaceAll(' ', '_')] =
                                controllers[i].text.trim();
                          }
                          final ok = await ChatInteropService.connectBridge(
                            bridgeType: bridge.bridgeType,
                            credentials: creds,
                          );
                          setSheetState(() => connecting = false);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            if (ok) {
                              _loadBridges();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${_bridgeDisplayName(bridge)} imeunganishwa',
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Imeshindwa kuunganisha ${_bridgeDisplayName(bridge)}',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryText,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: connecting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Unganisha',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 15, color: _primaryText),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: _secondaryText, fontSize: 14),
        hintStyle: TextStyle(color: _secondaryText.withValues(alpha: 0.5), fontSize: 14),
        filled: true,
        fillColor: _backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: const TajiriAppBar(
        title: 'Madaraja ya mazungumzo',
        backgroundColor: _cardBackground,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: _primaryText),
              )
            : RefreshIndicator(
                onRefresh: _loadBridges,
                color: _primaryText,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header description
                      const Text(
                        'Unganisha akaunti zako za mazungumzo ya nje kupitia madaraja. '
                        'Ujumbe kutoka Matrix, RCS, SMS na barua pepe utaonekana '
                        'kwenye mazungumzo yako ya Tajiri.',
                        style: TextStyle(
                          fontSize: 13,
                          color: _secondaryText,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.red, fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Bridge cards
                      ..._bridges.map(_buildBridgeCard),
                      const SizedBox(height: 32),
                      // Info footer
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _secondaryText.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 20,
                              color: _secondaryText.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Madaraja ya mazungumzo yanakuruhusu kupokea na kutuma '
                                'ujumbe kupitia mifumo ya nje bila kuacha Tajiri. '
                                'Taarifa zako za kuingia zinahifadhiwa kwa usalama.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _secondaryText,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildBridgeCard(BridgeInfo bridge) {
    final isConnecting = _connectingBridges[bridge.bridgeType] == true;
    final connected = bridge.isConnected;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _iconBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _bridgeIcon(bridge.bridgeType),
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
                        _bridgeDisplayName(bridge),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _primaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        connected ? 'Imeunganishwa' : 'Haijaunganishwa',
                        style: TextStyle(
                          fontSize: 12,
                          color: connected
                              ? const Color(0xFF25D366)
                              : _secondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (connected && bridge.externalUserId != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          bridge.externalUserId!,
                          style: TextStyle(
                            fontSize: 11,
                            color: _secondaryText.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (isConnecting)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _primaryText,
                    ),
                  )
                else
                  Switch(
                    value: connected,
                    onChanged: (_) => _toggleBridge(bridge),
                    activeTrackColor: _primaryText.withValues(alpha: 0.5),
                    activeThumbColor: _primaryText,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
