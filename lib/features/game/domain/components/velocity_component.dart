import 'package:flame/components.dart';

/// Component that manages velocity, acceleration, and physics properties for entities
class VelocityComponent extends Component {
  Vector2 velocity;
  Vector2 acceleration;
  double maxSpeed;
  double friction;

  VelocityComponent({
    Vector2? velocity,
    Vector2? acceleration,
    this.maxSpeed = double.infinity,
    this.friction = 0.0,
  }) : velocity = velocity ?? Vector2.zero(),
       acceleration = acceleration ?? Vector2.zero();

  /// Applies acceleration to velocity with delta time
  void applyAcceleration(double deltaTime) {
    velocity.add(acceleration * deltaTime);
    
    // Apply friction
    if (friction > 0) {
      final frictionForce = velocity.normalized() * friction * deltaTime;
      if (frictionForce.length < velocity.length) {
        velocity.sub(frictionForce);
      } else {
        velocity.setZero();
      }
    }
    
    // Clamp to max speed
    if (velocity.length > maxSpeed) {
      velocity.normalize();
      velocity.scale(maxSpeed);
    }
  }

  /// Adds an impulse to the velocity
  void addImpulse(Vector2 impulse) {
    velocity.add(impulse);
  }

  /// Sets velocity directly
  void setVelocity(Vector2 newVelocity) {
    velocity.setFrom(newVelocity);
  }

  /// Stops all movement
  void stop() {
    velocity.setZero();
    acceleration.setZero();
  }

  /// Gets the current speed (magnitude of velocity)
  double get speed => velocity.length;
}