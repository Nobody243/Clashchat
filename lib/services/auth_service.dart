import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'usage_quota_service.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;

  static String _safeAvatarSeed(String? seed, {String fallback = 'Debater'}) {
    final value = seed?.trim();
    return (value == null || value.isEmpty) ? fallback : value;
  }

  // Sign Up
  static Future<String?> signUp(
    String email,
    String password, {
    String? displayName,
  }) async {
    try {
      // Create user in Firebase Auth
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) {
        return 'Failed to create user account';
      }

      // Use provided displayName, fallback to email prefix
      final finalDisplayName = (displayName != null && displayName.isNotEmpty)
          ? displayName
          : email.split('@').first;

      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      // Run Firebase Auth display name update and Firestore doc initialization concurrently
      await Future.wait([
        user.updateDisplayName(finalDisplayName).catchError((e) {
          debugPrint('Error updating displayName: $e');
        }),
        userDoc.set({
          'displayName': finalDisplayName,
          'email': user.email,
          'bio': '',
          'role': 'Member',
          'rankPoints': 0,
          'dailyUsageLimit': UsageQuotaService.defaultDailyLimit,
          'dailyUsageUsed': 0,
          'dailyUsageDayKey': UsageQuotaService.todayKey(),
          'createdAt': FieldValue.serverTimestamp(),
        }).catchError((firestoreError) {
          debugPrint('Firestore error (non-blocking): $firestoreError');
        }),
      ]);

      debugPrint('SignUp successful for $email - uid: ${user.uid}');
      return null; // null = success
    } on FirebaseAuthException catch (authError) {
      debugPrint('FirebaseAuthException: ${authError.code} - ${authError.message}');
      return authError.message ?? authError.code;
    } catch (e) {
      debugPrint('Unexpected SignUp error: $e');
      return 'Signup failed: ${e.toString()}';
    }
  }

  // Login
  static Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? e.code;
    }
  }

  // Logout
  /// Sends a Firebase password-reset email. Returns null on success or a
  /// user-readable error message.
  static Future<String?> sendPasswordReset(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return 'Enter your email first.';
    try {
      await _auth.sendPasswordResetEmail(email: trimmed);
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          return 'That email address is not valid.';
        case 'user-not-found':
          // Don't reveal whether an account exists.
          return null;
        default:
          return 'Could not send the reset email. Please try again.';
      }
    } catch (e) {
      debugPrint('Password reset error: $e');
      return 'Could not send the reset email. Please try again.';
    }
  }

  static Future<void> logout() async {
    await _auth.signOut();
  }

  // Current user
  static User? get currentUser => _auth.currentUser;

  // Check if logged in
  static bool get isLoggedIn => _auth.currentUser != null;

  // Check if user account still exists in Firestore
  static Future<bool> userAccountExists(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking user account: $e');
      return false;
    }
  }

  // Fetch user profile from Firestore
  static Future<Map<String, dynamic>?> fetchProfile(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return doc.data();
  }

  // Stream user profile updates
  static Stream<DocumentSnapshot<Map<String, dynamic>>> profileStream(
    String uid,
  ) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snap, _) => snap.data() ?? <String, dynamic>{},
          toFirestore: (data, _) => data,
        )
        .snapshots();
  }

  // Google Sign In
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final UserCredential userCredential;
      if (kIsWeb) {
        userCredential = await FirebaseAuth.instance.signInWithPopup(
          GoogleAuthProvider(),
        );
      } else {
        final googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
      }

      final user = userCredential.user;
      if (user == null) return null;

      final displayName = _safeAvatarSeed(user.displayName);
      final email = user.email ?? '';

      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      // Only a brand-new account gets the full default profile. A returning user
      // must NOT have rankPoints, quota, bio, or avatar reset on every login.
      final Map<String, dynamic> profileData = isNewUser
          ? <String, dynamic>{
              'displayName': displayName,
              'email': email,
              'avatarSeed': displayName,
              'isGoogleSignIn': true,
              'bio': '',
              'role': 'Member',
              'rankPoints': 0,
              'dailyUsageLimit': UsageQuotaService.defaultDailyLimit,
              'dailyUsageUsed': 0,
              'dailyUsageDayKey': UsageQuotaService.todayKey(),
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            }
          : <String, dynamic>{
              'lastLoginAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            };

      await Future.wait([
        user.updateDisplayName(displayName).catchError((e) {
          debugPrint('Error updating displayName on Google sign in: $e');
        }),
        userDoc.set(profileData, SetOptions(merge: true)),
      ]);

      return userCredential;
    } catch (e) {
      debugPrint('Google Sign In Error: $e');
      return null;
    }
  }

  // Check if user has password authentication set
  static bool hasPasswordAuth() {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Check if password provider exists in user's provider data
    return user.providerData.any(
      (provider) => provider.providerId == 'password',
    );
  }
}
