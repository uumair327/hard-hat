import 'package:hard_hat/features/game/domain/domain.dart';

/// Target entity that respawns after a delay when hit
class RespawningTargetEntity extends TargetEntity {
  /// How long before the target respawns
  final double respawnTime;

  double _timer = 0;
  bool _isRespawning = false;

  RespawningTargetEntity({
    required super.id,
    required super.position,
    super.onHit,
    this.respawnTime = 4.0,
  });

  @override
  void updateEntity(double dt) {
    if (_isRespawning) {
      _timer += dt;
      if (_timer >= respawnTime) {
        _respawn();
      }
    }
  }

  void handleCollision(GameCollisionComponent other) {
    if (other.type == GameCollisionType.ball && !isHit) {
      super.handleCollision(other);

      // Start respawn timer
      _isRespawning = true;
      _timer = 0.0;
    }
  }

  void _respawn() {
    _isRespawning = false;
    resetTarget();
  }
}
