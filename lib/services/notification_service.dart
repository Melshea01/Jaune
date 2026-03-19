import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

enum NotificationType { success, warning, danger, info }

enum MessageTone { encouraging, warning, critical, neutral }

class NotificationService {
  /// Affiche une notification toast en bas de l'écran
  static void showToast(
    BuildContext context,
    String message, {
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final color = _getColorForType(type);
    final icon = _getIconForType(type);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Affiche une alerte modale
  static Future<bool?> showAlert(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'OK',
    String? cancelText,
    bool isDestructive = false,
  }) {
    return showCupertinoDialog<bool>(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              if (cancelText != null)
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(cancelText),
                ),
              CupertinoDialogAction(
                isDestructiveAction: isDestructive,
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(confirmText),
              ),
            ],
          ),
    );
  }

  /// Génère un message motivationnel basé sur les statistiques
  static String generateMotivationalMessage({
    required double healthPercent,
    required int todayConsos,
    required int level,
    MessageTone tone = MessageTone.encouraging,
  }) {
    if (healthPercent > 0.9) {
      return _getHighHealthMessage(level, tone);
    } else if (healthPercent > 0.7) {
      return _getGoodHealthMessage(todayConsos, tone);
    } else if (healthPercent > 0.4) {
      return _getWarningHealthMessage(todayConsos, tone);
    } else {
      return _getCriticalHealthMessage(tone);
    }
  }

  static String _getHighHealthMessage(int level, MessageTone tone) {
    final messages = [
      'Forme olympique ! Niveau $level atteint ! 💪',
      'Tu rayonnes de santé ! Continue comme ça !',
      'Énergie au maximum ! Tu es un exemple à suivre !',
      'Santé de fer ! Ton niveau $level le prouve !',
    ];
    return messages[DateTime.now().millisecond % messages.length];
  }

  static String _getGoodHealthMessage(int todayConsos, MessageTone tone) {
    if (todayConsos == 0) {
      final messages = [
        'Jour sobre, corps content ! 🌟',
        'Aucune consommation aujourd\'hui, bravo !',
        'Ta santé te remercie pour cette pause !',
        'Journée claire, esprit libre !',
      ];
      return messages[DateTime.now().millisecond % messages.length];
    } else {
      final messages = [
        'Consommation modérée, équilibre maintenu !',
        'Tu gardes le contrôle, c\'est parfait !',
        'Bonne gestion de ta consommation !',
        'L\'équilibre est la clé, tu l\'as trouvée !',
      ];
      return messages[DateTime.now().millisecond % messages.length];
    }
  }

  static String _getWarningHealthMessage(int todayConsos, MessageTone tone) {
    final messages = [
      'Attention, ton corps commence à fatiguer...',
      'Il serait temps de lever le pied !',
      'Ta santé demande une pause, écoute-la !',
      'Zone d\'alerte atteinte, sois vigilant !',
    ];
    return messages[DateTime.now().millisecond % messages.length];
  }

  static String _getCriticalHealthMessage(MessageTone tone) {
    final messages = [
      'URGENT : Ton corps a besoin d\'aide !',
      'Zone critique ! Il faut agir maintenant !',
      'Ta santé est en danger, prends soin de toi !',
      'SOS : Ton corps tire la sonnette d\'alarme !',
    ];
    return messages[DateTime.now().millisecond % messages.length];
  }

  /// Génère un conseil personnalisé basé sur les tendances
  static String generateAdvice({
    required double healthPercent,
    required int todayConsos,
    required int weeklyTotal,
    required int drinkingDays,
  }) {
    if (healthPercent < 0.3) {
      return 'Il est temps de faire une pause complète. Consulte un professionnel si tu en ressens le besoin.';
    }

    if (drinkingDays >= 5) {
      return 'Essaie d\'avoir au moins 2 jours sans consommation par semaine.';
    }

    if (weeklyTotal > 14) {
      return 'Ta consommation hebdomadaire dépasse les recommandations. Que dirais-tu de réduire progressivement ?';
    }

    if (todayConsos > 4) {
      return 'Tu as déjà beaucoup bu aujourd\'hui. Pense à boire de l\'eau et à manger !';
    }

    if (healthPercent > 0.8) {
      return 'Tu maintiens un bon équilibre ! Continue sur cette voie.';
    }

    return 'Chaque petit pas compte. Tu peux y arriver !';
  }

  static Color _getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Colors.green.shade600;
      case NotificationType.warning:
        return Colors.orange.shade600;
      case NotificationType.danger:
        return Colors.red.shade600;
      case NotificationType.info:
        return Colors.blue.shade600;
    }
  }

  static IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return CupertinoIcons.check_mark_circled;
      case NotificationType.warning:
        return CupertinoIcons.exclamationmark_triangle;
      case NotificationType.danger:
        return CupertinoIcons.xmark_octagon;
      case NotificationType.info:
        return CupertinoIcons.info_circle;
    }
  }
}

class ToastHelper {
  static void showSuccess(BuildContext context, String message) {
    NotificationService.showToast(
      context,
      message,
      type: NotificationType.success,
    );
  }

  static void showWarning(BuildContext context, String message) {
    NotificationService.showToast(
      context,
      message,
      type: NotificationType.warning,
    );
  }

  static void showDanger(BuildContext context, String message) {
    NotificationService.showToast(
      context,
      message,
      type: NotificationType.danger,
    );
  }

  static void showInfo(BuildContext context, String message) {
    NotificationService.showToast(
      context,
      message,
      type: NotificationType.info,
    );
  }
}
