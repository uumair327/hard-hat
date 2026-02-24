import 'package:hard_hat/features/game/domain/entities/shutter.dart';

/// Shutter entity that retracts back to its original position after a cooldown
class RetractingShutterEntity extends ShutterEntity {
  /// Time it takes to return to start position
  final double retractDuration;

  /// Cooldown before it starts retracting
  final double cooldown;

  RetractingShutterEntity({
    required super.id,
    required super.position,
    super.targetId,
    super.offset,
    super.duration,
    this.retractDuration = 1.0,
    this.cooldown = 2.0,
  }) : super(retracting: true);

  /// Trigger the shutter to open, then schedule retraction
  @override
  void openShutter() {
    super.openShutter();
    // Scheduling logic goes here, or in an update/component logic
  }
}
