import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// State for locale management.
class LocaleState extends Equatable {
  /// The current locale. Null means follow system.
  final Locale? locale;

  /// Whether the locale follows system settings.
  bool get isSystem => locale == null;

  const LocaleState({this.locale});

  LocaleState copyWith({Locale? locale, bool clearLocale = false}) {
    return LocaleState(
      locale: clearLocale ? null : (locale ?? this.locale),
    );
  }

  @override
  List<Object?> get props => [locale];
}
