import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_demo/constants/constants.dart';
import 'package:flutter_chat_demo/models/models.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Authentication provider handles user sign-in/out with Google and Firebase,
/// stores user data locally, and maintains auth state.
enum Status {
  uninitialized,
  authenticated,
  authenticating,
  authenticateError,
  authenticateException,
  authenticateCanceled,
}

class AuthProvider extends ChangeNotifier {
  final GoogleSignIn googleSignIn;
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firebaseFirestore;
  final SharedPreferences prefs;

  Status _status = Status.uninitialized;

  AuthProvider({
    required this.firebaseAuth,
    required this.googleSignIn,
    required this.prefs,
    required this.firebaseFirestore,
  });

  Status get status => _status;

  String? get userFirebaseId => prefs.getString(FirestoreConstants.id);

  /// Checks if user is already signed in.
  Future<bool> isLoggedIn() async {
    final isSignedIn = await googleSignIn.isSignedIn();
    final hasId = prefs.getString(FirestoreConstants.id)?.isNotEmpty == true;
    return isSignedIn && hasId;
  }

  /// Handles Google Sign-In flow and updates Firestore and local prefs.
  Future<bool> handleSignIn() async {
    _status = Status.authenticating;
    notifyListeners();

    try {
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        _status = Status.authenticateCanceled;
        notifyListeners();
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        _status = Status.authenticateError;
        notifyListeners();
        return false;
      }

      // Check if user data exists in Firestore
      final result = await firebaseFirestore
          .collection(FirestoreConstants.pathUserCollection)
          .where(FirestoreConstants.id, isEqualTo: firebaseUser.uid)
          .get();

      if (result.docs.isEmpty) {
        // New user — create Firestore doc
        await firebaseFirestore
            .collection(FirestoreConstants.pathUserCollection)
            .doc(firebaseUser.uid)
            .set({
          FirestoreConstants.nickname: firebaseUser.displayName,
          FirestoreConstants.photoUrl: firebaseUser.photoURL,
          FirestoreConstants.id: firebaseUser.uid,
          FirestoreConstants.createdAt:
              DateTime.now().millisecondsSinceEpoch.toString(),
          FirestoreConstants.chattingWith: null,
        });

        // Save to local prefs
        await _saveUserToPrefs(
            firebaseUser.uid, firebaseUser.displayName, firebaseUser.photoURL);
      } else {
        // Existing user — load data from Firestore doc
        final userChat = UserChat.fromDocument(result.docs.first);
        await _saveUserToPrefs(
            userChat.id, userChat.nickname, userChat.photoUrl,
            aboutMe: userChat.aboutMe);
      }

      _status = Status.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      print('🛑 GoogleSignIn failed: $e');
      _status = Status.authenticateException;
      notifyListeners();
      return false;
    }
  }

  /// Saves user data to shared preferences
  Future<void> _saveUserToPrefs(String id, String? nickname, String? photoUrl,
      {String aboutMe = ""}) async {
    await prefs.setString(FirestoreConstants.id, id);
    await prefs.setString(FirestoreConstants.nickname, nickname ?? "");
    await prefs.setString(FirestoreConstants.photoUrl, photoUrl ?? "");
    await prefs.setString(FirestoreConstants.aboutMe, aboutMe);
  }

  /// Signs out user from Firebase and Google.
  Future<void> handleSignOut() async {
    _status = Status.uninitialized;
    notifyListeners();

    await firebaseAuth.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();

    // Optionally clear preferences if needed
    await prefs.clear();
  }

  void handleException() {
    _status = Status.authenticateException;
    notifyListeners();
  }
}
