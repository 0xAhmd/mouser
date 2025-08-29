import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static const String _keyServerIP = 'server_ip';
  static const String _keyServerPort = 'server_port';
  static const String _keyMouseSensitivity = 'mouse_sensitivity';
  static const String _keyScrollSensitivity = 'scroll_sensitivity';
  static const String _keyOnboardingCompleted = 'onboarding_completed';

  // Default values
  static const String _defaultServerIP = '192.168.1.1';
  static const int _defaultServerPort = 8080;
  static const double _defaultMouseSensitivity = 2.5;
  static const double _defaultScrollSensitivity = 1.0;

  static SharedPreferences? _prefs;

  /// Initialize SharedPreferences
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Ensure preferences are initialized
  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Server IP methods
  static Future<String> getServerIP() async {
    final prefs = await _instance;
    return prefs.getString(_keyServerIP) ?? _defaultServerIP;
  }

  static Future<bool> setServerIP(String ip) async {
    final prefs = await _instance;
    return prefs.setString(_keyServerIP, ip);
  }

  // Server Port methods
  static Future<int> getServerPort() async {
    final prefs = await _instance;
    return prefs.getInt(_keyServerPort) ?? _defaultServerPort;
  }

  static Future<bool> setServerPort(int port) async {
    final prefs = await _instance;
    return prefs.setInt(_keyServerPort, port);
  }

  // Mouse Sensitivity methods
  static Future<double> getMouseSensitivity() async {
    final prefs = await _instance;
    return prefs.getDouble(_keyMouseSensitivity) ?? _defaultMouseSensitivity;
  }

  static Future<bool> setMouseSensitivity(double sensitivity) async {
    final prefs = await _instance;
    return prefs.setDouble(_keyMouseSensitivity, sensitivity);
  }

  // Scroll Sensitivity methods
  static Future<double> getScrollSensitivity() async {
    final prefs = await _instance;
    return prefs.getDouble(_keyScrollSensitivity) ?? _defaultScrollSensitivity;
  }

  static Future<bool> setScrollSensitivity(double sensitivity) async {
    final prefs = await _instance;
    return prefs.setDouble(_keyScrollSensitivity, sensitivity);
  }

  // Onboarding methods
  static Future<bool> getOnboardingCompleted() async {
    final prefs = await _instance;
    return prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  static Future<bool> setOnboardingCompleted(bool completed) async {
    final prefs = await _instance;
    return prefs.setBool(_keyOnboardingCompleted, completed);
  }

  // Load all user preferences at once
  static Future<Map<String, dynamic>> getAllPreferences() async {
    return {
      'serverIP': await getServerIP(),
      'serverPort': await getServerPort(),
      'mouseSensitivity': await getMouseSensitivity(),
      'scrollSensitivity': await getScrollSensitivity(),
      'onboardingCompleted': await getOnboardingCompleted(),
    };
  }

  // Save multiple preferences at once
  static Future<void> saveConnectionSettings({
    required String serverIP,
    int? serverPort,
  }) async {
    final prefs = await _instance;
    await Future.wait([
      prefs.setString(_keyServerIP, serverIP),
      if (serverPort != null) prefs.setInt(_keyServerPort, serverPort),
    ]);
  }

  static Future<void> saveSensitivitySettings({
    double? mouseSensitivity,
    double? scrollSensitivity,
  }) async {
    final prefs = await _instance;
    await Future.wait([
      if (mouseSensitivity != null)
        prefs.setDouble(_keyMouseSensitivity, mouseSensitivity),
      if (scrollSensitivity != null)
        prefs.setDouble(_keyScrollSensitivity, scrollSensitivity),
    ]);
  }

  // Clear all preferences (useful for reset functionality)
  static Future<bool> clearAllPreferences() async {
    final prefs = await _instance;
    return prefs.clear();
  }

  // Clear specific preference categories
  static Future<void> clearConnectionSettings() async {
    final prefs = await _instance;
    await Future.wait([
      prefs.remove(_keyServerIP),
      prefs.remove(_keyServerPort),
    ]);
  }

  static Future<void> clearSensitivitySettings() async {
    final prefs = await _instance;
    await Future.wait([
      prefs.remove(_keyMouseSensitivity),
      prefs.remove(_keyScrollSensitivity),
    ]);
  }
}
