import 'package:flutter/material.dart';
import '../../models/device_session.dart';

/// Configuration de localisation pour DeviceSessionTile.
class DeviceSessionTileStrings {
  final String thisDevice;
  final String activeNow;
  final String Function(String timeAgo) activeAgo;
  final String disconnect;

  const DeviceSessionTileStrings({
    this.thisDevice = 'This device',
    this.activeNow = 'Active now',
    this.activeAgo = _defaultActiveAgo,
    this.disconnect = 'Disconnect',
  });

  static String _defaultActiveAgo(String timeAgo) => 'Active $timeAgo';
}

/// Tuile représentant une session d'appareil.
class DeviceSessionTile extends StatelessWidget {
  final DeviceSession session;
  final bool isCurrent;
  final VoidCallback? onDisconnect;
  final DeviceSessionTileStrings strings;

  const DeviceSessionTile({
    super.key,
    required this.session,
    required this.isCurrent,
    this.onDisconnect,
    this.strings = const DeviceSessionTileStrings(),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          _buildDeviceIcon(colorScheme),
          const SizedBox(width: 16),
          Expanded(child: _buildDeviceInfo(colorScheme)),
          if (!isCurrent && onDisconnect != null)
            _buildDisconnectButton(colorScheme),
        ],
      ),
    );
  }

  Widget _buildDeviceIcon(ColorScheme colorScheme) {
    final IconData icon;
    switch (session.deviceType) {
      case DeviceType.ios:
        icon = Icons.phone_iphone;
      case DeviceType.android:
        icon = Icons.phone_android;
      case DeviceType.web:
        icon = Icons.language;
      case DeviceType.unknown:
        icon = Icons.devices;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: colorScheme.onPrimaryContainer, size: 24),
    );
  }

  Widget _buildDeviceInfo(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                session.deviceName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isCurrent) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  strings.thisDevice,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          session.deviceDetails,
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (session.locationDisplay != null) ...[
          const SizedBox(height: 2),
          Text(
            session.locationDisplay!,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          _formatLastActive(),
          style: TextStyle(
            fontSize: 12,
            color: isCurrent || session.inactiveDuration.inMinutes < 5
                ? Colors.green
                : colorScheme.onSurfaceVariant,
            fontWeight: isCurrent ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildDisconnectButton(ColorScheme colorScheme) {
    return TextButton(
      onPressed: onDisconnect,
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.error,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        strings.disconnect,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }

  String _formatLastActive() {
    if (isCurrent || session.inactiveDuration.inMinutes < 2) {
      return strings.activeNow;
    }

    final duration = session.inactiveDuration;

    if (duration.inMinutes < 60) {
      return strings.activeAgo('${duration.inMinutes}m');
    } else if (duration.inHours < 24) {
      return strings.activeAgo('${duration.inHours}h');
    } else if (duration.inDays < 7) {
      return strings.activeAgo('${duration.inDays}d');
    } else {
      final weeks = duration.inDays ~/ 7;
      return strings.activeAgo('${weeks}w');
    }
  }
}
