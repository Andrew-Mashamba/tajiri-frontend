import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/tajirika_models.dart';
import '../services/tajirika_service.dart';
import '../widgets/portfolio_item_card.dart';

class PortfolioManagerPage extends StatefulWidget {
  final int partnerId;

  const PortfolioManagerPage({super.key, required this.partnerId});

  @override
  State<PortfolioManagerPage> createState() => _PortfolioManagerPageState();
}

class _PortfolioManagerPageState extends State<PortfolioManagerPage> {
  static const Color _kBg = Color(0xFFFAFAFA);
  static const Color _kPrimary = Color(0xFF1A1A1A);
  static const Color _kSecondary = Color(0xFF666666);

  List<PortfolioItem> _items = [];
  bool _isLoading = true;
  String? _error;

  final _picker = ImagePicker();
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadPortfolio();
  }

  Future<String?> _getToken() async {
    final storage = await LocalStorageService.getInstance();
    _userId ??= storage.getUser()?.userId;
    return storage.getAuthToken();
  }

  Future<void> _loadPortfolio() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _getToken();
      if (token == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = 'Not authenticated';
        });
        return;
      }

      final result = await TajirikaService.getPortfolio(token, widget.partnerId);
      if (!mounted) return;

      if (result.success) {
        setState(() {
          _items = result.items;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = result.message ?? 'Failed to load portfolio';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Error: $e';
      });
    }
  }

  void _showImageViewer(PortfolioItem item) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  item.displayUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 48),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black45,
                  minimumSize: const Size(48, 48),
                ),
              ),
            ),
            if (item.caption != null && item.caption!.isNotEmpty)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Text(
                  item.caption!,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(PortfolioItem item) {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isSwahili ? 'Futa Kazi' : 'Delete Item',
          style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600),
        ),
        content: Text(
          isSwahili
              ? 'Una uhakika unataka kufuta kazi hii kutoka kwenye portfolio yako?'
              : 'Are you sure you want to delete this item from your portfolio?',
          style: const TextStyle(color: _kSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isSwahili ? 'Hapana' : 'Cancel',
              style: const TextStyle(color: _kSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteItem(item);
            },
            child: Text(
              isSwahili ? 'Futa' : 'Delete',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(PortfolioItem item) async {
    try {
      final token = await _getToken();
      if (token == null || _userId == null) return;

      final result = await TajirikaService.deletePortfolioItem(token, _userId!, item.id);
      if (!mounted) return;

      if (result.success) {
        setState(() {
          _items.removeWhere((i) => i.id == item.id);
        });
        final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isSwahili ? 'Imefutwa kikamilifu' : 'Deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Failed to delete')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showAddOptions() {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isSwahili ? 'Ongeza Kazi' : 'Add Work Sample',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: _kPrimary),
                title: Text(
                  isSwahili ? 'Kamera' : 'Camera',
                  style: const TextStyle(color: _kPrimary),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                minVerticalPadding: 12,
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUpload(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: _kPrimary),
                title: Text(
                  isSwahili ? 'Galeri' : 'Gallery',
                  style: const TextStyle(color: _kPrimary),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                minVerticalPadding: 12,
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUpload(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, maxWidth: 1920, imageQuality: 85);
    if (picked == null || !mounted) return;

    final file = File(picked.path);
    _showUploadDialog(file);
  }

  void _showUploadDialog(File file) {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    final captionController = TextEditingController();
    SkillCategory? selectedCategory;
    bool uploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            isSwahili ? 'Maelezo ya Kazi' : 'Work Details',
            style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    file,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: captionController,
                  decoration: InputDecoration(
                    labelText: isSwahili ? 'Maelezo' : 'Caption',
                    labelStyle: const TextStyle(color: _kSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _kPrimary),
                    ),
                  ),
                  maxLines: 2,
                  maxLength: 200,
                  style: const TextStyle(color: _kPrimary),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<SkillCategory>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: isSwahili ? 'Aina ya Ujuzi' : 'Skill Category',
                    labelStyle: const TextStyle(color: _kSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _kPrimary),
                    ),
                  ),
                  isExpanded: true,
                  items: SkillCategory.values.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(
                        isSwahili ? cat.labelSwahili : cat.label,
                        style: const TextStyle(color: _kPrimary, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: uploading
                      ? null
                      : (val) {
                          setDialogState(() => selectedCategory = val);
                        },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: uploading ? null : () => Navigator.pop(ctx),
              child: Text(
                isSwahili ? 'Ghairi' : 'Cancel',
                style: const TextStyle(color: _kSecondary),
              ),
            ),
            TextButton(
              onPressed: uploading
                  ? null
                  : () async {
                      setDialogState(() => uploading = true);
                      await _uploadItem(
                        ctx,
                        file,
                        captionController.text.trim(),
                        selectedCategory,
                        setDialogState,
                      );
                    },
              child: uploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _kPrimary,
                      ),
                    )
                  : Text(
                      isSwahili ? 'Pakia' : 'Upload',
                      style: const TextStyle(
                        color: _kPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadItem(
    BuildContext dialogContext,
    File file,
    String caption,
    SkillCategory? category,
    StateSetter setDialogState,
  ) async {
    try {
      final token = await _getToken();
      if (token == null || _userId == null) return;

      final result = await TajirikaService.uploadPortfolioItem(
        token,
        _userId!,
        file,
        caption.isNotEmpty ? caption : null,
        category?.name,
      );

      if (!mounted) return;

      if (result.success) {
        Navigator.pop(dialogContext);
        _loadPortfolio();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStringsScope.of(context)?.isSwahili == true
                  ? 'Imepakiwa kikamilifu'
                  : 'Uploaded successfully',
            ),
          ),
        );
      } else {
        setDialogState(() {});
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Upload failed')),
        );
      }
    } catch (e) {
      setDialogState(() {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        surfaceTintColor: _kBg,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
        ),
        title: Text(
          isSwahili ? 'Kazi Zangu' : 'My Portfolio',
          style: const TextStyle(
            color: _kPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _kPrimary))
            : _error != null
                ? _buildError(isSwahili)
                : _items.isEmpty
                    ? _buildEmpty(isSwahili)
                    : _buildGrid(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        backgroundColor: _kPrimary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildError(bool isSwahili) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: _kSecondary),
            const SizedBox(height: 16),
            Text(
              _error ?? '',
              style: const TextStyle(color: _kSecondary, fontSize: 14),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadPortfolio,
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(
                isSwahili ? 'Jaribu tena' : 'Try again',
                style: const TextStyle(color: _kPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isSwahili) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_library_rounded, size: 64, color: _kSecondary),
            const SizedBox(height: 16),
            Text(
              isSwahili
                  ? 'Ongeza kazi yako ya kwanza'
                  : 'Add your first work sample',
              style: const TextStyle(
                color: _kSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isSwahili
                  ? 'Onyesha kazi zako bora kwa wateja watakaokuja'
                  : 'Showcase your best work to potential clients',
              style: const TextStyle(color: _kSecondary, fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddOptions,
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
              label: Text(
                isSwahili ? 'Pakia Kazi' : 'Upload Work',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                minimumSize: const Size(48, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return RefreshIndicator(
      onRefresh: _loadPortfolio,
      color: _kPrimary,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return PortfolioItemCard(
            item: item,
            onTap: () => _showImageViewer(item),
            onDelete: () => _confirmDelete(item),
          );
        },
      ),
    );
  }
}
