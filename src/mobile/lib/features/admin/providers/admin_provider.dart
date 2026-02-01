import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Admin emails (project owner + authorized admins)
/// CONFIGURAZIONE: Account admin autorizzati
const _adminEmails = ['giovanni.sapere@witup.ai'];

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
  final bool isSecret;
  final DateTime updatedAt;
  final String? updatedBy;

  SystemConfig({
    required this.key,
    required this.value,
    this.description,
    this.isSecret = false,
    required this.updatedAt,
    this.updatedBy,
  });

  factory SystemConfig.fromJson(Map<String, dynamic> json) {
    return SystemConfig(
      key: json['key'] as String,
      value: json['value'] as String,
      description: json['description'] as String?,
      isSecret: json['is_secret'] as bool? ?? false,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      updatedBy: json['updated_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
      'description': description,
      'is_secret': isSecret,
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'updated_by': updatedBy,
    };
  }

  bool get isSensitive => isSecret || key.contains('TOKEN') || key.contains('KEY') || key.contains('SECRET');
}

/// ============================================================================
/// USAGE LOGS PROVIDERS (Cost Intelligence)
/// ============================================================================

/// Usage log model
class UsageLog {
  final String id;
  final String? drawingId;
  final String? userId;
  final String provider;
  final String? model;
  final String? operation;
  final String status;
  final double? costEstimated;
  final int? latencyMs;
  final String? errorMessage;
  final DateTime createdAt;

  UsageLog({
    required this.id,
    this.drawingId,
    this.userId,
    required this.provider,
    this.model,
    this.operation,
    required this.status,
    this.costEstimated,
    this.latencyMs,
    this.errorMessage,
    required this.createdAt,
  });

  factory UsageLog.fromJson(Map<String, dynamic> json) {
    return UsageLog(
      id: json['id'] as String,
      drawingId: json['drawing_id'] as String?,
      userId: json['user_id'] as String?,
      provider: json['provider'] as String,
      model: json['model'] as String?,
      operation: json['operation'] as String?,
      status: json['status'] as String,
      costEstimated: (json['cost_estimated'] as num?)?.toDouble(),
      latencyMs: json['latency_ms'] as int?,
      errorMessage: json['error_message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Cost summary stats
class CostSummary {
  final double totalCostToday;
  final double totalCostMonth;
  final int totalCallsToday;
  final int totalCallsMonth;
  final int errorsToday;
  final double monthlyLimit;
  final Map<String, double> costByProvider;
  final Map<String, int> callsByOperation;

  CostSummary({
    required this.totalCostToday,
    required this.totalCostMonth,
    required this.totalCallsToday,
    required this.totalCallsMonth,
    required this.errorsToday,
    required this.monthlyLimit,
    required this.costByProvider,
    required this.callsByOperation,
  });
}

/// Recent usage logs
final usageLogsProvider = FutureProvider<List<UsageLog>>((ref) async {
  final supabase = Supabase.instance.client;
  try {
    final result = await supabase
        .from('usage_logs')
        .select('*')
        .order('created_at', ascending: false)
        .limit(100);
    return (result as List).map((item) => UsageLog.fromJson(item)).toList();
  } catch (_) {
    return [];
  }
});

/// Cost summary for dashboard
final costSummaryProvider = FutureProvider<CostSummary>((ref) async {
  final supabase = Supabase.instance.client;

  final now = DateTime.now().toUtc();
  final todayStart = DateTime.utc(now.year, now.month, now.day).toIso8601String();
  final monthStart = DateTime.utc(now.year, now.month, 1).toIso8601String();

  // Get monthly limit from config
  double monthlyLimit = 10.0;
  try {
    final limitResult = await supabase
        .from('system_config')
        .select('value')
        .eq('key', 'MONTHLY_SPEND_LIMIT')
        .maybeSingle();
    if (limitResult != null) {
      monthlyLimit = double.tryParse(limitResult['value'] as String) ?? 10.0;
    }
  } catch (_) {}

  try {
    // All logs this month
    final monthLogs = await supabase
        .from('usage_logs')
        .select('*')
        .gte('created_at', monthStart)
        .order('created_at', ascending: false);

    final logs = (monthLogs as List).map((e) => UsageLog.fromJson(e)).toList();

    double totalCostMonth = 0;
    double totalCostToday = 0;
    int totalCallsToday = 0;
    int errorsToday = 0;
    final costByProvider = <String, double>{};
    final callsByOperation = <String, int>{};

    for (final log in logs) {
      final cost = log.costEstimated ?? 0;
      totalCostMonth += cost;
      costByProvider[log.provider] = (costByProvider[log.provider] ?? 0) + cost;
      final op = log.operation ?? 'unknown';
      callsByOperation[op] = (callsByOperation[op] ?? 0) + 1;

      if (log.createdAt.toIso8601String().compareTo(todayStart) >= 0) {
        totalCostToday += cost;
        totalCallsToday++;
        if (log.status != 'success') errorsToday++;
      }
    }

    return CostSummary(
      totalCostToday: totalCostToday,
      totalCostMonth: totalCostMonth,
      totalCallsToday: totalCallsToday,
      totalCallsMonth: logs.length,
      errorsToday: errorsToday,
      monthlyLimit: monthlyLimit,
      costByProvider: costByProvider,
      callsByOperation: callsByOperation,
    );
  } catch (_) {
    return CostSummary(
      totalCostToday: 0,
      totalCostMonth: 0,
      totalCallsToday: 0,
      totalCallsMonth: 0,
      errorsToday: 0,
      monthlyLimit: monthlyLimit,
      costByProvider: {},
      callsByOperation: {},
    );
  }
});

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
