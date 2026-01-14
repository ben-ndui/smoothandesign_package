import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Events pour ThemeBloc.
abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object?> get props => [];
}

/// Charge le thème sauvegardé.
class LoadThemeEvent extends ThemeEvent {
  const LoadThemeEvent();
}

/// Change le mode de thème.
class ChangeThemeEvent extends ThemeEvent {
  final ThemeMode themeMode;

  const ChangeThemeEvent({required this.themeMode});

  @override
  List<Object?> get props => [themeMode];
}
