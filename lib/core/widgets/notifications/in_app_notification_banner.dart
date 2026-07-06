import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Configuration for notification type styling
class NotificationTypeConfig {
  final FaIconData icon;
  final Color? color;

  const NotificationTypeConfig({
    required this.icon,
    this.color,
  });
}

/// Generic in-app notification banner widget.
///
/// Shows a slide-down banner when a push notification arrives while the app
/// is in foreground. Configurable icons and colors per notification type.
class InAppNotificationBanner {
  static OverlayEntry? _currentOverlay;
  static bool _isShowing = false;

  /// Default icon/color mapping for common notification types
  static Map<String, NotificationTypeConfig> defaultTypeConfigs = {
    'new_message': const NotificationTypeConfig(icon: FontAwesomeIcons.message),
    'session_assigned': const NotificationTypeConfig(icon: FontAwesomeIcons.calendarCheck),
    'session_updated': const NotificationTypeConfig(icon: FontAwesomeIcons.calendarCheck),
    'booking_confirmed': const NotificationTypeConfig(icon: FontAwesomeIcons.ticket),
    'booking_updated': const NotificationTypeConfig(icon: FontAwesomeIcons.ticket),
    'mission_assigned': const NotificationTypeConfig(icon: FontAwesomeIcons.briefcase),
    'client_mission_request': const NotificationTypeConfig(icon: FontAwesomeIcons.userClock),
    'contract_invitation': const NotificationTypeConfig(icon: FontAwesomeIcons.fileContract),
    'contract_signed': const NotificationTypeConfig(icon: FontAwesomeIcons.fileContract),
    'payment_received': const NotificationTypeConfig(icon: FontAwesomeIcons.moneyBill),
    'invoice_sent': const NotificationTypeConfig(icon: FontAwesomeIcons.fileInvoice),
    'quote_accepted': const NotificationTypeConfig(icon: FontAwesomeIcons.fileCircleCheck),
    'team_invitation': const NotificationTypeConfig(icon: FontAwesomeIcons.userPlus),
  };

  /// Show a notification banner
  ///
  /// [context] - BuildContext for overlay insertion
  /// [message] - The FCM RemoteMessage
  /// [onTap] - Callback when banner is tapped (for navigation)
  /// [typeConfigs] - Optional custom type configurations
  /// [autoDismissSeconds] - Auto-dismiss delay (default 4 seconds)
  static void show(
    BuildContext context,
    RemoteMessage message, {
    VoidCallback? onTap,
    Map<String, NotificationTypeConfig>? typeConfigs,
    int autoDismissSeconds = 4,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showBanner(
        context,
        message,
        onTap: onTap,
        typeConfigs: typeConfigs ?? defaultTypeConfigs,
        autoDismissSeconds: autoDismissSeconds,
      );
    });
  }

  static void _showBanner(
    BuildContext context,
    RemoteMessage message, {
    VoidCallback? onTap,
    required Map<String, NotificationTypeConfig> typeConfigs,
    required int autoDismissSeconds,
  }) {
    if (_isShowing) {
      _currentOverlay?.remove();
      _currentOverlay = null;
      _isShowing = false;
    }

    final notification = message.notification;
    final data = message.data;
    final title = notification?.title ?? data['title'] ?? 'Notification';
    final body = notification?.body ?? data['body'] ?? '';
    final type = data['type'] as String?;

    final overlay = Navigator.of(context, rootNavigator: true).overlay;
    if (overlay == null) return;

    final config = typeConfigs[type];

    _currentOverlay = OverlayEntry(
      builder: (overlayContext) => _NotificationBannerWidget(
        title: title,
        body: body,
        icon: config?.icon ?? FontAwesomeIcons.bell,
        accentColor: config?.color,
        onTap: () {
          _dismiss();
          onTap?.call();
        },
        onDismiss: _dismiss,
      ),
    );

    _isShowing = true;
    overlay.insert(_currentOverlay!);

    Future.delayed(Duration(seconds: autoDismissSeconds), () {
      if (_isShowing) _dismiss();
    });
  }

  static void _dismiss() {
    _currentOverlay?.remove();
    _currentOverlay = null;
    _isShowing = false;
  }

  /// Dismiss any showing banner
  static void dismiss() => _dismiss();
}

class _NotificationBannerWidget extends StatefulWidget {
  final String title;
  final String body;
  final FaIconData icon;
  final Color? accentColor;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationBannerWidget({
    required this.title,
    required this.body,
    required this.icon,
    this.accentColor,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_NotificationBannerWidget> createState() => _NotificationBannerWidgetState();
}

class _NotificationBannerWidgetState extends State<_NotificationBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = widget.accentColor ?? colorScheme.primary;

    return Positioned(
      top: topPadding + 8,
      left: 12,
      right: 12,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: widget.onTap,
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
                widget.onDismiss();
              }
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: FaIcon(
                          widget.icon,
                          size: 18,
                          color: accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.body.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.body,
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: widget.onDismiss,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
