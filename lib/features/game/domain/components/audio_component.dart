import 'package:flame/components.dart';

/// Component for entity-based audio functionality
class AudioComponent extends Component {
  /// The audio asset ID to play
  String? soundId;
  
  /// Whether the audio should loop
  bool isLooping;
  
  /// Volume level (0.0 to 1.0)
  double volume;
  
  /// Spatial position for 2D audio positioning (null for non-spatial audio)
  Vector2? spatialPosition;
  
  /// Whether the audio is currently playing
  bool isPlaying;
  
  /// Whether this is a one-shot audio (plays once and removes itself)
  bool isOneShot;
  
  /// Audio category for mixing purposes
  AudioCategory category;
  
  /// Maximum distance for spatial audio falloff
  double maxDistance;
  
  /// Minimum distance for spatial audio (no falloff within this range)
  double minDistance;

  AudioComponent({
    this.soundId,
    this.isLooping = false,
    this.volume = 1.0,
    this.spatialPosition,
    this.isPlaying = false,
    this.isOneShot = false,
    this.category = AudioCategory.sfx,
    this.maxDistance = 500.0,
    this.minDistance = 50.0,
  });

  /// Play the audio with the specified sound ID
  void play(String audioId) {
    soundId = audioId;
    isPlaying = true;
  }

  /// Stop the audio
  void stop() {
    isPlaying = false;
    soundId = null;
  }

  /// Set the spatial position for 2D audio
  void setSpatialPosition(Vector2 position) {
    spatialPosition = position.clone();
  }

  /// Remove spatial positioning (makes audio non-spatial)
  void removeSpatialPosition() {
    spatialPosition = null;
  }

  /// Reset the component for reuse in object pool
  void reset() {
    soundId = null;
    isLooping = false;
    volume = 1.0;
    spatialPosition = null;
    isPlaying = false;
    isOneShot = false;
    category = AudioCategory.sfx;
    maxDistance = 500.0;
    minDistance = 50.0;
  }

  /// Calculate volume based on distance from listener
  double calculateSpatialVolume(Vector2 listenerPosition) {
    if (spatialPosition == null) return volume;
    
    final distance = spatialPosition!.distanceTo(listenerPosition);
    
    if (distance <= minDistance) {
      return volume;
    } else if (distance >= maxDistance) {
      return 0.0;
    } else {
      // Linear falloff between min and max distance
      final falloff = 1.0 - ((distance - minDistance) / (maxDistance - minDistance));
      return volume * falloff;
    }
  }
}

/// Audio categories for mixing and volume control
enum AudioCategory {
  sfx,
  music,
  voice,
  ambient,
}