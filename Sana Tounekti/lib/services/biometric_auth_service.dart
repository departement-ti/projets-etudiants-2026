import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BiometricAuthService {
  static final BiometricAuthService _instance =
      BiometricAuthService._internal();
  factory BiometricAuthService() => _instance;
  BiometricAuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();

  bool get _isMobilePlatform {
    return Platform.isIOS || Platform.isAndroid;
  }

  Future<bool> isBiometricAvailable() async {
    if (kIsWeb || !_isMobilePlatform) return false;

    try {
      print('Checking biometric availability...');
      final canCheck = await _localAuth.canCheckBiometrics;
      print('canCheckBiometrics: $canCheck');
      final isSupported = await _localAuth.isDeviceSupported();
      print('isDeviceSupported: $isSupported');

      // On Android, isDeviceSupported is more reliable
      return isSupported;
    } catch (e) {
      print('Error checking biometric: $e');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (kIsWeb || !_isMobilePlatform) return [];

    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  Future<bool> authenticate(
      {String reason = 'Please authenticate to access your account'}) async {
    if (kIsWeb || !_isMobilePlatform) return false;

    try {
      print('Starting biometric authentication...');
      final result = await _localAuth.authenticate(
        localizedReason: reason,
      );
      print('Biometric auth result: $result');
      return result;
    } catch (e) {
      print('Biometric auth error: $e');
      return false;
    }
  }

  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometric_enabled') ?? false;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', enabled);
  }

  Future<bool> hasBiometricCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('biometric_user_id') != null;
  }

  Future<String?> getBiometricUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('biometric_user_id');
  }

  Future<void> saveBiometricUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('biometric_user_id', userId);
  }

  Future<void> clearBiometricCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('biometric_user_id');
    await prefs.setBool('biometric_enabled', false);
  }

  String getBiometricName(List<BiometricType> biometrics) {
    if (biometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (biometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (biometrics.contains(BiometricType.iris)) {
      return 'Iris';
    }
    return 'Biometric';
  }

  Future<bool> authenticateWithBiometric() async {
    final isAvailable = await isBiometricAvailable();
    final isEnabled = await isBiometricEnabled();
    final hasCredentials = await hasBiometricCredentials();

    if (!isAvailable || !isEnabled || !hasCredentials) {
      return false;
    }

    final biometrics = await getAvailableBiometrics();
    final bioName = getBiometricName(biometrics);

    return await authenticate(
      reason: 'Use $bioName to sign in',
    );
  }

  Future<String?> registerWithBiometric(String name) async {
    try {
      // First authenticate with biometrics before creating account
      print('Requesting biometric authentication...');
      final authResult = await _localAuth.authenticate(
        localizedReason: 'Authenticate to create your account',
      );

      if (!authResult) {
        print('Biometric authentication failed');
        return null;
      }

      print('Biometric authenticated, creating account...');

      // Create anonymous Firebase user
      final firebaseResult = await FirebaseAuth.instance.signInAnonymously();
      final userId = firebaseResult.user!.uid;

      // Save to Firestore
      await FirebaseFirestore.instance.collection('Users').doc(userId).set({
        'name': name,
        'role': 'personneAge',
        'createdAt': DateTime.now().toIso8601String(),
      });

      await saveBiometricUserId(userId);
      await setBiometricEnabled(true);

      return userId;
    } catch (e) {
      print('Error creating account: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final userId = await getBiometricUserId();
    if (userId == null) return null;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();

      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<String?> getUserId() async {
    return await getBiometricUserId();
  }
}
