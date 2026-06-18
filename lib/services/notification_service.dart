import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// IDs stables des notifications — un slot par usage, le re-scheduling
/// remplace toujours la précédente du même type
const int kAperoNotifId = 1;
const int kStreakNotifId = 2;
const int kLevelTeaserNotifId = 3;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> Function(String payload)? onNotificationTap;

  /// Initialise les notifications locales
  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Pas de demande de permission au lancement : le dialogue système est
    // déclenché par l'onboarding (priming) via requestPermissions(), au
    // moment où l'utilisateur comprend à quoi servent les rappels
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Gérer le clic sur la notification via le callback du widget
        if (response.payload != null && onNotificationTap != null) {
          await onNotificationTap!(response.payload!);
          return;
        }

        if (response.payload == 'be_real_capture') {
          debugPrint(
            'Notification cliquée: ouvrir BeReal capture (callback non configuré)',
          );
        }
      },
    );
  }

  /// Déclenche le dialogue système de permission (iOS et Android 13+).
  /// Appelé depuis l'onboarding et la réactivation dans les réglages.
  static Future<bool> requestPermissions() async {
    try {
      final ios =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();
      if (ios != null) {
        final granted = await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }

      final android =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return granted ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Programme une notification à une heure spécifique
  static Future<void> scheduleNotification({
    int id = kAperoNotifId,
    required DateTime scheduledTime,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'be_real_channel',
          'BeReal Notifications',
          channelDescription: 'Notifications pour les moments BeReal',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: false,
        );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
