import 'package:flutter/material.dart';
import '../../models/page_models.dart';
import '../../services/page_service.dart';

/// Create Page screen (Story 44).
/// Navigation: Discover/Profile → Create Page flow.
/// POST /api/pages with name, category, description.
class CreatePageScreen extends StatefulWidget {
  final int creatorId;

  const CreatePageScreen({super.key, required this.creatorId});

  @override
  State<CreatePageScreen> createState() => _CreatePageScreenState();
}

class _CreatePageScreenState extends State<CreatePageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final PageService _pageService = PageService();

  List<PageCategory> _categories = [];
  String? _selectedCategory;
  bool _isLoading = false;

  static const Color _bgColor = Color(0xFFFAFAFA);
  static const Color _primaryText = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories = await _pageService.getCategories();
    if (!mounted) return;
    setState(() {
      _categories = categories;
      if (categories.isNotEmpty && _selectedCategory == null) {
        _selectedCategory = categories.first.value;
      }
    });
  }

  Future<void> _createPage() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chagua aina ya ukurasa')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _pageService.createPage(
      creatorId: widget.creatorId,
      name: _nameController.text.trim(),
      category: _selectedCategory!,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ukurasa umeundwa')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Imeshindikana kuunda ukurasa'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        foregroundColor: _primaryText,
        elevation: 0,
        title: const Text(
          'Unda Ukurasa',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _primaryText,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),

                  // Name (required)
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(fontSize: 14, color: _primaryText),
                    decoration: InputDecoration(
                      labelText: 'Jina la ukurasa *',
                      hintText: 'Weka jina la ukurasa',
                      labelStyle: const TextStyle(color: _secondaryText),
                      hintStyle: const TextStyle(color: _secondaryText),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Jina linahitajika';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category (required)
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    style: const TextStyle(fontSize: 14, color: _primaryText),
                    decoration: InputDecoration(
                      labelText: 'Aina ya ukurasa *',
                      labelStyle: const TextStyle(color: _secondaryText),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    items: _categories
                        .map(
                          (c) => DropdownMenuItem<String>(
                            value: c.value,
                            child: Text(
                              c.label,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _isLoading
                        ? null
                        : (v) => setState(() => _selectedCategory = v),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    maxLength: 2000,
                    style: const TextStyle(fontSize: 14, color: _primaryText),
                    decoration: InputDecoration(
                      labelText: 'Maelezo',
                      hintText: 'Eleza ukurasa wako...',
                      labelStyle: const TextStyle(color: _secondaryText),
                      hintStyle: const TextStyle(color: _secondaryText),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Create button (48dp min height, DESIGN.md button template)
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 72,
                        maxHeight: 80,
                      ),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        elevation: 2,
                        shadowColor: Colors.black.withOpacity(0.1),
                        child: InkWell(
                          onTap: _isLoading ? null : _createPage,
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Unda Ukurasa',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: _primaryText,
                                    ),
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
      ),
    );
  }
}
