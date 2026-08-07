import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Live From Seed to Supper API (same as web + Android).
class FstsApi {
  static const base =
      'https://mixapps.store/from-seed-to-supper/api/index.php';

  String? token;

  Future<void> loadToken() async {
    final p = await SharedPreferences.getInstance();
    token = p.getString('fsts_token');
  }

  Future<void> saveToken(String? t) async {
    token = t;
    final p = await SharedPreferences.getInstance();
    if (t == null) {
      await p.remove('fsts_token');
      await p.remove('fsts_name');
    } else {
      await p.setString('fsts_token', t);
    }
  }

  Future<void> saveName(String name) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('fsts_name', name);
  }

  Future<String?> loadName() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('fsts_name');
  }

  Uri _uri(String path, [Map<String, String>? extra]) {
    final segs = path.split('/').where((s) => s.isNotEmpty).join('/');
    // Build manually so path slashes stay unencoded for Apache
    final buf = StringBuffer('$base?path=$segs');
    extra?.forEach((k, v) {
      buf.write(
          '&${Uri.encodeQueryComponent(k)}=${Uri.encodeQueryComponent(v)}');
    });
    return Uri.parse(buf.toString());
  }

  Map<String, String> get _headers {
    final h = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null && token!.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
      h['X-FSTS-Token'] = token!;
    }
    return h;
  }

  Future<Map<String, dynamic>> _req(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final uri = _uri(path, query);
    late http.Response res;
    if (method == 'POST') {
      res = await http.post(uri, headers: _headers, body: jsonEncode(body ?? {}));
    } else if (method == 'PATCH') {
      res = await http.patch(uri, headers: _headers, body: jsonEncode(body ?? {}));
    } else {
      res = await http.get(uri, headers: _headers);
    }
    Map<String, dynamic> data = {};
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      data = {'error': 'bad_json', 'raw': res.body};
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(data['error']?.toString() ?? 'HTTP ${res.statusCode}');
    }
    return data;
  }

  Future<Map<String, dynamic>> demoLogin() =>
      _req('auth/demo', method: 'POST', body: {});

  Future<Map<String, dynamic>> login(String email, String password) =>
      _req('auth/login', method: 'POST', body: {
        'email': email,
        'password': password,
      });

  Future<Map<String, dynamic>> today() => _req('today');

  Future<Map<String, dynamic>> growing() => _req('growing');

  Future<Map<String, dynamic>> garden() => _req('garden');

  Future<Map<String, dynamic>> journalList() => _req('journal');

  Future<Map<String, dynamic>> photos() => _req('photos');

  Future<void> completeTask(int id) =>
      _req('tasks/$id', method: 'PATCH', body: {'status': 'done'});

  Future<Map<String, dynamic>> plant({
    required String commonName,
    String? variety,
    required int quantity,
    int? featureId,
  }) =>
      _req('plantings', method: 'POST', body: {
        'common_name': commonName,
        if (variety != null && variety.isNotEmpty) 'variety': variety,
        'quantity': quantity,
        if (featureId != null) 'feature_id': featureId,
        'origin': 'seedling',
        'source': 'purchased',
      });

  Future<Map<String, dynamic>> harvest({
    required int plantingId,
    required double amount,
    String unit = 'kg',
  }) =>
      _req('harvests', method: 'POST', body: {
        'planting_id': plantingId,
        'amount': amount,
        'unit': unit,
        'quality': 'good',
      });

  Future<Map<String, dynamic>> journal(String body, {bool voice = false}) {
    if (voice) {
      return _req('journal/voice', method: 'POST', body: {
        'body': body,
        'transcript': body,
        'via_voice': true,
      });
    }
    return _req('journal', method: 'POST', body: {'body': body});
  }

  Future<Map<String, dynamic>> uploadPhotoBase64(
    String base64Jpeg, {
    String? caption,
  }) =>
      _req('photos', method: 'POST', body: {
        'image_base64': 'data:image/jpeg;base64,$base64Jpeg',
        if (caption != null && caption.isNotEmpty) 'caption': caption,
      });
}
