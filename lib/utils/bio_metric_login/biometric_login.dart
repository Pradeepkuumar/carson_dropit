import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

class BiometricLockScreen {
  static final BiometricLockScreen _instance = BiometricLockScreen._internal();
  factory BiometricLockScreen() => _instance;
  BiometricLockScreen._internal();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Check if device supports biometric authentication
  Future<bool> isBiometricSupported() async {
    try {
      final bool isSupported = await _auth.isDeviceSupported();
      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      return isSupported && canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  /// Get available biometric methods
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Authenticate with biometrics
  Future<bool> authenticate({
    required String localizedReason,
    bool biometricOnly = true,
    bool stickyAuth = false,
    bool sensitiveTransaction = true,
    bool useErrorDialogs = true,
    String? customMessages,
  }) async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          sensitiveTransaction: sensitiveTransaction,
          biometricOnly: biometricOnly,
          useErrorDialogs: useErrorDialogs,
        ),
        authMessages: _getDefaultAuthMessages(),
      );
      return didAuthenticate;
    } catch (e) {
      return false;
    }
  }

  /// Get platform-specific default messages
  Iterable<AuthMessages> _getDefaultAuthMessages() {
    return [
      const AndroidAuthMessages(
        signInTitle: 'Authentication Required',
        cancelButton: 'Cancel',
        biometricHint: 'Verify your identity',
        biometricNotRecognized: 'Biometric not recognized. Try again.',
        biometricRequiredTitle: 'Biometric required',
        biometricSuccess: 'Biometric recognized successfully',
        goToSettingsButton: 'Go to Settings',
        goToSettingsDescription: 'Please set up biometric authentication',
      ),
      const IOSAuthMessages(
        cancelButton: 'Cancel',
        lockOut: 'Authentication disabled. Please use device passcode.',
        goToSettingsButton: 'Settings',
        goToSettingsDescription: 'Please set up biometric authentication',
      ),
    ];
  }

  /// Get biometric icon based on available type
  IconData getBiometricIcon(List<BiometricType> availableBiometrics) {
    if (availableBiometrics.contains(BiometricType.face)) {
      return Icons.face;
    } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    } else if (availableBiometrics.contains(BiometricType.iris)) {
      return Icons.remove_red_eye;
    } else {
      return Icons.security;
    }
  }

  /// Get biometric name for UI
  String getBiometricName(List<BiometricType> availableBiometrics) {
    if (availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (availableBiometrics.contains(BiometricType.iris)) {
      return 'Iris Scan';
    } else {
      return 'Biometric';
    }
  }
}