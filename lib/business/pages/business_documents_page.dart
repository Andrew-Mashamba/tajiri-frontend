// lib/business/pages/business_documents_page.dart
// Full file management system for business documents.
// Each registered business gets an auto-created folder.
// Users can create additional folders for general documents.
// Any file type can be uploaded.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/local_storage_service.dart';
import '../models/business_models.dart';
import '../services/business_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class BusinessDocumentsPage extends StatefulWidget {
  final int userId;
  final List<Business> businesses;
  const BusinessDocumentsPage({super.key, required this.userId, required this.businesses});
  @override
  State<BusinessDocumentsPage> createState() => _BusinessDocumentsPageState();
}

class _BusinessDocumentsPageState extends State<BusinessDocumentsPage> {
  String? _token;
  bool _loading = true;

  // Current navigation
  _Folder? _currentFolder; // null = root

  // Root-level items: business folders (auto) + custom folders + root files
  final List<_Folder> _folders = [];
  final Map<int, List<BusinessDocument>> _bizDocs = {}; // businessId → docs
  List<BusinessDocument> _customFolderDocs = []; // docs in current custom folder

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    if (_token == null) { setState(() => _loading = false); return; }

    // Build folder list: one per business + any custom folders
    _folders.clear();

    // Business folders (auto-created)
    for (final biz in widget.businesses) {
      if (biz.id == null) continue;
      final res = await BusinessService.getDocuments(_token!, biz.id!);
      if (res.success) _bizDocs[biz.id!] = res.data;
      _folders.add(_Folder(
        name: biz.name,
        type: _FolderType.business,
        businessId: biz.id,
        fileCount: _bizDocs[biz.id]?.length ?? 0,
        icon: Icons.business_rounded,
      ));
    }

    // TODO: Load custom folders from backend when endpoint exists
    // For now, show a "General" folder placeholder
    _folders.add(_Folder(
      name: 'General',
      type: _FolderType.custom,
      icon: Icons.folder_rounded,
    ));

