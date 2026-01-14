import 'package:equatable/equatable.dart';
import '../../models/favorite.dart';

/// Base favorite event.
abstract class FavoriteEvent extends Equatable {
  const FavoriteEvent();

  @override
  List<Object?> get props => [];
}

/// Charge les favoris d'un utilisateur.
class LoadFavoritesEvent extends FavoriteEvent {
  final String userId;

  const LoadFavoritesEvent({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Charge les favoris par type.
class LoadFavoritesByTypeEvent extends FavoriteEvent {
  final String userId;
  final String type;

  const LoadFavoritesByTypeEvent({required this.userId, required this.type});

  @override
  List<Object?> get props => [userId, type];
}

/// Toggle un favori (ajoute ou supprime).
class ToggleFavoriteEvent extends FavoriteEvent {
  final String userId;
  final String targetId;
  final String type;
  final String? targetName;
  final String? targetPhotoUrl;
  final String? targetSubtitle;
  final Map<String, dynamic>? metadata;

  const ToggleFavoriteEvent({
    required this.userId,
    required this.targetId,
    required this.type,
    this.targetName,
    this.targetPhotoUrl,
    this.targetSubtitle,
    this.metadata,
  });

  @override
  List<Object?> get props => [userId, targetId, type];
}

/// Supprime un favori par ID.
class RemoveFavoriteEvent extends FavoriteEvent {
  final String favoriteId;

  const RemoveFavoriteEvent({required this.favoriteId});

  @override
  List<Object?> get props => [favoriteId];
}

/// Mise à jour interne quand les favoris changent.
class FavoritesUpdatedEvent extends FavoriteEvent {
  final List<Favorite> favorites;

  const FavoritesUpdatedEvent({required this.favorites});

  @override
  List<Object?> get props => [favorites];
}

/// Clear les favoris (déconnexion).
class ClearFavoritesEvent extends FavoriteEvent {
  const ClearFavoritesEvent();
}
