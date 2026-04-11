import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'DataStore.dart';

import 'HttpService.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';

class imagePicker extends StatefulWidget {
  const imagePicker({super.key});

  @override
  _ImagePickerScreenState createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<imagePicker> 
    with SingleTickerProviderStateMixin {
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      colors: true,
      printEmojis: true,
    ),
  );

  // Core state
  List<File> _imageFiles = [];
  String? _pickImageError;
  bool _isUploading = false;
  int _currentImageIndex = 0;
  
  // Controllers
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Image editing state
  double _imageRotation = 0;
  
  // Constants - Monochrome color palette
  static const Color primaryColor = Color(0xFF1A1A1A);
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF1A1A1A);
  static const Color secondaryTextColor = Color(0xFF666666);
  static const Color dividerColor = Color(0xFFE0E0E0);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _captionController.dispose();
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, {bool multiple = false}) async {
    _logger.i('Attempting to pick image from ${source.toString()}');
    try {
      if (multiple && source == ImageSource.gallery) {
        final pickedFiles = await _picker.pickMultiImage(
          imageQuality: 85,
        );
        if (pickedFiles.isNotEmpty) {
          setState(() {
            _imageFiles = pickedFiles.map((xFile) => File(xFile.path)).toList();
            _pickImageError = null;
          });
          _logger.d('${pickedFiles.length} images selected');
        }
      } else {
        final pickedFile = await _picker.pickImage(
          source: source,
          imageQuality: 85,
        );
        if (pickedFile != null) {
          _logger.d('Image selected: ${pickedFile.path}');
          setState(() {
            _imageFiles = [File(pickedFile.path)];
            _pickImageError = null;
          });
        }
      }
    } catch (e) {
      _logger.e('Error picking image: $e');
      setState(() {
        _pickImageError = 'Failed to pick image: ${e.toString()}';
      });
      _showErrorSnackbar('Failed to pick image');
    }
  }

  Future<File> _compressImage(File imageFile) async {
    try {
      _logger.d('Compressing image: ${imageFile.path}');
      
      // Read image
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      
      if (image == null) return imageFile;
      
      // Resize if too large (max 1920px on longest side)
      if (image.width > 1920 || image.height > 1920) {
        if (image.width > image.height) {
          image = img.copyResize(image, width: 1920);
        } else {
          image = img.copyResize(image, height: 1920);
        }
      }
      
      // Apply rotation if needed
      if (_imageRotation != 0) {
        image = img.copyRotate(image, angle: _imageRotation.toInt());
      }
      
      // Compress and save
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${const Uuid().v4()}.jpg');
      await tempFile.writeAsBytes(img.encodeJpg(image, quality: 85));
      
      _logger.d('Image compressed successfully');
      return tempFile;
    } catch (e) {
      _logger.e('Error compressing image: $e');
      return imageFile;
    }
  }

  Future<void> _uploadImages() async {
    if (_imageFiles.isEmpty) {
      _showErrorSnackbar('Please select at least one image');
      return;
    }

    if (_isUploading) return;

    setState(() => _isUploading = true);

    _logger.i('Starting image upload process for ${_imageFiles.length} images');
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildUploadDialog(),
    );

    try {
      final kikobaId = DataStore.currentKikobaId;
      final userId = DataStore.currentUserId;
      final userNumber = DataStore.userNumber;
      final userName = DataStore.currentUserName;
      final caption = _captionController.text.trim();
      
      int successfulUploads = 0;
      int failedUploads = 0;

      for (int i = 0; i < _imageFiles.length; i++) {
        final postId = const Uuid().v4();
        final timestamp = DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
        
        try {
          // Compress image before upload
          final compressedImage = await _compressImage(_imageFiles[i]);
          
          // Upload to server
          final imageUrl = await uploadImageToServer(
            imageFile: compressedImage,
            kikobaId: postId,
          );

          if (imageUrl != null && imageUrl.isNotEmpty) {
            _logger.i('Image ${i + 1} uploaded successfully. URL: $imageUrl');
            
            // Save to Firestore with the server URL
            await FirebaseFirestore.instance
                .collection('${kikobaId}barazaMessages')
                .add({
              'posterName': userName,
              'posterId': userId,
              'posterNumber': userNumber,
              'posterPhoto': "",
              'postComment': i == 0 ? caption : '', // Only add caption to first image
              'localpostImage': compressedImage.path,
              'remotepostImage': imageUrl,
              'postImage': '',
              'postType': 'textImage',
              'postId': postId,
              'postTime': timestamp,
              'kikobaId': kikobaId,
              'imageIndex': i,
              'totalImages': _imageFiles.length,
            });
            
            successfulUploads++;
          } else {
            _logger.w('Image ${i + 1} upload returned empty URL');
            failedUploads++;
          }
        } catch (e) {
          _logger.e('Failed to upload image ${i + 1}: $e');
          failedUploads++;
        }
      }

      if (successfulUploads > 0) {
        _logger.i('Upload complete: $successfulUploads succeeded, $failedUploads failed');
        if (failedUploads > 0) {
          _showSuccessSnackbar('$successfulUploads of ${_imageFiles.length} images uploaded');
        }
        _navigateBackToHome();
      } else {
        throw Exception('All uploads failed. Please check your connection.');
      }
    } catch (e, stackTrace) {
      _logger.e('Error in upload process', error: e, stackTrace: stackTrace);
      _showErrorSnackbar('Upload failed: ${e.toString()}');
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() => _isUploading = false);
      }
    }
  }

  Widget _buildUploadDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  color: primaryColor,
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Uploading Images',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Processing ${_imageFiles.length} ${_imageFiles.length == 1 ? 'image' : 'images'}...',
              style: const TextStyle(
                fontSize: 14,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Please wait, this may take a moment',
              style: TextStyle(
                fontSize: 12,
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _navigateBackToHome() {
    _logger.d('Navigating back to home');
    Navigator.of(context).pop();
  }

  Widget _buildImagePreview() {
    if (_pickImageError != null) {
      return _buildErrorState();
    }

    if (_imageFiles.isEmpty) {
      return _buildEmptyState();
    }

    return _buildImageCarousel();
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_photo_alternate_rounded,
                size: 60,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Add Photos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share moments with your group',
              style: TextStyle(
                fontSize: 14,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onTap: () => _pickImage(ImageSource.gallery, multiple: true),
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: primaryColor, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: secondaryTextColor,
          ),
          const SizedBox(height: 16),
          Text(
            _pickImageError!,
            style: const TextStyle(color: secondaryTextColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _pickImageError = null;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Try Again',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index;
            });
          },
          itemCount: _imageFiles.length,
          itemBuilder: (context, index) {
            return _buildImageView(_imageFiles[index]);
          },
        ),
        if (_imageFiles.length > 1) _buildImageIndicator(),
        _buildImageEditingControls(),
      ],
    );
  }

  Widget _buildImageView(File imageFile) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(imageFile),
      child: Transform.rotate(
        angle: _imageRotation * (3.14159 / 180),
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              imageFile,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageIndicator() {
    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _imageFiles.length,
          (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentImageIndex == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: _currentImageIndex == index
                  ? primaryColor
                  : secondaryTextColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageEditingControls() {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEditButton(
              icon: Icons.rotate_left_rounded,
              onTap: () {
                setState(() {
                  _imageRotation = (_imageRotation - 90) % 360;
                });
              },
            ),
            Container(width: 1, height: 24, color: dividerColor),
            _buildEditButton(
              icon: Icons.rotate_right_rounded,
              onTap: () {
                setState(() {
                  _imageRotation = (_imageRotation + 90) % 360;
                });
              },
            ),
            Container(width: 1, height: 24, color: dividerColor),
            _buildEditButton(
              icon: Icons.delete_outline_rounded,
              onTap: () {
                setState(() {
                  _imageFiles.removeAt(_currentImageIndex);
                  if (_currentImageIndex > 0) {
                    _currentImageIndex--;
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            size: 20,
            color: primaryColor,
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(File imageFile) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PhotoView(
              imageProvider: FileImage(imageFile),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3,
              backgroundDecoration: const BoxDecoration(
                color: Colors.black,
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_imageFiles.isEmpty) ...[
            _buildBottomButton(
              icon: Icons.photo_library_rounded,
              onTap: () => _pickImage(ImageSource.gallery, multiple: true),
            ),
            const SizedBox(width: 8),
            _buildBottomButton(
              icon: Icons.camera_alt_rounded,
              onTap: () => _pickImage(ImageSource.camera),
            ),
            const SizedBox(width: 12),
          ] else ...[
            _buildBottomButton(
              icon: Icons.add_photo_alternate_rounded,
              onTap: () => _pickImage(ImageSource.gallery, multiple: true),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _captionController,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Add a caption...',
                  hintStyle: const TextStyle(
                    color: secondaryTextColor,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(
                  color: textColor,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildBottomButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Icon(
            icon,
            size: 20,
            color: primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    final hasImages = _imageFiles.isNotEmpty;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: hasImages ? primaryColor : backgroundColor,
        shape: BoxShape.circle,
        boxShadow: hasImages
            ? [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hasImages ? _uploadImages : null,
          borderRadius: BorderRadius.circular(24),
          child: Icon(
            Icons.send_rounded,
            size: 22,
            color: hasImages ? Colors.white : secondaryTextColor,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0.5,
        toolbarHeight: 60,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Share Photos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            if (_imageFiles.isNotEmpty)
              Text(
                '${_imageFiles.length} ${_imageFiles.length == 1 ? 'photo' : 'photos'} selected',
                style: const TextStyle(
                  fontSize: 12,
                  color: secondaryTextColor,
                ),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_imageFiles.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  _imageFiles.clear();
                  _currentImageIndex = 0;
                  _imageRotation = 0;
                });
              },
              child: const Text(
                'Clear All',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _buildImagePreview(),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Future<String?> uploadImageToServer({
    required File imageFile,
    required String kikobaId,
  }) async {
    final uri = Uri.parse('${HttpService.baseUrl}upload-post-images');

    try {
      // Determine the content type based on file extension
      String contentType = 'image/jpeg';
      final extension = imageFile.path.split('.').last.toLowerCase();
      if (extension == 'png') {
        contentType = 'image/png';
      } else if (extension == 'gif') {
        contentType = 'image/gif';
      } else if (extension == 'webp') {
        contentType = 'image/webp';
      }

      var request = http.MultipartRequest('POST', uri)
        ..fields['kikobaId'] = kikobaId
        ..files.add(
          await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
            contentType: MediaType.parse(contentType),
          ),
        );

      _logger.d('Uploading to: $uri');
      var response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        _logger.d('Upload successful: $responseBody');
        return responseBody.trim(); // Trim any whitespace
      } else {
        _logger.e('Upload failed with status: ${response.statusCode}');
        final errorBody = await response.stream.bytesToString();
        _logger.e('Error response: $errorBody');
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error uploading image: $e');
      rethrow; // Re-throw to handle in calling function
    }
  }
}