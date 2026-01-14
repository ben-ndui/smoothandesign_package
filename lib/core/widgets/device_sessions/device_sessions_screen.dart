import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/device_session.dart';
import '../../services/base_device_session_service.dart';
import 'device_session_tile.dart';

/// Configuration de localisation pour DeviceSessionsScreen.
class DeviceSessionsScreenStrings {
  final String title;
  final String disconnectAllOthers;
  final String disconnectConfirmTitle;
  final String disconnectConfirmMessage;
  final String disconnectAllConfirmMessage;
  final String cancel;
  final String confirm;
  final String deviceDisconnected;
  final String allDevicesDisconnected;
  final String noDevices;
  final DeviceSessionTileStrings tileStrings;

  const DeviceSessionsScreenStrings({
    this.title = 'Connected devices',
    this.disconnectAllOthers = 'Disconnect all other devices',
    this.disconnectConfirmTitle = 'Disconnect device',
    this.disconnectConfirmMessage = 'Are you sure you want to disconnect this device?',
    this.disconnectAllConfirmMessage = 'Are you sure you want to disconnect all other devices?',
    this.cancel = 'Cancel',
    this.confirm = 'Confirm',
    this.deviceDisconnected = 'Device disconnected',
    this.allDevicesDisconnected = 'All other devices disconnected',
    this.noDevices = 'No connected devices',
    this.tileStrings = const DeviceSessionTileStrings(),
  });
}

/// Écran de gestion des sessions d'appareils.
class DeviceSessionsScreen extends StatefulWidget {
  final String userId;
  final BaseDeviceSessionService service;
  final DeviceSessionsScreenStrings strings;
  final Widget Function(BuildContext, bool isLoading)? loadingBuilder;

  const DeviceSessionsScreen({
    super.key,
    required this.userId,
    required this.service,
    this.strings = const DeviceSessionsScreenStrings(),
    this.loadingBuilder,
  });

  @override
  State<DeviceSessionsScreen> createState() => _DeviceSessionsScreenState();
}

class _DeviceSessionsScreenState extends State<DeviceSessionsScreen> {
  String? _currentDeviceId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentDeviceId();
  }

  Future<void> _loadCurrentDeviceId() async {
    final deviceId = await BaseDeviceSessionService.getStoredDeviceId();
    if (mounted) {
      setState(() => _currentDeviceId = deviceId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(widget.strings.title),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: StreamBuilder<List<DeviceSession>>(
        stream: widget.service.streamUserSessions(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          }

          if (snapshot.hasError) {
            debugPrint('DeviceSessionsScreen error: ${snapshot.error}');
            return _buildError(colorScheme, snapshot.error.toString());
          }

          final sessions = snapshot.data ?? [];

          if (sessions.isEmpty) {
            return _buildEmpty(colorScheme);
          }

          // Sort: current device first, then by lastActiveAt
          sessions.sort((a, b) {
            if (a.deviceId == _currentDeviceId) return -1;
            if (b.deviceId == _currentDeviceId) return 1;
            return b.lastActiveAt.compareTo(a.lastActiveAt);
          });

          final otherDevices = sessions.where((s) => s.deviceId != _currentDeviceId).length;

          return ListView(
            padding: const EdgeInsets.only(top: 16, bottom: 100),
            children: [
              ...sessions.map((session) => DeviceSessionTile(
                    session: session,
                    isCurrent: session.deviceId == _currentDeviceId,
                    strings: widget.strings.tileStrings,
                    onDisconnect: () => _confirmDisconnect(session),
                  )),
              if (otherDevices > 0) ...[
                const SizedBox(height: 24),
                _buildDisconnectAllButton(colorScheme),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoading() {
    if (widget.loadingBuilder != null) {
      return widget.loadingBuilder!(context, true);
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildEmpty(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.devices,
              size: 40,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.strings.noDevices,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ColorScheme colorScheme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisconnectAllButton(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _confirmDisconnectAll,
        icon: Icon(Icons.logout, size: 18, color: colorScheme.error),
        label: Text(widget.strings.disconnectAllOthers),
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.error,
          side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Future<void> _confirmDisconnect(DeviceSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.strings.disconnectConfirmTitle),
        content: Text(widget.strings.disconnectConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(widget.strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              widget.strings.confirm,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      await widget.service.revokeSession(session.id);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.strings.deviceDisconnected)),
        );
      }
    }
  }

  Future<void> _confirmDisconnectAll() async {
    if (_currentDeviceId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.strings.disconnectConfirmTitle),
        content: Text(widget.strings.disconnectAllConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(widget.strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              widget.strings.confirm,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      await widget.service.revokeAllOtherSessions(widget.userId, _currentDeviceId!);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.strings.allDevicesDisconnected)),
        );
      }
    }
  }
}
