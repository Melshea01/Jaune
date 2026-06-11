import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/citron_animation_controller.dart';
import '../l10n/gen/app_localizations.dart';
import '../main.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';
import '../theme/jaune_design.dart';
import '../widgets/citron_character.dart';
import '../widgets/health_bar.dart';
import '../widgets/pressable.dart';

const String kOnboardingDoneKey = 'onboarding_done';

/// Premier lancement : 3 écrans — le concept, la santé (avec avertissement),
/// et le BeJaune avec priming de la permission de notification (le dialogue
/// système n'apparaît qu'après le CTA, jamais à froid).
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  late final CitronAnimationController _citronController;
  int _page = 0;
  bool _remindersEnabled = false;

  @override
  void initState() {
    super.initState();
    _citronController = CitronAnimationController();
    _citronController.updateHealth(100);
    _citronController.idleMood = 'happy';
    _citronController.playSpecialAnimation('greeting');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _citronController.dispose();
    super.dispose();
  }

  void _next() {
    HapticFeedback.selectionClick();
    _pageController.nextPage(
      duration: JauneMotion.standard,
      curve: JauneMotion.smooth,
    );
  }

  Future<void> _enableReminders() async {
    HapticFeedback.mediumImpact();
    final granted = await NotificationService.requestPermissions();
    await SettingsService.instance.setNotificationsEnabled(granted);
    if (granted && mounted) {
      setState(() => _remindersEnabled = true);
      // Laisse le ✓ s'afficher un instant avant d'entrer dans l'app
      await Future.delayed(const Duration(milliseconds: 600));
    }
    await _finish();
  }

  Future<void> _skipReminders() async {
    await SettingsService.instance.setNotificationsEnabled(false);
    await _finish();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kOnboardingDoneKey, true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: JauneMotion.standard,
        pageBuilder: (_, __, ___) => const MyHomePage(),
        transitionsBuilder:
            (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // Même gradient que la home : continuité visuelle parfaite
          gradient: LinearGradient(
            colors: [JauneColors.sky, JauneColors.skyLight, Colors.white],
            stops: [0.0, 0.45, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) => setState(() => _page = page),
                  children: [
                    _OnboardingPage(
                      title: l10n.onboarding1Title,
                      text: l10n.onboarding1Text,
                      illustration: Center(
                        child: CitronCharacter(controller: _citronController),
                      ),
                    ),
                    _OnboardingPage(
                      title: l10n.onboarding2Title,
                      text: l10n.onboarding2Text,
                      illustration: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const IgnorePointer(
                              child: HealthBar(percent: 0.86, level: 3),
                            ),
                            const SizedBox(height: 28),
                            const Text('🍻', style: TextStyle(fontSize: 64)),
                          ],
                        ),
                      ),
                      footer: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(JauneRadii.card),
                        ),
                        child: Row(
                          children: [
                            const Text('⚕️', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l10n.onboardingDisclaimer,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: JauneColors.inkSoft,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _OnboardingPage(
                      title: l10n.onboarding3Title,
                      text: l10n.onboarding3Text,
                      illustration: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('📸', style: TextStyle(fontSize: 72)),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    JauneColors.flameLight,
                                    JauneColors.flame,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                '17h – 20h 🍋',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Points de progression
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final active = i == _page;
                  return AnimatedContainer(
                    duration: JauneMotion.quick,
                    curve: JauneMotion.smooth,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color:
                          active
                              ? JauneColors.lemonDeep
                              : JauneColors.inkSoft.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // CTA selon la page
              Padding(
                padding: const EdgeInsets.only(left: 32, right: 32, bottom: 24),
                child: AnimatedSwitcher(
                  duration: JauneMotion.quick,
                  child: switch (_page) {
                    0 => _PrimaryButton(
                      key: const ValueKey('next'),
                      label: l10n.onboardingNext,
                      onTap: _next,
                    ),
                    1 => _PrimaryButton(
                      key: const ValueKey('ack'),
                      label: l10n.onboardingDisclaimerAck,
                      onTap: _next,
                    ),
                    _ => Column(
                      key: const ValueKey('reminders'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _PrimaryButton(
                          label:
                              _remindersEnabled
                                  ? l10n.onboardingRemindersEnabled
                                  : l10n.onboardingEnableReminders,
                          onTap: _remindersEnabled ? null : _enableReminders,
                        ),
                        CupertinoButton(
                          onPressed: _skipReminders,
                          child: Text(
                            l10n.onboardingLater,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: JauneColors.inkSoft,
                            ),
                          ),
                        ),
                      ],
                    ),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final String title;
  final String text;
  final Widget illustration;
  final Widget? footer;

  const _OnboardingPage({
    required this.title,
    required this.text,
    required this.illustration,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: illustration),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: JauneColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: JauneColors.inkSoft,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (footer != null) footer!,
        const SizedBox(height: 16),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _PrimaryButton({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [JauneColors.lemon, JauneColors.lemonDeep],
          ),
          borderRadius: BorderRadius.circular(JauneRadii.pill),
          boxShadow: [
            BoxShadow(
              color: JauneColors.lemon.withValues(alpha: 0.5),
              offset: const Offset(0, 6),
              blurRadius: 16,
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
