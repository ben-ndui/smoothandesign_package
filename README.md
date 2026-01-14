# Smoothandesign Package

Package Flutter réutilisable focalisé sur la **logique métier** pour accélérer le développement d'applications utilisant Firebase.

## Fonctionnalités

### Services de Base
- **Firebase Multi-Database** : Initialisation configurable pour différents projets
- **Auth Service** : Email + Google + Apple Sign-In
- **Storage Service** : Upload/download Firebase Storage
- **Notification Service** : FCM + notifications locales
- **Preferences Service** : SharedPreferences + Firestore sync

### Fonctionnalités Avancées (v1.1)
- **Messaging Service** : Chat temps réel avec Firestore (privé/groupe)
- **PDF Service** : Génération PDF avec templates extensibles
- **Export Service** : Export Excel/CSV avec partage
- **File Picker Helper** : Sélection images/documents unifiée

### Modèles & Utils
- **Modèles Extensibles** : BaseUser, BaseClient, BaseProduct, BaseDocument, BaseMessage, BaseConversation
- **BLoCs Génériques** : AuthBloc, ThemeBloc, NotificationBloc
- **Utilitaires** : Validation (SIRET, IBAN), formatage français (TVA, €), couleurs WCAG

## Installation

```yaml
dependencies:
  smoothandesign_package:
    path: ../smoothandesign_package
```

## Démarrage Rapide

### 1. Initialiser Firebase

```dart
import 'package:smoothandesign_package/smoothandesign.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SmoothFirebase.initialize(options: DefaultFirebaseOptions.currentPlatform);
  SmoothDI.setup();
  runApp(MyApp());
}
```

### 2. Authentification

```dart
final authService = SmoothDI.get<BaseAuthService>();
await authService.signInWithEmail(email, password);
await authService.signInWithGoogle();
await authService.signInWithApple();
```

### 3. Messagerie Temps Réel

```dart
final messaging = BaseMessagingService();

// Stream des conversations
messaging.streamUserConversations(userId).listen((conversations) {
  // Mise à jour UI
});

// Créer/trouver une conversation privée
final response = await messaging.getOrCreatePrivateConversation(
  userId1: currentUserId,
  userId2: otherUserId,
  user1Info: ParticipantInfo(name: 'John'),
  user2Info: ParticipantInfo(name: 'Jane'),
);

// Envoyer un message
await messaging.sendTextMessage(
  conversationId: conversation.id,
  senderId: currentUserId,
  senderName: 'John',
  text: 'Hello!',
  participantIds: conversation.participantIds,
);

// Stream des messages
messaging.streamMessages(conversationId).listen((messages) {
  // Afficher les messages
});
```

### 4. Génération PDF

```dart
// Étendre BasePdfService pour votre template
class MyPdfService extends BasePdfService {
  @override
  Future<pw.Document> generateDocument() async {
    await loadFonts();

    final doc = pw.Document();
    doc.addPage(pw.MultiPage(
      build: (context) => [
        buildHeader(title: 'FACTURE', config: config),
        pw.SizedBox(height: 20),
        buildParties(config: config, recipient: recipient),
        pw.SizedBox(height: 20),
        buildItemsTable(items: items),
        pw.SizedBox(height: 20),
        buildTotals(items: items),
      ],
    ));

    return doc;
  }
}
```

### 5. Export Excel/CSV

```dart
final exportService = BaseExportService();

// Export Excel
await exportService.exportAndShareExcel(
  fileName: 'factures',
  sheets: {
    'Factures': ExcelSheetData(
      columns: [
        ExcelColumn(header: 'Date', width: 15),
        ExcelColumn(header: 'Client', width: 25),
        ExcelColumn(header: 'Montant', width: 15),
      ],
      rows: [
        [DateTime.now(), 'Client A', 1500.0],
        [DateTime.now(), 'Client B', 2300.0],
      ],
    ),
  },
);

// Export CSV
await exportService.exportAndShareCsv(
  fileName: 'export',
  headers: ['Date', 'Client', 'Montant'],
  rows: [
    [DateTime.now(), 'Client A', 1500.0],
  ],
);
```

### 6. Sélection de Fichiers

```dart
final picker = FilePickerHelper();

// Image depuis galerie (compressée)
final image = await picker.pickImageFromGallery(imageQuality: 80);

// Photo depuis caméra
final photo = await picker.pickImageFromCamera();

// Fichier PDF
final pdf = await picker.pickPdf();

// Plusieurs images
final images = await picker.pickMultipleImages(limit: 5);

// N'importe quel fichier
final file = await picker.pickFile(type: FilePickerType.any);
```

## Structure du Package

```
lib/
├── smoothandesign.dart
├── core/
│   ├── firebase/
│   │   ├── smooth_firebase.dart
│   │   └── base_firestore_service.dart
│   ├── services/
│   │   ├── base_auth_service.dart
│   │   ├── base_storage_service.dart
│   │   ├── base_notification_service.dart
│   │   ├── base_preferences_service.dart
│   │   ├── base_messaging_service.dart    # NEW
│   │   ├── base_pdf_service.dart          # NEW
│   │   ├── base_export_service.dart       # NEW
│   │   └── file_picker_helper.dart        # NEW
│   ├── models/
│   │   ├── base_user.dart
│   │   ├── base_client.dart
│   │   ├── base_product.dart
│   │   ├── base_document.dart
│   │   ├── base_message.dart              # NEW
│   │   ├── base_conversation.dart         # NEW
│   │   ├── document_status.dart           # NEW
│   │   └── smooth_response.dart
│   ├── blocs/
│   │   ├── auth/
│   │   ├── theme/
│   │   └── notification/
│   └── utils/
├── config/
└── di/
```

## Modèles de Messagerie

```dart
// Message avec pièce jointe
final attachment = MessageAttachment(
  url: 'https://...',
  fileName: 'document.pdf',
  fileType: 'application/pdf',
  fileSize: 1024000,
);

await messaging.sendAttachmentMessage(
  conversationId: id,
  senderId: userId,
  senderName: 'John',
  attachment: attachment,
  participantIds: participantIds,
);

// Message avec objet métier (devis, facture...)
final businessObject = BusinessObjectAttachment(
  objectType: 'invoice',
  objectId: 'inv-123',
  title: 'Facture #123',
  amount: 1500.0,
  status: 'paid',
);

await messaging.sendBusinessObjectMessage(
  conversationId: id,
  senderId: userId,
  senderName: 'John',
  businessObject: businessObject,
  participantIds: participantIds,
);
```

## Status de Documents

```dart
// Enum avec noms français et couleurs
final status = DocumentStatus.sent;
print(status.displayName);  // "Envoyé"
print(status.colorHex);     // "3B82F6"
print(status.isEditable);   // false
print(status.isFinal);      // false

// Types de documents
final type = DocumentType.invoice;
print(type.displayName);    // "Facture"
print(type.prefix);         // "FAC"
```

## Dépendances

```yaml
# Firebase
firebase_core, firebase_auth, cloud_firestore, firebase_storage, firebase_messaging

# State Management
flutter_bloc, bloc, equatable, get_it

# Auth Providers
google_sign_in, sign_in_with_apple

# Notifications
flutter_local_notifications

# PDF & Export
pdf, printing, excel, path_provider, share_plus

# File Picker
file_picker, image_picker

# Utils
shared_preferences, intl, google_fonts
```

## Philosophie

Ce package fournit uniquement la **logique métier** réutilisable. Chaque projet garde son propre :
- Design UI (widgets, composants)
- Thème et couleurs
- Routes et navigation
- Modèles métier spécifiques

## Licence

Propriétaire - Smooth & Design
