import 'package:cloud_firestore/cloud_firestore.dart';
import 'smooth_firebase.dart';

/// Service Firestore générique avec CRUD de base.
///
/// Étendre cette classe pour créer des services spécifiques à un type.
/// ```dart
/// class ClientService extends BaseFirestoreService<Client> {
///   ClientService() : super('clients');
///
///   @override
///   Client fromMap(Map<String, dynamic> map, String id) {
///     return Client.fromMap({...map, 'id': id});
///   }
///
///   @override
///   Map<String, dynamic> toMap(Client item) => item.toMap();
/// }
/// ```
abstract class BaseFirestoreService<T> {
  final String collectionPath;
  late final CollectionReference<Map<String, dynamic>> _collection;

  BaseFirestoreService(this.collectionPath) {
    _collection = SmoothFirebase.collection(collectionPath);
  }

  /// Convertit une Map Firestore en objet T.
  T fromMap(Map<String, dynamic> map, String id);

  /// Convertit un objet T en Map pour Firestore.
  Map<String, dynamic> toMap(T item);

  /// Référence à la collection.
  CollectionReference<Map<String, dynamic>> get collection => _collection;

  /// Crée un nouveau document avec ID auto-généré.
  Future<String> create(T item) async {
    final docRef = await _collection.add(toMap(item));
    return docRef.id;
  }

  /// Crée un document avec un ID spécifique.
  Future<void> createWithId(String id, T item) async {
    await _collection.doc(id).set(toMap(item));
  }

  /// Met à jour un document existant.
  Future<void> update(String id, T item) async {
    await _collection.doc(id).update(toMap(item));
  }

  /// Met à jour des champs spécifiques.
  Future<void> updateFields(String id, Map<String, dynamic> fields) async {
    await _collection.doc(id).update(fields);
  }

  /// Supprime un document.
  Future<void> delete(String id) async {
    await _collection.doc(id).delete();
  }

  /// Récupère un document par ID.
  Future<T?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return fromMap(doc.data()!, doc.id);
  }

  /// Récupère tous les documents.
  Future<List<T>> getAll() async {
    final snapshot = await _collection.get();
    return snapshot.docs
        .map((doc) => fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Récupère les documents avec une query.
  Future<List<T>> query({
    String? orderBy,
    bool descending = false,
    int? limit,
    List<QueryFilter>? filters,
  }) async {
    Query<Map<String, dynamic>> query = _collection;

    if (filters != null) {
      for (final filter in filters) {
        query = _applyFilter(query, filter);
      }
    }

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Stream d'un document.
  Stream<T?> streamById(String id) {
    return _collection.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return fromMap(doc.data()!, doc.id);
    });
  }

  /// Stream de tous les documents.
  Stream<List<T>> streamAll() {
    return _collection.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => fromMap(doc.data(), doc.id)).toList());
  }

  /// Stream avec query.
  Stream<List<T>> streamQuery({
    String? orderBy,
    bool descending = false,
    int? limit,
    List<QueryFilter>? filters,
  }) {
    Query<Map<String, dynamic>> query = _collection;

    if (filters != null) {
      for (final filter in filters) {
        query = _applyFilter(query, filter);
      }
    }

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => fromMap(doc.data(), doc.id)).toList());
  }

  Query<Map<String, dynamic>> _applyFilter(
    Query<Map<String, dynamic>> query,
    QueryFilter filter,
  ) {
    switch (filter.operator) {
      case FilterOperator.equals:
        return query.where(filter.field, isEqualTo: filter.value);
      case FilterOperator.notEquals:
        return query.where(filter.field, isNotEqualTo: filter.value);
      case FilterOperator.lessThan:
        return query.where(filter.field, isLessThan: filter.value);
      case FilterOperator.lessThanOrEqual:
        return query.where(filter.field, isLessThanOrEqualTo: filter.value);
      case FilterOperator.greaterThan:
        return query.where(filter.field, isGreaterThan: filter.value);
      case FilterOperator.greaterThanOrEqual:
        return query.where(filter.field, isGreaterThanOrEqualTo: filter.value);
      case FilterOperator.arrayContains:
        return query.where(filter.field, arrayContains: filter.value);
      case FilterOperator.arrayContainsAny:
        return query.where(filter.field, arrayContainsAny: filter.value as List);
      case FilterOperator.whereIn:
        return query.where(filter.field, whereIn: filter.value as List);
      case FilterOperator.whereNotIn:
        return query.where(filter.field, whereNotIn: filter.value as List);
      case FilterOperator.isNull:
        return query.where(filter.field, isNull: filter.value as bool);
    }
  }
}

/// Filtre pour les queries Firestore.
class QueryFilter {
  final String field;
  final FilterOperator operator;
  final dynamic value;

  const QueryFilter({
    required this.field,
    required this.operator,
    required this.value,
  });

  /// Raccourci pour égalité.
  factory QueryFilter.equals(String field, dynamic value) {
    return QueryFilter(field: field, operator: FilterOperator.equals, value: value);
  }

  /// Raccourci pour arrayContains.
  factory QueryFilter.arrayContains(String field, dynamic value) {
    return QueryFilter(field: field, operator: FilterOperator.arrayContains, value: value);
  }
}

/// Opérateurs de filtre Firestore.
enum FilterOperator {
  equals,
  notEquals,
  lessThan,
  lessThanOrEqual,
  greaterThan,
  greaterThanOrEqual,
  arrayContains,
  arrayContainsAny,
  whereIn,
  whereNotIn,
  isNull,
}
