import 'package:flutter/cupertino.dart';

class ResetConfirmDialog extends StatelessWidget {
  const ResetConfirmDialog({super.key, required this.onConfirm});

  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('Réinitialiser la journée ?'),
      content: const Text(
        "Cela remettra à zéro tes consommations d'aujourd'hui. Tu confirmes ?",
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () async {
            await onConfirm();
          },
          child: const Text('Réinitialiser'),
        ),
      ],
    );
  }
}
