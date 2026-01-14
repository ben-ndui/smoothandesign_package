import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'locale_event.dart';
import 'locale_state.dart';

/// BLoC générique pour la gestion de la locale.
///
/// Usage:
/// ```dart
/// // Dans main.dart
/// BlocProvider(
///   create: (_) => LocaleBloc()..add(const LoadLocaleEvent()),
///   child: BlocBuilder<LocaleBloc, LocaleState>(
///     builder: (context, state) => MaterialApp(
///       locale: state.locale,
///       supportedLocales: [Locale('en'), Locale('fr')],
///       // ...
///     ),
///   ),
/// )
///
/// // Changer la langue
/// context.read<LocaleBloc>().add(ChangeLocaleEvent(locale: Locale('fr')));
///
/// // Revenir au système
/// context.read<LocaleBloc>().add(ChangeLocaleEvent(locale: null));
/// ```
class LocaleBloc extends Bloc<LocaleEvent, LocaleState> {
  /// Clé de stockage SharedPreferences.
  final String storageKey;

  LocaleBloc({this.storageKey = 'app_locale'}) : super(const LocaleState()) {
    on<LoadLocaleEvent>(_onLoadLocale);
    on<ChangeLocaleEvent>(_onChangeLocale);
  }

  Future<void> _onLoadLocale(
    LoadLocaleEvent event,
    Emitter<LocaleState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString(storageKey);

    if (localeCode != null && localeCode.isNotEmpty) {
      emit(LocaleState(locale: Locale(localeCode)));
    } else {
      emit(const LocaleState(locale: null)); // System default
    }
  }

  Future<void> _onChangeLocale(
    ChangeLocaleEvent event,
    Emitter<LocaleState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    if (event.locale != null) {
      await prefs.setString(storageKey, event.locale!.languageCode);
      emit(LocaleState(locale: event.locale));
    } else {
      await prefs.remove(storageKey);
      emit(const LocaleState(locale: null)); // System default
    }
  }
}
