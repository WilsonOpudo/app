import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static Future<void> logEvent(String name, Map<String, dynamic> params) async {
    try {
      await _analytics.logEvent(name: name, parameters: params);
    } catch (_) {
      // fail silently
    }
  }

  static Future<void> setUserRole(String role) async {
    await _analytics.setUserProperty(name: 'role', value: role);
  }
}
