import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/contribution_models.dart';
import '../../services/contribution_service.dart';

/// Create Campaign (Michango) screen – Story 80.
/// Path: Home → Profile → Tab [Michango] → Create campaign.
class CreateCampaignScreen extends StatefulWidget {
  final int currentUserId;

  const CreateCampaignScreen({super.key, required this.currentUserId});

  @override
  State<CreateCampaignScreen> createState() => _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends State<CreateCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _storyController = TextEditingController();
  final _goalController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _mobileMoneyController = TextEditingController();
  final ContributionService _contributionService = ContributionService();
  final ImagePicker _imagePicker = ImagePicker();

  CampaignCategory _category = CampaignCategory.other;
  File? _coverImage;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _storyController.dispose();
    _goalController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _mobileMoneyController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (image != null && mounted) {
      setState(() => _coverImage = File(image.path));
    }
  }

  Future<void> _submit() async {
    _errorMessage = null;
    if (!_formKey.currentState!.validate()) return;

    final goalAmount = double.tryParse(_goalController.text.trim());
    if (goalAmount == null || goalAmount < 1000) {
      setState(() => _errorMessage = 'Lengo lazima liwe angalau TSh 1,000');
      return;
    }

    final bankName = _bankNameController.text.trim();
    final accountNumber = _accountNumberController.text.trim();
    final mobileMoney = _mobileMoneyController.text.trim();
    if (bankName.isEmpty && accountNumber.isEmpty && mobileMoney.isEmpty) {
      setState(() => _errorMessage =
          'Ongeza nambari ya benki au pesa za simu ili kupokea michango');
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    final result = await _contributionService.createCampaign(
      userId: widget.currentUserId,
      title: _titleController.text.trim(),
      story: _storyController.text.trim(),
      goalAmount: goalAmount,
      category: _category,
      coverImage: _coverImage,
      bankName: bankName.isNotEmpty ? bankName : null,
      accountNumber: accountNumber.isNotEmpty ? accountNumber : null,
      mobileMoneyNumber: mobileMoney.isNotEmpty ? mobileMoney : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mchango umeundwa. Unaweza kuchapisha kutoka Michango.')),
      );
      Navigator.pop(context, true);
    } else {
      setState(() => _errorMessage = result.message ?? 'Imeshindwa kuunda mchango');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Unda Mchango'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Hifadhi'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Cover image – min 48dp touch
                Semantics(
                  label: 'Picha ya jalada la mchango',
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    elevation: 2,
                    shadowColor: Colors.black.withOpacity(0.1),
                    child: InkWell(
                      onTap: _isLoading ? null : _pickCoverImage,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 72),
                        height: MediaQuery.of(context).size.height * 0.22,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: const Color(0xFFF5F5F5),
                          image: _coverImage != null
                              ? DecorationImage(
                                  image: FileImage(_coverImage!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _coverImage == null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      size: 48,
                                      color: const Color(0xFF999999),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Ongeza picha ya jalada',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: const Color(0xFF666666),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Kichwa *',
                    hintText: 'Jina la mchango',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v?.trim().isEmpty == true ? 'Kichwa kinahitajika' : null,
                  maxLines: 1,
                  maxLength: 120,
                ),
                const SizedBox(height: 16),
                // Story
                TextFormField(
                  controller: _storyController,
                  decoration: const InputDecoration(
                    labelText: 'Hadithi / Maelezo *',
                    hintText: 'Eleza lengo la mchango na jinsi michango itatumika',
                    filled: true,
                    fillColor: Colors.white,
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v?.trim().isEmpty == true ? 'Maelezo yanahitajika' : null,
                  maxLines: 5,
                  maxLength: 2000,
                ),
                const SizedBox(height: 16),
                // Goal amount
                TextFormField(
                  controller: _goalController,
                  decoration: const InputDecoration(
                    labelText: 'Lengo (TSh) *',
                    hintText: 'Kiasi cha lengo',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v?.trim().isEmpty == true) return 'Kiasi cha lengo kinahitajika';
                    final n = double.tryParse(v!.trim());
                    if (n == null || n < 1000) return 'Lazima angalau TSh 1,000';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Category
                DropdownButtonFormField<CampaignCategory>(
                  value: _category,
                  decoration: const InputDecoration(
                    labelText: 'Aina ya mchango *',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                  items: CampaignCategory.values
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(
                              c.displayName,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ))
                      .toList(),
                  onChanged: _isLoading
                      ? null
                      : (v) {
                          if (v != null) setState(() => _category = v);
                        },
                ),
                const SizedBox(height: 24),
                // Bank / Mobile money section
                Text(
                  'Maelezo ya kupokea michango',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ongeza angalau benki au nambari ya pesa za simu',
                  style: TextStyle(fontSize: 12, color: const Color(0xFF666666)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bankNameController,
                  decoration: const InputDecoration(
                    labelText: 'Jina la benki',
                    hintText: 'Mf. CRDB, NMB',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _accountNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Nambari ya akaunti',
                    hintText: 'Nambari ya akaunti ya benki',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  maxLines: 1,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _mobileMoneyController,
                  decoration: const InputDecoration(
                    labelText: 'Pesa za simu (M-Pesa, Tigo Pesa, n.k.)',
                    hintText: '07XXXXXXXX',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  maxLines: 1,
                ),
                const SizedBox(height: 32),
                // Submit button – 48dp min height
                SizedBox(
                  height: 56,
                  child: Material(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(16),
                    elevation: 2,
                    child: InkWell(
                      onTap: _isLoading ? null : _submit,
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Hifadhi mchango',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
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
    );
  }
}
