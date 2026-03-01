import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/page_models.dart';
import '../../services/page_service.dart';

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
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final PageService _pageService = PageService();

  List<PageCategory> _categories = [];
  String? _selectedCategory;
  File? _profilePhoto;
  File? _coverPhoto;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories = await _pageService.getCategories();
    setState(() {
      _categories = categories;
      if (categories.isNotEmpty) _selectedCategory = categories.first.value;
    });
  }

  Future<void> _pickImage(bool isProfile) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (isProfile) {
          _profilePhoto = File(image.path);
        } else {
          _coverPhoto = File(image.path);
        }
      });
    }
  }

  Future<void> _createPage() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
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
      phone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
      website: _websiteController.text.trim().isNotEmpty
          ? _websiteController.text.trim()
          : null,
      address: _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : null,
      profilePhoto: _profilePhoto,
      coverPhoto: _coverPhoto,
    );

    setState(() => _isLoading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ukurasa umeundwa')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Imeshindikana kuunda ukurasa')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unda Ukurasa'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createPage,
            child: _isLoading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Unda'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Cover & profile photo
            Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: () => _pickImage(false),
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      image: _coverPhoto != null
                          ? DecorationImage(image: FileImage(_coverPhoto!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: _coverPhoto == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 32, color: Colors.grey.shade500),
                                const Text('Picha ya jalada'),
                              ],
                            ),
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: -30,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => _pickImage(true),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      backgroundImage: _profilePhoto != null ? FileImage(_profilePhoto!) : null,
                      child: _profilePhoto == null
                          ? Icon(Icons.camera_alt, size: 32, color: Colors.grey.shade500)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Jina la ukurasa *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.trim().isEmpty == true ? 'Jina linahitajika' : null,
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Aina *',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((c) {
                return DropdownMenuItem(value: c.value, child: Text(c.label));
              }).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Maelezo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Mawasiliano', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Simu',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Barua pepe',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _websiteController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Tovuti',
                prefixIcon: Icon(Icons.language),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Anwani',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
