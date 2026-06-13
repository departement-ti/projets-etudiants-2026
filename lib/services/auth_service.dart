import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../components/alert.dart';

class AuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  Future<OAuthCredential?> getGoogleCredential(BuildContext context) async {
    try {
      if (!context.mounted) return null;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(
            color: Color.fromRGBO(7, 82, 96, 1),
          ),
        ),
      );

      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        if (context.mounted) Navigator.of(context).pop();
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      if (context.mounted) {
        Navigator.of(context).pop();
      }

      return credential;
    } catch (e) {
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();

        String errorMessage = e.toString();
        if (e is FirebaseAuthException) {
          errorMessage = 'Error: ${e.code} - ${e.message}';
        }

        showDialog(
          context: context,
          builder: (ctx) => Alert_Dialog(
            isError: true,
            alertTitle: 'Error',
            errorMessage: errorMessage,
            buttonText: 'OK',
          ),
        );
      }
      return null;
    }
  }

  Future<UserCredential> signInWithCredential(
      OAuthCredential credential) async {
    return FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithGoogle(BuildContext context) async {
    if (kIsWeb) {
      // Use Firebase Auth popup for web
      final provider = GoogleAuthProvider();
      provider.addScope('email');
      provider.addScope('profile');
      // Optional: force account selection
      provider.setCustomParameters({'prompt': 'select_account'});
      return await FirebaseAuth.instance.signInWithPopup(provider);
    }

    final credential = await getGoogleCredential(context);
    if (credential == null) {
      return Future.error(Exception('Google Sign-In cancelled'));
    }
    return FirebaseAuth.instance.signInWithCredential(credential);
  }
}
