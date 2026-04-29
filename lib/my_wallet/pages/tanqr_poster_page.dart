import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/message_models.dart';
import '../../models/tajiri_pay_qr_models.dart';
import '../../services/message_service.dart';

class TanQrPosterPage extends StatefulWidget {
  final TajiriPayQrCode code;
  const TanQrPosterPage({super.key, required this.code});

  @override
  State<TanQrPosterPage> createState() => _TanQrPosterPageState();
}

class _TanQrPosterPageState extends State<TanQrPosterPage> {
  static const Color _kPrimary = Color(0xFF1A1A1A);
  static const Color _kSecondary = Color(0xFF666666);
  static const Color _kBackground = Color(0xFFFAFAFA);
  final GlobalKey _posterKey = GlobalKey();
  bool _isExporting = false;
  final MessageService _messageService = MessageService();

  bool get _isPaymentQr =>
      widget.code.sourceType == 'shop' || widget.code.sourceType == 'business';

  bool get _isContactQr => widget.code.sourceType == 'user_contact';

  String get _posterTitle {
    if (_isPaymentQr) return 'TANQR Poster';
    if (_isContactQr) return 'Contact QR Poster';
    return 'Business QR Poster';
  }

  String get _posterHeader {
    if (_isPaymentQr) return 'TAJIRI PAY • TANQR';
    if (_isContactQr) return 'TAJIRI CONTACT • QR';
    return 'TAJIRI BUSINESS • QR';
  }

  String get _posterHeroText {
    if (_isPaymentQr) return 'Lipa kwa kuscan';
    if (_isContactQr) return 'Hifadhi mawasiliano';
    return 'Pata taarifa za biashara';
  }

  String get _posterFooterText {
    if (_isPaymentQr) return 'Lipa kutoka mitandao yote na Benki';
    if (_isContactQr) return 'Scan kuhifadhi contact ya TAJIRI';
    return 'Scan kupata taarifa za biashara';
  }

  Future<File?> _capturePosterToFile({bool forDownload = false}) async {
    try {
      final boundary =
          _posterKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      Directory targetDir;
      if (forDownload) {
        Directory? preferredDir;
        try {
          preferredDir = await getDownloadsDirectory();
        } catch (_) {
          preferredDir = null;
        }
        targetDir = preferredDir ?? await getApplicationDocumentsDirectory();
      } else {
        targetDir = await getTemporaryDirectory();
      }

      final fileName =
          'tajiri_tanqr_${widget.code.aliasMerchantId}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${targetDir.path}/$fileName');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      return file;
    } catch (_) {
      return null;
    }
  }

  Future<void> _downloadPoster() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    final file = await _capturePosterToFile(forDownload: true);
    if (!mounted) return;
    setState(() => _isExporting = false);
    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to download poster')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Poster downloaded: ${file.path}')),
    );
  }

  Future<void> _sharePosterImage() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    final file = await _capturePosterToFile();
    if (!mounted) return;
    setState(() => _isExporting = false);
    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create share image')),
      );
      return;
    }
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'TAJIRI QR - ${widget.code.displayName}',
      ),
    );
  }

  Future<void> _shareToTajiriChatImage() async {
    await _showChatPicker();
  }

  Future<void> _showChatPicker() async {
    final selected = await showModalBottomSheet<Conversation>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _TanqrChatPickerSheet(
        userId: widget.code.walletUserId,
      ),
    );

    if (!mounted || selected == null) return;

    setState(() => _isExporting = true);
    try {
      final file = await _capturePosterToFile();
      if (file == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to prepare poster image')),
        );
        return;
      }
      final result = await _messageService.sendMessage(
        conversationId: selected.id,
        userId: widget.code.walletUserId,
        messageType: 'image',
        media: file,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? 'Sent to ${selected.title}'
                : (result.errorMessage ?? 'Failed to send to chat'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        title: Text(
          _posterTitle,
          style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16),
        ),
        actions: [
          if (_isExporting)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
                ),
              ),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: _kPrimary),
              onSelected: (value) {
                switch (value) {
                  case 'download':
                    _downloadPoster();
                    break;
                  case 'share_image':
                    _sharePosterImage();
                    break;
                  case 'share_chat_image':
                    _shareToTajiriChatImage();
                    break;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'download',
                  child: Text('Download poster'),
                ),
                PopupMenuItem(
                  value: 'share_image',
                  child: Text('Share poster image'),
                ),
                PopupMenuItem(
                  value: 'share_chat_image',
                  child: Text('Share to TAJIRI chat (poster image)'),
                ),
              ],
            ),
        ],
        centerTitle: true,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: RepaintBoundary(
              key: _posterKey,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: _kPrimary,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _kPrimary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Text(
                                'T',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _posterHeader,
                              style: const TextStyle(
                                color: _kPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _posterHeroText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: QrImageView(
                          data: widget.code.tanqrPayload,
                          version: QrVersions.auto,
                          size: 260,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.code.aliasMerchantId.trim().isEmpty
                              ? widget.code.sourceType.toUpperCase()
                              : widget.code.aliasMerchantId,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _kPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.code.displayName.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _kPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _posterFooterText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _kBackground,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                      ),
                      child: const Text(
                        'TAJIRI QR CARD',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _kPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TanqrChatPickerSheet extends StatefulWidget {
  final int userId;
  const _TanqrChatPickerSheet({required this.userId});

  @override
  State<_TanqrChatPickerSheet> createState() => _TanqrChatPickerSheetState();
}

class _TanqrChatPickerSheetState extends State<_TanqrChatPickerSheet> {
  final MessageService _messageService = MessageService();
  final TextEditingController _searchController = TextEditingController();
  List<Conversation> _conversations = [];
  List<Conversation> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    final result = await _messageService.getConversations(
      userId: widget.userId,
      perPage: 50,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success) {
        _conversations = result.conversations;
        _filtered = _conversations;
      }
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = _conversations;
      } else {
        _filtered = _conversations
            .where((c) => c.title.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 10),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Share to TAJIRI Chat',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search chats...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: const Color(0xFFF3F3F3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : _filtered.isEmpty
                      ? const Center(
                          child: Text(
                            'No chats found',
                            style: TextStyle(color: Color(0xFF666666)),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final conversation = _filtered[index];
                            final avatar = conversation.photo;
                            return ListTile(
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor: const Color(0xFF1A1A1A).withValues(alpha: 0.08),
                                backgroundImage:
                                    avatar != null && avatar.isNotEmpty ? NetworkImage(avatar) : null,
                                child: avatar == null || avatar.isEmpty
                                    ? Text(
                                        conversation.title.isNotEmpty
                                            ? conversation.title.substring(0, 1).toUpperCase()
                                            : 'C',
                                        style: const TextStyle(
                                          color: Color(0xFF1A1A1A),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                conversation.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => Navigator.pop(context, conversation),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
