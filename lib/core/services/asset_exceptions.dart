/// Base exception for asset-related errors
abstract class AssetException implements Exception {
  const AssetException(this.message, this.assetId);
  
  final String message;
  final String assetId;
  
  @override
  String toString() => 'AssetException: $message (Asset: $assetId)';
}

/// Exception thrown when an asset is not found
class AssetNotFoundException extends AssetException {
  const AssetNotFoundException(String assetId) 
      : super('Asset not found', assetId);
}

/// Exception thrown when an asset is corrupted or invalid
class AssetCorruptedException extends AssetException {
  const AssetCorruptedException(String assetId, [String? details]) 
      : super('Asset corrupted${details != null ? ': $details' : ''}', assetId);
}

/// Exception thrown when asset loading fails
class AssetLoadingException extends AssetException {
  const AssetLoadingException(String assetId, [String? details]) 
      : super('Failed to load asset${details != null ? ': $details' : ''}', assetId);
}

/// Exception thrown when sprite atlas operations fail
class SpriteAtlasException extends AssetException {
  const SpriteAtlasException(String assetId, [String? details]) 
      : super('Sprite atlas error${details != null ? ': $details' : ''}', assetId);
}