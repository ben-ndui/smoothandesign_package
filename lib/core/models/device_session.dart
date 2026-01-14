import 'package:equatable/equatable.dart';
import 'base_model.dart';

/// Type d'appareil.
enum DeviceType {
  ios,
  android,
  web,
  unknown;

  static DeviceType fromString(String? value) {
    return DeviceType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DeviceType.unknown,
    );
  }
}

/// Session d'appareil connecté.
///
/// Représente une connexion utilisateur sur un appareil spécifique.
class DeviceSession extends Equatable implements BaseModel {
  @override
  final String id;
  final String userId;
  final String deviceId;
  final String deviceName;
  final String? deviceModel;
  final DeviceType deviceType;
  final String? osVersion;
  final String? appVersion;
  final String? fcmToken;
  final String? ipAddress;
  final String? city;
  final String? country;
  final DateTime loginAt;
  final DateTime lastActiveAt;
  final bool isActive;

  const DeviceSession({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.deviceName,
    this.deviceModel,
    required this.deviceType,
    this.osVersion,
    this.appVersion,
    this.fcmToken,
    this.ipAddress,
    this.city,
    this.country,
    required this.loginAt,
    required this.lastActiveAt,
    this.isActive = true,
  });

  /// Durée depuis la dernière activité.
  Duration get inactiveDuration => DateTime.now().difference(lastActiveAt);

  /// Affichage de la localisation.
  String? get locationDisplay {
    if (city != null && country != null) return '$city, $country';
    if (city != null) return city;
    if (country != null) return country;
    return null;
  }

  /// Informations détaillées de l'appareil.
  String get deviceDetails {
    final parts = <String>[];
    if (deviceModel != null) parts.add(deviceModel!);
    if (osVersion != null) parts.add(osVersion!);
    return parts.join(' • ');
  }

  /// Icône selon le type d'appareil.
  String get deviceIcon {
    switch (deviceType) {
      case DeviceType.ios:
        return '📱';
      case DeviceType.android:
        return '📱';
      case DeviceType.web:
        return '🌐';
      case DeviceType.unknown:
        return '💻';
    }
  }

  factory DeviceSession.fromMap(Map<String, dynamic> map, String id) {
    return DeviceSession(
      id: id,
      userId: map['userId'] ?? '',
      deviceId: map['deviceId'] ?? '',
      deviceName: map['deviceName'] ?? 'Unknown Device',
      deviceModel: map['deviceModel'],
      deviceType: DeviceType.fromString(map['deviceType']),
      osVersion: map['osVersion'],
      appVersion: map['appVersion'],
      fcmToken: map['fcmToken'],
      ipAddress: map['ipAddress'],
      city: map['city'],
      country: map['country'],
      loginAt: FirestoreModel.dateTimeFromFirestore(map['loginAt']) ?? DateTime.now(),
      lastActiveAt: FirestoreModel.dateTimeFromFirestore(map['lastActiveAt']) ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'deviceModel': deviceModel,
      'deviceType': deviceType.name,
      'osVersion': osVersion,
      'appVersion': appVersion,
      'fcmToken': fcmToken,
      'ipAddress': ipAddress,
      'city': city,
      'country': country,
      'loginAt': FirestoreModel.dateTimeToFirestore(loginAt),
      'lastActiveAt': FirestoreModel.dateTimeToFirestore(lastActiveAt),
      'isActive': isActive,
    };
  }

  @override
  DeviceSession copyWith({
    String? id,
    String? userId,
    String? deviceId,
    String? deviceName,
    String? deviceModel,
    DeviceType? deviceType,
    String? osVersion,
    String? appVersion,
    String? fcmToken,
    String? ipAddress,
    String? city,
    String? country,
    DateTime? loginAt,
    DateTime? lastActiveAt,
    bool? isActive,
  }) {
    return DeviceSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      deviceModel: deviceModel ?? this.deviceModel,
      deviceType: deviceType ?? this.deviceType,
      osVersion: osVersion ?? this.osVersion,
      appVersion: appVersion ?? this.appVersion,
      fcmToken: fcmToken ?? this.fcmToken,
      ipAddress: ipAddress ?? this.ipAddress,
      city: city ?? this.city,
      country: country ?? this.country,
      loginAt: loginAt ?? this.loginAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        deviceId,
        deviceName,
        deviceModel,
        deviceType,
        osVersion,
        appVersion,
        fcmToken,
        ipAddress,
        city,
        country,
        loginAt,
        lastActiveAt,
        isActive,
      ];
}
