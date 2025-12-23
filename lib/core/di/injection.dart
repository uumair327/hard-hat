import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'manual_injection.dart';

// Import will be generated later
// ignore: unused_import, depend_on_referenced_packages
// import 'injection.config.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async {
  // Use manual setup for now until injectable generates properly
  await setupManualDependencies();
  
  // TODO: Replace with generated code when available
  // getIt.init();
}

/// Initialize all dependencies
Future<void> initializeDependencies() async {
  await configureDependencies();
}