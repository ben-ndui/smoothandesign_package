import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/base_preferences_service.dart';
import 'theme_event.dart';
import 'theme_state.dart';

/// BLoC pour la gestion du thème.
///
/// Gère le mode de thème (light/dark/system) avec persistence.
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final BasePreferencesService _preferencesService;
  final String? _userId;

  ThemeBloc({
    required BasePreferencesService preferencesService,
    String? userId,
  })  : _preferencesService = preferencesService,
        _userId = userId,
        super(const ThemeState()) {
    on<LoadThemeEvent>(_onLoadTheme);
    on<ChangeThemeEvent>(_onChangeTheme);
  }

  Future<void> _onLoadTheme(
    LoadThemeEvent event,
    Emitter<ThemeState> emit,
  ) async {
    await _preferencesService.loadPreferences();

    emit(state.copyWith(
      themeMode: _preferencesService.themeMode,
      isLoading: false,
    ));
  }

  Future<void> _onChangeTheme(
    ChangeThemeEvent event,
    Emitter<ThemeState> emit,
  ) async {
    await _preferencesService.setThemeMode(
      event.themeMode,
      userId: _userId,
    );

    emit(state.copyWith(themeMode: event.themeMode));
  }

  /// Bascule entre light et dark.
  void toggleTheme() {
    final newMode = state.themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;

    add(ChangeThemeEvent(themeMode: newMode));
  }

  /// Définit le mode système.
  void useSystemTheme() {
    add(const ChangeThemeEvent(themeMode: ThemeMode.system));
  }
}
