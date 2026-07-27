# SMOOTH_MANIFEST — smoothandesign_package

Package Dart/Flutter partagé de Smooth & Design : logique métier Firebase mutualisée (auth, storage, messaging, PDF, export, Stripe/IAP) — services, BLoCs, modèles et widgets réutilisables consommés par les apps mobiles.

## Identité

- **Type** : package Dart/Flutter partagé (`name: smoothandesign_package`, `version: 1.5.0`).
- **SDK** : Dart `^3.8.1`, Flutter `>=3.0.0`. Toolchain via **FVM** (`.fvmrc`) — toujours `fvm flutter`, jamais `flutter` direct.
- **Repo** : `https://github.com/ben-ndui/smoothandesign_package` (remote `origin`). ⚠️ le champ `homepage` du pubspec pointe encore vers `github.com/smoothandesign/...` — le vrai remote est `ben-ndui`.
- **Consommateurs connus** : `uzme` (prod, via git `ref: v1.5.0`) et `amobiz` (dev local, `path: ../smoothandesign_package`).
  - Note : `CLAUDE.md` et d'anciens docs parlent de `useme`/`easybiz` = anciens noms de `uzme`/`amobiz`.
- **Installation** :
  ```yaml
  # Prod (uzme) — tag git figé
  smoothandesign_package:
    git: { url: https://github.com/ben-ndui/smoothandesign_package, ref: v1.5.0 }
  # Dev local (amobiz)
  smoothandesign_package: { path: ../smoothandesign_package }
  ```

## Architecture

- `lib/smoothandesign.dart` — **point d'entrée public unique** (barrel : re-exporte firebase, services, models, blocs, utils, config, DI, dev, widgets).
- `lib/core/firebase/` — `SmoothFirebase.initialize`, `base_firestore_service.dart`.
- `lib/core/services/` — services de base extensibles (`Base*Service`).
- `lib/core/blocs/` — BLoCs réutilisables (auth, messaging, notification, theme, locale, favorite).
- `lib/core/models/` — modèles `Base*` à étendre par projet (Equatable).
- `lib/core/utils/` — validators, `french_utils`, `geo_utils`, `color_utils`.
- `lib/core/widgets/` — widgets UI (messaging, glass, dashboard, forms, navigation…).
- `lib/config/` — tokens design (`app_spacing`, `app_text_styles`, `app_animations`).
- `lib/di/smooth_di.dart` — `SmoothDI` (wrapper get_it) + `getIt` global.
- `lib/dev/` — Dev Console (feature flags, impersonation, logs, migrations, DB) + `triple_tap_detector`.

## Features — API publique

- **DI** : `SmoothDI.setup({authService, storageService, notificationService, preferencesService})` après `SmoothFirebase.initialize`. `getIt<T>()`, `SmoothDI.register/registerLazy/registerFactory/reset`. Chaque `Base*Service` peut être injecté ou surchargé.
- **Auth** — `base_auth_service.dart` + `blocs/auth/` : email/Google/Apple, `LockApp`/`UnlockApp` (relogin biométrique), refresh forcé du claim `role` (`getIdToken(true)`) quand le rôle change côté doc user, timeouts 8-10 s sur `saveUserToFirestore`/`_updateFcmToken`, mapping FR des erreurs.
- **Messaging** — `base_messaging_service.dart` + `blocs/messaging/` + `widgets/messaging/` (`ChatView`, `MessageBubble`, `MessageInput`…). État `ChatOpenState` expose `isSending` (bool) et `sendError` (String? transitoire, émis puis cleared → écouter en `BlocListener`). `ChatView` : `showAttachmentButton`/`showAudioButton`.
- **Storage / Photo / Files** — `base_storage_service.dart`, `base_photo_service.dart`, `file_picker_helper.dart`.
- **Notifications** — `base_notification_service.dart` (FCM + local) + `blocs/notification/`.
- **PDF / Export** — `base_pdf_service.dart` (pdf + printing), `base_export_service.dart` (Excel/CSV).
- **Paiements** — `base_stripe_service.dart` (config bornée 10 s), `base_iap_service.dart`, `base_subscription_service.dart`.
- **Modèles de base** : `BaseUser`, `BaseClient`, `BaseProduct`, `BaseDocument`, `BaseMessage`, `BaseConversation` (avec `ParticipantInfo` denormalisé, champ `isPioneer` depuis v1.2.4), `BaseNotification`, `DeviceSession`, `SmoothResponse`…

## Intégrations

- Firebase : `firebase_core` 4.x, `firebase_auth` 6.x, `cloud_firestore` 6.x, `firebase_storage` 13.x, `firebase_messaging` 16.x, `cloud_functions` 6.x.
- State : `flutter_bloc`/`bloc` 9.x, `equatable`, `get_it` 8.x.
- Auth providers : `google_sign_in`, `sign_in_with_apple`.
- Paiement : `flutter_stripe` 12.x, `in_app_purchase` 3.x.
- Autres : `pdf`/`printing`, `excel`, `record`/`just_audio`, `geolocator`, `flutter_secure_storage`/`encrypt`/`crypto`, `font_awesome_flutter` 11 (`FaIconData`), `google_fonts`, `flutter_local_notifications`.
- Package sibling : `smoothandesign_auth_biometric` (bio + comptes récents, extrait pour isoler les deps natives).

## Commandes

```bash
fvm flutter pub get
fvm flutter analyze
fvm flutter test          # test/ : auth error messages, conversation mute, package_test
fvm flutter pub publish --dry-run
git tag v1.x.x && git push origin v1.x.x   # versionnage = tags git
```

## Pièges

- **La CI builde le TAG, pas le local.** `uzme` tire `ref: vX.Y.Z` ; le `pubspec_overrides.yaml` path est gitignoré. Toute évolution = bump version pubspec + tag + `git push --tags` + bump la ref dans le pubspec de l'app, sinon la CI compile une version antérieure à celle testée.
- **Impact double** : tout changement touche `uzme` ET `amobiz` — tester les deux apps après modif.
- **`sendError` est transitoire** : émis puis immédiatement cleared → l'app doit l'écouter via `BlocListener`, pas via `BlocBuilder`.
- **Claim `role` périmé ~1 h** : les rules Firestore lisent `request.auth.token.role` ; le refresh est déclenché par le package quand le doc user change — ne pas court-circuiter.
- **Exports partiels** : `location_service.dart`, `encryption_service.dart`, `base_favorite_service.dart`, `base_subscription_service.dart`, `base_availability_service.dart`, `base_invitation_service.dart` **ne sont PAS** dans le barrel (conflits) → les importer explicitement par leur chemin complet.
- Toujours `fvm flutter` (jamais `flutter` direct) — sinon mismatch de version SDK.

> MAJ : 2026-07-27
