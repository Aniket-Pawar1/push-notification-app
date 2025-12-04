import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// Service to display in-app notifications
class NotificationDisplayService {
  static final NotificationDisplayService _instance =
      NotificationDisplayService._internal();
  factory NotificationDisplayService() => _instance;
  NotificationDisplayService._internal();

  /// Global key to access navigator context
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Show notification as an overlay banner
  void showNotificationBanner(RemoteMessage message) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final notification = message.notification;
    if (notification == null) return;

    // Show as a material banner or overlay
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black26,
      builder: (BuildContext context) {
        return NotificationDialog(
          title: notification.title ?? 'Notification',
          body: notification.body ?? '',
          imageUrl:
              notification.android?.imageUrl ?? notification.apple?.imageUrl,
          onTap: () {
            Navigator.of(context).pop();
            // Handle notification tap action here
            _handleNotificationAction(message);
          },
        );
      },
    );

    // Auto dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (navigatorKey.currentContext != null) {
        Navigator.of(context).pop();
      }
    });
  }

  /// Show notification as a snackbar (alternative approach)
  void showNotificationSnackbar(RemoteMessage message) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final notification = message.notification;
    if (notification == null) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: NotificationSnackbarContent(
            title: notification.title ?? 'Notification',
            body: notification.body ?? '',
          ),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      // Silently fail if ScaffoldMessenger is not available
      // This can happen during app initialization
    }
  }

  /// Show notification as a top banner (iOS style)
  void showNotificationTopBanner(RemoteMessage message) async {
    print('🎯 showNotificationTopBanner called');
    // Add a small delay to ensure overlay is ready
    await Future.delayed(const Duration(milliseconds: 100));

    final context = navigatorKey.currentContext;
    if (context == null) {
      print('❌ Context is null');
      return;
    }
    print('✅ Context found');

    final notification = message.notification;
    if (notification == null) {
      print('❌ Notification is null');
      return;
    }
    print('✅ Notification found');

    // Check if overlay is available
    try {
      final overlay = Overlay.of(context);
      if (overlay == null) {
        print('❌ Overlay is null');
        return;
      }
      print('✅ Overlay found! Creating banner at TOP position...');

      late OverlayEntry overlayEntry;

      overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: NotificationBannerWidget(
              title: notification.title ?? 'Notification',
              body: notification.body ?? '',
              imageUrl:
                  notification.android?.imageUrl ??
                  notification.apple?.imageUrl,
              onTap: () {
                if (overlayEntry.mounted) {
                  overlayEntry.remove();
                }
                _handleNotificationAction(message);
              },
              onDismiss: () {
                if (overlayEntry.mounted) {
                  overlayEntry.remove();
                }
              },
            ),
          ),
        ),
      );

      overlay.insert(overlayEntry);
      print('✅ Banner inserted into overlay at TOP!');

      // Auto dismiss after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (overlayEntry.mounted) {
          overlayEntry.remove();
        }
      });
    } catch (e) {
      print('❌ Error showing top banner: $e');
      print('⚠️ Falling back to dialog (TOP)');
      // If overlay is not available, fall back to dialog at top
      showNotificationBanner(message);
    }
  }

  /// Handle notification action when tapped
  void _handleNotificationAction(RemoteMessage message) {
    // You can navigate to specific screens based on message data
    // Example:
    // if (message.data['screen'] == 'chat') {
    //   navigatorKey.currentState?.pushNamed('/chat');
    // }
  }
}

/// Notification Dialog Widget
class NotificationDialog extends StatelessWidget {
  final String title;
  final String body;
  final String? imageUrl;
  final VoidCallback onTap;

  const NotificationDialog({
    super.key,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
        ),
        child: Material(
          borderRadius: BorderRadius.circular(16),
          elevation: 8,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.secondaryContainer,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_active,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          body,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Notification Banner Widget (iOS style)
class NotificationBannerWidget extends StatefulWidget {
  final String title;
  final String body;
  final String? imageUrl;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const NotificationBannerWidget({
    super.key,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<NotificationBannerWidget> createState() =>
      _NotificationBannerWidgetState();
}

class _NotificationBannerWidgetState extends State<NotificationBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

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
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: GestureDetector(
        onTap: () async {
          await _controller.reverse();
          widget.onTap();
        },
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! < 0) {
            _dismiss();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.notifications,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
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
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.body,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: _dismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Notification Snackbar Content
class NotificationSnackbarContent extends StatelessWidget {
  final String title;
  final String body;

  const NotificationSnackbarContent({
    super.key,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_active,
            color: Theme.of(context).colorScheme.onInverseSurface,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onInverseSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onInverseSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
