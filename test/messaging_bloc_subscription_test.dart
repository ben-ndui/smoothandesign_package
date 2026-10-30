import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smoothandesign_package/core/blocs/messaging/messaging_bloc.dart';
import 'package:smoothandesign_package/core/blocs/messaging/messaging_event.dart';
import 'package:smoothandesign_package/core/models/base_conversation.dart';
import 'package:smoothandesign_package/core/models/base_message.dart';
import 'package:smoothandesign_package/core/services/base_messaging_service.dart';

class MockMessagingService extends Mock implements BaseMessagingService {}

/// `_onOpenConversation` n'a, contrairement a `_onLoadConversations`, aucun
/// garde-fou : il annule puis reassigne `_messagesSubscription`/
/// `_conversationSubscription` sans jamais verifier s'il est deja en train
/// de s'executer pour le meme event. Deux `OpenConversationEvent` rapproches
/// (double tap sur une conversation) pouvaient donc laisser un flux Firestore
/// actif et invisible. Corrige avec `transformer: restartable()`.
void main() {
  late MockMessagingService mockService;

  setUp(() {
    mockService = MockMessagingService();
    when(() => mockService.streamMessages(any()))
        .thenAnswer((_) => const Stream<List<BaseMessage>>.empty());
  });

  test(
    'OpenConversationEvent annule le flux de conversation precedent quand il est redispatche rapidement',
    () async {
      final controller1 = StreamController<BaseConversation?>();
      final controller2 = StreamController<BaseConversation?>();
      var call = 0;
      when(() => mockService.streamConversation(any())).thenAnswer((_) {
        call++;
        return call == 1 ? controller1.stream : controller2.stream;
      });

      final bloc = MessagingBloc(messagingService: mockService);
      addTearDown(bloc.close);

      bloc.add(const OpenConversationEvent(conversationId: 'conv-1'));
      bloc.add(const OpenConversationEvent(conversationId: 'conv-1'));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(
        controller1.hasListener,
        isFalse,
        reason: 'le premier flux de conversation doit être annulé par restartable()',
      );
      expect(controller2.hasListener, isTrue);

      await controller1.close();
      await controller2.close();
    },
  );
}
