import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') return 'Please enter a valid email address.';
      if (e.code == 'user-disabled') return 'This account has been disabled.';
      if (e.code == 'too-many-requests') return 'Too many attempts. Please try again later.';
      return 'Incorrect email or password.';
    }
  }

  Future<String?> signUp(String name, String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await cred.user?.updateDisplayName(name);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') return 'An account with that email already exists.';
      if (e.code == 'invalid-email') return 'Please enter a valid email address.';
      if (e.code == 'weak-password') return 'Password must be at least 6 characters.';
      return 'Sign up failed. Please try again.';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<String?> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return 'Please log out and log back in before deleting your account.';
      }
      return 'Failed to delete account. Please try again.';
    }
  }
}
