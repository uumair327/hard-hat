import 'package:flutter/services.dart';

/// Input actions that can be remapped
enum InputAction {
  moveLeft,
  moveRight,
  jump,
  shoot,
  pause,
  aim,
  menu,
  confirm,
  cancel,
}

/// Input remapper for customizable key bindings
class InputRemapper {
  // Default key mappings
  static final Map<InputAction, List<LogicalKeyboardKey>> _defaultMapping = {
    InputAction.moveLeft: [LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyA],
    InputAction.moveRight: [LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.keyD],
    InputAction.jump: [LogicalKeyboardKey.space, LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.keyW],
    InputAction.shoot: [LogicalKeyboardKey.keyX, LogicalKeyboardKey.keyZ, LogicalKeyboardKey.enter],
    InputAction.pause: [LogicalKeyboardKey.escape, LogicalKeyboardKey.keyP],
    InputAction.aim: [LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.controlRight],
    InputAction.menu: [LogicalKeyboardKey.escape, LogicalKeyboardKey.tab],
    InputAction.confirm: [LogicalKeyboardKey.enter, LogicalKeyboardKey.space],
    InputAction.cancel: [LogicalKeyboardKey.escape, LogicalKeyboardKey.backspace],
  };
  
  // Current key mappings
  Map<InputAction, List<LogicalKeyboardKey>> _currentMapping = {};
  
  // Reverse mapping for quick lookup
  Map<LogicalKeyboardKey, Set<InputAction>> _reverseMapping = {};
  
  /// Initialize the input remapper
  Future<void> initialize() async {
    // Load default mapping
    _currentMapping = Map.from(_defaultMapping);
    _buildReverseMapping();
  }
  
  /// Build reverse mapping for efficient key-to-action lookup
  void _buildReverseMapping() {
    _reverseMapping.clear();
    
    for (final entry in _currentMapping.entries) {
      final action = entry.key;
      final keys = entry.value;
      
      for (final key in keys) {
        _reverseMapping.putIfAbsent(key, () => {}).add(action);
      }
    }
  }
  
  /// Get keys mapped to a specific action
  List<LogicalKeyboardKey> getKeysForAction(InputAction action) {
    return _currentMapping[action] ?? [];
  }
  
  /// Get actions mapped to a specific key
  Set<InputAction> getActionsForKey(LogicalKeyboardKey key) {
    return _reverseMapping[key] ?? {};
  }
  
  /// Set custom mapping for an action
  void setActionMapping(InputAction action, List<LogicalKeyboardKey> keys) {
    // Validate that keys aren't already mapped to conflicting actions
    final conflicts = _findConflicts(action, keys);
    if (conflicts.isNotEmpty) {
      throw ArgumentError('Keys $keys conflict with existing mappings: $conflicts');
    }
    
    _currentMapping[action] = List.from(keys);
    _buildReverseMapping();
  }
  
  /// Set custom mapping for multiple actions
  void setCustomMapping(Map<InputAction, List<LogicalKeyboardKey>> mapping) {
    // Validate entire mapping for conflicts
    final allConflicts = <String>[];
    
    for (final entry in mapping.entries) {
      final conflicts = _findConflicts(entry.key, entry.value, excludeAction: entry.key);
      if (conflicts.isNotEmpty) {
        allConflicts.add('${entry.key}: $conflicts');
      }
    }
    
    if (allConflicts.isNotEmpty) {
      throw ArgumentError('Mapping conflicts found: ${allConflicts.join(', ')}');
    }
    
    _currentMapping = Map.from(mapping);
    _buildReverseMapping();
  }
  
  /// Find conflicts for a given action and keys
  List<String> _findConflicts(InputAction action, List<LogicalKeyboardKey> keys, {InputAction? excludeAction}) {
    final conflicts = <String>[];
    
    for (final key in keys) {
      final existingActions = _reverseMapping[key] ?? {};
      
      for (final existingAction in existingActions) {
        if (existingAction != action && existingAction != excludeAction) {
          // Check if this is a problematic conflict
          if (_isConflictingAction(action, existingAction)) {
            conflicts.add('$key -> $existingAction');
          }
        }
      }
    }
    
    return conflicts;
  }
  
  /// Check if two actions conflict with each other
  bool _isConflictingAction(InputAction action1, InputAction action2) {
    // Define which actions can share keys
    const compatibleActions = {
      {InputAction.confirm, InputAction.jump},
      {InputAction.cancel, InputAction.pause},
      {InputAction.menu, InputAction.pause},
    };
    
    for (final compatibleSet in compatibleActions) {
      if (compatibleSet.contains(action1) && compatibleSet.contains(action2)) {
        return false;
      }
    }
    
    return true;
  }
  
  /// Reset to default mapping
  void resetToDefault() {
    _currentMapping = Map.from(_defaultMapping);
    _buildReverseMapping();
  }
  
  /// Reset a specific action to default
  void resetActionToDefault(InputAction action) {
    final defaultKeys = _defaultMapping[action];
    if (defaultKeys != null) {
      _currentMapping[action] = List.from(defaultKeys);
      _buildReverseMapping();
    }
  }
  
