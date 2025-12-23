import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Utility for validating and testing level data
class LevelValidator {
  /// Validate level data structure and content
  static ValidationResult validateLevel(Map<String, dynamic> levelData) {
    final errors = <String>[];
    final warnings = <String>[];
    final suggestions = <String>[];

    // Structural validation
    errors.addAll(_validateStructure(levelData));
    
    // Content validation
    warnings.addAll(_validateContent(levelData));
    
    // Gameplay validation
    suggestions.addAll(_validateGameplay(levelData));
    
    // Performance validation
    warnings.addAll(_validatePerformance(levelData));

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      suggestions: suggestions,
    );
  }

  /// Validate basic level structure
  static List<String> _validateStructure(Map<String, dynamic> levelData) {
    final errors = <String>[];

    // Required top-level fields
    final requiredFields = {
      'id': int,
      'name': String,
      'size': Map,
      'playerSpawn': Map,
      'tiles': List,
    };

    for (final entry in requiredFields.entries) {
      final field = entry.key;
      final expectedType = entry.value;
      
      if (!levelData.containsKey(field)) {
        errors.add('Missing required field: $field');
        continue;
      }

      final value = levelData[field];
      if (expectedType == int && value is! int) {
        errors.add('Field $field must be an integer');
      } else if (expectedType == String && value is! String) {
        errors.add('Field $field must be a string');
      } else if (expectedType == Map && value is! Map) {
        errors.add('Field $field must be an object');
      } else if (expectedType == List && value is! List) {
        errors.add('Field $field must be an array');
      }
    }

    // Validate size object
    final size = levelData['size'];
    if (size is Map) {
      if (!size.containsKey('x') || !size.containsKey('y')) {
        errors.add('Size object must have x and y properties');
      }
      if (size['x'] is! num || size['y'] is! num) {
        errors.add('Size x and y must be numbers');
      }
    }

    // Validate player spawn
    final playerSpawn = levelData['playerSpawn'];
    if (playerSpawn is Map) {
      if (!playerSpawn.containsKey('x') || !playerSpawn.containsKey('y')) {
        errors.add('Player spawn must have x and y coordinates');
      }
      if (playerSpawn['x'] is! num || playerSpawn['y'] is! num) {
        errors.add('Player spawn x and y must be numbers');
      }
    }

    // Validate tiles array
    final tiles = levelData['tiles'];
    if (tiles is List) {
      for (int i = 0; i < tiles.length; i++) {
        final tile = tiles[i];
        if (tile is! Map) {
          errors.add('Tile $i must be an object');
          continue;
        }

        final tileErrors = _validateTile(tile as Map<String, dynamic>, i);
        errors.addAll(tileErrors);
      }
    }

    return errors;
  }

  /// Validate individual tile structure
  static List<String> _validateTile(Map<String, dynamic> tile, int index) {
    final errors = <String>[];

    // Required tile fields
    final requiredFields = ['position', 'type', 'durability', 'isDestructible'];
    for (final field in requiredFields) {
      if (!tile.containsKey(field)) {
        errors.add('Tile $index missing required field: $field');
      }
    }

    // Validate position
    final position = tile['position'];
    if (position is Map) {
      if (!position.containsKey('x') || !position.containsKey('y')) {
        errors.add('Tile $index position must have x and y coordinates');
      }
      if (position['x'] is! num || position['y'] is! num) {
        errors.add('Tile $index position x and y must be numbers');
      }
    } else if (position != null) {
      errors.add('Tile $index position must be an object');
    }

    // Validate tile type
    final validTypes = [
      'scaffolding', 'timber', 'timber_one_hit', 'bricks', 'bricks_one_hit',
      'bricks_two_hits', 'beam', 'girder', 'support', 'spikes', 'shutter'
    ];
    if (tile['type'] is String && !validTypes.contains(tile['type'])) {
      errors.add('Tile $index has invalid type: ${tile['type']}');
    }

    // Validate durability
    if (tile['durability'] is! int) {
      errors.add('Tile $index durability must be an integer');
    }

    // Validate isDestructible
    if (tile['isDestructible'] is! bool) {
      errors.add('Tile $index isDestructible must be a boolean');
    }

    return errors;
  }

  /// Validate level content and design
  static List<String> _validateContent(Map<String, dynamic> levelData) {
    final warnings = <String>[];

    // Check for empty level
    final tiles = levelData['tiles'] as List?;
    if (tiles == null || tiles.isEmpty) {
      warnings.add('Level has no tiles - players may fall through the world');
    }

    // Check player spawn safety
    final spawnWarnings = _validatePlayerSpawn(levelData);
    warnings.addAll(spawnWarnings);

    // Check for unreachable areas
    final reachabilityWarnings = _validateReachability(levelData);
    warnings.addAll(reachabilityWarnings);

    // Check tile distribution
    final distributionWarnings = _validateTileDistribution(levelData);
    warnings.addAll(distributionWarnings);

    return warnings;
  }

  /// Validate player spawn location
  static List<String> _validatePlayerSpawn(Map<String, dynamic> levelData) {
    final warnings = <String>[];
    
    final playerSpawn = levelData['playerSpawn'] as Map?;
    final tiles = levelData['tiles'] as List?;
    
    if (playerSpawn == null || tiles == null) return warnings;

    final spawnX = playerSpawn['x'] as num?;
    final spawnY = playerSpawn['y'] as num?;
    
    if (spawnX == null || spawnY == null) return warnings;

    // Check if spawn is inside a tile
    bool spawnInTile = false;
    for (final tile in tiles) {
      if (tile is! Map) continue;
      
      final position = tile['position'] as Map?;
      if (position == null) continue;
      
      final tileX = position['x'] as num?;
      final tileY = position['y'] as num?;
      
      if (tileX == null || tileY == null) continue;
      
      // Check if spawn point overlaps with tile (assuming 32x32 tiles)
      if ((spawnX - tileX).abs() < 32 && (spawnY - tileY).abs() < 32) {
        spawnInTile = true;
        break;
      }
    }

    if (spawnInTile) {
      warnings.add('Player spawn point is inside a tile - player may get stuck');
    }

    // Check if spawn has ground support
    bool hasGroundSupport = false;
    for (final tile in tiles) {
      if (tile is! Map) continue;
      
      final position = tile['position'] as Map?;
      if (position == null) continue;
      
      final tileX = position['x'] as num?;
      final tileY = position['y'] as num?;
      
      if (tileX == null || tileY == null) continue;
      
      // Check if there's a tile below spawn point
      if ((spawnX - tileX).abs() < 32 && (tileY - spawnY) > 0 && (tileY - spawnY) < 64) {
        hasGroundSupport = true;
        break;
      }
    }

    if (!hasGroundSupport) {
      warnings.add('Player spawn point has no ground support - player may fall');
    }

    return warnings;
  }

  /// Validate level reachability
  static List<String> _validateReachability(Map<String, dynamic> levelData) {
    final warnings = <String>[];
    
    final tiles = levelData['tiles'] as List?;
    final elements = levelData['elements'] as List?;
    
    if (tiles == null) return warnings;

    // Simple reachability check - ensure there are platforms or ground tiles
    bool hasGroundLevel = false;
    bool hasPlatforms = false;
    
    for (final tile in tiles) {
      if (tile is! Map) continue;
      
      final position = tile['position'] as Map?;
      if (position == null) continue;
      
      final tileY = position['y'] as num?;
      if (tileY == null) continue;
      
      // Check for ground level tiles (bottom 20% of level)
      final size = levelData['size'] as Map?;
      if (size != null) {
        final height = size['y'] as num?;
        if (height != null && tileY > height * 0.8) {
          hasGroundLevel = true;
        }
      }
      
      // Check for platform tiles (not at ground level)
      if (tileY < (size?['y'] as num? ?? 600) * 0.8) {
        hasPlatforms = true;
      }
    }

    if (!hasGroundLevel && !hasPlatforms) {
      warnings.add('Level has no ground or platforms - may be unplayable');
    }

    // Check for objectives reachability
    if (elements != null) {
      for (final element in elements) {
        if (element is! Map) continue;
        
        final type = element['type'] as String?;
        if (type == 'target' || type == 'elevator') {
          // Could add more sophisticated reachability analysis here
        }
      }
    }

    return warnings;
  }

  /// Validate tile distribution and balance
  static List<String> _validateTileDistribution(Map<String, dynamic> levelData) {
    final warnings = <String>[];
    
    final tiles = levelData['tiles'] as List?;
    if (tiles == null || tiles.isEmpty) return warnings;

    // Count tile types
    final typeCounts = <String, int>{};
    int destructibleCount = 0;
    int indestructibleCount = 0;

    for (final tile in tiles) {
      if (tile is! Map) continue;
      
      final type = tile['type'] as String?;
      final isDestructible = tile['isDestructible'] as bool?;
      
      if (type != null) {
        typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      }
      
      if (isDestructible == true) {
        destructibleCount++;
      } else {
        indestructibleCount++;
      }
    }

    // Check for tile variety
    if (typeCounts.length < 2) {
      warnings.add('Level uses only one tile type - consider adding variety');
    }

    // Check destructible/indestructible balance
    final totalTiles = tiles.length;
    final destructibleRatio = destructibleCount / totalTiles;
    
    if (destructibleRatio > 0.9) {
      warnings.add('Level has too many destructible tiles - may be too easy');
    } else if (destructibleRatio < 0.1) {
      warnings.add('Level has too few destructible tiles - may be too difficult');
    }

    // Check for specific tile type issues
    final scaffoldingCount = typeCounts['scaffolding'] ?? 0;
    if (scaffoldingCount > totalTiles * 0.5) {
      warnings.add('Level has too many scaffolding tiles - may be too easy');
    }

    return warnings;
  }

  /// Validate gameplay mechanics
  static List<String> _validateGameplay(Map<String, dynamic> levelData) {
    final suggestions = <String>[];

    final tiles = levelData['tiles'] as List?;
    final elements = levelData['elements'] as List?;
    final objectives = levelData['objectives'] as List?;

    // Suggest objectives if none exist
    if (objectives == null || objectives.isEmpty) {
      suggestions.add('Consider adding objectives to guide player progression');
    }

    // Suggest interactive elements
    if (elements == null || elements.isEmpty) {
      suggestions.add('Consider adding interactive elements (elevators, springs) for variety');
    }

    // Suggest difficulty progression
    final levelId = levelData['id'] as int?;
    if (levelId != null && levelId > 1) {
      // Could add difficulty comparison with previous levels
      suggestions.add('Ensure difficulty progression from previous levels');
    }

    // Suggest visual landmarks
    if (tiles != null && tiles.length > 50) {
      suggestions.add('Consider adding visual landmarks to help player navigation');
    }

    return suggestions;
  }

  /// Validate performance considerations
  static List<String> _validatePerformance(Map<String, dynamic> levelData) {
    final warnings = <String>[];

    final tiles = levelData['tiles'] as List?;
    final elements = levelData['elements'] as List?;

    // Check tile count
    if (tiles != null && tiles.length > 500) {
      warnings.add('Level has many tiles (${tiles.length}) - may impact performance');
    }

    // Check element count
    if (elements != null && elements.length > 20) {
      warnings.add('Level has many elements (${elements.length}) - may impact performance');
    }

    // Check level size
    final size = levelData['size'] as Map?;
    if (size != null) {
      final width = size['x'] as num?;
      final height = size['y'] as num?;
      
      if (width != null && height != null) {
        final area = width * height;
        if (area > 5000000) { // 5M square units
          warnings.add('Level is very large - may impact performance and memory usage');
        }
      }
    }

    return warnings;
  }

  /// Test level playability (basic simulation)
  static PlayabilityResult testPlayability(Map<String, dynamic> levelData) {
    final issues = <String>[];
    final playerSpawn = levelData['playerSpawn'] as Map?;
    final tiles = levelData['tiles'] as List?;

    if (playerSpawn == null || tiles == null) {
      return PlayabilityResult(
        isPlayable: false,
        issues: ['Invalid level data for playability testing'],
        completionPossible: false,
      );
    }

    // Simulate basic player movement and reachability
    final spawnX = playerSpawn['x'] as num? ?? 0;
    final spawnY = playerSpawn['y'] as num? ?? 0;

    // Check if player can move from spawn
    bool canMoveLeft = _canMoveInDirection(spawnX, spawnY, -1, 0, tiles);
    bool canMoveRight = _canMoveInDirection(spawnX, spawnY, 1, 0, tiles);
    bool canJump = _canJumpFromPosition(spawnX, spawnY, tiles);

    if (!canMoveLeft && !canMoveRight && !canJump) {
      issues.add('Player appears to be trapped at spawn point');
    }

    // Check for completion possibility
    bool completionPossible = _checkCompletionPossible(levelData);

    return PlayabilityResult(
      isPlayable: issues.isEmpty,
      issues: issues,
      completionPossible: completionPossible,
    );
  }

  /// Check if player can move in a direction
  static bool _canMoveInDirection(num x, num y, int dirX, int dirY, List tiles) {
    final newX = x + (dirX * 32);
    final newY = y + (dirY * 32);

    // Check for tile collision
    for (final tile in tiles) {
      if (tile is! Map) continue;
      
      final position = tile['position'] as Map?;
      if (position == null) continue;
      
      final tileX = position['x'] as num?;
      final tileY = position['y'] as num?;
      
      if (tileX == null || tileY == null) continue;
      
      if ((newX - tileX).abs() < 32 && (newY - tileY).abs() < 32) {
        return false; // Blocked by tile
      }
    }

    return true; // Can move
  }

  /// Check if player can jump from position
  static bool _canJumpFromPosition(num x, num y, List tiles) {
    // Simple check - can player jump up without hitting a tile
    return _canMoveInDirection(x, y, 0, -1, tiles);
  }

  /// Check if level completion is possible
  static bool _checkCompletionPossible(Map<String, dynamic> levelData) {
    final objectives = levelData['objectives'] as List?;
    final elements = levelData['elements'] as List?;

    // If no objectives, assume completion is reaching the end
    if (objectives == null || objectives.isEmpty) {
      return true; // Assume basic completion is possible
    }

    // Check specific objective types
    for (final objective in objectives) {
      if (objective is! Map) continue;
      
      final type = objective['type'] as String?;
      
      switch (type) {
        case 'reach_elevator':
          // Check if elevator exists
          if (elements != null) {
            bool hasElevator = elements.any((element) => 
              element is Map && element['type'] == 'elevator');
            if (!hasElevator) return false;
          }
          break;
        case 'destroy_targets':
          // Check if destructible tiles exist
          final tiles = levelData['tiles'] as List?;
          if (tiles != null) {
            bool hasDestructible = tiles.any((tile) =>
              tile is Map && tile['isDestructible'] == true);
            if (!hasDestructible) return false;
          }
          break;
      }
    }

    return true;
  }
}

