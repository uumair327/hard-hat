import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

// Import the generated injectable configuration
import 'injection.config.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async {
  // Use the generated injectable configuration
  getIt.init();
}

/// Initialize all dependencies
Future<void> initializeDependencies() async {
  await configureDependencies();
}