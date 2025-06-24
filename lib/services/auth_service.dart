import 'package:firebase_auth/firebase_auth.dart';
import 'package:sell_n_buy_updated/models/activity_log.dart';
import 'package:sell_n_buy_updated/services/database_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _databaseService = DatabaseService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Log user login activity
      if (result.user != null) {
        final userProfile = await _databaseService.getUserProfile(result.user!.uid);
        await _databaseService.logActivity(ActivityLog(
          id: '', // Will be set by push()
          type: ActivityType.userLogin,
          userId: result.user!.uid,
          description: 'User login: ${userProfile?.name ?? email}',
          timestamp: DateTime.now(),
        ));
      }
      
      return result;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign up with email and password
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'email-already-in-use':
          return 'Email is already registered.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'weak-password':
          return 'Password is too weak.';
        default:
          return 'Authentication failed. Please try again.';
      }
    }
    return 'An error occurred. Please try again.';
  }
}
