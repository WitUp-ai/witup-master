import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
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
    const _ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          elevation: 0,
          backgroundColor: Colors.transparent,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.textTertiary,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.photo_library_outlined),
              activeIcon: Icon(Icons.photo_library),
              label: 'Gallery',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
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
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppTheme.magicGradient,
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.shadowSmall,
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                  ),
                )
                    .animate()
                    .scale(delay: 300.ms, duration: 500.ms)
                    .fadeIn(),
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
                  return _buildDrawingsGrid(context, drawings);
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

  Widget _buildDrawingsGrid(BuildContext context, List<Map<String, dynamic>> drawings) {
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
        return _DrawingCard(drawing: drawing)
            .animate()
            .fadeIn(delay: Duration(milliseconds: index * 100))
            .scale(begin: const Offset(0.9, 0.9));
      },
    );
  }
}

/// Card for a single drawing in the gallery
class _DrawingCard extends StatelessWidget {
  final Map<String, dynamic> drawing;

  const _DrawingCard({required this.drawing});

  @override
  Widget build(BuildContext context) {
    final id = drawing['id'] as String;
    final title = drawing['title'] as String? ?? 'Untitled';
    final status = drawing['model_status'] as String? ?? 'pending';
    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'completed':
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle;
        break;
      case 'processing':
        statusColor = AppTheme.accentColor;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'failed':
        statusColor = AppTheme.errorColor;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.schedule;
    }

    return GestureDetector(
      onTap: () {
        if (status == 'completed') {
          context.push('/viewer/$id');
        } else if (status == 'pending') {
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
              padding: const EdgeInsets.all(8),
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
                  const SizedBox(height: 4),
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

/// Profile Tab - User settings and info
class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userName = authState.user?.userMetadata?['name'] ?? 'User';
    final userEmail = authState.user?.email ?? 'user@email.com';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceM),
        child: Column(
          children: [
            // Profile Header
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppTheme.magicGradient,
                shape: BoxShape.circle,
                boxShadow: AppTheme.shadowMedium,
              ),
              child: Center(
                child: Text(
                  userName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

            const SizedBox(height: AppTheme.spaceM),

            Text(
              userName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: AppTheme.spaceXS),

            Text(
              userEmail,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),

            const SizedBox(height: AppTheme.spaceXL),

            // Admin Panel (visible only to admins)
            Consumer(
              builder: (context, ref, _) {
                final isAdmin = ref.watch(isAdminProvider);
                return isAdmin.when(
                  data: (admin) => admin
                      ? _ProfileMenuItem(
                          icon: Icons.admin_panel_settings,
                          title: 'Admin Panel',
                          color: AppTheme.primaryColor,
                          onTap: () => context.push('/admin'),
                        )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
            ),

            // Menu Items
            _ProfileMenuItem(
              icon: Icons.person,
              title: 'Edit Profile',
              onTap: () {},
            ),
            _ProfileMenuItem(
              icon: Icons.notifications,
              title: 'Notifications',
              onTap: () {},
            ),
            _ProfileMenuItem(
              icon: Icons.payment,
              title: 'Subscription',
              onTap: () {},
            ),
            _ProfileMenuItem(
              icon: Icons.help,
              title: 'Help & Support',
              onTap: () {},
            ),
            _ProfileMenuItem(
              icon: Icons.info,
              title: 'About',
              onTap: () {},
            ),
            _ProfileMenuItem(
              icon: Icons.logout,
              title: 'Logout',
              color: AppTheme.errorColor,
              onTap: () async {
                await ref.read(authProvider.notifier).signOut();
              },
            ),
          ],
        ),
      ),
    );
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

/// Profile Menu Item Widget
class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? AppTheme.textPrimary;

    return ListTile(
      leading: Icon(icon, color: itemColor),
      title: Text(
        title,
        style: TextStyle(color: itemColor),
      ),
      trailing: Icon(Icons.chevron_right, color: itemColor),
      onTap: onTap,
    );
  }
}
