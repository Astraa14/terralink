import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/app_models.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserProfile? _currentUser;
  bool _isLoading = false;
  String? _lastError;

  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  AuthService() {
    // Listen to Firebase Auth state changes so sign-in persists across restarts
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _currentUser = _profileFromFirebaseUser(user);
      } else {
        // Keep local guest session alive even if Firebase user is null
        if (_currentUser?.uid.startsWith('guest_') ?? false) return;
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  // ─────────────────────────────────────────────
  // Google Sign In
  // ─────────────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    if (_isLoading) return false;
    _lastError = null;
    _setLoading(true);

    try {
      UserCredential credential;

      if (kIsWeb) {
        // Web: Open a Google sign-in popup (no Client ID needed separately)
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');
        credential = await _auth.signInWithPopup(provider);
      } else {
        // Android / iOS: use google_sign_in package to get credentials
        final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
        final account = await googleSignIn.signIn();
        if (account == null) {
          _setLoading(false);
          return false;
        }
        final googleAuth = await account.authentication;
        final oauthCredential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        credential = await _auth.signInWithCredential(oauthCredential);
      }

      _currentUser = _profileFromFirebaseUser(credential.user!);
      _setLoading(false);
      return true;
    } catch (e) {
      _lastError = _friendlyError(e);
      debugPrint('Google Sign In: $e');
    }

    _setLoading(false);
    return false;
  }

  // ─────────────────────────────────────────────
  // Email / Password Sign In
  // ─────────────────────────────────────────────
  Future<bool> signInWithEmail(String email, String password) async {
    if (_isLoading) return false;
    _lastError = null;
    _setLoading(true);

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _currentUser = _profileFromFirebaseUser(credential.user!);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _lastError = _friendlyError(e);
      debugPrint('Email Sign In: ${e.code} – ${e.message}');
    } catch (e) {
      _lastError = 'Sign in failed. Please try again.';
      debugPrint('Email Sign In: $e');
    }

    _setLoading(false);
    return false;
  }

  // ─────────────────────────────────────────────
  // Email / Password Sign Up (Account Creation)
  // ─────────────────────────────────────────────
  Future<bool> signUpWithEmail(
      String email, String password, String name) async {
    if (_isLoading) return false;
    _lastError = null;
    _setLoading(true);

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // Save display name to Firebase profile
      if (name.trim().isNotEmpty) {
        await credential.user?.updateDisplayName(name.trim());
        await credential.user?.reload();
      }
      final displayName = name.trim().isNotEmpty
          ? name.trim()
          : (credential.user?.email?.split('@')[0] ?? 'Soil Analyst');
      _currentUser = UserProfile(
        uid: credential.user!.uid,
        displayName: displayName,
        email: credential.user!.email,
        photoUrl: credential.user!.photoURL,
      );
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _lastError = _friendlyError(e);
      debugPrint('Sign Up: ${e.code} – ${e.message}');
    } catch (e) {
      _lastError = 'Account creation failed. Please try again.';
      debugPrint('Sign Up: $e');
    }

    _setLoading(false);
    return false;
  }

  // ─────────────────────────────────────────────
  // Guest / Anonymous
  // ─────────────────────────────────────────────
  Future<bool> signInAsGuest() async {
    if (_isLoading) return false;
    _lastError = null;
    _setLoading(true);

    try {
      // Sign in anonymously so we get a real Firebase UID
      final credential = await _auth.signInAnonymously();
      _currentUser = UserProfile(
        uid: credential.user!.uid,
        displayName: 'Guest User',
        email: null,
        photoUrl: null,
      );
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      // Fallback to local guest session if Anonymous auth isn't enabled
      debugPrint('Anonymous sign-in: ${e.code}');
      _currentUser = UserProfile(
        uid: 'guest_${DateTime.now().millisecondsSinceEpoch}',
        displayName: 'Guest User',
        email: null,
        photoUrl: null,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _lastError = 'Guest sign-in failed.';
      debugPrint('Guest: $e');
    }

    _setLoading(false);
    return false;
  }

  // ─────────────────────────────────────────────
  // Sign Out
  // ─────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      // Also sign out of Google on mobile so users can switch accounts
      if (!kIsWeb) {
        await GoogleSignIn().signOut();
      }
    } catch (_) {}
    _currentUser = null;
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  UserProfile _profileFromFirebaseUser(User user) {
    return UserProfile(
      uid: user.uid,
      displayName:
          user.displayName ?? user.email?.split('@')[0] ?? 'Soil Analyst',
      email: user.email,
      photoUrl: user.photoURL,
    );
  }

  String _friendlyError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No account found for that email.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'email-already-in-use':
          return 'An account already exists for that email.';
        case 'weak-password':
          return 'Password must be at least 6 characters.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'network-request-failed':
          return 'No internet connection.';
        default:
          return e.message ?? 'Authentication error.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
