import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smoothandesign_package/core/blocs/messaging/messaging_bloc.dart';
import 'package:smoothandesign_package/core/blocs/messaging/messaging_event.dart';
import 'package:smoothandesign_package/core/blocs/messaging/messaging_state.dart';
import 'package:smoothandesign_package/core/models/base_conversation.dart';
import 'package:smoothandesign_package/core/models/base_message.dart';
import 'package:smoothandesign_package/core/models/smooth_response.dart';
import 'package:smoothandesign_package/core/services/base_messaging_service.dart';

class MockMessagingService extends Mock implements BaseMessagingService {}

/// Régression (Ben, 30/10/2026) : un envoi dont la conversation n'est plus
/// dans le cache local (ex. liste renvoyée vide entre-temps par le stream)
/// faisait un `return` nu — rien en Firestore, rien à l'écran. On vérifie
/// maintenant qu'un `sendError` transitoire est émis à la place, repris
/// par `ChatScreen` pour un SnackBar (cf. `messaging_bloc_send.dart`).
void main() {
  late MockMessagingService mockService;

  final conversation = BaseConversation(
    id: 'conv-1',
    type: ConversationType.private,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    createdByUserId: 'user-a',
    participantIds: const ['user-a', 'user-b'],
  );

  setUp(() {
    mockService = MockMessagingService();
    when(() => mockService.streamUserConversations(any()))
        .thenAnswer((_) => Stream.value([conversation]));
    when(() => mockService.streamMessages(any()))
        .thenAnswer((_) => const Stream<List<BaseMessage>>.empty());
    when(() => mockService.streamConversation(any()))
        .thenAnswer((_) => const Stream<BaseConversation?>.empty());
    when(() => mockService.markConversationAsRead(
          conversationId: any(named: 'conversationId'),
          userId: any(named: 'userId'),
        )).thenAnswer((_) async => SmoothResponse.success());
  });

  test(
    'envoi de texte sur une conversation sortie du cache : sendError au lieu du silence',
    () async {
      final bloc = MessagingBloc(messagingService: mockService)
        ..setCurrentUser(userId: 'user-a', userName: 'Studio');
      addTearDown(bloc.close);

      // Charge la liste (conversation en cache), ouvre le chat -> ChatOpenState.
      bloc.add(const LoadConversationsEvent(userId: 'user-a'));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(const OpenConversationEvent(conversationId: 'conv-1'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(MessagesUpdatedEvent(messages: const []));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<ChatOpenState>());

      // Course réelle : le stream conversations renvoie une liste qui ne
      // contient plus 'conv-1' (déconnexion/relisting) pendant que le chat
      // reste affiché — _conversations est mise à jour même si l'état ne
      // change pas (cf. _onConversationsUpdated).
      bloc.add(const ConversationsUpdatedEvent(conversations: []));
      await Future<void>.delayed(Duration.zero);

      final errors = <String?>[];
      final sub = bloc.stream.listen((state) {
        if (state is ChatOpenState) errors.add(state.sendError);
      });

      bloc.add(const SendTextMessageEvent(text: 'Hola bro'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      verifyNever(() => mockService.sendTextMessage(
            conversationId: any(named: 'conversationId'),
            senderId: any(named: 'senderId'),
            senderName: any(named: 'senderName'),
            senderAvatarUrl: any(named: 'senderAvatarUrl'),
            text: any(named: 'text'),
            participantIds: any(named: 'participantIds'),
          ));
      expect(
        errors.any((e) => e != null),
        isTrue,
        reason: 'un sendError doit être émis au lieu du silence total',
      );

      await sub.cancel();
    },
  );
}
