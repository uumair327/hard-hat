import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Component that manages sprite rendering with layers and effects
class GameSpriteComponent extends SpriteComponent {
  int renderLayer;
  Paint? customPaint;
  
  GameSpriteComponent({
    super.sprite,
    super.position,
    super.size,
    super.anchor,
    this.renderLayer = 0,
    this.customPaint,
  });

  /// Updates the sprite with a new sprite object
  void updateSprite(Sprite newSprite) {
    sprite = newSprite;
  }

  /// Sets a custom paint for special rendering effects
  void setCustomPaint(Paint paint) {
    customPaint = paint;
  }

  /// Removes custom paint to use default rendering
  void clearCustomPaint() {
    customPaint = null;
  }

  @override
  void render(Canvas canvas) {
    if (customPaint != null) {
      final originalPaint = paint;
      paint = customPaint!;
      super.render(canvas);
      paint = originalPaint;
    } else {
      super.render(canvas);
    }
  }

  /// Sets the opacity of the sprite
  @override
  void setOpacity(double opacity, {Object? paintId}) {
    paint = Paint()..color = Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0));
  }

  /// Flips the sprite horizontally
  @override
  void flipHorizontally() {
    scale.x *= -1;
  }

  /// Flips the sprite vertically
  @override
  void flipVertically() {
    scale.y *= -1;
  }
}