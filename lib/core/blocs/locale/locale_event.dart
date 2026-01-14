import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Base class for locale events.
abstract class LocaleEvent extends Equatable {
  const LocaleEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load saved locale preference.
class LoadLocaleEvent extends LocaleEvent {
  const LoadLocaleEvent();
}

/// Event to change the app locale.
class ChangeLocaleEvent extends LocaleEvent {
  /// The new locale. Null means system default.
  final Locale? locale;

  const ChangeLocaleEvent({this.locale});

  @override
  List<Object?> get props => [locale];
}
