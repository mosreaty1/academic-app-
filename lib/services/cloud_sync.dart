import '../data/app_state.dart';
import '../models/models.dart';

/// Result of a sign-in attempt. [error] is one of: `invalid`
/// (wrong ID or password), `network`, `other`.
class SignInResult {
  final UserProfile? user;
  final String? error;
  const SignInResult.ok(UserProfile this.user) : error = null;
  const SignInResult.fail(String this.error) : user = null;
}

/// Backend abstraction. The app ships with [FirebaseCloud]; when Firebase is
/// not configured the app runs in offline demo mode and no [CloudSync] exists.
abstract class CloudSync {
  /// The profile of an already signed-in user (session restore), or null.
  Future<UserProfile?> currentUser();

  Future<SignInResult> signIn(String id, String password);
  Future<void> signOut();

  /// Loads the data this user may see into [s] (lessons, subscriptions, ...).
  Future<void> load(AppState s);

  Future<void> saveSubscription(Subscription x);
  Future<void> saveCode(ActivationCode c);
  Future<void> saveLesson(Lesson l);
  Future<void> deleteLesson(String id);
  Future<void> saveProgress(String studentId, String lessonId, double value);

  /// Atomically claims an activation code. Returns `ok`, `invalid`, `used`.
  Future<String> claimCode(String code, String studentId);

  /// Creates a Firebase Auth account + profile for a new student. Returns the
  /// new user's uid (used as the app-level id), or throws.
  Future<String> createStudent(UserProfile draft, String password);
}
