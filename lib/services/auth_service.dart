import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/app_models.dart';

class AuthService extends ChangeNotifier {
  UserProfile? _currentUser;
  bool _isLoading = false;

  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  AuthService() {
    _currentUser = null;
  }

  Future<bool> signInWithGoogle() async {
    if (_isLoading) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      final account = await googleSignIn.signIn();
      if (account != null) {
        _currentUser = UserProfile(
          uid: account.id,
          displayName: account.displayName ?? "Botanist User",
          email: account.email,
          photoUrl: account.photoUrl,
        );
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Google Sign In Notice (Fallback active): $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> signInWithEmail(String email, String password) async {
    if (_isLoading) return false;
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      _currentUser = UserProfile(
        uid: "email_user_${email.hashCode}",
        displayName: email.split('@')[0],
        email: email,
        photoUrl: null,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Email Sign In Error: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> signInAsGuest() async {
    if (_isLoading) return false;
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 300));
      _currentUser = UserProfile(
        uid: "guest_user_${DateTime.now().millisecondsSinceEpoch}",
        displayName: "Guest User",
        email: null,
        photoUrl: null,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Guest Sign In Error: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> signOut() async {
    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
    } catch (_) {}
    _currentUser = null;
    notifyListeners();
  }
}
