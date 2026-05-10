import 'package:flame/components.dart';
import 'package:flame/flame.dart';

/// Billboard component — replicates Godot tutorial billboards
/// Consists of a wood frame (small/large) and a tutorial image (move, jump, etc.)
class BillboardComponent extends PositionComponent {
  final String type; // 'move', 'jump', 'strike', 'aim', 'pogo'
  final bool large;

  BillboardComponent({
    required this.type,
    required Vector2 position,
    this.large = false,
  }) : super(position: position);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Background frame
    final frameImg = large ? 'billboard_large.png' : 'billboard_small.png';
    final frameSprite = await Flame.images.load('sprites/game/billboard/$frameImg');
    
    // Size logic: small is roughly 160x120, large is 240x240, Godot scale is 0.5.
    // Let's use image size directly and scale it down to match Godot (0.5).
    // The Godot tiles are 40x40. 0.5 scale means actual size * 0.5 * pixel-to-meter factor.
    // But we can just draw them at actual resolution.
    
    final frame = SpriteComponent(
      sprite: Sprite(frameSprite),
      anchor: Anchor.bottomCenter,
    );
    add(frame);
    
    // Tutorial image
    try {
      final tutSprite = await Flame.images.load('sprites/game/billboard/$type.png');
      final tut = SpriteComponent(
        sprite: Sprite(tutSprite),
        anchor: Anchor.bottomCenter,
        position: large ? Vector2(0, -60) : Vector2(0, -10),
      );
      add(tut);
    } catch (_) {}
  }
}
