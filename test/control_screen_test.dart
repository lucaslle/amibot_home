import 'package:amibot_home/control_screen.dart';
import 'package:amibot_home/robot/simulated_robot_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('starting the robot updates the displayed state', (tester) async {
    await tester.pumpWidget(MaterialApp(home: ControlScreen(robot: SimulatedRobotService(), simulated: true)));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('En charge'), findsOneWidget);

    await tester.tap(find.text('Démarrer le nettoyage'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('En cours de nettoyage'), findsOneWidget);
  });
}
