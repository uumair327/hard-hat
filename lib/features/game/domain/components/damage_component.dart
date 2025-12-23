import 'package:flame/components.dart';

/// Component that manages damage state and calculations for entities
class DamageComponent extends Component {
  /// Current damage value
  int currentDamage;
  
  /// Maximum damage this entity can take
  final int maxDamage;
  
  /// Whether this entity can take damage
  bool canTakeDamage;
  
  /// Damage immunity duration after taking damage
  final double immunityDuration;
  
  /// Current immunity timer
  double _immunityTimer = 0.0;
  
  /// Damage multiplier for different damage types
  final Map<DamageType, double> damageMultipliers;
  
  /// Callbacks for damage events
  void Function(int damage, DamageType type)? onDamageReceived;
  void Function()? onDestroyed;
  
  DamageComponent({
    this.currentDamage = 0,
    required this.maxDamage,
    this.canTakeDamage = true,
    this.immunityDuration = 0.0,
    Map<DamageType, double>? damageMultipliers,
    this.onDamageReceived,
    this.onDestroyed,
  }) : damageMultipliers = damageMultipliers ?? {};
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Update immunity timer
    if (_immunityTimer > 0) {
      _immunityTimer -= dt;
    }
  }
  
  /// Apply damage to this component
  bool takeDamage(int damage, {DamageType type = DamageType.physical}) {
    if (!canTakeDamage || _immunityTimer > 0) {
      return false;
    }
    
    // Apply damage multiplier
    final multiplier = damageMultipliers[type] ?? 1.0;
    final actualDamage = (damage * multiplier).round();
    
    currentDamage += actualDamage;
    
    // Start immunity period
    if (immunityDuration > 0) {
      _immunityTimer = immunityDuration;
    }
    
    // Trigger callback
    onDamageReceived?.call(actualDamage, type);
    
    // Check if destroyed
    if (currentDamage >= maxDamage) {
      onDestroyed?.call();
      return true; // Entity should be destroyed
    }
    
    return false;
  }
  
  /// Heal damage
  void heal(int amount) {
    currentDamage = (currentDamage - amount).clamp(0, maxDamage);
  }
  
  /// Get current health percentage (0.0 to 1.0)
  double get healthPercentage {
    if (maxDamage <= 0) return 1.0;
    return (maxDamage - currentDamage) / maxDamage;
  }
  
  /// Check if entity is destroyed
  bool get isDestroyed => currentDamage >= maxDamage;
  
  /// Check if entity is currently immune to damage
  bool get isImmune => _immunityTimer > 0;
  
  /// Get remaining immunity time
  double get remainingImmunityTime => _immunityTimer;
  
  /// Reset damage to zero
  void resetDamage() {
    currentDamage = 0;
    _immunityTimer = 0.0;
  }
  
  /// Set damage multiplier for a specific damage type
  void setDamageMultiplier(DamageType type, double multiplier) {
    damageMultipliers[type] = multiplier;
  }
  
  /// Remove damage multiplier for a specific damage type
  void removeDamageMultiplier(DamageType type) {
    damageMultipliers.remove(type);
  }
}

/// Types of damage that can be applied
enum DamageType {
  physical,
  impact,
  explosion,
  environmental,
  special,
}