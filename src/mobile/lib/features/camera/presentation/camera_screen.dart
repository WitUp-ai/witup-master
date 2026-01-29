import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/camera_provider.dart';

/// Camera screen for capturing drawings
class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _capturedImage;
  Uint8List? _imageBytes;
  bool _isProcessing = false;

  Future<void> _captureFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (image != null) {
        await _processImage(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (image != null) {
        await _processImage(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gallery error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _processImage(XFile image) async {
    setState(() {
      _capturedImage = image;
      _isProcessing = true;
    });

    // Read image bytes for preview
    final bytes = await image.readAsBytes();

    setState(() {
      _imageBytes = bytes;
      _isProcessing = false;
    });
  }

  void _retakePhoto() {
    setState(() {
      _capturedImage = null;
      _imageBytes = null;
    });
  }

  Future<void> _confirmAndProcess() async {
    if (_capturedImage == null || _imageBytes == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Upload to provider for processing
      await ref.read(cameraProvider.notifier).uploadDrawing(
        _capturedImage!,
        _imageBytes!,
      );

      // Get the drawing ID from the provider
      final drawingId = ref.read(cameraProvider).lastDrawingId;

      if (mounted) {
        if (drawingId != null) {
          // Navigate to processing screen with the drawing ID
          context.go('/processing/$drawingId');
        } else {
          // Fallback: show success and go home
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Drawing captured! Processing magic... ✨'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          _capturedImage == null ? 'Capture Drawing' : 'Preview',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: _capturedImage == null
          ? _buildCaptureView()
          : _buildPreviewView(),
    );
  }

  Widget _buildCaptureView() {
    return SafeArea(
      child: Column(
        children: [
          // Instructions
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceL),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.draw,
                        size: 80,
                        color: AppTheme.primaryColor,
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.1, 1.1),
                          duration: 1500.ms,
                        ),

                    const SizedBox(height: AppTheme.spaceXL),

                    const Text(
                      'Ready to capture your drawing!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppTheme.spaceM),

                    Text(
                      'Take a photo of your drawing or select from gallery.\nMake sure the drawing is well-lit and clearly visible.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppTheme.space2XL),

                    // Tips
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spaceM),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: Column(
                        children: [
                          _buildTip(Icons.wb_sunny, 'Good lighting'),
                          const SizedBox(height: AppTheme.spaceS),
                          _buildTip(Icons.crop_square, 'Flat surface'),
                          const SizedBox(height: AppTheme.spaceS),
                          _buildTip(Icons.visibility, 'Clear lines'),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 500.ms)
                        .slideY(begin: 0.2),
                  ],
                ),
              ),
            ),
          ),

          // Action buttons - Show Gallery prominently on web
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceL),
            child: kIsWeb
                ? Column(
                    children: [
                      // On web, show Gallery as primary option
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton.icon(
                          onPressed: _pickFromGallery,
                          icon: const Icon(Icons.photo_library, size: 28),
                          label: const Text(
                            'Select from Gallery',
                            style: TextStyle(fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceM),
                      const Text(
                        'Camera not available on web browser',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Gallery button
                      _CaptureButton(
                        icon: Icons.photo_library,
                        label: 'Gallery',
                        onPressed: _pickFromGallery,
                        isPrimary: false,
                      ),

                      // Camera button
                      _CaptureButton(
                        icon: Icons.camera_alt,
                        label: 'Camera',
                        onPressed: _captureFromCamera,
                        isPrimary: true,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.accentColor, size: 20),
        const SizedBox(width: AppTheme.spaceS),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewView() {
    return SafeArea(
      child: Column(
        children: [
          // Image preview
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(AppTheme.spaceM),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                boxShadow: AppTheme.shadowLarge,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  _imageBytes != null
                      ? Image.memory(
                          _imageBytes!,
                          fit: BoxFit.contain,
                        )
                      : const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),

                  // Loading overlay
                  if (_isProcessing)
                    Container(
                      color: Colors.black54,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: AppTheme.accentColor,
                            ),
                            const SizedBox(height: AppTheme.spaceM),
                            const Text(
                              'Processing magic...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            )
                                .animate(onPlay: (c) => c.repeat())
                                .shimmer(duration: 1500.ms),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          )
              .animate()
              .scale(duration: 300.ms, curve: Curves.easeOut)
              .fadeIn(),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceL),
            child: Row(
              children: [
                // Retake button
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _retakePhoto,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retake'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: AppTheme.spaceM),

                // Confirm button
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _confirmAndProcess,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Create Magic!'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Capture button widget
class _CaptureButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _CaptureButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: isPrimary ? 80 : 60,
            height: isPrimary ? 80 : 60,
            decoration: BoxDecoration(
              gradient: isPrimary ? AppTheme.magicGradient : null,
              color: isPrimary ? null : Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: isPrimary ? 4 : 2,
              ),
              boxShadow: isPrimary ? AppTheme.shadowMedium : null,
            ),
            child: Icon(
              icon,
              size: isPrimary ? 40 : 28,
              color: Colors.white,
            ),
          ),
        )
            .animate()
            .scale(duration: 300.ms, curve: Curves.elasticOut),
        const SizedBox(height: AppTheme.spaceS),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
