import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'app_config.dart';

/// Firebase configuration loaded from environment values.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    var apiKey = AppConfig.firebaseApiKey;
    var appId = AppConfig.firebaseAppId;

    if (!kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        // Android API Key & App ID from google-services.json
        final androidId = AppConfig.firebaseAndroidAppId;
        if (androidId.isNotEmpty) appId = androidId;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosId = AppConfig.firebaseIosAppId;
        if (iosId.isNotEmpty) appId = iosId;
      }
    }

    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: AppConfig.firebaseSenderId,
      projectId: AppConfig.firebaseProjectId,
      authDomain: AppConfig.firebaseAuthDomain,
      storageBucket: AppConfig.firebaseStorageBucket,
      measurementId: AppConfig.firebaseMeasurementId,
    );
  }
}
