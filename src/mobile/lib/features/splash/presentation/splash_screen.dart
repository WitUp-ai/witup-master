import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';

/// Splash Screen with magical loading animation
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(AppConfig.splashDuration);
    
    if (mounted) {
      // Router will handle navigation based on auth state
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.heroGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo Placeholder
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  boxShadow: AppTheme.shadowLarge,
                ),
                child: const Icon(
                  Icons.draw,
                  size: 64,
                  color: AppTheme.primaryColor,
                ),
              ),
              
              const SizedBox(height: AppTheme.spaceXL),
              
              // App Name
              Text(
                'Draw2Toy',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 48,
                ),
              ),
              
              const SizedBox(height: AppTheme.spaceS),
              
              // Tagline
              Text(
                'Bring Your Drawings to Life ✨',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white.withValues(alpha:0.95),
                  fontSize: 18,
                ),
              ),
              
              const SizedBox(height: AppTheme.space2XL),
              
              // Demo Info
              Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha:0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: Colors.white.withValues(alpha:0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '🎨 MVP Demo',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Architecture: ✅ Complete\nSupabase: ✅ Connected\nFlutter: ✅ Running\nTheme: ✅ Child-Friendly',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha:0.9),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppTheme.spaceXL),
              
              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
              
              const SizedBox(height: AppTheme.spaceM),
              
              Text(
                'Ready for next features...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha:0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