/// Result of level validation
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final List<String> suggestions;

  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.suggestions,
  });

  /// Check if level has any issues
  bool get hasIssues => errors.isNotEmpty || warnings.isNotEmpty;

  /// Get total issue count
  int get totalIssues => errors.length + warnings.length;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Validation Result: ${isValid ? 'VALID' : 'INVALID'}');
    
    if (errors.isNotEmpty) {
      buffer.writeln('Errors (${errors.length}):');
      for (final error in errors) {
        buffer.writeln('  - $error');
      }
    }
    
    if (warnings.isNotEmpty) {
      buffer.writeln('Warnings (${warnings.length}):');
      for (final warning in warnings) {
        buffer.writeln('  - $warning');
      }
    }
    
    if (suggestions.isNotEmpty) {
      buffer.writeln('Suggestions (${suggestions.length}):');
      for (final suggestion in suggestions) {
        buffer.writeln('  - $suggestion');
      }
    }
    
    return buffer.toString();
  }
}

/// Result of playability testing
class PlayabilityResult {
  final bool isPlayable;
  final List<String> issues;
  final bool completionPossible;

  PlayabilityResult({
    required this.isPlayable,
    required this.issues,
    required this.completionPossible,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Playability: ${isPlayable ? 'PLAYABLE' : 'NOT PLAYABLE'}');
    buffer.writeln('Completion Possible: ${completionPossible ? 'YES' : 'NO'}');
    
    if (issues.isNotEmpty) {
      buffer.writeln('Issues (${issues.length}):');
      for (final issue in issues) {
        buffer.writeln('  - $issue');
      }
    }
    
    return buffer.toString();
  }
}