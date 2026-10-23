import 'package:flutter/material.dart';

import 'robot/robot_service.dart';

const _suctionLabels = {
  Suction.gentle: 'Douce',
  Suction.normal: 'Normale',
  Suction.strong: 'Forte',
};

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key, required this.robot, required this.simulated});

  final RobotService robot;
  final bool simulated;

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  RobotStatus? _status;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() => _run(() async {});

  /// Runs a command then reloads the status, so the screen always shows the robot's real state.
  Future<void> _run(Future<void> Function() command) async {
    setState(() => _busy = true);
    try {
      await command();
      final status = await widget.robot.status();
      if (!mounted) return;
      setState(() {
        _status = status;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Amibot'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _busy ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.simulated)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.science_outlined),
                  title: Text('Mode simulé'),
                  subtitle: Text('Aucune clé Tuya fournie : le robot est imaginaire.'),
                ),
              ),
            if (_error != null)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: ListTile(
                  leading: const Icon(Icons.error_outline),
                  title: const Text('Impossible de joindre le robot'),
                  subtitle: Text(_error!),
                ),
              ),
            _StatusCard(status: status, busy: _busy),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _busy ? null : () => _run(widget.robot.start),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Démarrer le nettoyage'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _run(widget.robot.pause),
              icon: const Icon(Icons.pause),
              label: const Text('Mettre en pause'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _run(widget.robot.dock),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Retour à la base'),
            ),
            const SizedBox(height: 24),
            Text("Puissance d'aspiration", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<Suction>(
              segments: [
                for (final entry in _suctionLabels.entries)
                  ButtonSegment(value: entry.key, label: Text(entry.value)),
              ],
              selected: {if (status?.suction != null) status!.suction!},
              emptySelectionAllowed: true,
              onSelectionChanged: _busy
                  ? null
                  : (selection) => _run(() => widget.robot.setSuction(selection.first)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status, required this.busy});

  final RobotStatus? status;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final status = this.status;
    final label = status == null
        ? 'État inconnu'
        : status.cleaning
            ? 'En cours de nettoyage'
            : status.charging
                ? 'En charge'
                : "À l'arrêt";
    return Card(
      child: ListTile(
        leading: busy
            ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(status?.cleaning == true ? Icons.cleaning_services : Icons.smart_toy_outlined),
        title: Text(label),
        subtitle: Text(status?.battery == null ? 'Batterie : —' : 'Batterie : ${status!.battery} %'),
      ),
    );
  }
}
