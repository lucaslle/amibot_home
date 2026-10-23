import 'robot_service.dart';

/// In-memory robot used when no Tuya keys are provided, to work on the UI.
class SimulatedRobotService implements RobotService {
  var _status = const RobotStatus(cleaning: false, charging: true, battery: 100, suction: Suction.normal);

  Future<void> _latency() => Future.delayed(const Duration(milliseconds: 300));

  @override
  Future<RobotStatus> status() async {
    await _latency();
    return _status;
  }

  @override
  Future<void> start() async {
    await _latency();
    _status = RobotStatus(cleaning: true, battery: _status.battery, suction: _status.suction);
  }

  @override
  Future<void> pause() async {
    await _latency();
    _status = RobotStatus(cleaning: false, battery: _status.battery, suction: _status.suction);
  }

  @override
  Future<void> dock() async {
    await _latency();
    _status = RobotStatus(cleaning: false, charging: true, battery: _status.battery, suction: _status.suction);
  }

  @override
  Future<void> setSuction(Suction suction) async {
    await _latency();
    _status = RobotStatus(
      cleaning: _status.cleaning,
      charging: _status.charging,
      battery: _status.battery,
      suction: suction,
    );
  }
}
