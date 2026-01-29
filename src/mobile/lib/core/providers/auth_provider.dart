import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Auth change notifier for router refresh
class AuthChangeNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// Global auth change notifier instance for router refresh
final authChangeNotifier = AuthChangeNotifier();

/// Auth state notifier
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// Auth state
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isFirstTime;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isFirstTime = true,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isFirstTime,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isFirstTime: isFirstTime ?? this.isFirstTime,
    );
  }

  bool get isAuthenticated => user != null;
}

/// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  final _supabase = Supabase.instance.client;

  Future<void> _init() async {
    // Check if first time
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('is_first_time') ?? true;

    // Check current session
    final session = _supabase.auth.currentSession;

    state = state.copyWith(
      user: session?.user,
      isFirstTime: isFirstTime,
      isLoading: false,
    );

    // Listen to auth changes
    _supabase.auth.onAuthStateChange.listen((data) {
      state = state.copyWith(user: data.session?.user);
      // Notify router to refresh
      authChangeNotifier.notify();
    });
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_time', false);
    state = state.copyWith(isFirstTime: false);
    // Notify router to refresh
    authChangeNotifier.notify();
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      state = state.copyWith(
        user: response.user,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> signUpWithEmail(String email, String password, String name) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      debugPrint('AuthProvider: Starting signup for $email');

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      debugPrint('AuthProvider: Signup response - user: ${response.user?.id}, session: ${response.session != null}');

      // Check if email confirmation is required
      if (response.user != null && response.session == null) {
        debugPrint('AuthProvider: Email confirmation required - check your inbox');
        state = state.copyWith(
          isLoading: false,
          error: 'Controlla la tua email per confermare la registrazione',
        );
        return;
      }

      state = state.copyWith(
        user: response.user,
        isLoading: false,
      );

      // Notify router to refresh after successful signup
      authChangeNotifier.notify();
    } catch (e) {
      debugPrint('AuthProvider: Signup error - $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.draw2toy.app://callback',
      );

      // State will be updated by auth listener
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> signInWithApple() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'com.draw2toy.app://callback',
      );

      // State will be updated by auth listener
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      state = state.copyWith(user: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Supabase client provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
