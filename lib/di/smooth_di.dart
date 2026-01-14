import 'package:get_it/get_it.dart';
import '../core/services/services_exports.dart';

/// Global GetIt instance.
final getIt = GetIt.instance;

/// Dependency Injection setup for Smoothandesign.
///
/// Call [SmoothDI.setup] after Firebase initialization.
///
/// ```dart
/// void main() async {
///   await SmoothFirebase.initialize(options: options);
///   SmoothDI.setup();
///   runApp(MyApp());
/// }
/// ```
class SmoothDI {
  SmoothDI._();

  static bool _initialized = false;

  /// Registers all base services as singletons.
  static void setup({
    BaseAuthService? authService,
    BaseStorageService? storageService,
    BaseNotificationService? notificationService,
    BasePreferencesService? preferencesService,
  }) {
    if (_initialized) return;

    // Auth service
    getIt.registerLazySingleton<BaseAuthService>(
      () => authService ?? BaseAuthService(),
    );

    // Storage service
    getIt.registerLazySingleton<BaseStorageService>(
      () => storageService ?? BaseStorageService(),
    );

    // Notification service
    getIt.registerLazySingleton<BaseNotificationService>(
      () => notificationService ?? BaseNotificationService.instance,
    );

    // Preferences service
    getIt.registerLazySingleton<BasePreferencesService>(
      () => preferencesService ?? BasePreferencesService(),
    );

    _initialized = true;
  }

  /// Registers a custom service.
  static void register<T extends Object>(
    T instance, {
    String? instanceName,
  }) {
    if (getIt.isRegistered<T>(instanceName: instanceName)) {
      getIt.unregister<T>(instanceName: instanceName);
    }
    getIt.registerSingleton<T>(instance, instanceName: instanceName);
  }

  /// Registers a lazy singleton.
  static void registerLazy<T extends Object>(
    T Function() factory, {
    String? instanceName,
  }) {
    if (getIt.isRegistered<T>(instanceName: instanceName)) {
      getIt.unregister<T>(instanceName: instanceName);
    }
    getIt.registerLazySingleton<T>(factory, instanceName: instanceName);
  }

  /// Registers a factory (new instance each time).
  static void registerFactory<T extends Object>(
    T Function() factory, {
    String? instanceName,
  }) {
    if (getIt.isRegistered<T>(instanceName: instanceName)) {
      getIt.unregister<T>(instanceName: instanceName);
    }
    getIt.registerFactory<T>(factory, instanceName: instanceName);
  }

  /// Gets a registered service.
  static T get<T extends Object>({String? instanceName}) {
    return getIt.get<T>(instanceName: instanceName);
  }

  /// Checks if a service is registered.
  static bool isRegistered<T extends Object>({String? instanceName}) {
    return getIt.isRegistered<T>(instanceName: instanceName);
  }

  /// Resets all registrations (useful for testing).
  static Future<void> reset() async {
    await getIt.reset();
    _initialized = false;
  }
}
