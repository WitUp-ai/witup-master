import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/debug_log_service.dart';

/// Camera state
class CameraState {
  final bool isUploading;
  final String? lastUploadedUrl;
  final String? lastDrawingId;
  final String? error;
  final double uploadProgress;

  const CameraState({
    this.isUploading = false,
    this.lastUploadedUrl,
    this.lastDrawingId,
    this.error,
    this.uploadProgress = 0,
  });

  CameraState copyWith({
    bool? isUploading,
    String? lastUploadedUrl,
    String? lastDrawingId,
    String? error,
    double? uploadProgress,
  }) {
    return CameraState(
      isUploading: isUploading ?? this.isUploading,
      lastUploadedUrl: lastUploadedUrl ?? this.lastUploadedUrl,
      lastDrawingId: lastDrawingId ?? this.lastDrawingId,
      error: error,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }
}

/// Camera provider for handling image capture and upload
final cameraProvider = StateNotifierProvider<CameraNotifier, CameraState>((ref) {
  return CameraNotifier(ref);
});

class CameraNotifier extends StateNotifier<CameraState> {
  final Ref _ref;
  final _uuid = const Uuid();

  CameraNotifier(this._ref) : super(const CameraState());

  SupabaseClient get _supabase => Supabase.instance.client;

  final _debug = DebugLogService.instance;

  /// Upload a drawing image to Supabase Storage
  /// Returns the drawing ID if successful
  Future<String?> uploadDrawing(XFile imageFile, Uint8List imageBytes) async {
    try {
      _debug.log('Upload', 'Starting upload: ${imageFile.name} (${(imageBytes.length / 1024).toStringAsFixed(1)} KB)');
      state = state.copyWith(isUploading: true, error: null, uploadProgress: 0);

      // Get current user - must be authenticated
      final authState = _ref.read(authProvider);
      final userId = authState.user?.id;

      if (userId == null) {
        throw Exception('You must be logged in to upload drawings');
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueId = _uuid.v4().substring(0, 8);
      final extension = imageFile.name.split('.').last.toLowerCase();
      final fileName = 'drawing_${timestamp}_$uniqueId.$extension';
      // Path: {user_id}/{filename} - matches RLS policy
      final storagePath = '$userId/$fileName';

      state = state.copyWith(uploadProgress: 0.3);

      // Use Edge Function for upload to ensure RLS bypass if needed
      // This is more robust than direct storage upload which requires perfect RLS policies
      final session = _supabase.auth.currentSession;
      if (session == null) throw Exception('No active session');

      final functionUrl = '${_supabase.rest.url.toString().replaceAll('/rest/v1', '')}/functions/v1/upload-drawing';
      
      _debug.log('Upload', 'Uploading via Edge Function: $functionUrl');

      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode({
          'image_base64': base64Encode(imageBytes),
          'file_name': fileName,
          'content_type': 'image/${extension == 'jpg' ? 'jpeg' : extension}',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Upload failed: ${response.statusCode} - ${response.body}');
      }

      final responseData = jsonDecode(response.body);
      _debug.success('Upload', 'Storage upload complete via Edge Function: $storagePath');
      state = state.copyWith(uploadProgress: 0.7);

      // Use the URL returned by the function (it includes a signed token)
      final publicUrl = responseData['public_url'] as String;

      _debug.success('Upload', 'Signed URL created');
      state = state.copyWith(uploadProgress: 0.9);

      // Save drawing record to database and get the ID
      final drawingId = await _saveDrawingRecord(
        userId: userId,
        storagePath: storagePath,
        publicUrl: publicUrl,
        fileName: fileName,
      );

      _debug.success('Upload', 'Drawing record saved, ID: $drawingId');

      state = state.copyWith(
        isUploading: false,
        lastUploadedUrl: publicUrl,
        lastDrawingId: drawingId,
        uploadProgress: 1.0,
      );

      return drawingId;
    } catch (e) {
      _debug.error('Upload', 'Upload failed', error: e);
      state = state.copyWith(
        isUploading: false,
        error: e.toString(),
        uploadProgress: 0,
      );
      rethrow;
    }
  }

  /// Save drawing record to database (matches .spec/database-schema.sql)
  /// Returns the drawing ID if successful
  Future<String?> _saveDrawingRecord({
    required String userId,
    required String storagePath,
    required String publicUrl,
    required String fileName,
  }) async {
    try {
      _debug.log('Database', 'Inserting drawing record for user: $userId');

      // WORKAROUND: Ensure user exists in public.users before inserting drawing
      // Fixes FK constraint error when user only exists in auth.users
      try {
        final userCheck = await _supabase.from('users').select('id').eq('id', userId).maybeSingle();
        if (userCheck == null) {
          final authUser = _supabase.auth.currentUser;
          await _supabase.from('users').insert({
            'id': userId,
            'email': authUser?.email ?? 'unknown@example.com',
            'subscription_status': 'active',
            'monthly_quota': 10,
          });
          _debug.success('Database', 'User synced to public.users');
        }
      } catch (e) {
        _debug.warning('Database', 'User sync attempt: $e');
      }

      final response = await _supabase.from('drawings').insert({
        'user_id': userId,
        'original_image_url': storagePath,
        'title': 'Drawing ${DateTime.now().toString().substring(0, 10)}',
        'model_status': 'pending',
      }).select('id').single();

      final drawingId = response['id'] as String?;
      _debug.success('Database', 'Drawing created: $drawingId');
      return drawingId;
    } catch (e) {
      _debug.error('Database', 'Failed to save drawing', error: e);
      throw Exception('Failed to save drawing: ${e.toString()}');
    }
  }

  /// Get the last uploaded drawing ID
  String? get lastDrawingId => state.lastDrawingId;

  /// Reset state
  void reset() {
    state = const CameraState();
  }
}

/// Provider for recent drawings
final recentDrawingsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id;

  if (userId == null) return [];

  try {
    final response = await Supabase.instance.client
        .from('drawings')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(20);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    return [];
  }
});
