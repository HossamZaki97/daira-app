import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../design/design.dart';
import '../../l10n/messages.dart';

/// Switches between العربية and English (also changes the server language).
class LanguageButton extends ConsumerWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arabic = ref.watch(localeProvider).languageCode == 'ar';
    final t = context.l10n;
    return TextButton.icon(
      onPressed: () => ref.read(localeProvider.notifier).set(arabic ? 'en' : 'ar'),
      icon: const Icon(AppIcons.language, size: 20),
      // Always offer the *other* language, written in that language.
      label: Text(arabic ? t.english : t.arabic),
    );
  }
}

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final code = ref.watch(localeProvider).languageCode;
    return SegmentedButton<String>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(value: 'ar', label: Text(t.arabic)),
        ButtonSegment(value: 'en', label: Text(t.english)),
      ],
      selected: {code},
      onSelectionChanged: (s) => ref.read(localeProvider.notifier).set(s.first),
    );
  }
}

class ThemeSelector extends ConsumerWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    return SegmentedButton<ThemeMode>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(value: ThemeMode.system, label: Text(t.themeSystem)),
        ButtonSegment(value: ThemeMode.light, label: Text(t.themeLight), icon: const Icon(AppIcons.lightMode, size: 18)),
        ButtonSegment(value: ThemeMode.dark, label: Text(t.themeDark), icon: const Icon(AppIcons.darkMode, size: 18)),
      ],
      selected: {ref.watch(themeModeProvider)},
      onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).set(s.first),
    );
  }
}
