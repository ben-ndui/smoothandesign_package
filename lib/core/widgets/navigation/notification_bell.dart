import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../firebase/smooth_firebase.dart';

/// Notification bell icon with badge based on unread notifications count.
///
/// Supports two styles:
/// - Default: For light backgrounds
/// - Glass: For dark backgrounds with glassmorphism effect
///
/// Usage:
/// ```dart
/// NotificationBell(
///   userId: currentUser.uid,
///   onTap: () => navigateToNotifications(),
///   useGlassStyle: false,
/// )
/// ```
class NotificationBell extends StatelessWidget {
  final String userId;
  final VoidCallback onTap;

  /// Use glass style (for dark backgrounds).
  final bool useGlassStyle;

  /// Collection name for notifications (default: 'user_notifications').
  final String collection;

  /// Custom unread count stream (if not using default Firestore query).
  final Stream<int>? unreadCountStream;

  const NotificationBell({
    super.key,
    required this.userId,
    required this.onTap,
    this.useGlassStyle = false,
    this.collection = 'user_notifications',
    this.unreadCountStream,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (unreadCountStream != null) {
      return StreamBuilder<int>(
        stream: unreadCountStream,
        builder: (context, snapshot) {
          final hasUnread = (snapshot.data ?? 0) > 0;
          if (useGlassStyle) {
            return _buildGlassStyle(hasUnread);
          }
          return _buildDefaultStyle(theme, hasUnread);
        },
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: SmoothFirebase.collection(collection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final hasUnread = (snapshot.data?.docs.length ?? 0) > 0;

        if (useGlassStyle) {
          return _buildGlassStyle(hasUnread);
        }
        return _buildDefaultStyle(theme, hasUnread);
      },
    );
  }

  Widget _buildDefaultStyle(ThemeData theme, bool hasUnread) {
    return Stack(
      children: [
        Material(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: FaIcon(
                FontAwesomeIcons.bell,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        if (hasUnread)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGlassStyle(bool hasUnread) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasUnread
                    ? const Color(0xFFF43F5E).withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.2),
                width: hasUnread ? 2 : 1,
              ),
              boxShadow: hasUnread
                  ? [
                      BoxShadow(
                        color: const Color(0xFFF43F5E).withValues(alpha: 0.3),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                const Center(
                  child: FaIcon(FontAwesomeIcons.bell, size: 18, color: Colors.white),
                ),
                if (hasUnread)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF43F5E).withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
