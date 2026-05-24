import 'dart:async';

// MOCK AUTH SERVICE
// This is a fake auth service so Person B can build the UI
// without waiting for Person A's real Firebase setup.
// When Person A finishes, they replace this file with the real one
// and the screens dont need to change.

// represents a user
class AppUser {
  final String uid;
  final String name;
  final String email;

  AppUser({required this.uid, required this.name, required this.email});
}

class AuthService {
  static AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;

  // sign in with email and password
  // returns null on success, error message on failure
  Future<String?> signIn(String email, String password) async {
    // pretend it takes time like a real network call
    await Future.delayed(const Duration(seconds: 1));

    if (email.isEmpty || password.isEmpty) {
      return "Please fill in all fields.";
    }
    if (!email.contains("@")) {
      return "Please enter a valid email.";
    }
    if (password.length < 6) {
      return "Wrong email or password.";
    }

    // pretend success
    _currentUser = AppUser(
      uid: "mock-uid-123",
      name: email.split("@").first,
      email: email,
    );
    return null;
  }

  // sign up new user
  Future<String?> signUp(String name, String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      return "Please fill in all fields.";
    }
    if (!email.contains("@")) {
      return "Please enter a valid email.";
    }
    if (password.length < 6) {
      return "Password must be at least 6 characters.";
    }

    _currentUser = AppUser(
      uid: "mock-uid-${DateTime.now().millisecondsSinceEpoch}",
      name: name,
      email: email,
    );
    return null;
  }

  // sign out the current user
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
  }
}
