import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/Core/Widgets/CommonHeader.dart';
import 'package:tailorapp/Core/Widgets/CustomSnakBar.dart';
import 'package:tailorapp/Core/Services/Services.dart';
import 'package:tailorapp/Core/Services/Urls.dart';
import 'package:tailorapp/GlobalVariables.dart';
import 'package:dio/dio.dart' show Dio, FormData, MultipartFile, DioMediaType, Response;
import 'package:http/http.dart' as http;

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _galleryImages = []; // Changed to store backend data
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadGalleryImages();
  }

  Future<void> _loadGalleryImages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final shopId = GlobalVariables.shopIdGet;
      if (shopId == null) {
        print('❌ Gallery: Shop ID is null');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('🔍 Gallery: Loading images from backend for shopId: $shopId');
      final response = await ApiService().get(
        '${Urls.gallery}/$shopId?pageNumber=1&pageSize=100',
        context,
      );

      if (response.data != null && response.data['success'] == true) {
        final images = response.data['data'] as List<dynamic>? ?? [];
        print('✅ Gallery: Loaded ${images.length} images from backend');
        
        setState(() {
          _galleryImages = images.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        print('⚠️ Gallery: No images found or invalid response');
        setState(() {
          _galleryImages = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Gallery: Error loading images: $e');
      setState(() {
        _galleryImages = [];
        _isLoading = false;
      });
      if (mounted) {
        CustomSnackbar.showSnackbar(
          context,
          'Error loading gallery images: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _showImagePickerOptions() async {
    print('🔵 Gallery: _showImagePickerOptions called');
    
    try {
      if (kIsWeb) {
        print('🔵 Gallery: Running on web, opening file picker directly');
        // On web, directly open file picker
        await _pickFromGallery();
        return;
      }

      print('🔵 Gallery: Running on mobile, showing bottom sheet');
      // On mobile, show bottom sheet
      await showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (BuildContext context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                children: [
                  ListTile(
                    leading: const Icon(Icons.camera_alt, color: ColorPalatte.primary),
                    title: const Text("Take Photo"),
                    onTap: () {
                      Navigator.pop(context);
                      _pickFromCamera();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library, color: ColorPalatte.primary),
                    title: const Text("Choose from Gallery"),
                    onTap: () {
                      Navigator.pop(context);
                      _pickFromGallery();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e, stackTrace) {
      print('❌ Gallery: Error in _showImagePickerOptions: $e');
      print('❌ Gallery: Stack trace: $stackTrace');
      if (mounted) {
        CustomSnackbar.showSnackbar(
          context,
          'Error: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      print('📷 Gallery: Starting camera...');
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        print('📷 Gallery: Image captured: ${pickedFile.name}');
        await _uploadImageToBackend(pickedFile);
      }
    } catch (e) {
      print('❌ Gallery: Camera error: $e');
      if (mounted) {
        CustomSnackbar.showSnackbar(
          context,
          'Error taking photo: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      print('🖼️ Gallery: Opening file picker...');
      
      // Use pickMultiImage for multiple selection
      final List<XFile>? pickedFiles = await _picker.pickMultiImage(
        imageQuality: 85,
      );

      print('🖼️ Gallery: Files selected: ${pickedFiles?.length ?? 0}');

      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        print('🖼️ Gallery: Processing ${pickedFiles.length} image(s)');
        
        // Upload all selected images
        for (var file in pickedFiles) {
          await _uploadImageToBackend(file);
        }

        print('✅ Gallery: Uploaded ${pickedFiles.length} image(s)');
      } else {
        print('⚠️ Gallery: No files selected');
      }
    } catch (e, stackTrace) {
      print('❌ Gallery: Error picking images: $e');
      print('❌ Gallery: Stack trace: $stackTrace');
      if (mounted) {
        CustomSnackbar.showSnackbar(
          context,
          'Error selecting images: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _uploadImageToBackend(XFile imageFile) async {
    final shopId = GlobalVariables.shopIdGet;
    if (shopId == null) {
      if (mounted) {
        CustomSnackbar.showSnackbar(context, 'Shop ID is missing');
      }
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      print('📤 Gallery: Uploading image to backend...');
      
      Response response;
      
      if (kIsWeb) {
        // On web, read bytes from XFile
        final bytes = await imageFile.readAsBytes();
        String fileName = imageFile.name;
        if (fileName.isEmpty) {
          final pathParts = imageFile.path.split('/');
          if (pathParts.isNotEmpty) {
            fileName = pathParts.last;
            if (fileName.contains('?')) {
              fileName = fileName.split('?').first;
            }
          }
        }
        if (fileName.isEmpty || !fileName.contains('.')) {
          fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        }

        final formData = FormData.fromMap({
          'shopId': shopId.toString(),
          'owner': GlobalVariables.userId?.toString() ?? '',
          'file': MultipartFile.fromBytes(
            bytes,
            filename: fileName,
            contentType: DioMediaType.parse('image/jpeg'),
          ),
        });

        response = await ApiService().postFormData(
          '${Urls.gallery}/$shopId/upload',
          context,
          formData,
        );
      } else {
        // On mobile, use File
        final file = File(imageFile.path);
        response = await ApiService().uploadMediaFile(
          '${Urls.gallery}/$shopId/upload',
          context,
          file: file,
          fields: {
            'shopId': shopId.toString(),
            'owner': GlobalVariables.userId?.toString() ?? '',
          },
        );
      }

      if (response.data != null && response.data['success'] == true) {
        print('✅ Gallery: Image uploaded successfully');
        // Reload gallery images from backend
        await _loadGalleryImages();
        if (mounted) {
          CustomSnackbar.showSnackbar(context, 'Image uploaded successfully');
        }
      } else {
        throw Exception('Upload failed: ${response.data?['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('❌ Gallery: Error uploading image: $e');
      if (mounted) {
        CustomSnackbar.showSnackbar(
          context,
          'Error uploading image: ${e.toString()}',
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _deleteImage(int index) async {
    final image = _galleryImages[index];
    final galleryId = image['galleryId'];
    final shopId = GlobalVariables.shopIdGet;

    if (shopId == null || galleryId == null) {
      if (mounted) {
        CustomSnackbar.showSnackbar(context, 'Cannot delete: missing shop ID or gallery ID');
      }
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Image'),
          content: const Text('Are you sure you want to delete this image?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteImageFromBackend(shopId, galleryId);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteImageFromBackend(int shopId, int galleryId) async {
    try {
      print('🗑️ Gallery: Deleting image galleryId: $galleryId');
      
      final response = await ApiService().delete(
        '${Urls.gallery}/$shopId/$galleryId',
        context,
      );

      if (response.data != null && response.data['success'] == true) {
        print('✅ Gallery: Image deleted successfully');
        // Reload gallery images from backend
        await _loadGalleryImages();
        if (mounted) {
          CustomSnackbar.showSnackbar(context, 'Image deleted successfully');
        }
      } else {
        throw Exception('Delete failed: ${response.data?['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('❌ Gallery: Error deleting image: $e');
      if (mounted) {
        CustomSnackbar.showSnackbar(
          context,
          'Error deleting image: ${e.toString()}',
        );
      }
    }
  }

  void _viewImage(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: _buildImageWidget(_galleryImages[index]),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageWidget(Map<String, dynamic> imageData) {
    final imageUrl = imageData['imageUrl']?.toString() ?? '';
    
    // Check if URL is already a full URL (S3 URLs start with https://)
    final fullImageUrl = imageUrl.startsWith('http://') || imageUrl.startsWith('https://')
        ? imageUrl
        : '${Urls.baseUrl}$imageUrl';
    
    return Image.network(
      fullImageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[200],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[200],
          child: const Center(
            child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalatte.white,
      appBar: Commonheader(
        title: 'Gallery',
        showBackArrow: false,
      ),
      body: (_isLoading || _isUploading)
          ? const Center(child: CircularProgressIndicator())
          : _galleryImages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No images in gallery',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the upload button to add images',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () {
                          print('🔵 Gallery: Upload button clicked (empty state)');
                          _showImagePickerOptions();
                        },
                        icon: const Icon(Icons.upload, color: Colors.white, size: 24),
                        label: const Text(
                          'Upload Images',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorPalatte.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          print('🔵 Gallery: Upload More button clicked');
                          _showImagePickerOptions();
                        },
                        icon: const Icon(Icons.upload, color: Colors.white, size: 20),
                        label: const Text(
                          'Upload More Images',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorPalatte.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1,
                        ),
                        itemCount: _galleryImages.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => _viewImage(index),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: _buildImageWidget(_galleryImages[index]),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _deleteImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

