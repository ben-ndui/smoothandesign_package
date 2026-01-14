import 'package:equatable/equatable.dart';
import '../../models/favorite.dart';

/// Base favorite state.
class FavoriteState extends Equatable {
  final List<Favorite> favorites;
  final bool isLoading;
  final String? errorMessage;

  const FavoriteState({
    this.favorites = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  /// Vérifie si un élément est en favori.
  bool isFavorite(String targetId) {
    return favorites.any((f) => f.targetId == targetId);
  }

  /// Récupère les favoris par type.
  List<Favorite> getFavoritesByType(String type) {
    return favorites.where((f) => f.type == type).toList();
  }

  /// Nombre de favoris par type.
  int countByType(String type) => getFavoritesByType(type).length;

  @override
  List<Object?> get props => [favorites, isLoading, errorMessage];

  FavoriteState copyWith({
    List<Favorite>? favorites,
    bool? isLoading,
    String? errorMessage,
  }) {
    return FavoriteState(
      favorites: favorites ?? this.favorites,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// État initial.
class FavoriteInitialState extends FavoriteState {
  const FavoriteInitialState() : super();
}

/// État de chargement.
class FavoriteLoadingState extends FavoriteState {
  const FavoriteLoadingState({super.favorites}) : super(isLoading: true);
}

/// Favoris chargés.
class FavoritesLoadedState extends FavoriteState {
  const FavoritesLoadedState({required super.favorites})
      : super(isLoading: false);
}

/// Favori togglé (ajouté ou supprimé).
class FavoriteToggledState extends FavoriteState {
  final String targetId;
  final bool isNowFavorite;

  const FavoriteToggledState({
    required this.targetId,
    required this.isNowFavorite,
    required super.favorites,
  }) : super(isLoading: false);

  @override
  List<Object?> get props => [targetId, isNowFavorite, favorites, isLoading];
}

/// État d'erreur.
class FavoriteErrorState extends FavoriteState {
  const FavoriteErrorState({
    required super.errorMessage,
    super.favorites,
  }) : super(isLoading: false);
}
