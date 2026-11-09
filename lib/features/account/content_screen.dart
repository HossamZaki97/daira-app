import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/app_settings.dart';
import '../../core/providers.dart';
import '../../design/design.dart';
import '../../l10n/messages.dart';
import '../common.dart';

final _contentProvider = FutureProvider.autoDispose.family<ContentPage, (String, String)>(
  (ref, key) => ref.watch(appRepositoryProvider).content(key.$1),
);

/// FAQ, help, terms and privacy — written by staff in the backend, in both languages.
class ContentScreen extends ConsumerWidget {
  const ContentScreen({required this.slug, super.key});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    // The language is part of the key so switching language reloads the text.
    final key = (slug, ref.watch(localeProvider).languageCode);
    final page = ref.watch(_contentProvider(key));
    final title = switch (slug) {
      'faq' => t.faq,
      'help' => t.help,
      'terms' => t.terms,
      'privacy' => t.privacy,
      _ => t.appName,
    };
    final expandable = slug == 'faq' || slug == 'help';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: page.when(
        loading: () => const LoadingView(),
        error: (e, _) => LoadError(e, onRetry: () => ref.invalidate(_contentProvider(key))),
        data: (p) => p.items.isEmpty
            ? MessageView(icon: AppIcons.document, title: t.contentEmpty)
            : PageBody(
                children: [
                  for (final item in p.items)
                    if (expandable)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Space.sm),
                        child: AppCard(
                          padding: EdgeInsets.zero,
                          child: ExpansionTile(
                            shape: const Border(),
                            collapsedShape: const Border(),
                            title: Text(item.title, style: context.text.titleSmall),
                            childrenPadding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
                            expandedCrossAxisAlignment: CrossAxisAlignment.start,
                            children: [Text(item.body, style: context.text.bodyMedium)],
                          ),
                        ),
                      )
                    else ...[
                      const SizedBox(height: Space.md),
                      Text(item.title, style: context.text.titleMedium),
                      const SizedBox(height: Space.xs),
                      SelectableText(item.body, style: context.text.bodyMedium?.copyWith(height: 1.7)),
                    ],
                  if (p.updatedAt != null) ...[
                    const SizedBox(height: Space.xl),
                    Text(t.lastUpdated(t.date(p.updatedAt!)), style: context.text.bodySmall),
                  ],
                ],
              ),
      ),
    );
  }
}
