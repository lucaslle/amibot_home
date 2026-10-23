import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'robot_service.dart';

// Standard codes of the Tuya robot vacuum category ("sd"). Check the real ones
// in the Tuya console: Cloud > Devices > your robot > Device Debugging.
const _codeStart = 'power_go';
const _codePause = 'pause';
const _codeDock = 'switch_charge';
const _codeSuction = 'suction';
const _codeBattery = 'electricity_left';
const _codeState = 'status';

class TuyaException implements Exception {
  TuyaException(this.message);

  final String message;

  @override
  String toString() => 'Tuya : $message';
}

/// Tuya cloud request signature (HMAC-SHA256 method, upper-case hex).
/// https://developer.tuya.com/en/docs/iot/new-singnature
String tuyaSign({
  required String clientId,
  required String secret,
  required String timestamp,
  required String method,
  required String pathAndQuery,
  String body = '',
  String accessToken = '',
  String nonce = '',
}) {
  final bodyHash = sha256.convert(utf8.encode(body)).toString();
  final stringToSign = '$method\n$bodyHash\n\n$pathAndQuery';
  final payload = '$clientId$accessToken$timestamp$nonce$stringToSign';
  return Hmac(sha256, utf8.encode(secret)).convert(utf8.encode(payload)).toString().toUpperCase();
}

class TuyaCloudRobotService implements RobotService {
  TuyaCloudRobotService({
    required this.accessId,
    required this.accessSecret,
    required this.deviceId,
    String region = 'eu',
    http.Client? client,
  })  : _baseUrl = Uri.parse('https://openapi.tuya$region.com'),
        _client = client ?? http.Client();

  final String accessId;
  final String accessSecret;
  final String deviceId;
  final Uri _baseUrl;
  final http.Client _client;

  String? _token;
  DateTime _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  Future<RobotStatus> status() async {
    final result = await _request('GET', '/v1.0/devices/$deviceId/status') as List;
    final values = {for (final item in result) item['code'] as String: item['value']};
    final state = values[_codeState]?.toString() ?? '';
    return RobotStatus(
      cleaning: values[_codeStart] == true && values[_codePause] != true,
      charging: state.contains('charg'),
      battery: (values[_codeBattery] as num?)?.toInt(),
      suction: Suction.values.asNameMap()[values[_codeSuction]],
    );
  }

  @override
  Future<void> start() => _send(_codeStart, true);

  @override
  Future<void> pause() => _send(_codePause, true);

  @override
  Future<void> dock() => _send(_codeDock, true);

  @override
  Future<void> setSuction(Suction suction) => _send(_codeSuction, suction.name);

  Future<void> _send(String code, Object value) => _request(
        'POST',
        '/v1.0/devices/$deviceId/commands',
        body: {
          'commands': [
            {'code': code, 'value': value},
          ],
        },
      );

  Future<String> _accessToken() async {
    // Renew a minute early so a request never goes out with an expiring token.
    if (_token != null && DateTime.now().isBefore(_tokenExpiry)) return _token!;
    final result = await _request('GET', '/v1.0/token?grant_type=1', authenticated: false) as Map;
    _token = result['access_token'] as String;
    _tokenExpiry = DateTime.now().add(Duration(seconds: (result['expire_time'] as num).toInt() - 60));
    return _token!;
  }

  Future<Object?> _request(String method, String pathAndQuery, {Object? body, bool authenticated = true}) async {
    final token = authenticated ? await _accessToken() : '';
    final encodedBody = body == null ? '' : jsonEncode(body);
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final headers = {
      'client_id': accessId,
      't': timestamp,
      'sign_method': 'HMAC-SHA256',
      'sign': tuyaSign(
        clientId: accessId,
        secret: accessSecret,
        timestamp: timestamp,
        method: method,
        pathAndQuery: pathAndQuery,
        body: encodedBody,
        accessToken: token,
      ),
      if (authenticated) 'access_token': token,
      'Content-Type': 'application/json',
    };

    final request = http.Request(method, _baseUrl.resolve(pathAndQuery))
      ..headers.addAll(headers)
      ..body = encodedBody;
    final response = await http.Response.fromStream(await _client.send(request));
    if (response.statusCode != 200) {
      throw TuyaException('HTTP ${response.statusCode}');
    }

    // Tuya answers 200 even on failure and reports the error in the JSON body.
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['success'] != true) {
      if (json['code'] == 1010) _token = null; // token expired: renewed on next call
      throw TuyaException('${json['msg'] ?? 'erreur inconnue'} (code ${json['code']})');
    }
    return json['result'];
  }
}
