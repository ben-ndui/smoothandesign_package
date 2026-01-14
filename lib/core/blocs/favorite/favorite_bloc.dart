import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/favorite.dart';
import '../../services/base_favorite_service.dart';
import 'favorite_event.dart';
import 'favorite_state.dart';

/// BLoC générique pour la gestion des favoris.
///
/// Usage:
/// ```dart
/// // Création avec service personnalisé
/// BlocProvider(
///   create: (_) => FavoriteBloc(
///     favoriteService: BaseFavoriteService(collectionName: 'myapp_favorites'),
///   ),
///   child: MyApp(),
/// )
///
/// // Charger les favoris
/// context.read<FavoriteBloc>().add(LoadFavoritesEvent(userId: user.id));
///
/// // Toggle favori
/// context.read<FavoriteBloc>().add(ToggleFavoriteEvent(
///   userId: user.id,
///   targetId: product.id,
///   type: 'product',
///   targetName: product.name,
/// ));
///
/// // Vérifier si favori
/// final isFav = context.watch<FavoriteBloc>().state.isFavorite(productId);
/// ```
class FavoriteBloc extends Bloc<FavoriteEvent, FavoriteState> {
  final BaseFavoriteService _favoriteService;
  StreamSubscription? _favoritesSubscription;
  String? _currentUserId;

  FavoriteBloc({BaseFavoriteService? favoriteService})
      : _favoriteService = favoriteService ?? BaseFavoriteService(),
        super(const FavoriteInitialState()) {
    on<LoadFavoritesEvent>(_onLoadFavorites);
    on<LoadFavoritesByTypeEvent>(_onLoadFavoritesByType);
    on<ToggleFavoriteEvent>(_onToggleFavorite);
    on<RemoveFavoriteEvent>(_onRemoveFavorite);
    on<FavoritesUpdatedEvent>(_onFavoritesUpdated);
    on<ClearFavoritesEvent>(_onClear);
  }

  Future<void> _onLoadFavorites(
    LoadFavoritesEvent event,
    Emitter<FavoriteState> emit,
  ) async {
    // Éviter les rechargements inutiles
    if (_currentUserId == event.userId &&
        state is FavoritesLoadedState &&
        state.favorites.isNotEmpty) {
      return;
    }

    _currentUserId = event.userId;
    emit(FavoriteLoadingState(favorites: state.favorites));

    await _favoritesSubscription?.cancel();
    _favoritesSubscription = _favoriteService.streamFavorites(event.userId).listen(
      (favorites) => add(FavoritesUpdatedEvent(favorites: favorites)),
      onError: (e) {
        debugPrint('FavoriteBloc stream error: $e');
        add(const FavoritesUpdatedEvent(favorites: []));
      },
    );
  }

  Future<void> _onLoadFavoritesByType(
    LoadFavoritesByTypeEvent event,
    Emitter<FavoriteState> emit,
  ) async {
    _currentUserId = event.userId;
    emit(FavoriteLoadingState(favorites: state.favorites));

    await _favoritesSubscription?.cancel();
    _favoritesSubscription =
        _favoriteService.streamFavoritesByType(event.userId, event.type).listen(
              (favorites) => add(FavoritesUpdatedEvent(favorites: favorites)),
              onError: (e) => add(const FavoritesUpdatedEvent(favorites: [])),
            );
  }

  void _onFavoritesUpdated(
    FavoritesUpdatedEvent event,
    Emitter<FavoriteState> emit,
  ) {
    emit(FavoritesLoadedState(favorites: event.favorites));
  }

  Future<void> _onToggleFavorite(
    ToggleFavoriteEvent event,
    Emitter<FavoriteState> emit,
  ) async {
    final result = await _favoriteService.toggleFavorite(
      userId: event.userId,
      targetId: event.targetId,
      type: event.type,
      targetName: event.targetName,
      targetPhotoUrl: event.targetPhotoUrl,
      targetSubtitle: event.targetSubtitle,
      metadata: event.metadata,
    );

    if (result.isSuccess && result.data != null) {
      final isNowFavorite = result.data!;

      // Mise à jour optimiste de la liste locale
      List<Favorite> updatedFavorites;
      if (isNowFavorite) {
        final newFavorite = Favorite(
          id: '',
          userId: event.userId,
          targetId: event.targetId,
          type: event.type,
          createdAt: DateTime.now(),
          targetName: event.targetName,
          targetPhotoUrl: event.targetPhotoUrl,
          targetSubtitle: event.targetSubtitle,
          metadata: event.metadata,
        );
        updatedFavorites = [...state.favorites, newFavorite];
      } else {
        updatedFavorites =
            state.favorites.where((f) => f.targetId != event.targetId).toList();
      }

      emit(FavoriteToggledState(
        targetId: event.targetId,
        isNowFavorite: isNowFavorite,
        favorites: updatedFavorites,
      ));
    } else {
      emit(FavoriteErrorState(
        errorMessage: result.message,
        favorites: state.favorites,
      ));
    }
  }

  Future<void> _onRemoveFavorite(
    RemoveFavoriteEvent event,
    Emitter<FavoriteState> emit,
  ) async {
    final result = await _favoriteService.removeFavorite(event.favoriteId);

    if (!result.isSuccess) {
      emit(FavoriteErrorState(
        errorMessage: result.message,
        favorites: state.favorites,
      ));
    }
  }

  Future<void> _onClear(
    ClearFavoritesEvent event,
    Emitter<FavoriteState> emit,
  ) async {
    await _favoritesSubscription?.cancel();
    _favoritesSubscription = null;
    _currentUserId = null;
    emit(const FavoriteInitialState());
  }

  @override
  Future<void> close() {
    _favoritesSubscription?.cancel();
    return super.close();
  }
}
