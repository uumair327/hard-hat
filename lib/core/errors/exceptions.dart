class ServerException implements Exception {}

class CacheException implements Exception {}

class NetworkException implements Exception {}

class LevelLoadException implements Exception {
  final String message;
  LevelLoadException(this.message);
}

class SaveException implements Exception {
  final String message;
  SaveException(this.message);
}

class SaveCorruptionException extends SaveException {
  final String filePath;
  SaveCorruptionException(this.filePath) : super('Save file corrupted: $filePath');
}

class SaveIntegrityException extends SaveException {
  SaveIntegrityException(String message) : super('Save integrity error: $message');
}

class AssetLoadException implements Exception {
  final String assetPath;
  AssetLoadException(this.assetPath);
}