# Firebase Setup & Configuration Guide for TerraLink

To integrate live **Firebase Authentication** and **Cloud Firestore** for user accounts, follow these standard steps:

---

## 1. Add Dependencies to `pubspec.yaml`
Add `firebase_core` and `firebase_auth` under `dependencies`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.1.0
  firebase_auth: ^5.1.0
  google_sign_in: ^6.2.1
```

---

## 2. Configure Firebase Project via FlutterFire CLI
Run the following commands in your project root:

```bash
# 1. Install FlutterFire CLI globally
dart pub global activate flutterfire_cli

# 2. Login to your Firebase account
firebase login

# 3. Configure app with Firebase project (generates firebase_options.dart)
flutterfire configure --project=terralink-soil-monitor
```

---

## 3. Initialize Firebase in `main.dart`
Update `main()` in `lib/main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TerraLinkApp());
}
```

---

## 4. Production FirebaseAuth Service Implementation
When you connect your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS), update `AuthService` (`lib/services/auth_service.dart`):

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/app_models.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  UserProfile? _currentUser;
  bool _isLoading = false;

  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _currentUser = UserProfile(
          uid: user.uid,
          displayName: user.displayName ?? user.email?.split('@')[0] ?? 'Soil Analyst',
          email: user.email,
          photoUrl: user.photoURL,
        );
      } else {
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  Future<bool> signUpWithEmail(String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (name.isNotEmpty) {
        await credential.user?.updateDisplayName(name);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }
}
```
