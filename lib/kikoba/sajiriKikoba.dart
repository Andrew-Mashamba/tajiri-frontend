import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import 'HttpService.dart';
import 'DataStore.dart';
// import 'main.dart'; // removed — auth handled by TAJIRI bridge
import 'vicobaList.dart';
import 'waitDialog.dart';

class sajiriKikoba extends StatefulWidget {
  const sajiriKikoba({super.key});

  @override
  State<sajiriKikoba> createState() => _SajiriKikobaState();
}

class _SajiriKikobaState extends State<sajiriKikoba> {
  final Logger _logger = Logger();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _kikobaNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String _selectedRole = "Mjumbe";
  File? _selectedImage;
  bool _isLoading = false;
  bool _hasValidationError = false;
  String? _validationErrorMessage;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _logger.i('SajiriKikoba initialized');
  }

  @override
  void dispose() {
    _kikobaNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    _logger.d('Picking image from source: $source');
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        _logger.i('Image selected: ${pickedFile.path}');
      }
    } catch (e, stackTrace) {
      _logger.e('Error picking image', error: e, stackTrace: stackTrace);
      _showErrorDialog("Kuna tatizo la kuchagua picha. Tafadhali jaribu tena");
    }
  }

  Future<void> _submitForm() async {
    _logger.d('Submitting kikoba creation form');

    if (!_formKey.currentState!.validate()) {
      _logger.w('Form validation failed');
      return;
    }

    setState(() {
      _isLoading = true;
      _hasValidationError = false;
    });

    try {
      // Prepare data for submission
      DataStore.createKikobaName = _kikobaNameController.text;
      DataStore.createKikobaMaelezo = _descriptionController.text;
      DataStore.createKikobaEneo = _locationController.text;

      final uuid = const Uuid().v4();
      DataStore.currentKikobaId = uuid;

      // Show improved loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const waitDialog(
          title: "Inasajili Kikoba",
          descriptions: "Tafadhali subiri, tunasajili kikoba chako...",
          text: "",
        ),
      );

      // Handle image upload if exists
      String imageUrl = "noimage";
      if (_selectedImage != null) {
        _logger.d('Starting image upload...');
        try {
          // Check if file exists and is readable
          if (!await _selectedImage!.exists()) {
            throw Exception('Selected image file no longer exists');
          }
          
          imageUrl = await _uploadImagex(uuid);
          _logger.i('Image uploaded successfully to Firebase');
        } catch (e, stackTrace) {
          // Image upload failed, but we can still continue without image
          _logger.w('Image upload failed, continuing without image: $e', stackTrace: stackTrace);
          imageUrl = "noimage";
          
          // Show user a message about image upload failure
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Picha haikuweza kupakiwa, lakini kikoba kitaendelea kusajiliwa'),
                duration: Duration(seconds: 3),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      // Submit to server
      _logger.d('Creating kikoba with imageUrl: $imageUrl');
      await _createKikoba(imageUrl);

    } catch (e, stackTrace) {
      _logger.e('Error submitting form', error: e, stackTrace: stackTrace);
      
      // Show user-friendly error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kuna tatizo la kuunda kikoba. Tafadhali jaribu tena.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        // Close loading dialog if it's still open
        if (Navigator.canPop(context)) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      }
    }
  }

  Future<String> _uploadImagex(String kikobaId) async {
    _logger.d('Uploading image for kikoba: $kikobaId to remote server');

    try {
      // Check if file exists and is readable
      if (!await _selectedImage!.exists()) {
        throw Exception('Selected image file no longer exists');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = "kikoba_${kikobaId}_$timestamp.jpg";
      
      _logger.d('Starting upload to remote server: $fileName');
      
      // Read file bytes
      final fileBytes = await _selectedImage!.readAsBytes();
      _logger.d('File size: ${fileBytes.length} bytes');
      
      // Create multipart request  
      final uri = Uri.parse('http://172.240.241.179:8001/api/upload-image');
      final request = http.MultipartRequest('POST', uri);
      
      // Add the image file
      request.files.add(http.MultipartFile.fromBytes(
        'image', // field name
        fileBytes,
        filename: fileName,
        contentType: MediaType('image', 'jpeg'),
      ));
      
      // Add metadata (server expects camelCase field names)
      request.fields['kikobaId'] = kikobaId;  // Changed from kikoba_id to kikobaId
      
      _logger.d('Sending multipart request to server...');
      _logger.d('Request fields: ${request.fields}');
      _logger.d('Request files: ${request.files.map((f) => f.field).toList()}');
      
      // Send request with timeout
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Upload timeout after 30 seconds');
        },
      );
      
      final response = await http.Response.fromStream(streamedResponse);
      _logger.d('Server response status: ${response.statusCode}');
      _logger.d('Server response body: ${response.body}');
      
      // Handle redirects (3xx status codes)
      if (response.statusCode >= 300 && response.statusCode < 400) {
        _logger.w('Server returned redirect (${response.statusCode}). This might indicate incorrect endpoint.');
        // For now, treat redirect as success and construct URL
        final constructedUrl = 'http://172.240.241.179:8001/storage/$fileName';
        _logger.i('Using constructed URL after redirect: $constructedUrl');
        return constructedUrl;
      } else if (response.statusCode == 200 || response.statusCode == 201) {
        // Try to parse response
        try {
          final responseData = json.decode(response.body);
          final imageUrl = responseData['url'] ?? responseData['image_url'] ?? responseData['path'];
          
          if (imageUrl != null) {
            _logger.i('Image uploaded successfully. URL: $imageUrl');
            return imageUrl;
          } else {
            // If no URL in response, use a constructed path
            final constructedUrl = 'http://172.240.241.179:8001/storage/$fileName';
            _logger.i('Using constructed URL: $constructedUrl');
            return constructedUrl;
          }
        } catch (e) {
          // If JSON parsing fails, construct URL
          final constructedUrl = 'http://172.240.241.179:8001/storage/$fileName';
          _logger.w('Could not parse server response, using constructed URL: $constructedUrl');
          return constructedUrl;
        }
      } else {
        throw Exception('Upload failed with status code: ${response.statusCode}, body: ${response.body}');
      }
      
    } catch (e, stackTrace) {
      _logger.e('Error uploading image to remote server', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }





  Future<void> _createKikoba(String imageUrl) async {
    _logger.d('Creating kikoba with image URL: $imageUrl');

    try {
      final result = await HttpService.createKikoba(imageUrl, _selectedRole);
      _logger.d('Kikoba creation result: $result');

      // Check if the result is an HTML error response (server error)
      if (result.contains('<!DOCTYPE html') || result.contains('<html')) {
        _logger.w('Server returned HTML error page instead of JSON response');
        
        // Try to extract error message from HTML
        String errorMessage = "Kuna tatizo la seva ya data";
        
        if (result.contains('SQLSTATE') || result.contains('Column not found')) {
          errorMessage = "Kuna tatizo la muundo wa data, tafadhali jaribu tena baadaye";
          _logger.w('Database schema error detected in server response');
        } else if (result.contains('500') || result.contains('Internal Server Error')) {
          errorMessage = "Kuna tatizo la seva, tafadhali jaribu tena baadaye";
          _logger.w('Internal server error detected');
        }
        
        // Close loading dialog first
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        _showErrorDialog(errorMessage);
        return;
      }

      // Parse JSON response - API returns {"message": "success"} or {"message": "error"}
      bool isSuccess = false;
      try {
        final jsonResponse = json.decode(result);
        if (jsonResponse is Map<String, dynamic>) {
          final message = jsonResponse['message']?.toString().toLowerCase();
          isSuccess = message == 'success';
        }
      } catch (e) {
        // Fallback: check for plain string "success" for backward compatibility
        isSuccess = result.trim().toLowerCase() == "success";
      }

      if (isSuccess) {
        _logger.i('Kikoba created successfully');
        DataStore.defaultTab = 4;

        Future.delayed(Duration.zero, () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const VikobaListPage()),
                (Route<dynamic> route) => false,
          );
        });
      } else if (result.contains("error")) {
        _logger.w('Kikoba creation failed with error response');
        // Close loading dialog first
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        _showErrorDialog("Kuna tatizo la kuunda kikoba, tafadhali jaribu tena");
      } else {
        _logger.w('Kikoba creation failed: $result');
        // Close loading dialog first
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        _showErrorDialog("Kuna tatizo la mtandao, tafadhali jaribu tena");
      }

    } catch (e, stackTrace) {
      _logger.e('Error creating kikoba', error: e, stackTrace: stackTrace);
      // Close loading dialog first
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      _showErrorDialog("Kuna tatizo la muunganisho, hakikisha una mtandao");
    }
  }

  void _showErrorDialog(String message) {
    _logger.w('Showing error dialog: $message');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Kuna tatizo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A1A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Sawa',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                      width: 120,
                      height: 120,
                    ),
                  )
                : const Icon(
                    Icons.group_rounded,
                    color: Color(0xFF666666),
                    size: 48,
                  ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _pickImage(ImageSource.gallery),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Nafasi yako katika kikundi",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        ...['Mwenyekiti', 'Katibu', 'Mjumbe'].map((role) {
          final isSelected = _selectedRole == role;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF1A1A1A) : const Color(0xFFE0E0E0),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() => _selectedRole = role);
                  _logger.d('Selected role: $role');
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? const Color(0xFF1A1A1A) : const Color(0xFF999999),
                            width: 2,
                          ),
                          color: isSelected ? const Color(0xFF1A1A1A) : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 12,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              role,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? const Color(0xFF1A1A1A) : const Color(0xFF666666),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              role == 'Mjumbe'
                                  ? "Kitambulisho chako hakita hitajika"
                                  : "Kitambulisho chako kita hitajika baadae",
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF999999),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int? maxLines,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines ?? 1,
        validator: validator,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF1A1A1A),
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(
            fontSize: 12,
            color: Color(0xFF666666),
          ),
          hintStyle: const TextStyle(
            fontSize: 12,
            color: Color(0xFF999999),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 56, maxHeight: 64),
      child: Material(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          onTap: _isLoading ? null : _submitForm,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "Sajiri Kikoba",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _logger.d('Building SajiriKikoba UI');

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Header Section
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A1A), size: 24),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        "Sajiri Kikoba",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 32),
                _buildImagePicker(),
                const SizedBox(height: 32),
                // Content Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Taarifa za kikundi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                      controller: _kikobaNameController,
                      label: 'Jina la kikundi',
                      hint: 'Andika jina la kikundi',
                      validator: (value) {
                        if (value == null || value.length < 4) {
                          return 'Jina la kikundi lazima liwe na herufi zaidi ya 3';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildFormField(
                      controller: _descriptionController,
                      label: 'Maelezo ya kikundi',
                      hint: 'Andika maelezo kuhusu kikundi',
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.length < 4) {
                          return 'Maelezo ya kikundi yanahitajika';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildFormField(
                      controller: _locationController,
                      label: 'Eneo',
                      hint: 'Dar es salaam, Ilala',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Tafadhali andika eneo la kikundi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildRoleSelector(),
                    const SizedBox(height: 24),
                    _buildSubmitButton(),
                    if (_hasValidationError)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          _validationErrorMessage ?? 'Tafadhali jaza taarifa zote kikamilifu',
                          style: const TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}