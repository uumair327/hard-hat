import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure([List properties = const <dynamic>[]]);
  
  @override
  List<Object> get props => [];
}

// General failures
class ServerFailure extends Failure {}

class CacheFailure extends Failure {}

class NetworkFailure extends Failure {}

// Game-specific failures
class LevelLoadFailure extends Failure {
  final String message;
  
  const LevelLoadFailure(this.message);
  
  @override
  List<Object> get props => [message];
}

class SaveFailure extends Failure {
  final String message;
  
  const SaveFailure(this.message);
  
  @override
  List<Object> get props => [message];
}

class SaveCorruptionFailure extends SaveFailure {
  final String filePath;
  
  const SaveCorruptionFailure(this.filePath) : super('Save file corrupted: $filePath');
  
  @override
  List<Object> get props => [filePath];
}

class SaveIntegrityFailure extends SaveFailure {
  const SaveIntegrityFailure(String message) : super('Save integrity error: $message');
}

class AssetLoadFailure extends Failure {
  final String assetPath;
  
  const AssetLoadFailure(this.assetPath);
  
  @override
  List<Object> get props => [assetPath];
}