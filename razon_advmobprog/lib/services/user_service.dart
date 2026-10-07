import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';

import '../models/user.dart' as model;

// Enhancement 2 & 3
// Saved in SharedPreferences ('loginType') when the user signs in so the
// profile screen can show details depending on the LoginType.
enum LoginType { dummyJson, firebase }

ValueNotifier<UserService> userService = ValueNotifier(UserService());

// Handles API requests for user authentication
class UserService {
  Map<String, dynamic> data = {};

  // Enhancement 2
  // Logs in a user against the DummyJSON /auth/login
  // endpoint and called from signin_screen.dart.
  Future<Map<String, dynamic>> loginUser(
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$host/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': 60,
      }),
    );

    if (response.statusCode == 200) {
      data = jsonDecode(response.body);
      await saveUserData(data);

      // DummyJSON login
      await _saveLoginType(LoginType.dummyJson);
      data['loginType'] = LoginType.dummyJson.name;

      return data;
    } else {
      throw Exception(response.body);
    }
  }

  // Enhancement 1 & 3
  // Save user data from the API response based on the User model 
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final user = model.User.fromJson(userData);

    await prefs.setInt('id', user.id);
    await prefs.setString('username', user.username);
    await prefs.setString('email', user.email);
    await prefs.setString('firstName', user.firstName);
    await prefs.setString('lastName', user.lastName);
    await prefs.setString('gender', user.gender);
    await prefs.setString('image', user.image);
    await prefs.setString('accessToken', user.accessToken);
    await prefs.setString('refreshToken', user.refreshToken);

    // support a generic token key if present in the API response
    if (userData.containsKey('token')) {
      await prefs.setString('token', userData['token'] ?? '');
    } else if (user.accessToken.isNotEmpty) {
      await prefs.setString('token', user.accessToken);
    }
  }

  // Enhancement 3
  // Returns the LoginType of the saved session
  Future<LoginType> getLoginType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('loginType') == LoginType.firebase.name
        ? LoginType.firebase
        : LoginType.dummyJson;
  }

  Future<void> _saveLoginType(LoginType loginType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loginType', loginType.name);
  }

  // Enhancement 3
  // Returns loginType. For Firebase users the data comes
  // from FirebaseAuth.currentUser plus the details saved by the
  // sign-up screen
  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final loginType = await getLoginType();

    if (loginType == LoginType.firebase && currentUser != null) {
      final profile = await getFirebaseProfile(currentUser!.uid);

      return {
        'loginType': LoginType.firebase.name,
        'id': 0, // DummyJSON-only field
        'uid': currentUser!.uid,
        'username': currentUser!.displayName ?? profile['username'] ?? '',
        'email': currentUser!.email ?? '',
        'firstName': profile['firstName'] ?? '',
        'lastName': profile['lastName'] ?? '',
        'age': profile['age'] ?? '',
        'contactNo': profile['contactNo'] ?? '',
        'gender': '',
        'image': currentUser!.photoURL ?? '',
        'accessToken': prefs.getString('accessToken') ?? '',
        'token': prefs.getString('token') ?? '',
      };
    }

    return {
      'loginType': LoginType.dummyJson.name,
      'id': prefs.getInt('id') ?? 0,
      'username': prefs.getString('username') ?? '',
      'email': prefs.getString('email') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'image': prefs.getString('image') ?? '',
      'accessToken': prefs.getString('accessToken') ?? '',
      'refreshToken': prefs.getString('refreshToken') ?? '',
      'token': prefs.getString('token') ?? prefs.getString('accessToken') ?? '',
    };
  }

  // Enhancement 3
  // Retrieve the User model from SharedPreferences. Used
  // by profile_screen.dart to render the saved profile.
  Future<model.User> getUser() async {
    final userData = await getUserData();
    return model.User.fromJson(userData);
  }

  // Enhancement 1 & 2
  // Check if a user is currently logged in 
  // Firebase sessions are checked with the FirebaseAuth SDK:
  // authStateChanges().first waits for Firebase to restore the
  // signed-in user, then the ID token is refreshed
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();

    if (await getLoginType() == LoginType.firebase) {
      final user = await authStateChanges.first;
      if (user == null) return false;
      return refreshToken();
    }

    final token = prefs.getString('accessToken') ?? prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  // Enhancement 1 & 3
  // Logout and clear all saved user data
  // Also signs out of Firebase. Removes the session/token keys
  // but keeps the Firebase sign-up details for the next sign-in.
  Future<void> logout() async {
    try {
      await signOut();

      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys().toList()) {
        if (!key.startsWith('profile_')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      throw Exception('Failed to log out: $e');
    }
  }

  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  // Enhancement 1
  // saves the Firebase session (login type + ID token)
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _saveFirebaseSession();
    return credential;
  }

  // Enhancement 1
  // used by signup_screen.dart
  // added: saves the session (Firebase signs the new user in)
  Future<UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _saveFirebaseSession();
    return credential;
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  Future<void> updateUsername({required String username}) async {
    await currentUser!.updateDisplayName(username);
    await currentUser!.reload();
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    await currentUser!.reauthenticateWithCredential(credential);
    final uid = currentUser!.uid;
    await currentUser!.delete();
    await firebaseAuth.signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_$uid');
    await logout();
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.updatePassword(newPassword);
  }

  // Enhancement 2
  // the SDK refreshes the ID token every hour by itself
  // Returns false if Firebase rejects the session
  Future<bool> refreshToken() async {
    try {
      final token = await currentUser?.getIdToken(true) ?? '';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', token);
      await prefs.setString('token', token);
      return true;
    } on FirebaseAuthException catch (e) {
      // offline: keep the user logged in
      return e.code == 'network-request-failed';
    }
  }

  Future<void> _saveFirebaseSession() async {
    final prefs = await SharedPreferences.getInstance();
    await _saveLoginType(LoginType.firebase);
    await prefs.setString('accessToken', await currentUser?.getIdToken() ?? '');
    await prefs.setString('token', prefs.getString('accessToken') ?? '');
  }

  Future<void> saveFirebaseProfile(
    String uid,
    Map<String, dynamic> profile,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_$uid', jsonEncode(profile));
  }

  Future<Map<String, dynamic>> getFirebaseProfile(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('profile_$uid');
    return saved == null ? {} : Map<String, dynamic>.from(jsonDecode(saved));
  }

  static String errorMessage(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'email-already-in-use':
          return 'An account already exists for that email.';
        case 'weak-password':
          return 'The password is too weak.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'network-request-failed':
          return 'No internet connection.';
        default:
          return e.message ?? e.code;
      }
    }

    final text = e.toString().replaceFirst('Exception: ', '');
    try {
      return jsonDecode(text)['message'] ?? text;
    } catch (_) {
      return text;
    }
  }
}