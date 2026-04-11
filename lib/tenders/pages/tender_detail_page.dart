// Single tender detail view
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../business/business_notifier.dart';
import '../../business/models/business_models.dart';
import '../../business/services/business_service.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/tender_models.dart';
import '../services/tender_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kUrgent = Color(0xFFD32F2F);
const Color _kWarning = Color(0xFFE65100);
const Color _kSuccess = Color(0xFF2E7D32);

class TenderDetailPage extends StatefulWidget {
  final String tenderId;
  final Tender? initialTender;

  const TenderDetailPage({super.key, required this.tenderId, this.initialTender});

  @override
  State<TenderDetailPage> createState() => _TenderDetailPageState();
}

class _TenderDetailPageState extends State<TenderDetailPage> {
  Tender? _tender;
  bool _isLoading = true;
  bool _isApplying = false;
  String? _error;

  bool get _isSwahili =>
      AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _tender = widget.initialTender;
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    if (mounted) setState(() => _isLoading = _tender == null);
    final result = await TenderService.getTenderDetail(widget.tenderId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success && result.data != null) {
          _tender = result.data;
        } else if (_tender == null) {
          _error = result.error ?? (_isSwahili ? 'Zabuni haipatikani' : 'Tender not found');
        }
      });
    }
  }

  Future<void> _applyToTender() async {
    if (_tender == null) return;

    // Show document attachment flow if user has businesses
    String? docNotes;
    final businesses = BusinessNotifier.instance.businesses;
    if (businesses.isNotEmpty) {
      docNotes = await _showDocumentAttachmentSheet(businesses.first);
      if (docNotes == null) return; // Cancelled
    }

    final notes = await _showNotesDialog();
    if (notes == null) return; // Cancelled

    final combinedNotes = [
      if (notes.isNotEmpty) notes,
      if (docNotes != null && docNotes.isNotEmpty) '\n\nAttached Documents:\n$docNotes',
    ].join();

    setState(() => _isApplying = true);

    final result = await TenderService.applyToTender(
      tenderId: _tender!.tenderId,
      tenderTitle: _tender!.title,
      institutionSlug: _tender!.institution,
      notes: combinedNotes.isNotEmpty ? combinedNotes : null,
      deadline: _tender!.closingDate?.toIso8601String(),
    );

    if (mounted) {
      setState(() => _isApplying = false);
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isSwahili
                ? 'Umefanikiwa kuomba zabuni hii'
                : 'Successfully applied for this tender'),
            backgroundColor: _kSuccess,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ??
                (_isSwahili ? 'Imeshindwa kuomba' : 'Failed to apply')),
            backgroundColor: _kUrgent,
          ),
        );
      }
    }
  }

  Future<String?> _showDocumentAttachmentSheet(Business business) async {
    // Fetch documents
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    if (token == null) return '';

    final res = await BusinessService.getDocuments(token, business.id!);
    if (!res.success || res.data.isEmpty) return '';

    final docs = res.data;
    final selected = List<bool>.filled(docs.length, true);

    if (!mounted) return '';

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_isSwahili ? 'Ambatisha Nyaraka' : 'Attach Documents',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _kPrimary)),
              const SizedBox(height: 4),
              Text('${_isSwahili ? "Kutoka" : "From"}: ${business.name}',
                  style: const TextStyle(fontSize: 12, color: _kSecondary)),
              const SizedBox(height: 12),
              ...List.generate(docs.length, (i) => CheckboxListTile(
                    value: selected[i],
                    onChanged: (v) => setLocal(() => selected[i] = v ?? false),
                    title: Text(docs[i].name,
                        style: const TextStyle(fontSize: 13, color: _kPrimary)),
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: _kPrimary,
                  )),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton(
                  onPressed: () {
                    final attached = <String>[];
                    for (int i = 0; i < docs.length; i++) {
                      if (selected[i] && docs[i].fileUrl != null) {
                        attached.add('- ${docs[i].name}: ${docs[i].fileUrl}');
                      }
                    }
                    Navigator.pop(ctx, attached.join('\n'));
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _kPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(_isSwahili ? 'Endelea' : 'Continue',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showNotesDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isSwahili ? 'Omba Zabuni' : 'Apply for Tender', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: _isSwahili ? 'Andika maelezo (si lazima)...' : 'Add notes (optional)...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_isSwahili ? 'Ghairi' : 'Cancel', style: const TextStyle(color: _kSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style: FilledButton.styleFrom(backgroundColor: _kPrimary),
            child: Text(_isSwahili ? 'Omba' : 'Apply'),
          ),
        ],
      ),
    );
  }

  void _shareTender() {
    if (_tender == null) return;
    final text = '${_tender!.title}\n${_tender!.institutionDisplay}\n'
        '${_tender!.sourceUrl ?? ''}\n\n${_isSwahili ? 'Kupitia TAJIRI Zabuni' : 'Via TAJIRI Tenders'}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isSwahili ? 'Imekopwa kwenye clipboard' : 'Copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isSwahili ? 'Maelezo ya Zabuni' : 'Tender Details',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _kPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: _kPrimary, size: 20),
            onPressed: _shareTender,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _tender != null && !_tender!.isClosed ? _buildBottomBar() : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: _kSecondary),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(fontSize: 14, color: _kSecondary)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadDetail,
              style: FilledButton.styleFrom(backgroundColor: _kPrimary),
              child: Text(_isSwahili ? 'Jaribu Tena' : 'Retry'),
            ),
          ],
        ),
      );
    }

    final tender = _tender!;
    final days = tender.daysRemaining;

    return RefreshIndicator(
      onRefresh: _loadDetail,
      color: _kPrimary,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          // Header card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status + category
                Row(
                  children: [
                    _buildBadge(tender.status.label, tender.status.color),
                    const SizedBox(width: 8),
                    _buildBadge(tender.category.label, _kPrimary),
                  ],
                ),
                const SizedBox(height: 14),

                // Title
                Text(
                  tender.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary, height: 1.3),
                ),
                const SizedBox(height: 8),

                // Institution
                Row(
                  children: [
                    const Icon(Icons.business_rounded, size: 16, color: _kSecondary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        tender.institutionDisplay,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Reference number
                if (tender.referenceNumber != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.tag_rounded, size: 16, color: _kSecondary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          tender.referenceNumber!,
                          style: TextStyle(
                            fontSize: 13,
                            color: _kSecondary.withValues(alpha: 0.8),
                            fontFamily: 'monospace',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Countdown card
          if (tender.closingDate != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: days >= 0 && days <= 3
                    ? _kUrgent.withValues(alpha: 0.08)
                    : days >= 0 && days <= 7
                        ? _kWarning.withValues(alpha: 0.08)
                        : _kCardBg,
                borderRadius: BorderRadius.circular(12),
                border: days >= 0 && days <= 3
                    ? Border.all(color: _kUrgent.withValues(alpha: 0.3))
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 28,
                    color: days >= 0 && days <= 3
                        ? _kUrgent
                        : days >= 0 && days <= 7
                            ? _kWarning
                            : _kSecondary,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tender.isClosed
                              ? (_isSwahili ? 'Imefungwa' : 'Closed')
                              : days == 0
                                  ? (_isSwahili ? 'Inafungwa Leo!' : 'Closing Today!')
                                  : days == 1
                                      ? (_isSwahili ? 'Siku 1 imebaki!' : '1 day left!')
                                      : (_isSwahili ? 'Siku $days zimebaki' : '$days days left'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: days >= 0 && days <= 3 ? _kUrgent : days >= 0 && days <= 7 ? _kWarning : _kPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isSwahili
                              ? 'Tarehe ya kufungwa: ${_formatDate(tender.closingDate!)}${tender.closingTime != null ? ' saa ${tender.closingTime}' : ''}'
                              : 'Closing date: ${_formatDate(tender.closingDate!)}${tender.closingTime != null ? ' at ${tender.closingTime}' : ''}',
                          style: const TextStyle(fontSize: 13, color: _kSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Description
          if (tender.description != null && tender.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSection(_isSwahili ? 'Maelezo' : 'Description', Icons.info_outline_rounded),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tender.description!,
                style: const TextStyle(fontSize: 14, color: _kPrimary, height: 1.5),
              ),
            ),
          ],

          // Eligibility
          if (tender.eligibility != null && tender.eligibility!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSection(_isSwahili ? 'Vigezo vya Ushiriki' : 'Eligibility', Icons.check_circle_outline_rounded),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tender.eligibility!,
                style: const TextStyle(fontSize: 14, color: _kPrimary, height: 1.5),
              ),
            ),
          ],

          // Documents
          if (tender.documents.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSection(_isSwahili ? 'Nyaraka (${tender.documents.length})' : 'Documents (${tender.documents.length})', Icons.attach_file_rounded),
            ...tender.documents.map((doc) => _buildDocumentTile(doc)),
          ],

          // Contact
          if (tender.contact != null && tender.contact!.hasAnyInfo) ...[
            const SizedBox(height: 16),
            _buildSection(_isSwahili ? 'Mawasiliano' : 'Contact', Icons.phone_rounded),
            _buildContactCard(tender.contact!),
          ],

          // Source URL
          if (tender.sourceUrl != null) ...[
            const SizedBox(height: 16),
            _buildSection(_isSwahili ? 'Chanzo' : 'Source', Icons.link_rounded),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () => _openUrl(tender.sourceUrl!),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _kCardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.open_in_new_rounded, size: 18, color: _kPrimary),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          tender.sourceUrl!,
                          style: const TextStyle(fontSize: 13, color: _kPrimary, decoration: TextDecoration.underline),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // Published date
          if (tender.publishedDate != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _isSwahili
                    ? 'Iliyochapishwa: ${_formatDate(tender.publishedDate!)}'
                    : 'Published: ${_formatDate(tender.publishedDate!)}',
                style: TextStyle(fontSize: 12, color: _kSecondary.withValues(alpha: 0.7)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _kSecondary),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildDocumentTile(TenderDocument doc) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(doc.icon, color: _kPrimary, size: 22),
        title: Text(
          doc.filename,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: doc.contentType != null
            ? Text(doc.contentType!, style: const TextStyle(fontSize: 11, color: _kSecondary))
            : null,
        trailing: doc.originalUrl != null
            ? IconButton(
                icon: const Icon(Icons.download_rounded, size: 20, color: _kPrimary),
                onPressed: () => _openUrl(doc.originalUrl!),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        dense: true,
      ),
    );
  }

  Widget _buildContactCard(TenderContact contact) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (contact.name != null) ...[
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 16, color: _kSecondary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    contact.name!,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (contact.email != null)
            _buildContactRow(Icons.email_outlined, contact.email!, () => _openUrl('mailto:${contact.email}')),
          if (contact.phone != null)
            _buildContactRow(Icons.phone_outlined, contact.phone!, () => _openUrl('tel:${contact.phone}')),
          if (contact.address != null) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: _kSecondary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    contact.address!,
                    style: const TextStyle(fontSize: 13, color: _kSecondary, height: 1.4),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 16, color: _kSecondary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  color: _kPrimary,
                  decoration: TextDecoration.underline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCardBg,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2)),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            onPressed: _isApplying ? null : _applyToTender,
            style: FilledButton.styleFrom(
              backgroundColor: _kPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isApplying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    _isSwahili ? 'Omba Zabuni' : 'Apply for Tender',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatDate(DateTime date) {
    final months = _isSwahili
        ? ['Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni', 'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba']
        : ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
