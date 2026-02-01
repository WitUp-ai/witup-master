import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';
import '../../../core/providers/auth_provider.dart';
import '../../camera/providers/camera_provider.dart';
import '../../admin/providers/admin_provider.dart';

/// Home screen - Main hub after authentication
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    _HomeTab(onSwitchTab: (i) => setState(() { _selectedIndex = i; })),
    const _GalleryTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _pages[_selectedIndex],
          Positioned(
            bottom: 4,
            right: 8,
            child: IgnorePointer(
              child: Text(
                'v${AppConfig.appVersion}+${AppConfig.appBuildNumber}',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
              ),
            ),
          ),
        ],
      ),
      // FAB Camera button - center prominent
      floatingActionButton: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: AppTheme.magicGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => context.push('/camera'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          child: const Icon(Icons.camera_alt, color: Colors.white, size: 30),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 16,
        color: Colors.white,
        surfaceTintColor: Colors.white,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Home tab
              _NavBarItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                isSelected: _selectedIndex == 0,
                onTap: () => setState(() { _selectedIndex = 0; }),
              ),
              // Spacer for FAB
              const SizedBox(width: 48),
              // Gallery 3D tab
              _NavBarItem(
                icon: Icons.view_in_ar_outlined,
                activeIcon: Icons.view_in_ar,
                label: 'Gallery 3D',
                isSelected: _selectedIndex == 1,
                onTap: () => setState(() { _selectedIndex = 1; }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom nav bar item
class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textTertiary,
              size: 26,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Home Tab - Main creative hub
class _HomeTab extends ConsumerWidget {
  final void Function(int) onSwitchTab;
  const _HomeTab({required this.onSwitchTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userName = authState.user?.userMetadata?['name'] ?? 'Creative Maker';
    final isAdmin = ref.watch(isAdminProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello,',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    Text(
                      userName,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                )
                    .animate()
                    .slideX(begin: -0.3, duration: 500.ms)
                    .fadeIn(),
                Row(
                  children: [
                    // Admin button (only for admins)
                    isAdmin.when(
                      data: (admin) => admin
                          ? Container(
                              width: 50,
                              height: 50,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: AppTheme.shadowSmall,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.admin_panel_settings,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                onPressed: () => context.go('/admin'),
                                tooltip: 'Admin Panel',
                              ),
                            )
                              .animate()
                              .scale(delay: 200.ms, duration: 500.ms)
                              .fadeIn()
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    // Profile menu with logout
                    PopupMenuButton<String>(
                      icon: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: AppTheme.magicGradient,
                          shape: BoxShape.circle,
                          boxShadow: AppTheme.shadowSmall,
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: Colors.white,
                        ),
                      ).animate().scale(delay: 300.ms, duration: 500.ms).fadeIn(),
                      offset: const Offset(0, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          enabled: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authState.user?.email ?? 'User',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const Divider(),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'profile',
                          child: Row(
                            children: [
                              Icon(Icons.person, size: 20, color: AppTheme.textSecondary),
                              SizedBox(width: 12),
                              Text('Profilo'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'settings',
                          child: Row(
                            children: [
                              Icon(Icons.settings, size: 20, color: AppTheme.textSecondary),
                              SizedBox(width: 12),
                              Text('Impostazioni'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, size: 20, color: AppTheme.errorColor),
                              SizedBox(width: 12),
                              Text(
                                'Logout',
                                style: TextStyle(color: AppTheme.errorColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) async {
                        switch (value) {
                          case 'profile':
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Profilo - In sviluppo')),
                            );
                            break;
                          case 'settings':
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Impostazioni - In sviluppo')),
                            );
                            break;
                          case 'logout':
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Conferma Logout'),
                                content: const Text('Sei sicuro di voler uscire?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: const Text('Annulla'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    child: const Text(
                                      'Esci',
                                      style: TextStyle(color: AppTheme.errorColor),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true && context.mounted) {
                              await ref.read(authProvider.notifier).signOut();
                              if (context.mounted) {
                                context.go('/login');
                              }
                            }
                            break;
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spaceXL),

            // Hero Card - Create New
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.heroGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                boxShadow: AppTheme.shadowLarge,
              ),
              padding: const EdgeInsets.all(AppTheme.spaceL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  Text(
                    'Bring Your Drawings to Life!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppTheme.spaceS),
                  Text(
                    'Draw on paper, snap a photo, and watch your creation transform into a 3D toy in seconds! ✨',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: AppTheme.spaceL),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.push('/camera');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryColor,
                      ),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text(
                        'Start Creating',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .slideY(begin: 0.3, duration: 600.ms)
                .fadeIn(delay: 200.ms),

            const SizedBox(height: AppTheme.spaceXL),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            )
                .animate()
                .slideX(begin: -0.2, duration: 500.ms)
                .fadeIn(delay: 400.ms),

            const SizedBox(height: AppTheme.spaceM),

            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.photo_library,
                    title: 'My Gallery',
                    color: AppTheme.accentColor,
                    onTap: () => onSwitchTab(1),
                  ).animate().scale(delay: 500.ms, duration: 400.ms).fadeIn(),
                ),
                const SizedBox(width: AppTheme.spaceM),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.shopping_bag,
                    title: 'Orders',
                    color: AppTheme.warningColor,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Orders coming soon!')),
                      );
                    },
                  ).animate().scale(delay: 600.ms, duration: 400.ms).fadeIn(),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spaceM),

            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.view_in_ar,
                    title: 'AR Preview',
                    color: AppTheme.secondaryColor,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('AR Preview coming soon!')),
                      );
                    },
                  ).animate().scale(delay: 700.ms, duration: 400.ms).fadeIn(),
                ),
                const SizedBox(width: AppTheme.spaceM),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.tips_and_updates,
                    title: 'Tips',
                    color: AppTheme.successColor,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tips & Tutorials coming soon!')),
                      );
                    },
                  ).animate().scale(delay: 800.ms, duration: 400.ms).fadeIn(),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spaceL),
          ],
        ),
      ),
    );
  }
}

