import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';

/// Provider to fetch drawing data with signed URLs
final drawingDataProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, drawingId) async {
  try {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('drawings')
        .select()
        .eq('id', drawingId)
        .single();

    // Generate signed URL for original image if it's a storage path
    final originalPath = response['original_image_url'] as String?;
    if (originalPath != null && !originalPath.startsWith('http')) {
      try {
        final signedUrl = await supabase.storage
            .from('drawings-original')
            .createSignedUrl(originalPath, 86400); // 24 hours
        response['original_image_url'] = signedUrl;
      } catch (e) {
        debugPrint('Could not create signed URL for original: $e');
      }
    }

    return response;
  } catch (e) {
    return null;
  }
});

/// 3D Viewer and AR Preview Screen
class ViewerScreen extends ConsumerWidget {
  final String drawingId;

  const ViewerScreen({
    super.key,
    required this.drawingId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawingAsync = ref.watch(drawingDataProvider(drawingId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('3D Viewer'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareDrawing(context),
          ),
        ],
      ),
      body: drawingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorView(context, error.toString()),
        data: (drawing) {
          if (drawing == null) {
            return _buildErrorView(context, 'Drawing not found');
          }
          return _buildViewerContent(context, drawing);
        },
      ),
    );
  }

  Widget _buildViewerContent(BuildContext context, Map<String, dynamic> drawing) {
    final model3dUrl = drawing['model_3d_url'] as String?;
    final processedImageUrl = drawing['processed_image_url'] as String?;
    final originalImageUrl = drawing['original_image_url'] as String?;
    final title = drawing['title'] as String? ?? 'My Drawing';
    final status = drawing['model_status'] as String? ?? 'pending';

    return SingleChildScrollView(
      child: Column(
        children: [
          // 3D Model Viewer or Image Preview
          Container(
            height: 400,
            margin: const EdgeInsets.all(AppTheme.spaceM),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: AppTheme.shadowMedium,
            ),
            clipBehavior: Clip.antiAlias,
            child: model3dUrl != null
                ? _build3DViewer(model3dUrl)
                : _buildImagePreview(processedImageUrl ?? originalImageUrl, status),
          ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceL),
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: AppTheme.spaceM),

          // Status badge
          _buildStatusBadge(status),

          const SizedBox(height: AppTheme.spaceXL),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceL),
            child: Column(
              children: [
                // AR Button (if 3D model available)
                if (model3dUrl != null) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => _launchAR(context, model3dUrl),
                      icon: const Icon(Icons.view_in_ar, size: 28),
                      label: const Text(
                        'View in AR',
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
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                  const SizedBox(height: AppTheme.spaceM),
                ],

                // Order Physical Toy Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: status == 'completed' ? () => _orderToy(context) : null,
                    icon: const Icon(Icons.local_shipping, size: 24),
                    label: const Text(
                      'Order Physical Toy',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: status == 'completed'
                            ? AppTheme.primaryColor
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

                const SizedBox(height: AppTheme.spaceL),

                // Info card
                if (model3dUrl == null && status == 'completed')
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spaceM),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppTheme.accentColor),
                        const SizedBox(width: AppTheme.spaceM),
                        Expanded(
                          child: Text(
                            '3D model generation requires API configuration. The image has been processed and saved.',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spaceXL),
        ],
      ),
    );
  }

  Widget _build3DViewer(String modelUrl) {
    return ModelViewer(
      src: modelUrl,
      alt: "3D Model of your drawing",
      ar: true,
      autoRotate: true,
      cameraControls: true,
      disableZoom: false,
      backgroundColor: const Color(0xFFF5F5F5),
      loading: Loading.eager,
      poster: null,
    );
  }

  Widget _buildImagePreview(String? imageUrl, String status) {
    if (imageUrl == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == 'processing' ? Icons.hourglass_empty : Icons.image,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: AppTheme.spaceM),
            Text(
              status == 'processing'
                  ? 'Processing your drawing...'
                  : 'No preview available',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          imageUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stack) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: AppTheme.spaceM),
                  Text(
                    'Could not load image',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          },
        ),
        // 3D unavailable overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spaceM),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
            child: Text(
              status == 'processing_3d'
                  ? '2D Preview - 3D model is being generated...'
                  : '2D Preview - 3D model not yet available',
              style: const TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'completed':
        color = AppTheme.successColor;
        text = 'Ready';
        icon = Icons.check_circle;
        break;
      case 'processing':
      case 'processing_3d':
        color = AppTheme.accentColor;
        text = status == 'processing_3d' ? 'Generating 3D...' : 'Processing';
        icon = Icons.hourglass_empty;
        break;
      case 'failed':
        color = AppTheme.errorColor;
        text = 'Failed';
        icon = Icons.error;
        break;
      default:
        color = Colors.grey;
        text = 'Pending';
        icon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceM,
        vertical: AppTheme.spaceS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: AppTheme.spaceXS),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: AppTheme.spaceL),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spaceM),
            Text(
              error,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spaceXL),
            ElevatedButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.home),
              label: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }

  void _shareDrawing(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing feature coming soon!'),
      ),
    );
  }

  void _launchAR(BuildContext context, String modelUrl) {
    // On supported devices, model_viewer_plus handles AR automatically
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tap the AR icon in the 3D viewer to launch AR mode'),
      ),
    );
  }

  void _orderToy(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Physical toy ordering coming soon!'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }
}
