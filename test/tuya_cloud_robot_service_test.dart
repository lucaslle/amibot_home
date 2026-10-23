import 'dart:convert';

import 'package:amibot_home/robot/robot_service.dart';
import 'package:amibot_home/robot/tuya_cloud_robot_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('signature matches an independent HMAC-SHA256 computation', () {
    final sign = tuyaSign(
      clientId: 'client1',
      secret: 'secret1',
      timestamp: '1700000000000',
      method: 'POST',
      pathAndQuery: '/v1.0/devices/dev1/commands',
      body: '{"commands":[{"code":"power_go","value":true}]}',
      accessToken: 'tok1',
    );
    // Reference computed with Python's hmac module.
    expect(sign, 'DC72EE8D54A24B9AAFBECB709E9E02375441966658D46CC6AEABE74BDABB1E59');
  });

  test('fetches a token once, then reads and sends with it', () async {
    final calls = <http.Request>[];
    final client = MockClient((request) async {
      calls.add(request);
      if (request.url.path == '/v1.0/token') {
        return http.Response(jsonEncode({'success': true, 'result': {'access_token': 'tok', 'expire_time': 7200}}), 200);
      }
      if (request.method == 'GET') {
        return http.Response(
          jsonEncode({
            'success': true,
            'result': [
              {'code': 'power_go', 'value': true},
              {'code': 'pause', 'value': false},
              {'code': 'electricity_left', 'value': 87},
              {'code': 'suction', 'value': 'strong'},
              {'code': 'status', 'value': 'smart'},
            ],
          }),
          200,
        );
      }
      return http.Response(jsonEncode({'success': true, 'result': true}), 200);
    });
    final robot = TuyaCloudRobotService(accessId: 'id', accessSecret: 's', deviceId: 'dev1', client: client);

    final status = await robot.status();
    await robot.dock();

    expect(status.cleaning, isTrue);
    expect(status.charging, isFalse);
    expect(status.battery, 87);
    expect(status.suction, Suction.strong);
    expect(calls.where((c) => c.url.path == '/v1.0/token'), hasLength(1));
    expect(calls.last.url.toString(), 'https://openapi.tuyaeu.com/v1.0/devices/dev1/commands');
    expect(calls.last.headers['access_token'], 'tok');
    expect(jsonDecode(calls.last.body), {
      'commands': [
        {'code': 'switch_charge', 'value': true},
      ],
    });
  });

  test('turns a Tuya error body into a TuyaException', () async {
    final client = MockClient(
      (_) async => http.Response(jsonEncode({'success': false, 'code': 1004, 'msg': 'sign invalid'}), 200),
    );
    final robot = TuyaCloudRobotService(accessId: 'id', accessSecret: 's', deviceId: 'dev1', client: client);

    expect(robot.status(), throwsA(isA<TuyaException>()));
  });
}
