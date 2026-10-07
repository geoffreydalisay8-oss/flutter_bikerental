import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<User?> login(
    String email,
    String password,
  ) async {
    UserCredential result =
        await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return result.user;
  }

  // ============================================================
  // GOOGLE LOGIN
  // ============================================================

  Future<User?> loginWithGoogle() async {
    // ----------------------------------------------------------
    // WEB
    // ----------------------------------------------------------

    if (kIsWeb) {
      final GoogleAuthProvider googleProvider =
          GoogleAuthProvider();

      UserCredential result =
          await auth.signInWithPopup(
        googleProvider,
      );

      return result.user;
    }

    // ----------------------------------------------------------
    // ANDROID / IOS
    // ----------------------------------------------------------

    final GoogleSignIn googleSignIn =
        GoogleSignIn(
      scopes: <String>[
        'email',
      ],
    );

    // Open Google account selection
    final GoogleSignInAccount? googleUser =
        await googleSignIn.signIn();

    // User cancelled Google login
    if (googleUser == null) {
      return null;
    }

    // Get Google authentication information
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Create Firebase credential
    final AuthCredential credential =
        GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase
    final UserCredential result =
        await auth.signInWithCredential(
      credential,
    );

    return result.user;
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    try {
      final GoogleSignIn googleSignIn =
          GoogleSignIn();

      await googleSignIn.signOut();
    } catch (_) {
      // Ignore Google logout error
    }

    await auth.signOut();
  }
}