  /// Get current mapping
  Map<InputAction, List<LogicalKeyboardKey>> getCurrentMapping() {
    return Map.from(_currentMapping);
  }
  
  /// Load mapping from configuration
  void loadMapping(Map<String, dynamic> config) {
    final mapping = <InputAction, List<LogicalKeyboardKey>>{};
    
    for (final entry in config.entries) {
      try {
        final action = InputAction.values.firstWhere(
          (a) => a.toString() == entry.key,
        );
        
        final keyNames = List<String>.from(entry.value);
        final keys = keyNames.map((name) => _parseKeyName(name)).where((key) => key != null).cast<LogicalKeyboardKey>().toList();
        
        if (keys.isNotEmpty) {
          mapping[action] = keys;
        }
      } catch (e) {
        // Skip invalid entries
        continue;
      }
    }
    
    if (mapping.isNotEmpty) {
      try {
        setCustomMapping(mapping);
      } catch (e) {
        // If there are conflicts, fall back to default
        resetToDefault();
      }
    }
  }
  
  /// Parse key name to LogicalKeyboardKey
  LogicalKeyboardKey? _parseKeyName(String keyName) {
    // This is a simplified implementation
    // In a real implementation, you'd have a comprehensive mapping
    switch (keyName.toLowerCase()) {
      case 'space':
        return LogicalKeyboardKey.space;
      case 'enter':
        return LogicalKeyboardKey.enter;
      case 'escape':
        return LogicalKeyboardKey.escape;
      case 'arrowleft':
        return LogicalKeyboardKey.arrowLeft;
      case 'arrowright':
        return LogicalKeyboardKey.arrowRight;
      case 'arrowup':
        return LogicalKeyboardKey.arrowUp;
      case 'arrowdown':
        return LogicalKeyboardKey.arrowDown;
      case 'a':
        return LogicalKeyboardKey.keyA;
      case 'd':
        return LogicalKeyboardKey.keyD;
      case 'w':
        return LogicalKeyboardKey.keyW;
      case 's':
        return LogicalKeyboardKey.keyS;
      case 'x':
        return LogicalKeyboardKey.keyX;
      case 'z':
        return LogicalKeyboardKey.keyZ;
      case 'p':
        return LogicalKeyboardKey.keyP;
      case 'tab':
        return LogicalKeyboardKey.tab;
      case 'backspace':
        return LogicalKeyboardKey.backspace;
      case 'controlleft':
        return LogicalKeyboardKey.controlLeft;
      case 'controlright':
        return LogicalKeyboardKey.controlRight;
      default:
        return null;
    }
  }
  
  /// Convert LogicalKeyboardKey to string name
  String _keyToString(LogicalKeyboardKey key) {
    // This is a simplified implementation
    if (key == LogicalKeyboardKey.space) return 'space';
    if (key == LogicalKeyboardKey.enter) return 'enter';
    if (key == LogicalKeyboardKey.escape) return 'escape';
    if (key == LogicalKeyboardKey.arrowLeft) return 'arrowleft';
    if (key == LogicalKeyboardKey.arrowRight) return 'arrowright';
    if (key == LogicalKeyboardKey.arrowUp) return 'arrowup';
    if (key == LogicalKeyboardKey.arrowDown) return 'arrowdown';
    if (key == LogicalKeyboardKey.keyA) return 'a';
    if (key == LogicalKeyboardKey.keyD) return 'd';
    if (key == LogicalKeyboardKey.keyW) return 'w';
    if (key == LogicalKeyboardKey.keyS) return 's';
    if (key == LogicalKeyboardKey.keyX) return 'x';
    if (key == LogicalKeyboardKey.keyZ) return 'z';
    if (key == LogicalKeyboardKey.keyP) return 'p';
    if (key == LogicalKeyboardKey.tab) return 'tab';
    if (key == LogicalKeyboardKey.backspace) return 'backspace';
    if (key == LogicalKeyboardKey.controlLeft) return 'controlleft';
    if (key == LogicalKeyboardKey.controlRight) return 'controlright';
    
    return key.toString();
  }
  
  /// Export current mapping to configuration format
  Map<String, dynamic> exportMapping() {
    final config = <String, dynamic>{};
    
    for (final entry in _currentMapping.entries) {
      final actionName = entry.key.toString();
      final keyNames = entry.value.map((key) => _keyToString(key)).toList();
      config[actionName] = keyNames;
    }
    
    return config;
  }
  
  /// Check if a key is mapped to any action
  bool isKeyMapped(LogicalKeyboardKey key) {
    return _reverseMapping.containsKey(key);
  }
  
  /// Get all mapped keys
  Set<LogicalKeyboardKey> getAllMappedKeys() {
    return _reverseMapping.keys.toSet();
  }
  
  /// Dispose of the remapper
  void dispose() {
    _currentMapping.clear();
    _reverseMapping.clear();
  }
}