/// Gallery Tab - View all creations from database
class _GalleryTab extends ConsumerWidget {
  const _GalleryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawingsAsync = ref.watch(recentDrawingsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Creations',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.invalidate(recentDrawingsProvider),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceM),
            Expanded(
              child: drawingsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text('Error: $error'),
                ),
                data: (drawings) {
                  if (drawings.isEmpty) {
                    return _buildEmptyGallery(context);
                  }
                  return _buildDrawingsGrid(context, drawings, ref);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyGallery(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.photo_library_outlined,
              size: 60,
              color: AppTheme.accentColor,
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: AppTheme.spaceL),
          Text(
            'No Creations Yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            'Start creating your first 3D toy!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawingsGrid(BuildContext context, List<Map<String, dynamic>> drawings, WidgetRef ref) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: drawings.length,
      itemBuilder: (context, index) {
        final drawing = drawings[index];
        return _DrawingCard(
          drawing: drawing,
          onDelete: () => _deleteDrawing(context, ref, drawing),
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: index * 100))
            .scale(begin: const Offset(0.9, 0.9));
      },
    );
  }

  Future<void> _deleteDrawing(BuildContext context, WidgetRef ref, Map<String, dynamic> drawing) async {
    final id = drawing['id'] as String;
    final title = drawing['title'] as String? ?? 'Untitled';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina disegno'),
        content: Text('Vuoi eliminare "$title"? Questa azione è irreversibile.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final supabase = Supabase.instance.client;

      // Delete storage files (ignore errors)
      final originalPath = drawing['original_image_url'] as String?;
      if (originalPath != null) {
        try { await supabase.storage.from('drawings-original').remove([originalPath]); } catch (_) {}
      }
      final processedUrl = drawing['processed_image_url'] as String?;
      if (processedUrl != null && !processedUrl.startsWith('http')) {
        try { await supabase.storage.from('drawings-processed').remove([processedUrl]); } catch (_) {}
      }

      // Delete DB record
      await supabase.from('drawings').delete().eq('id', id);

      // Refresh gallery
      ref.invalidate(recentDrawingsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Disegno eliminato'), backgroundColor: AppTheme.successColor),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }
}

/// Card for a single drawing in the gallery
class _DrawingCard extends StatelessWidget {
  final Map<String, dynamic> drawing;
  final VoidCallback onDelete;

  const _DrawingCard({required this.drawing, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final id = drawing['id'] as String;
    final title = drawing['title'] as String? ?? 'Untitled';
    final rawStatus = drawing['model_status'] as String? ?? 'pending';
    final has3dModel = drawing['model_3d_url'] != null;
    // A drawing is truly "completed" only if it has a 3D model
    final status = (rawStatus == 'completed' && !has3dModel) ? 'draft' : rawStatus;
    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'completed':
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle;
        break;
      case 'processing':
      case 'processing_3d':
        statusColor = AppTheme.accentColor;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'failed':
        statusColor = AppTheme.errorColor;
        statusIcon = Icons.error;
        break;
      case 'draft':
        statusColor = Colors.orange;
        statusIcon = Icons.image;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.schedule;
    }

    return GestureDetector(
      onTap: () {
        if (status == 'completed' || status == 'draft') {
          context.push('/viewer/$id');
        } else if (status == 'processing' || status == 'processing_3d') {
          context.push('/processing/$id');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: AppTheme.shadowSmall,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.grey.shade100,
                child: FutureBuilder<String>(
                  future: _getImageUrl(drawing),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      return Image.network(
                        snapshot.data!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(statusIcon, statusColor),
                      );
                    }
                    return _buildPlaceholder(statusIcon, statusColor);
                  },
                ),
              ),
            ),
            // Info area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(statusIcon, size: 14, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              status[0].toUpperCase() + status.substring(1),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onDelete,
                    child: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(IconData icon, Color color) {
    return Center(
      child: Icon(icon, size: 48, color: color.withValues(alpha: 0.4)),
    );
  }

  Future<String> _getImageUrl(Map<String, dynamic> drawing) async {
    // Try processed image first, then original
    final processedUrl = drawing['processed_image_url'] as String?;
    if (processedUrl != null && processedUrl.startsWith('http')) {
      return processedUrl;
    }

    final originalPath = drawing['original_image_url'] as String?;
    if (originalPath != null && !originalPath.startsWith('http')) {
      try {
        return await Supabase.instance.client.storage
            .from('drawings-original')
            .createSignedUrl(originalPath, 3600);
      } catch (_) {
        return '';
      }
    }

    return originalPath ?? '';
  }
}

/// Quick Action Card Widget
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceM),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: AppTheme.spaceS),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

