import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/group_service.dart';

/// Create Group screen (Story 41).
/// Navigation: Home → Profile → Groups tab → Unda Kikundi OR Groups discover → FAB Create.
class CreateGroupScreen extends StatefulWidget {
  final int creatorId;

  const CreateGroupScreen({super.key, required this.creatorId});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final GroupService _groupService = GroupService();

  static const Color _background = Color(0xFFFAFAFA);
  static const Color _primaryText = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);
  static const Color _accent = Color(0xFF999999);
  static const Color _buttonBg = Color(0xFFFFFFFF);

  String _privacy = 'public';
  bool _requiresApproval = false;
  File? _coverPhoto;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      setState(() => _coverPhoto = File(image.path));
    }
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _groupService.createGroup(
      creatorId: widget.creatorId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      privacy: _privacy,
      requiresApproval: _requiresApproval,
      coverPhoto: _coverPhoto,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kikundi kimeundwa')),
      );
      // Return the created group so caller can open its conversation (MESSAGES_BACKEND_IMPLEMENTATION_DIRECTIVE: one group = profile + conversation).
      Navigator.pop(context, result.group ?? true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Imeshindikana kuunda kikundi'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _buttonBg,
        foregroundColor: _primaryText,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        title: const Text(
          'Unda Kikundi',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _primaryText,
          ),
        ),
        actions: [
          SemanticButton(
            minSize: const Size(48, 48),
            onPressed: _isLoading ? null : _createGroup,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Unda', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCoverPhotoSection(),
                const SizedBox(height: 24),
                _buildNameField(),
                const SizedBox(height: 16),
                _buildDescriptionField(),
                const SizedBox(height: 24),
                _buildPrivacySection(),
                const SizedBox(height: 16),
                _buildRequiresApprovalSwitch(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoverPhotoSection() {
    return Semantics(
      button: true,
      label: 'Ongeza picha ya jalada',
      child: GestureDetector(
        onTap: _isLoading ? null : _pickCoverPhoto,
        child: Container(
          height: 150,
          constraints: const BoxConstraints(minHeight: 72),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            image: _coverPhoto != null
                ? DecorationImage(
                    image: FileImage(_coverPhoto!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: _coverPhoto == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate,
                        size: 48, color: _secondaryText),
                    const SizedBox(height: 8),
                    Text(
                      'Ongeza picha ya jalada',
                      style: TextStyle(
                        fontSize: 12,
                        color: _secondaryText,
                      ),
                    ),
                  ],
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      style: const TextStyle(color: _primaryText, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Jina la kikundi *',
        hintText: 'Weka jina la kikundi',
        labelStyle: const TextStyle(color: _secondaryText),
        hintStyle: const TextStyle(color: _accent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: _buttonBg,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Jina linahitajika';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 4,
      maxLength: 500,
      style: const TextStyle(color: _primaryText, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Maelezo',
        hintText: 'Eleza kikundi chako...',
        labelStyle: const TextStyle(color: _secondaryText),
        hintStyle: const TextStyle(color: _accent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: _buttonBg,
      ),
    );
  }

  Widget _buildPrivacySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Faragha',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _primaryText,
          ),
        ),
        const SizedBox(height: 12),
        _buildPrivacyOption(
          'public',
          'Wazi',
          'Kila mtu anaweza kuona na kujiunga',
          Icons.public,
        ),
        _buildPrivacyOption(
          'private',
          'Binafsi',
          'Kila mtu anaweza kuona lakini lazima kupata kibali kujiunga',
          Icons.lock,
        ),
        _buildPrivacyOption(
          'secret',
          'Siri',
          'Wanachama pekee wanaweza kuona',
          Icons.visibility_off,
        ),
      ],
    );
  }

  Widget _buildPrivacyOption(
    String value,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = _privacy == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: _buttonBg,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          onTap: _isLoading ? null : () => setState(() => _privacy = value),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? _primaryText : _secondaryText,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: _primaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: _secondaryText,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check, color: _primaryText, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequiresApprovalSwitch() {
    return Material(
      color: _buttonBg,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: SwitchListTile(
        title: const Text(
          'Hitaji kibali kujiunga',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: _primaryText,
          ),
        ),
        subtitle: const Text(
          'Wasimamizi lazima wakubali wanachama wapya',
          style: TextStyle(fontSize: 11, color: _secondaryText),
        ),
        value: _requiresApproval,
        onChanged: _isLoading
            ? null
            : (value) {
                setState(() => _requiresApproval = value);
              },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}

/// Wrapper to enforce 48dp minimum touch target (DESIGN.md).
class SemanticButton extends StatelessWidget {
  const SemanticButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.minSize = const Size(48, 48),
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Size minSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: minSize.width,
            minHeight: minSize.height,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
