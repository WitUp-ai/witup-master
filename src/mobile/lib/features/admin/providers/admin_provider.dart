import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Admin emails (project owner + authorized admins)
const _adminEmails = ['giovanni@witup.ai', 'testuser@gmail.com'];

/// Check if current user is admin
final isAdminProvider = FutureProvider<bool>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) return false;

  // First check by email (works without DB role column)
  if (_adminEmails.contains(user.email)) return true;

  // Then check DB role column if available
  try {
    final result = await supabase
        .from('users')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();
    return result?['role'] == 'admin';
  } catch (_) {
    return false;
  }
});

/// Admin stats from database
final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  final supabase = Supabase.instance.client;

  // Fetch counts in parallel
  final usersCount = await supabase.from('users').select('id').count(CountOption.exact);
  final drawingsCount = await supabase.from('drawings').select('id').count(CountOption.exact);
  final completedCount = await supabase
      .from('drawings')
      .select('id')
      .eq('model_status', 'completed')
      .count(CountOption.exact);
  final failedCount = await supabase
      .from('drawings')
      .select('id')
      .eq('model_status', 'failed')
      .count(CountOption.exact);
  final pendingCount = await supabase
      .from('drawings')
      .select('id')
      .eq('model_status', 'pending')
      .count(CountOption.exact);

  return AdminStats(
    totalUsers: usersCount.count,
    totalDrawings: drawingsCount.count,
    completedDrawings: completedCount.count,
    failedDrawings: failedCount.count,
    pendingDrawings: pendingCount.count,
  );
});

/// Recent drawings for admin view
final adminRecentDrawingsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final result = await supabase
      .from('drawings')
      .select('id, created_at, model_status, original_url, user_id')
      .order('created_at', ascending: false)
      .limit(50);
  return List<Map<String, dynamic>>.from(result);
});

/// All users for admin
final adminUsersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final result = await supabase
      .from('users')
      .select('id, email, created_at, subscription_tier, monthly_drawings_used, monthly_drawings_limit')
      .order('created_at', ascending: false)
      .limit(100);
  return List<Map<String, dynamic>>.from(result);
});

/// ============================================================================
/// SYSTEM CONFIG PROVIDERS (for dynamic configuration management)
/// ============================================================================

/// Get all system configurations (admin only)
final systemConfigProvider = FutureProvider<List<SystemConfig>>((ref) async {
  final supabase = Supabase.instance.client;
  
  try {
    // Use RPC to call get_system_config function (more secure) or direct select
    final result = await supabase
        .from('system_config')
        .select('*')
        .order('key');
    
    return (result as List)
        .map((item) => SystemConfig.fromJson(item))
        .toList();
  } catch (e) {
    // If table doesn't exist yet, return empty list
    return [];
  }
});

/// Get specific system config value (for app use)
final systemConfigValueProvider = FutureProvider.autoDispose
    .family<String?, String>((ref, key) async {
  final supabase = Supabase.instance.client;
  
  try {
    final result = await supabase
        .from('system_config')
        .select('value')
        .eq('key', key)
        .maybeSingle();
    
    return result?['value'] as String?;
  } catch (e) {
    return null;
  }
});

/// Update system config (admin only)
class SystemConfigRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> updateConfig(String key, String value, String description) async {
    await _supabase
        .from('system_config')
        .upsert({
          'key': key,
          'value': value,
          'description': description,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
  }

  Future<void> deleteConfig(String key) async {
    await _supabase
        .from('system_config')
        .delete()
        .eq('key', key);
  }
}

final systemConfigRepositoryProvider = Provider((ref) => SystemConfigRepository());

/// System config model
class SystemConfig {
  final String key;
  final String value;
  final String? description;
  final DateTime updatedAt;
  final String? updatedBy;

  SystemConfig({
    required this.key,
    required this.value,
    this.description,
    required this.updatedAt,
    this.updatedBy,
  });

  factory SystemConfig.fromJson(Map<String, dynamic> json) {
    return SystemConfig(
      key: json['key'] as String,
      value: json['value'] as String,
      description: json['description'] as String?,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      updatedBy: json['updated_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
      'description': description,
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'updated_by': updatedBy,
    };
  }

  bool get isSensitive => key.contains('TOKEN') || key.contains('KEY') || key.contains('SECRET');
}

/// Default system configurations (fallback if DB not ready)
final defaultSystemConfigs = [
  SystemConfig(
    key: 'REPLICATE_API_TOKEN',
    value: '', // Set via Admin Panel or system_config table
    description: 'API Key for Replicate AI services',
    updatedAt: DateTime(2026, 1, 29),
  ),
  SystemConfig(
    key: 'MODEL_VISION',
    value: 'moondream',
    description: 'Vision AI model for drawing validation',
    updatedAt: DateTime(2026, 1, 29),
  ),
  SystemConfig(
    key: 'MODEL_3D_GENERATOR',
    value: 'triposr',
    description: '3D generation model',
    updatedAt: DateTime(2026, 1, 29),
  ),
  SystemConfig(
    key: 'PRINTER_API_KEY',
    value: 'PLACEHOLDER_PRINTER_KEY',
    description: 'API Key for 3D printing service',
    updatedAt: DateTime(2026, 1, 29),
  ),
  SystemConfig(
    key: 'SYSTEM_STATUS',
    value: 'active',
    description: 'System status: active, maintenance, disabled',
    updatedAt: DateTime(2026, 1, 29),
  ),
];

/// ============================================================================
/// ADMIN STATS MODEL
/// ============================================================================

class AdminStats {
  final int totalUsers;
  final int totalDrawings;
  final int completedDrawings;
  final int failedDrawings;
  final int pendingDrawings;

  const AdminStats({
    required this.totalUsers,
    required this.totalDrawings,
    required this.completedDrawings,
    required this.failedDrawings,
    required this.pendingDrawings,
  });

  double get successRate =>
      totalDrawings > 0 ? (completedDrawings / totalDrawings * 100) : 0;
}
