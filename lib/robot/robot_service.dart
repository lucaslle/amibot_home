enum Suction { gentle, normal, strong }

class RobotStatus {
  const RobotStatus({
    required this.cleaning,
    this.charging = false,
    this.battery,
    this.suction,
  });

  final bool cleaning;
  final bool charging;
  final int? battery;
  final Suction? suction;
}

/// The screens only talk to this, so the cloud backend can later be swapped
/// for the Tuya mobile SDK without touching the UI.
abstract class RobotService {
  Future<RobotStatus> status();
  Future<void> start();
  Future<void> pause();
  Future<void> dock();
  Future<void> setSuction(Suction suction);
}
