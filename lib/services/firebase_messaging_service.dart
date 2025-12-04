import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'notification_display_service.dart';

/// Background message handler - must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('📱 Background Message Received!');
  log('Message ID: ${message.messageId}');
  log('Title: ${message.notification?.title ?? 'No Title'}');
  log('Body: ${message.notification?.body ?? 'No Body'}');
  log('Data: ${message.data}');
}

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _fcmToken;

  /// Get the current FCM token
  String? get fcmToken => _fcmToken;

  /// Initialize Firebase Messaging
  Future<void> initialize() async {
    try {
      // Request permission for iOS
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      log('🔔 Notification Permission Status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        log('✅ User granted notification permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        log('⚠️ User granted provisional notification permission');
      } else {
        log('❌ User declined or has not accepted notification permission');
      }

      // Get FCM token
      await _getFCMToken();

      // Listen to token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        log('🔄 FCM Token Refreshed: $newToken');
        _fcmToken = newToken;
      });

      // Set up message handlers
      _setupMessageHandlers();

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      log('✅ Firebase Messaging Initialized Successfully');
    } catch (e) {
      log('❌ Error initializing Firebase Messaging: $e');
    }
  }

  /// Get FCM Token
  Future<void> _getFCMToken() async {
    try {
      // For iOS, APNS token is required first
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        String? apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken != null) {
          log('📱 APNS Token: $apnsToken');
        } else {
          log('⚠️ APNS Token not available yet');
          // Wait a bit and try again
          await Future.delayed(const Duration(seconds: 3));
          apnsToken = await _firebaseMessaging.getAPNSToken();
        }
      }

      // Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      
      if (_fcmToken != null) {
        log('🎯 FCM Token Retrieved Successfully!');
        log('═' * 80);
        log('FCM TOKEN: $_fcmToken');
        log('═' * 80);
      } else {
        log('⚠️ FCM Token is null');
      }
    } catch (e) {
      log('❌ Error getting FCM Token: $e');
    }
  }

  /// Setup message handlers for different app states
  void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('📨 Foreground Message Received!');
      log('═' * 80);
      log('Message ID: ${message.messageId}');
      log('Sent Time: ${message.sentTime}');
      
      if (message.notification != null) {
        log('Notification Title: ${message.notification!.title}');
        log('Notification Body: ${message.notification!.body}');
        log('Notification Image: ${message.notification!.android?.imageUrl ?? message.notification!.apple?.imageUrl ?? 'No Image'}');
      }
      
      if (message.data.isNotEmpty) {
        log('Data Payload: ${message.data}');
      }
      
      log('═' * 80);
      // Show in-app notification
      NotificationDisplayService().showNotificationTopBanner(message);
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('🔔 Notification Tapped (App in Background)!');
      log('═' * 80);
      log('Message ID: ${message.messageId}');
      
      if (message.notification != null) {
        log('Notification Title: ${message.notification!.title}');
        log('Notification Body: ${message.notification!.body}');
      }
      
      if (message.data.isNotEmpty) {
        log('Data Payload: ${message.data}');
      }
      
      log('═' * 80);
      
      // Handle navigation or other actions based on notification data
      _handleNotificationTap(message);
    });
  }

  /// Handle notification tap actions
  void _handleNotificationTap(RemoteMessage message) {
    // You can navigate to specific screens based on the notification data
    // Example:
    // if (message.data['type'] == 'chat') {
    //   Navigator.pushNamed(context, '/chat', arguments: message.data);
    // }
    
    log('🎯 Handling notification tap action');
    log('Notification data: ${message.data}');
  }

  /// Check if app was opened from a terminated state via notification
  Future<void> checkInitialMessage() async {
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    
    if (initialMessage != null) {
      log('🚀 App Opened from Terminated State via Notification!');
      log('═' * 80);
      log('Message ID: ${initialMessage.messageId}');
      
      if (initialMessage.notification != null) {
        log('Notification Title: ${initialMessage.notification!.title}');
        log('Notification Body: ${initialMessage.notification!.body}');
      }
      
      if (initialMessage.data.isNotEmpty) {
        log('Data Payload: ${initialMessage.data}');
      }
      
      log('═' * 80);
      
      _handleNotificationTap(initialMessage);
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      log('✅ Subscribed to topic: $topic');
    } catch (e) {
      log('❌ Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      log('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      log('❌ Error unsubscribing from topic $topic: $e');
    }
  }
}
