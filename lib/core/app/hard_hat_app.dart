import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../navigation/app_router.dart';
import '../../features/game/presentation/bloc/game_bloc.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';

class HardHatApp extends StatelessWidget {
  const HardHatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Only register SettingsBloc for now
        BlocProvider<SettingsBloc>(
          create: (context) => GetIt.instance<SettingsBloc>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Hard Hat Havoc',
        debugShowCheckedModeBanner: false,
        // Disable widget inspector on web to avoid diagnostics issues
        builder: kIsWeb ? (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              // Disable text scaling for consistent game UI
              textScaler: const TextScaler.linear(1.0),
            ),
            child: child!,
          );
        } : null,
        routerConfig: AppRouter.router,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.orange,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
      ),
    );
  }
}