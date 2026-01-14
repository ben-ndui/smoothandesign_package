/// Wrapper générique pour les réponses API/Service.
///
/// Fournit un pattern uniforme pour gérer les succès et erreurs.
/// ```dart
/// final response = await service.getData();
/// if (response.isSuccess) {
///   print(response.data);
/// } else {
///   print(response.message);
/// }
/// ```
class SmoothResponse<T> {
  /// Code de réponse (200 = succès, 201 = créé, 4xx/5xx = erreur).
  final int code;

  /// Message descriptif.
  final String message;

  /// Données de la réponse (peut être null).
  final T? data;

  const SmoothResponse({
    this.code = 200,
    this.message = '',
    this.data,
  });

  /// Indique si la réponse est un succès (code 2xx).
  bool get isSuccess => code >= 200 && code < 300;

  /// Indique si la réponse est une erreur.
  bool get isError => !isSuccess;

  /// Indique si c'est un nouvel élément créé (code 201).
  bool get isCreated => code == 201;

  /// Indique si c'est une erreur d'authentification (code 401).
  bool get isUnauthorized => code == 401;

  /// Indique si c'est une erreur de permission (code 403).
  bool get isForbidden => code == 403;

  /// Indique si l'élément n'existe pas (code 404).
  bool get isNotFound => code == 404;

  /// Crée une réponse de succès.
  factory SmoothResponse.success({T? data, String message = 'Succès'}) {
    return SmoothResponse(code: 200, message: message, data: data);
  }

  /// Crée une réponse d'erreur.
  factory SmoothResponse.error({String message = 'Erreur', int code = 500}) {
    return SmoothResponse(code: code, message: message);
  }

  /// Crée une réponse pour élément non trouvé.
  factory SmoothResponse.notFound({String message = 'Non trouvé'}) {
    return SmoothResponse(code: 404, message: message);
  }

  /// Crée une réponse pour erreur d'authentification.
  factory SmoothResponse.unauthorized({String message = 'Non autorisé'}) {
    return SmoothResponse(code: 401, message: message);
  }

  /// Transforme les données avec une fonction.
  SmoothResponse<R> map<R>(R Function(T data) transform) {
    return SmoothResponse<R>(
      code: code,
      message: message,
      data: data != null ? transform(data as T) : null,
    );
  }

  /// Retourne les données ou une valeur par défaut.
  T dataOr(T defaultValue) => data ?? defaultValue;

  @override
  String toString() => 'SmoothResponse(code: $code, message: $message, data: $data)';
}
