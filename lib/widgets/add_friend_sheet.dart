import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/gen/app_localizations.dart';
import '../services/audio_service.dart';
import '../theme/jaune_design.dart';
import 'citron_avatar.dart';
import 'pressable.dart';

/// Schéma du lien d'invitation. La cible web/deep-link réelle sera branchée
/// en Phase 2 (app_links). En Phase 1, le code transite tel quel.
String friendLinkFor(String code) => 'https://jaune.app/add-friend?code=$code';

/// Extrait le `code` d'un lien d'invitation, ou renvoie la valeur brute.
String extractFriendCode(String raw) {
  final uri = Uri.tryParse(raw);
  final fromQuery = uri?.queryParameters['code'];
  return (fromQuery != null && fromQuery.isNotEmpty) ? fromQuery : raw;
}

/// Contenu QR + partage + scan, réutilisable dans un sheet ou en vue embarquée.
/// [onCodeReceived] est appelé après scan réussi — c'est au appelant de gérer
/// la navigation post-réception (pop, changement de vue, etc.).
class AddFriendBody extends StatelessWidget {
  final String myCode;
  final String mySkin;
  final Future<void> Function(String code) onCodeReceived;

  const AddFriendBody({
    super.key,
    required this.myCode,
    required this.mySkin,
    required this.onCodeReceived,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final link = friendLinkFor(myCode);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(JauneRadii.card),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: QrImageView(
            data: link,
            version: QrVersions.auto,
            size: 220,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.circle,
              color: JauneColors.ink,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.circle,
              color: JauneColors.ink,
            ),
            embeddedImage: null,
            embeddedImageStyle: const QrEmbeddedImageStyle(size: Size(56, 56)),
            embeddedImageEmitsError: false,
          ),
        ),
        const SizedBox(height: 14),
        CitronAvatar(size: 52, skin: mySkin),
        const SizedBox(height: 72),
        _PrimaryButton(
          icon: CupertinoIcons.share,
          label: l10n.addFriendShare,
          onTap: () => Share.share(l10n.addFriendShareMessage(link)),
        ),
        const SizedBox(height: 10),
        _SecondaryButton(
          icon: CupertinoIcons.qrcode_viewfinder,
          label: l10n.addFriendScan,
          onTap: () async {
            final code = await Navigator.of(context).push<String>(
              MaterialPageRoute(builder: (_) => const QrScannerPage()),
            );
            if (code == null || code.isEmpty) return;
            await onCodeReceived(extractFriendCode(code));
          },
        ),
      ],
    );
  }
}

/// Sheet autonome « Ajouter un ami » (usage hors classement).
class AddFriendSheet {
  static Future<void> show(
    BuildContext context, {
    required String myCode,
    required String mySkin,
    required Future<void> Function(String code) onCodeReceived,
  }) {
    HapticFeedback.selectionClick();
    AudioService.instance.playUiPop();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _AddFriendSheetContent(
            myCode: myCode,
            mySkin: mySkin,
            onCodeReceived: onCodeReceived,
          ),
    );
  }
}

class _AddFriendSheetContent extends StatelessWidget {
  final String myCode;
  final String mySkin;
  final Future<void> Function(String code) onCodeReceived;