    if (mounted) setState(() => _loading = false);
  }

  // ── Navigation ──────────────────────────────────────────────────

  void _openFolder(_Folder folder) {
    setState(() => _currentFolder = folder);
    if (folder.type == _FolderType.business && folder.businessId != null) {
      // Docs already loaded
    }
  }

  void _goBack() {
    setState(() => _currentFolder = null);
  }

  // ── File Operations ─────────────────────────────────────────────

  Future<void> _uploadFile() async {
    if (_token == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return;

    // Determine target business
    int? targetBizId = _currentFolder?.businessId;
    if (targetBizId == null && _currentFolder?.type == _FolderType.business) return;

    // If at root or in custom folder, ask which business (or general)
    if (targetBizId == null && widget.businesses.isNotEmpty) {
      targetBizId = await _pickBusiness();
      if (targetBizId == null) return; // cancelled
    }

    if (targetBizId == null) return;

    int successCount = 0;
    for (final file in result.files) {
      if (file.path == null) continue;
      final res = await BusinessService.uploadDocument(
        _token!, targetBizId, 'other', File(file.path!),
      );
      if (res.success) successCount++;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$successCount file${successCount != 1 ? 's' : ''} uploaded')),
      );
      _load();
    }
  }

  Future<int?> _pickBusiness() async {
    return showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Upload to which business?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
            ),
            const SizedBox(height: 8),
            ...widget.businesses.where((b) => b.id != null).map((biz) => ListTile(
                  leading: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text(biz.name.isNotEmpty ? biz.name[0] : '?', style: const TextStyle(fontWeight: FontWeight.w700, color: _kPrimary))),
                  ),
                  title: Text(biz.name),
                  subtitle: biz.tinNumber != null ? Text('TIN: ${biz.tinNumber}', style: const TextStyle(fontSize: 12)) : null,
                  onTap: () => Navigator.pop(ctx, biz.id),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteDocument(int docId) async {
    if (_token == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete File'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    final res = await BusinessService.deleteDocument(_token!, docId);
    if (mounted && res.success) _load();
  }

  void _viewFile(BusinessDocument doc) {
    if (doc.fileUrl == null || doc.fileUrl!.isEmpty) return;
    final uri = Uri.tryParse(doc.fileUrl!);
    if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _shareFile(BusinessDocument doc) {
    if (doc.fileUrl == null) return;
    SharePlus.instance.share(ShareParams(text: doc.fileUrl!, subject: doc.name));
  }

  void _createFolder() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Folder name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              setState(() {
                _folders.add(_Folder(name: name, type: _FolderType.custom, icon: Icons.folder_rounded));
              });
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: _kPrimary),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));

    return Column(
      children: [
        // Top action bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              if (_currentFolder != null)
                GestureDetector(
                  onTap: _goBack,
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_back_rounded, size: 18, color: _kSecondary),
                      SizedBox(width: 4),
                      Text('Back', style: TextStyle(fontSize: 13, color: _kSecondary)),
                    ],
                  ),
                ),
              if (_currentFolder != null) const SizedBox(width: 8),
              if (_currentFolder != null)
                Expanded(
                  child: Text(
                    _currentFolder!.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (_currentFolder == null) const Spacer(),
              _PillButton(icon: Icons.upload_file_rounded, label: 'Upload', onTap: _uploadFile),
              if (_currentFolder == null) ...[
                const SizedBox(width: 8),
                _PillButton(icon: Icons.create_new_folder_rounded, label: 'Folder', onTap: _createFolder),
              ],
            ],
          ),
        ),
        // Content
        Expanded(
          child: _currentFolder == null ? _buildRoot() : _buildFolderView(),
        ),
      ],
    );
  }

  // ── Root View (folders) ─────────────────────────────────────────

  Widget _buildRoot() {
    return RefreshIndicator(
      onRefresh: _load,
      color: _kPrimary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          // Folder grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.6,
            ),
            itemCount: _folders.length,
            itemBuilder: (context, index) {
              final folder = _folders[index];
              return _FolderCard(
                folder: folder,
                onTap: () => _openFolder(folder),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Folder View (files inside a folder) ─────────────────────────

  Widget _buildFolderView() {
    final folder = _currentFolder!;
    final docs = folder.type == _FolderType.business
        ? (_bizDocs[folder.businessId] ?? [])
        : _customFolderDocs;

    return Column(
      children: [
        // Compliance checklist for business folders
        if (folder.type == _FolderType.business && folder.businessId != null)
          _buildComplianceChecklist(folder.businessId!),

        // File list
        Expanded(
          child: docs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open_rounded, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No files yet', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                      const SizedBox(height: 8),
                      Text('Tap + to upload files', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    return _FileTile(
                      doc: doc,
                      onTap: () => _viewFile(doc),
                      onShare: () => _shareFile(doc),
                      onDelete: () => _deleteDocument(doc.id ?? 0),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildComplianceChecklist(int bizId) {
    final biz = widget.businesses.firstWhere((b) => b.id == bizId);
    final docs = _bizDocs[bizId] ?? [];
    final uploadedTypes = docs.map((d) => d.type).toSet();
    final required = requiredDocuments(biz.type, hasVrn: biz.vrn != null && biz.vrn!.isNotEmpty);
    final missingCount = required.where((dt) => !uploadedTypes.contains(dt)).length;

    if (missingCount == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$missingCount required documents missing', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.orange.shade700)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: required.where((dt) => !uploadedTypes.contains(dt)).map((dt) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(documentTypeLabel(dt), style: TextStyle(fontSize: 11, color: Colors.orange.shade700)),
                )).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Data Classes ──────────────────────────────────────────────────

enum _FolderType { business, custom }

class _Folder {
  final String name;
  final _FolderType type;
  final int? businessId;
  final int fileCount;
  final IconData icon;

  _Folder({required this.name, required this.type, this.businessId, this.fileCount = 0, this.icon = Icons.folder_rounded});
}

// ── Widgets ──────────────────────────────────────────────────────

class _FolderCard extends StatelessWidget {
  final _Folder folder;
  final VoidCallback onTap;
  const _FolderCard({required this.folder, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isBiz = folder.type == _FolderType.business;
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(
                    isBiz ? Icons.business_rounded : Icons.folder_rounded,
                    size: 28,
                    color: isBiz ? _kPrimary : Colors.amber.shade700,
                  ),
                  const Spacer(),
                  if (folder.fileCount > 0)
                    Text('${folder.fileCount}', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                folder.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              Text(
                isBiz ? 'Business folder' : 'Custom folder',
                style: const TextStyle(fontSize: 11, color: _kSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileTile extends StatelessWidget {
  final BusinessDocument doc;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  const _FileTile({required this.doc, required this.onTap, required this.onShare, required this.onDelete});

  IconData get _icon {
    final name = doc.name.toLowerCase();
    if (name.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
    if (name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.png')) return Icons.image_rounded;
    if (name.endsWith('.doc') || name.endsWith('.docx')) return Icons.description_rounded;
    if (name.endsWith('.xls') || name.endsWith('.xlsx')) return Icons.table_chart_rounded;
    if (name.endsWith('.ppt') || name.endsWith('.pptx')) return Icons.slideshow_rounded;
    if (name.endsWith('.zip') || name.endsWith('.rar')) return Icons.archive_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color get _iconColor {
    final name = doc.name.toLowerCase();
    if (name.endsWith('.pdf')) return Colors.red.shade700;
    if (name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.png')) return Colors.blue;
    if (name.endsWith('.doc') || name.endsWith('.docx')) return Colors.blue.shade700;
    if (name.endsWith('.xls') || name.endsWith('.xlsx')) return Colors.green.shade700;
    if (name.endsWith('.ppt') || name.endsWith('.pptx')) return Colors.orange;
    return _kSecondary;
  }

  Color? get _expiryColor {
    if (doc.expiryDate == null) return null;
    final days = doc.expiryDate!.difference(DateTime.now()).inDays;
    if (days < 0) return Colors.red;
    if (days <= 30) return Colors.orange;
    return const Color(0xFF4CAF50);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: _iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(_icon, size: 20, color: _iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Row(
                      children: [
                        Text(documentTypeLabel(doc.type), style: const TextStyle(fontSize: 11, color: _kSecondary)),
                        if (doc.expiryDate != null) ...[
                          const Text(' · ', style: TextStyle(color: _kSecondary)),
                          Text(
                            '${doc.expiryDate!.day}/${doc.expiryDate!.month}/${doc.expiryDate!.year}',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _expiryColor),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (_expiryColor != null)
                Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(color: _expiryColor, shape: BoxShape.circle)),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18, color: _kSecondary),
                onSelected: (v) {
                  if (v == 'view') onTap();
                  if (v == 'share') onShare();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.open_in_new, size: 18), SizedBox(width: 8), Text('Open')])),
                  PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share, size: 18), SizedBox(width: 8), Text('Share')])),
                  PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PillButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kPrimary,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
