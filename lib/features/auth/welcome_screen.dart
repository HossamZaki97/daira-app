import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../design/design.dart';
import '../../l10n/messages.dart';
import '../settings/preference_controls.dart';

/// First screen for signed-out people: what Daira is, in three short lines.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(actions: const [LanguageButton(), SizedBox(width: Space.xs)]),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Sizes.maxContent),
            child: FillScrollView(
              padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  const Center(child: DairaMark(size: 96)),
                  const SizedBox(height: Space.xl),
                  Text(t.welcomeTitle, textAlign: TextAlign.center, style: context.text.displaySmall),
                  const SizedBox(height: Space.xs),
                  Text(
                    t.welcomeBody,
                    textAlign: TextAlign.center,
                    style: context.text.bodyLarge?.copyWith(color: colors.textMuted),
                  ),
                  const SizedBox(height: Space.xl),
                  _Point(icon: AppIcons.calendar, text: t.welcomePoint1),
                  _Point(icon: AppIcons.confirmed, text: t.welcomePoint2),
                  _Point(icon: AppIcons.turn, text: t.welcomePoint3),
                  const Spacer(flex: 2),
                  AppButton(label: t.createAccount, onPressed: () => context.push(Routes.signUp)),
                  const SizedBox(height: Space.sm),
                  AppButton.secondary(label: t.signIn, onPressed: () => context.push(Routes.signIn)),
                  const SizedBox(height: Space.md),
                  Text.rich(
                    TextSpan(
                      text: t.welcomeTermsPrefix,
                      children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: GestureDetector(
                            onTap: () => context.push(Routes.content('terms')),
                            child: Text(
                              t.terms,
                              style: context.text.bodySmall?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: context.text.bodySmall,
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

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Space.xs),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: context.colors.primaryContainer, shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: context.colors.onPrimaryContainer),
        ),
        const SizedBox(width: Space.md),
        Expanded(child: Text(text, style: context.text.bodyLarge)),
      ],
    ),
  );
}
