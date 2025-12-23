import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    context.read<SettingsBloc>().add(LoadSettingsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/menu'),
        ),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (state.status == SettingsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == SettingsStatus.error) {
            return Center(
              child: Text('Error: ${state.errorMessage}'),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Audio Settings',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  
                  // SFX Volume
                  Text('Sound Effects Volume: ${(state.settings.sfxVolume * 100).round()}%'),
                  Slider(
                    value: state.settings.sfxVolume,
                    onChanged: (value) {
                      context.read<SettingsBloc>().add(UpdateSfxVolumeEvent(value));
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Music Volume
                  Text('Music Volume: ${(state.settings.musicVolume * 100).round()}%'),
                  Slider(
                    value: state.settings.musicVolume,
                    onChanged: (value) {
                      context.read<SettingsBloc>().add(UpdateMusicVolumeEvent(value));
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Mute Toggle
                  SwitchListTile(
                    title: const Text('Mute All Audio'),
                    value: state.settings.isMuted,
                    onChanged: (_) {
                      context.read<SettingsBloc>().add(ToggleMuteEvent());
                    },
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Back Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.go('/menu'),
                      child: const Text('Back to Menu'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}