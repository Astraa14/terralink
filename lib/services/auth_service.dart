import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/app_models.dart';

class AuthService extends ChangeNotifier {
  UserProfile? _currentUser;
  bool _isLoading = false;
  String? _lastError;
  StreamSubscription<AuthState>? _authSub;

  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  SupabaseClient get _client => Supabase.instance.client;

  AuthService() {
    if (!SupabaseConfig.isConfigured) return;

    final session = _client.auth.currentSession;
    if (session != null) {
      _currentUser = _profileFromUser(session.user);
    }

    _authSub = _client.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      if (user != null) {
        _currentUser = _profileFromUser(user);
      } else if (_currentUser?.uid.startsWith('guest_') ?? false) {
        // Keep local guest sessions when Supabase has no user.
        return;
      } else {
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<bool> signInWithGoogle() async {
    if (_isLoading) return false;
    if (!_ensureConfigured()) return false;

    _lastError = null;
    _setLoading(true);

    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.terralink://login-callback/',
        authScreenLaunchMode:
            kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      );
      // Session arrives via onAuthStateChange after redirect.
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _lastError = e.message;
      debugPrint('Google Sign In: ${e.message}');
    } catch (e) {
      _lastError = 'Google Sign-In failed. Enable Google in Supabase Auth.';
      debugPrint('Google Sign In: $e');
    }

    _setLoading(false);
    return false;
  }

  Future<bool> signInWithEmail(String email, String password) async {
    if (_isLoading) return false;
    if (!_ensureConfigured()) return false;

    _lastError = null;
    _setLoading(true);

    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      _currentUser = _profileFromUser(response.user!);
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _lastError = _friendlyAuthError(e);
      debugPrint('Email Sign In: ${e.message}');
    } catch (e) {
      _lastError = 'Sign in failed. Please try again.';
      debugPrint('Email Sign In: $e');
    }

    _setLoading(false);
    return false;
  }

  Future<bool> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    if (_isLoading) return false;
    if (!_ensureConfigured()) return false;

    _lastError = null;
    _setLoading(true);

    try {
      final displayName = name.trim().isNotEmpty
          ? name.trim()
          : email.trim().split('@').first;

      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'display_name': displayName},
      );

      if (response.user == null) {
        _lastError = 'Account creation failed. Please try again.';
        _setLoading(false);
        return false;
      }

      // Email confirmation may be required — no session until confirmed.
      if (response.session == null) {
        _lastError =
            'Account created. Check your email to confirm, then sign in.';
        _setLoading(false);
        return false;
      }

      _currentUser = _profileFromUser(response.user!, fallbackName: displayName);
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _lastError = _friendlyAuthError(e);
      debugPrint('Sign Up: ${e.message}');
    } catch (e) {
      _lastError = 'Account creation failed. Please try again.';
      debugPrint('Sign Up: $e');
    }

    _setLoading(false);
    return false;
  }

  Future<bool> signInAsGuest() async {
    if (_isLoading) return false;
    _lastError = null;
    _setLoading(true);

    if (SupabaseConfig.isConfigured) {
      try {
        final response = await _client.auth.signInAnonymously();
        _currentUser = UserProfile(
          uid: response.user!.id,
          displayName: 'Guest User',
          email: null,
          photoUrl: null,
        );
        _setLoading(false);
        return true;
      } on AuthException catch (e) {
        debugPrint('Anonymous sign-in: ${e.message}');
        // Fall through to local guest if Anonymous is disabled.
      } catch (e) {
        debugPrint('Anonymous sign-in: $e');
      }
    }

    _currentUser = UserProfile(
      uid: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      displayName: 'Guest User',
      email: null,
      photoUrl: null,
    );
    _setLoading(false);
    return true;
  }

  Future<void> signOut() async {
    try {
      if (SupabaseConfig.isConfigured) {
        await _client.auth.signOut();
      }
    } catch (_) {}
    _currentUser = null;
    notifyListeners();
  }

  bool _ensureConfigured() {
    if (SupabaseConfig.isConfigured) return true;
    _lastError =
        'Supabase is not configured yet. Add your URL and key in supabase_config.dart.';
    notifyListeners();
    return false;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  UserProfile _profileFromUser(User user, {String? fallbackName}) {
    final meta = user.userMetadata ?? {};
    final displayName = (meta['display_name'] as String?) ??
        (meta['full_name'] as String?) ??
        (meta['name'] as String?) ??
        fallbackName ??
        user.email?.split('@').first ??
        'Soil Analyst';

    return UserProfile(
      uid: user.id,
      displayName: displayName,
      email: user.email,
      photoUrl: (meta['avatar_url'] as String?) ?? (meta['picture'] as String?),
    );
  }

  String _friendlyAuthError(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'Incorrect email or password.';
    }
    if (message.contains('user already registered')) {
      return 'An account already exists for that email.';
    }
    if (message.contains('password')) {
      return 'Password must be at least 6 characters.';
    }
    if (message.contains('email')) {
      return e.message;
    }
    return e.message;
  }
}
