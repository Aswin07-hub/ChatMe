// lib/app_config.dart
//
// SAKTI App — Centralized Environment Configuration Loader
// Uses flutter_dotenv to read .env at startup.
// All other files should import this, NEVER hard-code secrets.

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // ── Firebase ──
  static String get firebaseApiKey        => dotenv.env['FIREBASE_API_KEY'] ?? '';
  static String get firebaseAuthDomain    => dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '';
  static String get firebaseProjectId     => dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  static String get firebaseStorageBucket => dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';
  static String get firebaseSenderId      => dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
  static String get firebaseAppId         => dotenv.env['FIREBASE_APP_ID'] ?? '';
  static String get firebaseMeasurementId => dotenv.env['FIREBASE_MEASUREMENT_ID'] ?? '';

  static String get firebaseAndroidAppId  => dotenv.env['FIREBASE_ANDROID_APP_ID'] ?? '';
  static String get firebaseIosAppId      => dotenv.env['FIREBASE_IOS_APP_ID'] ?? '';

  // ── Gemini AI ──
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static String get geminiModel  => dotenv.env['GEMINI_MODEL'] ?? 'gemini-1.5-flash';

  // ── SAKTI Backend API ──
  static String get saktiApiUrl =>
      dotenv.env['CHATME_API_URL'] ??
      dotenv.env['SAKTI_API_URL'] ??
      '';

  static String get saktiVoiceWsUrl {
    final url = saktiApiUrl.replaceAll(RegExp(r'/$'), '');
    if (url.startsWith('https://')) {
      return '${url.replaceFirst('https://', 'wss://')}/voice';
    } else if (url.startsWith('http://')) {
      return '${url.replaceFirst('http://', 'ws://')}/voice';
    }
    return '$url/voice';
  }

  // ── Google Sign-In ──
  static String get googleWebClientId     => dotenv.env['GOOGLE_SIGN_IN_WEB_CLIENT_ID'] ?? '';
  static String get googleAndroidClientId => dotenv.env['GOOGLE_SIGN_IN_ANDROID_CLIENT_ID'] ?? '';
  static String get googleIosClientId     => dotenv.env['GOOGLE_SIGN_IN_IOS_CLIENT_ID'] ?? '';

  // ── Google Maps (optional) ──
  static String get mapsAndroidKey => dotenv.env['GOOGLE_MAPS_ANDROID_KEY'] ?? '';
  static String get mapsIosKey     => dotenv.env['GOOGLE_MAPS_IOS_KEY'] ?? '';

  // ── App Meta ──
  static String get appEnv     => dotenv.env['APP_ENV'] ?? 'development';
  static String get appName    => dotenv.env['APP_NAME'] ?? 'ChatMe';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';

  static bool get isProduction  => appEnv == 'production';
  static bool get isDevelopment => appEnv == 'development';
  static bool get isStaging     => appEnv == 'staging';
}
