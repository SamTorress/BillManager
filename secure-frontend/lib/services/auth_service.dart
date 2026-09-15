import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String keycloakBaseUrl = 'http://192.168.113.139:8180';
  static const String realm = 'dmit2015-realm';
  static const String clientId = 'dmit2015-flutter-client';

  // Held in memory only — cleared on logout or app restart
  static String? accessToken;
  static String? username;
  static List<String> roles = [];

  static Future<bool> login(String usernameInput, String password) async {
    final url = Uri.parse(
      '$keycloakBaseUrl/realms/$realm/protocol/openid-connect/token',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': clientId,
        'grant_type': 'password',
        'username': usernameInput,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      accessToken = data['access_token'];
      _decodeToken(accessToken!);
      return true;
    }

    return false;
  }

  static void _decodeToken(String token) {
    final parts = token.split('.');
    final payload = base64Url.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(payload));
    final Map<String, dynamic> data = jsonDecode(decoded);

    username = data['preferred_username'];
    roles = List<String>.from(data['realm_access']?['roles'] ?? []);
  }

  static void logout() {
    accessToken = null;
    username = null;
    roles = [];
  }

  static bool get isLoggedIn => accessToken != null;
}
