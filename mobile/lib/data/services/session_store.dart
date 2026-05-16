import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  static const _tokenKey = 'auth_token';
  static const _baseUrlKey = 'api_base_url';

  SharedPreferences? _prefs;
  String _baseUrl = _defaultBaseUrl;

  static String get _defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8081';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8081';
      default:
        return 'http://localhost:8081';
    }
  }

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    _baseUrl = _prefs!.getString(_baseUrlKey) ?? _defaultBaseUrl;
  }

  String get baseUrl => _baseUrl;

  String? get token => _prefs?.getString(_tokenKey);

  Future<void> saveToken(String token) async {
    await _prefs!.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    await _prefs!.remove(_tokenKey);
  }

  Future<void> setBaseUrl(String value) async {
    _baseUrl = value;
    await _prefs!.setString(_baseUrlKey, value);
  }
}
