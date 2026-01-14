import 'package:cloud_firestore/cloud_firestore.dart';

/// Mixin pour les modèles avec sérialisation Firestore.
///
/// Fournit des helpers pour la conversion DateTime/Timestamp.
mixin FirestoreModel {
  /// Convertit un champ Firestore en DateTime.
  static DateTime? dateTimeFromFirestore(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Convertit un DateTime en format Firestore.
  static dynamic dateTimeToFirestore(DateTime? value) {
    if (value == null) return null;
    return Timestamp.fromDate(value);
  }

  /// Convertit une Map Firestore avec gestion des timestamps.
  static Map<String, dynamic> normalizeMap(Map<String, dynamic> map) {
    return map.map((key, value) {
      if (value is Timestamp) {
        return MapEntry(key, value.toDate().toIso8601String());
      }
      return MapEntry(key, value);
    });
  }
}

/// Interface de base pour tous les modèles.
///
/// Définit les méthodes requises pour la sérialisation.
abstract class BaseModel {
  /// Identifiant unique.
  String get id;

  /// Convertit le modèle en Map pour Firestore.
  Map<String, dynamic> toMap();

  /// Crée une copie avec des modifications.
  BaseModel copyWith();
}

/// Extension pour les listes de modèles.
extension BaseModelListExtension<T extends BaseModel> on List<T> {
  /// Trouve un élément par ID.
  T? findById(String id) {
    try {
      return firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Vérifie si un ID existe.
  bool containsId(String id) => any((item) => item.id == id);

  /// Convertit la liste en Maps.
  List<Map<String, dynamic>> toMapList() => map((item) => item.toMap()).toList();
}
