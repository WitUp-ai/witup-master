/// Application-wide configuration constants
class AppConfig {
  // Environment
  static const bool isDevelopment = true;
  static const bool isProduction = false;

  // App Info
  static const String appName = 'Draw2Toy';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // API Configuration
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;

  // Image Processing
  static const int maxImageSizeMB = 10;
  static const int imageQuality = 85;
  static const int thumbnailSize = 200;

  // Drawing Quotas (per tier)
  static const int freeDrawingsPerMonth = 1;
  static const int magicDrawingsPerMonth = 10;
  static const int familyDrawingsPerMonth = 999; // Unlimited

  // Storage
  static const int maxGalleryItemsFree = 5;
  static const int maxGalleryItemsMagic = 100;
  static const int maxGalleryItemsFamily = 999; // Unlimited

  // AR Configuration
  static const double defaultModelScale = 1.0;
  static const double minModelScale = 0.5;
  static const double maxModelScale = 3.0;

  // Animation Durations
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration shortAnimDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimDuration = Duration(milliseconds: 400);
  static const Duration longAnimDuration = Duration(milliseconds: 600);

  // UI Constants
  static const double borderRadius = 16.0;
  static const double cardElevation = 4.0;
  static const double buttonHeight = 56.0;
  static const double iconSize = 24.0;
  static const double avatarSize = 48.0;

  // Pagination
  static const int itemsPerPage = 20;
  static const int initialLoadCount = 10;

  // Logging
  static const bool enableLogging = isDevelopment;
  static const bool logNetworkCalls = isDevelopment;

  // Feature Flags (for gradual rollout)
  static const bool enableARMultiplayer = false;
  static const bool enableVoiceGeneration = false;
  static const bool enableSocialSharing = true;
  static const bool enablePhysicalOrders = true;

  // External Services
  static const bool useProductionAI = false; // Use mock AI in dev
  static const bool useStripeTestMode = true;

  // Cache
  static const Duration cacheExpirationDuration = Duration(hours: 24);
  static const int maxCacheSize = 100; // MB

  // Privacy
  static const int minChildAge = 4;
  static const int maxChildAge = 12;
  static const int minParentAge = 18;

  AppConfig._();
}
