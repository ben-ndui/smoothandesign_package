import 'package:flutter_test/flutter_test.dart';
import 'package:smoothandesign_package/core/models/base_conversation.dart';

void main() {
  group('BaseConversation.isMutedFor', () {
    final conversation = BaseConversation(
      id: 'conv1',
      type: ConversationType.private,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      createdByUserId: 'user1',
      participantIds: ['user1', 'user2'],
      isMuted: {'user1': true, 'user2': false},
    );

    test('returns true for muted user', () {
      expect(conversation.isMutedFor('user1'), true);
    });

    test('returns false for unmuted user', () {
      expect(conversation.isMutedFor('user2'), false);
    });

    test('returns false for unknown user', () {
      expect(conversation.isMutedFor('user3'), false);
    });
  });

  group('BaseConversation.fromMap isMuted', () {
    test('parses isMuted map from Firestore data', () {
      final map = {
        'type': 'private',
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-01T00:00:00.000',
        'createdByUserId': 'user1',
        'participantIds': ['user1', 'user2'],
        'isMuted': {'user1': true, 'user2': false},
      };

      final conversation = BaseConversation.fromMap(map, 'conv1');

      expect(conversation.isMutedFor('user1'), true);
      expect(conversation.isMutedFor('user2'), false);
    });

    test('defaults to empty map when isMuted is missing', () {
      final map = {
        'type': 'private',
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-01T00:00:00.000',
        'createdByUserId': 'user1',
        'participantIds': ['user1', 'user2'],
      };

      final conversation = BaseConversation.fromMap(map, 'conv1');

      expect(conversation.isMutedFor('user1'), false);
      expect(conversation.isMutedFor('user2'), false);
    });
  });

  group('BaseConversation.copyWith isMuted', () {
    test('copies with new isMuted map', () {
      final conversation = BaseConversation(
        id: 'conv1',
        type: ConversationType.private,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        createdByUserId: 'user1',
        participantIds: ['user1', 'user2'],
        isMuted: {'user1': false},
      );

      final updated = conversation.copyWith(
        isMuted: {'user1': true},
      );

      expect(updated.isMutedFor('user1'), true);
    });
  });

  group('BaseConversation.toMap isMuted', () {
    test('includes isMuted in serialized map', () {
      final conversation = BaseConversation(
        id: 'conv1',
        type: ConversationType.private,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        createdByUserId: 'user1',
        participantIds: ['user1', 'user2'],
        isMuted: {'user1': true, 'user2': false},
      );

      final map = conversation.toMap();

      expect(map['isMuted'], {'user1': true, 'user2': false});
    });
  });
}
