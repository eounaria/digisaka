import 'package:flutter/foundation.dart';

class Env {
  Env._();

  static const String apiKey = String.fromEnvironment('API_KEY');
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// True only when every required value was provided and is not a placeholder.
  static bool get isConfigured =>
      apiKey.isNotEmpty &&
      apiKey != 'PASTE_YOUR_REAL_KEY_HERE' &&
      apiBaseUrl.isNotEmpty;

  /// Non-blocking check for startup. Prints a warning in debug mode if not configured.
  static void assertConfigured() {
    if (kDebugMode && !isConfigured) {
      debugPrint(
        '⚠️ Env not configured: Run the app with '
        '--dart-define-from-file=env.json (copy env.example.json to env.json first).',
      );
    }
  }
}