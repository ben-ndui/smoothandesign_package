import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/invitation.dart';
import '../models/smooth_response.dart';

/// Service générique pour gérer les invitations.
///
/// Usage:
/// ```dart
/// final service = BaseInvitationService(
///   collectionName: 'team_invitations',
///   codePrefix: 'TEAM',
///   expirationDays: 30,
/// );
///
/// // Créer une invitation
/// final result = await service.createInvitation(
///   organizationId: 'org123',
///   organizationName: 'Mon Org',
///   email: 'user@example.com',
///   role: 'member',
/// );
///
/// // Valider un code
/// final invitation = await service.validateCode('TEAM-ABC123');
///
/// // Accepter
/// await service.acceptInvitation(invitationId: 'inv123', userId: 'user456');
/// ```
class BaseInvitationService {
  final FirebaseFirestore _firestore;
  final String collectionName;
  final String codePrefix;
  final int codeLength;
  final int expirationDays;

  /// Callback optionnel pour vérifier les limites (ex: subscription).
  final Future<bool> Function(String organizationId)? canCreateInvitation;

  /// Callback appelé après acceptation.
  final Future<void> Function(Invitation invitation, String userId)?
      onInvitationAccepted;

  BaseInvitationService({
    FirebaseFirestore? firestore,
    this.collectionName = 'invitations',
    this.codePrefix = 'INV',
    this.codeLength = 6,
    this.expirationDays = 30,
    this.canCreateInvitation,
    this.onInvitationAccepted,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  /// Crée une nouvelle invitation.
  Future<SmoothResponse<Invitation>> createInvitation({
    required String organizationId,
    required String organizationName,
    required String email,
    String? inviteeName,
    String? role,
    String? message,
    String? createdByUserId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Vérifier les limites si callback fourni
      if (canCreateInvitation != null) {
        final canCreate = await canCreateInvitation!(organizationId);
        if (!canCreate) {
          return SmoothResponse.error(
            message: 'Invitation limit reached',
            code: 403,
          );
        }
      }

      // Vérifier si une invitation pending existe déjà
      final normalizedEmail = email.toLowerCase().trim();
      final existing = await _findPendingInvitation(normalizedEmail, organizationId);
      if (existing != null) {
        return SmoothResponse.success(data: existing);
      }

      final docRef = _collection.doc();
      final invitation = Invitation(
        id: docRef.id,
        organizationId: organizationId,
        organizationName: organizationName,
        email: normalizedEmail,
        inviteeName: inviteeName,
        code: _generateCode(),
        status: InvitationStatus.pending,
        role: role,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(days: expirationDays)),
        createdByUserId: createdByUserId,
        message: message,
        metadata: metadata,
      );

      await docRef.set(invitation.toMap());
      return SmoothResponse(data: invitation, code: 201, message: 'Created');
    } catch (e) {
      debugPrint('Error creating invitation: $e');
      return SmoothResponse.error(message: 'Error: $e');
    }
  }

  /// Valide un code d'invitation.
  Future<Invitation?> validateCode(String code) async {
    final normalizedCode = code.toUpperCase().trim();
    final snapshot = await _collection
        .where('code', isEqualTo: normalizedCode)
        .where('status', isEqualTo: InvitationStatus.pending.value)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final invitation =
        Invitation.fromMap(snapshot.docs.first.data(), id: snapshot.docs.first.id);
    if (invitation.isExpired) return null;

    return invitation;
  }

  /// Accepte une invitation.
  Future<SmoothResponse<bool>> acceptInvitation({
    required String invitationId,
    required String userId,
  }) async {
    try {
      final doc = await _collection.doc(invitationId).get();
      if (!doc.exists) {
        return SmoothResponse.error(message: 'Invitation not found', code: 404);
      }

      final invitation = Invitation.fromMap(doc.data()!, id: doc.id);
      if (!invitation.canBeAccepted) {
        return SmoothResponse.error(message: 'Invitation cannot be accepted');
      }

      await _collection.doc(invitationId).update({
        'status': InvitationStatus.accepted.value,
        'acceptedByUserId': userId,
        'acceptedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Callback post-acceptation
      if (onInvitationAccepted != null) {
        await onInvitationAccepted!(invitation, userId);
      }

      return SmoothResponse.success(data: true);
    } catch (e) {
      debugPrint('Error accepting invitation: $e');
      return SmoothResponse.error(message: 'Error: $e');
    }
  }

  /// Refuse une invitation.
  Future<SmoothResponse<bool>> declineInvitation(String invitationId) async {
    try {
      await _collection.doc(invitationId).update({
        'status': InvitationStatus.declined.value,
        'declinedAt': DateTime.now().millisecondsSinceEpoch,
      });
      return SmoothResponse.success(data: true);
    } catch (e) {
      return SmoothResponse.error(message: 'Error: $e');
    }
  }

  /// Annule une invitation.
  Future<SmoothResponse<bool>> cancelInvitation(String invitationId) async {
    try {
      await _collection.doc(invitationId).update({
        'status': InvitationStatus.cancelled.value,
      });
      return SmoothResponse.success(data: true);
    } catch (e) {
      return SmoothResponse.error(message: 'Error: $e');
    }
  }

  /// Stream des invitations pending pour une organisation.
  Stream<List<Invitation>> streamPendingInvitations(String organizationId) {
    return _collection
        .where('organizationId', isEqualTo: organizationId)
        .where('status', isEqualTo: InvitationStatus.pending.value)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => Invitation.fromMap(d.data(), id: d.id))
            .where((inv) => !inv.isExpired)
            .toList());
  }

  /// Stream des invitations pending pour un email.
  Stream<List<Invitation>> streamMyPendingInvitations(String email) {
    final normalizedEmail = email.toLowerCase().trim();
    return _collection
        .where('email', isEqualTo: normalizedEmail)
        .where('status', isEqualTo: InvitationStatus.pending.value)
        .snapshots()
        .map((s) => s.docs
            .map((d) => Invitation.fromMap(d.data(), id: d.id))
            .where((inv) => !inv.isExpired)
            .toList());
  }

  /// Récupère les invitations pending pour un email (one-time).
  Future<List<Invitation>> getMyPendingInvitations(String email) async {
    final normalizedEmail = email.toLowerCase().trim();
    try {
      final snapshot = await _collection
          .where('email', isEqualTo: normalizedEmail)
          .where('status', isEqualTo: InvitationStatus.pending.value)
          .get();

      return snapshot.docs
          .map((d) => Invitation.fromMap(d.data(), id: d.id))
          .where((inv) => !inv.isExpired)
          .toList();
    } catch (e) {
      debugPrint('Error getting invitations: $e');
      return [];
    }
  }

  /// Récupère une invitation par ID.
  Future<Invitation?> getInvitation(String invitationId) async {
    try {
      final doc = await _collection.doc(invitationId).get();
      if (!doc.exists) return null;
      return Invitation.fromMap(doc.data()!, id: doc.id);
    } catch (e) {
      return null;
    }
  }

  Future<Invitation?> _findPendingInvitation(
      String email, String organizationId) async {
    final snapshot = await _collection
        .where('email', isEqualTo: email)
        .where('organizationId', isEqualTo: organizationId)
        .where('status', isEqualTo: InvitationStatus.pending.value)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final invitation =
        Invitation.fromMap(snapshot.docs.first.data(), id: snapshot.docs.first.id);
    if (invitation.isExpired) return null;
    return invitation;
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    // Random.secure() obligatoire : un PRNG seedé par l'horloge rendrait les
    // codes d'invitation devinables (finding audit 11/08).
    final random = Random.secure();
    final code = String.fromCharCodes(
      Iterable.generate(codeLength, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
    return '$codePrefix-$code';
  }
}
