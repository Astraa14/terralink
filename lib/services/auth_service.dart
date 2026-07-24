import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terralink/models/user_model.dart';

class AuthService extends ChangeNotifier {
  final fb.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AppUser? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<fb.User?>? _authStateSubscription;

  AuthService({
    fb.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn() {
    _initAuthListener();
  }

  // ──────────────────────────────── Getters ────────────────────────────────

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get errorMessage => _errorMessage;
  Stream<fb.User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // ──────────────────────────────── Init ───────────────────────────────────

  void _initAuthListener() {
    _authStateSubscription = _firebaseAuth.authStateChanges().listen(
      (fb.User? firebaseUser) {
        if (firebaseUser != null) {
          _currentUser = AppUser.fromFirebaseUser(firebaseUser);
        } else {
          _currentUser = null;
        }
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = 'Authentication state error: $error';
        notifyListeners();
      },
    );
  }

  // ──────────────────────────── Email/Password ────────────────────────────

  Future<AppUser?> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (displayName != null && displayName.isNotEmpty) {
        await credential.user?.updateDisplayName(displayName.trim());
        await credential.user?.reload();
      }

      final user = _firebaseAuth.currentUser;
      if (user != null) {
        _currentUser = AppUser.fromFirebaseUser(user);
        await _saveUserLocally(_currentUser!);
      }

      _setLoading(false);
      return _currentUser;
    } on fb.FirebaseAuthException catch (e) {
      _setLoading(false);
      _setError(_mapFirebaseAuthError(e.code));
      return null;
    } catch (e) {
      _setLoading(false);
      _setError('An unexpected error occurred. Please try again.');
      return null;
    }
  }

  Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        _currentUser = AppUser.fromFirebaseUser(credential.user!);
        await _saveUserLocally(_currentUser!);
      }

      _setLoading(false);
      return _currentUser;
    } on fb.FirebaseAuthException catch (e) {
      _setLoading(false);
      _setError(_mapFirebaseAuthError(e.code));
      return null;
    } catch (e) {
      _setLoading(false);
      _setError('An unexpected error occurred. Please try again.');
      return null;
    }
  }

  // ──────────────────────────── Google Sign-In ────────────────────────────

  Future<AppUser?> signInWithGoogle() async {
    try {
      _setLoading(true);
      _clearError();

      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _setLoading(false);
        return null;
      }

      final googleAuth = await googleUser.authentication;

      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user != null) {
        _currentUser = AppUser.fromFirebaseUser(userCredential.user!);
        await _saveUserLocally(_currentUser!);
      }

      _setLoading(false);
      return _currentUser;
    } on fb.FirebaseAuthException catch (e) {
      _setLoading(false);
      _setError(_mapFirebaseAuthError(e.code));
      return null;
    } catch (e) {
      _setLoading(false);
      _setError('Google sign-in failed. Please try again.');
      return null;
    }
  }

  // ──────────────────────────── Password Reset ────────────────────────────

  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _clearError();
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on fb.FirebaseAuthException catch (e) {
      _setError(_mapFirebaseAuthError(e.code));
      return false;
    } catch (e) {
      _setError('Failed to send password reset email.');
      return false;
    }
  }

  // ──────────────────────────────── Sign Out ──────────────────────────────

  Future<void> signOut() async {
    try {
      _setLoading(true);
      _clearError();

      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);

      _currentUser = null;
      await _clearLocalUser();

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Failed to sign out. Please try again.');
    }
  }

  // ─────────────────────────── Profile Update ─────────────────────────────

  Future<bool> updateDisplayName(String name) async {
    try {
      _clearError();
      final user = _firebaseAuth.currentUser;
      if (user == null) return false;

      await user.updateDisplayName(name.trim());
      await user.reload();

      final refreshedUser = _firebaseAuth.currentUser;
      if (refreshedUser != null) {
        _currentUser = AppUser.fromFirebaseUser(refreshedUser);
        await _saveUserLocally(_currentUser!);
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Failed to update profile.');
      return false;
    }
  }

  // ──────────────────────────── Local Storage ─────────────────────────────

  Future<void> _saveUserLocally(AppUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_uid', user.uid);
      await prefs.setString('user_email', user.email);
      if (user.displayName != null) {
        await prefs.setString('user_display_name', user.displayName!);
      }
    } catch (_) {
      // Non-critical: local caching failure shouldn't block auth
    }
  }

  Future<void> _clearLocalUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_uid');
      await prefs.remove('user_email');
      await prefs.remove('user_display_name');
    } catch (_) {
      // Non-critical
    }
  }

  // ──────────────────────────── Error Mapping ─────────────────────────────

  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'requires-recent-login':
        return 'Please sign in again to complete this action.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  // ──────────────────────────── Helpers ────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ──────────────────────────── Disposal ───────────────────────────────────

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
