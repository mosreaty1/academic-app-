import 'package:firebase_core/firebase_core.dart';

/// PLACEHOLDER - Firebase is not configured yet, so the app runs in offline
/// demo mode.
///
/// Run `flutterfire configure` (see FIREBASE_SETUP.md). It overwrites this file
/// with your project's real options and the app switches to Firebase
/// automatically.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw UnsupportedError(
      'Firebase is not configured. Run `flutterfire configure` (see FIREBASE_SETUP.md).');
}