  const _AddFriendSheetContent({
    required this.myCode,
    required this.mySkin,
    required this.onCodeReceived,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: 32 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(JauneRadii.sheet),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.addFriendTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: JauneColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.addFriendSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: JauneColors.inkSoft),
          ),
          const SizedBox(height: 22),
          AddFriendBody(
            myCode: myCode,
            mySkin: mySkin,
            onCodeReceived: (code) async {
              await onCodeReceived(code);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      semanticLabel: label,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [JauneColors.lemon, JauneColors.lemonDeep],
          ),
          borderRadius: BorderRadius.circular(JauneRadii.pill),
          boxShadow: [
            BoxShadow(
              color: JauneColors.lemonDeep.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: JauneColors.ink, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: JauneColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      semanticLabel: label,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: JauneColors.skyLight.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(JauneRadii.pill),
          border: Border.all(
            color: JauneColors.skyDeep.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: JauneColors.skyDeep, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: JauneColors.skyDeep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Plein écran de scan QR. Renvoie la première valeur détectée via [Navigator.pop].
class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage>
    with TickerProviderStateMixin {
  // autoStart laissé par défaut : c'est le widget MobileScanner qui démarre et
  // gère le cycle de vie de la caméra (chemin éprouvé). On ne pilote pas
  // start()/stop() à la main pour ne pas casser l'ouverture de la caméra.
  final MobileScannerController _controller = MobileScannerController();
  late final AnimationController _scanLine; // balayage continu de la ligne
  late final AnimationController _success; // pulse de validation
  bool _handled = false;
  MobileScannerErrorCode? _error;

  @override
  void initState() {
    super.initState();
    _scanLine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _success = AnimationController(vsync: this, duration: JauneMotion.standard);
  }

  @override
  void dispose() {
    _scanLine.dispose();
    _success.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Relance la caméra après une erreur (bouton « Réessayer »).
  Future<void> _retry() async {
    if (mounted) setState(() => _error = null);
    try {
      await _controller.start();
    } catch (_) {
      // L'errorBuilder de MobileScanner ré-affichera l'erreur si besoin.
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);
    if (raw == null) return;
    _handled = true;
    HapticFeedback.mediumImpact();
    AudioService.instance.playUiPop();
    _scanLine.stop();
    // Brève célébration du cadre avant de fermer.
    await _success.forward();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    Navigator.of(context).pop(raw);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final media = MediaQuery.of(context);

    if (_error != null) {
      return _ScannerErrorView(
        code: _error!,
        onRetry: _retry,
        onClose: () => Navigator.of(context).maybePop(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          // Fenêtre de visée carrée, centrée légèrement au-dessus du milieu.
          final window = (w * 0.72).clamp(220.0, 300.0);
          final left = (w - window) / 2;
          final top = (h - window) / 2 - h * 0.05;
          final frame = Rect.fromLTWH(left, top, window, window);

          return Stack(
            children: [
              // Caméra
              Positioned.fill(
                child: MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                  errorBuilder: (context, error, child) {
                    // Surface l'erreur via notre vue dédiée au prochain build.
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && _error != error.errorCode) {
                        setState(() => _error = error.errorCode);
                      }
                    });
                    return const ColoredBox(color: Colors.black);
                  },
                ),
              ),

              // Voile sombre avec découpe sur la fenêtre de visée
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _ScannerScrimPainter(frame)),
                ),
              ),

              // Cadre : coins animés + ligne de balayage
              Positioned.fromRect(
                rect: frame,
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_scanLine, _success]),
                    builder: (context, _) {
                      final success = _success.value;
                      final cornerColor =
                          Color.lerp(
                            JauneColors.lemon,
                            JauneColors.healthVibrant.first,
                            success,
                          )!;
                      return Transform.scale(
                        scale: 1 + 0.04 * Curves.easeOut.transform(success),
                        child: CustomPaint(
                          painter: _ScannerFramePainter(
                            cornerColor: cornerColor,
                            scanProgress: _scanLine.value,
                            showScanLine: !_handled,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Bouton de fermeture (haut gauche)
              Positioned(
                top: media.padding.top + 8,
                left: 12,
                child: _ScannerCircleButton(
                  icon: CupertinoIcons.xmark,
                  semanticLabel:
                      MaterialLocalizations.of(context).closeButtonTooltip,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),

              // Titre (haut centre)
              Positioned(
                top: media.padding.top + 16,
                left: 64,
                right: 64,
                child: Text(
                  l10n.addFriendScanTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),

              // Aide sous le cadre
              Positioned(
                top: frame.bottom + 28,
                left: 32,
                right: 32,
                child: Text(
                  l10n.addFriendScanHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),

              // Torche (bas centre) — reflète l'état réel du matériel.
              // Le bouton reste visible tant que la caméra tourne ; il est
              // simplement désactivé si l'appareil ne fournit pas de torche.
              Positioned(
                bottom: media.padding.bottom + 36,
                left: 0,
                right: 0,
                child: Center(
                  child: ValueListenableBuilder<MobileScannerState>(
                    valueListenable: _controller,
                    builder: (context, state, _) {
                      if (!state.isInitialized || !state.isRunning) {
                        return const SizedBox(height: 60);
                      }
                      final torch = state.torchState;
                      final unavailable = torch == TorchState.unavailable;
                      final on = torch == TorchState.on;
                      return _ScannerCircleButton(
                        icon:
                            on
                                ? CupertinoIcons.bolt_fill
                                : CupertinoIcons.bolt_slash,
                        semanticLabel: l10n.addFriendScanTorch,
                        large: true,
                        active: on,
                        disabled: unavailable,
                        onTap: () async {
                          HapticFeedback.selectionClick();
                          try {
                            await _controller.toggleTorch();
                          } catch (_) {
                            // Torche indisponible : on ignore silencieusement.
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// État affiché quand la caméra ne peut pas démarrer (permission, simulateur,
/// appareil non supporté). Donne une issue claire plutôt qu'un écran noir.
class _ScannerErrorView extends StatelessWidget {
  final MobileScannerErrorCode code;
  final Future<void> Function() onRetry;
  final VoidCallback onClose;

  const _ScannerErrorView({
    required this.code,
    required this.onRetry,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final media = MediaQuery.of(context);
    final isPermission = code == MobileScannerErrorCode.permissionDenied;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned(
            top: media.padding.top + 8,
            left: 12,
            child: _ScannerCircleButton(
              icon: CupertinoIcons.xmark,
              semanticLabel:
                  MaterialLocalizations.of(context).closeButtonTooltip,
              onTap: onClose,
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPermission
                        ? CupertinoIcons.camera_circle
                        : CupertinoIcons.exclamationmark_triangle,
                    size: 56,
                    color: JauneColors.lemon,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.addFriendScanError,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  if (isPermission) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.addFriendScanPermission,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                  const SizedBox(height: 26),
                  PressableScale(
                    semanticLabel: l10n.addFriendScanRetry,
                    onTap: onRetry,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [JauneColors.lemon, JauneColors.lemonDeep],
                        ),
                        borderRadius: BorderRadius.circular(JauneRadii.pill),
                      ),
                      child: Text(
                        l10n.addFriendScanRetry,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: JauneColors.ink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bouton circulaire translucide pour les overlays du scanner.
class _ScannerCircleButton extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;
  final bool large;
  final bool active;
  final bool disabled;

  const _ScannerCircleButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.large = false,
    this.active = false,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = large ? 60.0 : 44.0;
    final bg =
        active ? JauneColors.lemon : Colors.black.withValues(alpha: 0.45);
    final fg = active ? JauneColors.ink : Colors.white;
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: PressableScale(
        semanticLabel: semanticLabel,
        onTap: disabled ? null : onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            boxShadow:
                active
                    ? [
                      BoxShadow(
                        color: JauneColors.lemonDeep.withValues(alpha: 0.5),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ]
                    : null,
          ),
          child: Icon(icon, color: fg, size: large ? 26 : 20),
        ),
      ),
    );
  }
}

/// Assombrit tout l'écran sauf la fenêtre de visée (découpe arrondie).
class _ScannerScrimPainter extends CustomPainter {
  final Rect frame;
  const _ScannerScrimPainter(this.frame);

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      frame,
      const Radius.circular(JauneRadii.card + 6),
    );
    final scrim = Path()..addRect(Offset.zero & size);
    final hole = Path()..addRRect(rrect);
    final overlay = Path.combine(PathOperation.difference, scrim, hole);
    canvas.drawPath(
      overlay,
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );
  }

  @override
  bool shouldRepaint(_ScannerScrimPainter old) => old.frame != frame;
}

/// Dessine les 4 coins du cadre et la ligne de balayage.
class _ScannerFramePainter extends CustomPainter {
  final Color cornerColor;
  final double scanProgress;
  final bool showScanLine;

  const _ScannerFramePainter({
    required this.cornerColor,
    required this.scanProgress,
    required this.showScanLine,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const arm = 30.0;
    const inset = 2.0;
    const r = JauneRadii.card + 6;
    final paint =
        Paint()
          ..color = cornerColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round;

    final l = inset, t = inset;
    final right = size.width - inset, bottom = size.height - inset;

    // Coin haut-gauche
    canvas.drawPath(
      Path()
        ..moveTo(l, t + arm)
        ..lineTo(l, t + r)
        ..arcToPoint(Offset(l + r, t), radius: const Radius.circular(r))
        ..lineTo(l + arm, t),
      paint,
    );
    // Coin haut-droit
    canvas.drawPath(
      Path()
        ..moveTo(right - arm, t)
        ..lineTo(right - r, t)
        ..arcToPoint(Offset(right, t + r), radius: const Radius.circular(r))
        ..lineTo(right, t + arm),
      paint,
    );
    // Coin bas-droit
    canvas.drawPath(
      Path()
        ..moveTo(right, bottom - arm)
        ..lineTo(right, bottom - r)
        ..arcToPoint(
          Offset(right - r, bottom),
          radius: const Radius.circular(r),
        )
        ..lineTo(right - arm, bottom),
      paint,
    );
    // Coin bas-gauche
    canvas.drawPath(
      Path()
        ..moveTo(l + arm, bottom)
        ..lineTo(l + r, bottom)
        ..arcToPoint(Offset(l, bottom - r), radius: const Radius.circular(r))
        ..lineTo(l, bottom - arm),
      paint,
    );

    // Ligne de balayage
    if (showScanLine) {
      final y = (size.height - 24) * scanProgress + 12;
      final glow =
          Paint()
            ..shader = LinearGradient(
              colors: [
                JauneColors.lemon.withValues(alpha: 0),
                JauneColors.lemon.withValues(alpha: 0.9),
                JauneColors.lemon.withValues(alpha: 0),
              ],
            ).createShader(Rect.fromLTWH(14, y - 6, size.width - 28, 12));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(14, y - 1.5, size.width - 28, 3),
          const Radius.circular(2),
        ),
        glow,
      );
    }
  }

  @override
  bool shouldRepaint(_ScannerFramePainter old) =>
      old.scanProgress != scanProgress ||
      old.cornerColor != cornerColor ||
      old.showScanLine != showScanLine;
}
