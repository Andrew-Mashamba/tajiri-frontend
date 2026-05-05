// lib/myfiles/pages/my_files_page.dart
//
// Top-level entry for the lib/myfiles/ module. Lists the creator's
// uploaded files (PDFs, datasets, course materials, templates) via
// the existing FileService cloud-storage API.
//
// Per docs/CREATOR_REVENUE_TAXONOMY.md §2 — "My Files" earns from
// engagement (views, reactions, comments, shares, saves, read-time,
// tips) on document posts. The earning breakdown awaits backend v2;
// this page surfaces the file list itself.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../../models/file_models.dart';
import '../../services/file_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kBorder = Color(0xFFE5E5E5);
const Color _kSurface = Colors.white;

class MyFilesPage extends StatefulWidget {
  final int userId;
  final bool isOwnProfile;

  const MyFilesPage({
    super.key,
    required this.userId,
    this.isOwnProfile = true,
  });

  @override
  State<MyFilesPage> createState() => _MyFilesPageState();
}

class _MyFilesPageState extends State<MyFilesPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final FileService _service = FileService();
  List<UserFile> _files = const [];
  StorageQuota? _quota;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _service.getFiles(userId: widget.userId);
      if (!mounted) return;
      setState(() {
        _files = result.files;
        _quota = result.quota;
        _loading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[MyFiles] load error: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _kPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          isSw ? 'Faili Zangu' : 'My Files',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: _kPrimary,
          onRefresh: _load,
          child: _loading
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
                      ),
                    ),
                  ],
                )
              : _error != null && _files.isEmpty
                  ? _buildError(isSw)
                  : _files.isEmpty
                      ? _buildEmpty(isSw)
                      : _buildList(isSw),
        ),
      ),
    );
  }

  Widget _buildList(bool isSw) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _files.length + (_quota != null ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        if (_quota != null && i == 0) {
          return _QuotaCard(quota: _quota!, isSw: isSw);
        }
        final file = _files[_quota != null ? i - 1 : i];
        return _FileRow(file: file, isSw: isSw);
      },
    );
  }

  Widget _buildEmpty(bool isSw) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              isSw ? 'Hakuna faili bado' : 'No files yet',
              style: const TextStyle(color: _kSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(bool isSw) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              isSw ? 'Imeshindwa kupakia faili.' : 'Failed to load files.',
              style: const TextStyle(color: _kSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _load,
              style: OutlinedButton.styleFrom(
                foregroundColor: _kPrimary,
                side: const BorderSide(color: _kPrimary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(isSw ? 'Jaribu tena' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuotaCard extends StatelessWidget {
  final StorageQuota quota;
  final bool isSw;
  const _QuotaCard({required this.quota, required this.isSw});

  @override
  Widget build(BuildContext context) {
    final pct = (quota.usagePercent.clamp(0.0, 100.0)) / 100.0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSw ? 'Hifadhi' : 'Storage',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kTertiary, letterSpacing: 0.4),
          ),
          const SizedBox(height: 8),
          Text(
            '${quota.formattedUsed} / ${quota.formattedTotal}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: const Color(0xFFE5E5E5),
              valueColor: const AlwaysStoppedAnimation(_kPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  final UserFile file;
  final bool isSw;
  const _FileRow({required this.file, required this.isSw});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kSurface,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_iconFor(file), size: 20, color: _kPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.displayName ?? file.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_fmtBytes(file.size)} · ${file.mimeType}',
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (file.isStarred)
            const Icon(Icons.star_rounded, size: 18, color: _kSecondary),
        ],
      ),
    );
  }

  IconData _iconFor(UserFile f) {
    if (f.isFolder) return Icons.folder_rounded;
    final mime = f.mimeType.toLowerCase();
    if (mime.startsWith('image/')) return Icons.image_rounded;
    if (mime.startsWith('video/')) return Icons.videocam_rounded;
    if (mime.startsWith('audio/')) return Icons.audiotrack_rounded;
    if (mime.contains('pdf')) return Icons.picture_as_pdf_rounded;
    return Icons.insert_drive_file_rounded;
  }

  String _fmtBytes(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    if (b < 1024 * 1024 * 1024) return '${(b / 1024 / 1024).toStringAsFixed(1)} MB';
    return '${(b / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }
}
