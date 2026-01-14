import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// État pour ThemeBloc.
class ThemeState extends Equatable {
  final ThemeMode themeMode;
  final bool isLoading;

  const ThemeState({
    this.themeMode = ThemeMode.system,
    this.isLoading = true,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    bool? isLoading,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [themeMode, isLoading];
}
