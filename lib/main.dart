import 'package:flutter/material.dart';

import 'control_screen.dart';
import 'robot/robot_service.dart';
import 'robot/simulated_robot_service.dart';
import 'robot/tuya_cloud_robot_service.dart';

// Passed at build time with --dart-define-from-file=tuya.json (never committed).
const _accessId = String.fromEnvironment('TUYA_ACCESS_ID');
const _accessSecret = String.fromEnvironment('TUYA_ACCESS_SECRET');
const _deviceId = String.fromEnvironment('TUYA_DEVICE_ID');
const _region = String.fromEnvironment('TUYA_REGION', defaultValue: 'eu');

void main() {
  final simulated = _accessId.isEmpty || _accessSecret.isEmpty || _deviceId.isEmpty;
  final RobotService robot = simulated
      ? SimulatedRobotService()
      : TuyaCloudRobotService(
          accessId: _accessId,
          accessSecret: _accessSecret,
          deviceId: _deviceId,
          region: _region,
        );
  runApp(AmibotApp(robot: robot, simulated: simulated));
}

class AmibotApp extends StatelessWidget {
  const AmibotApp({super.key, required this.robot, required this.simulated});

  final RobotService robot;
  final bool simulated;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amibot',
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      darkTheme: ThemeData(colorSchemeSeed: Colors.teal, brightness: Brightness.dark),
      home: ControlScreen(robot: robot, simulated: simulated),
    );
  }
}
