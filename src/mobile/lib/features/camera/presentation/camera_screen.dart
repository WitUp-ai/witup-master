import 'dart:typed_data';
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
    if (_capturedImage == null || _imageBytes == null) {
      debugPrint('DEBUG: No image captured');
      return;
    }

    debugPrint('DEBUG: Starting upload process...');
    setState(() {
      _isProcessing = true;
    });

    try {
      debugPrint('DEBUG: Calling uploadDrawing...');

      // Show starting dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const AlertDialog(
          title: Text('DEBUG'),
          content: Text('Starting upload...'),
        ),
      );

      final drawingId = await ref.read(cameraProvider.notifier).uploadDrawing(
        _capturedImage!,
        _imageBytes!,
      );

      debugPrint('DEBUG: Upload completed, drawing ID: $drawingId');

      if (!mounted) return;

      // Close debug dialog
      Navigator.of(context).pop();

      // Show result dialog
      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('DEBUG: Upload Result'),
          content: Text('Drawing ID: $drawingId\nMounted: $mounted\nWill navigate: ${drawingId != null}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (!mounted) return;

      if (drawingId != null) {
        debugPrint('DEBUG: About to navigate to /processing/$drawingId');

        // Show navigation dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => const AlertDialog(
            title: Text('DEBUG'),
            content: Text('Navigating to processing...'),
          ),
        );

        // Small delay to see the dialog
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        debugPrint('DEBUG: Executing context.go...');
        context.go('/processing/$drawingId');
        debugPrint('DEBUG: context.go executed');
      } else {
        debugPrint('DEBUG: No drawing ID - showing error');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ERROR: Drawing uploaded but no ID returned'),
            backgroundColor: AppTheme.errorColor,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      debugPrint('DEBUG: Upload ERROR: $e');
      if (!mounted) return;

      // Close any open dialogs
      Navigator.of(context).popUntil((route) => route.isFirst);

      // Show error dialog
      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Upload Failed'),
          content: Text('Error: ${e.toString()}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceL),
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.draw,
                size: 52,
                color: AppTheme.primaryColor,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.08, 1.08),
                  duration: 1500.ms,
                ),

            const SizedBox(height: AppTheme.spaceL),

            const Text(
              'Cattura il tuo disegno!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppTheme.spaceS),

            Text(
              'Scatta una foto o seleziona dalla galleria.\nAssicurati che il disegno sia ben illuminato.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppTheme.spaceL),

            // Tips - compact horizontal row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildChip(Icons.wb_sunny, 'Luce'),
                const SizedBox(width: 10),
                _buildChip(Icons.crop_square, 'Piano'),
                const SizedBox(width: 10),
                _buildChip(Icons.visibility, 'Nitido'),
              ],
            )
                .animate()
                .fadeIn(delay: 400.ms),

            const Spacer(flex: 3),

            // Action buttons
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _captureFromCamera,
                icon: const Icon(Icons.camera_alt, size: 22),
                label: const Text(
                  'Scatta Foto',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library, size: 20),
                label: const Text(
                  'Carica da Galleria',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spaceL),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.accentColor, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
            ),
          ),
        ],
      ),
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

