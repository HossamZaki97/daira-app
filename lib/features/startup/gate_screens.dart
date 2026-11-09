import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/app_settings.dart';
import '../../core/providers.dart';
import '../../design/design.dart';
import '../../l10n/messages.dart';

/// First screen while /app/config loads: the mark with the orbiting segment.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(child: RingLoader(size: 72, semanticLabel: context.l10n.loading)),
  );
}

/// Shown when the backend turned maintenance on.
class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final info = ref.watch(settingsProvider)?.maintenance;
    return _GateScaffold(
      child: MessageView(
        icon: AppIcons.maintenance,
        title: t.maintenanceTitle,
        body: info?.message ?? t.maintenanceBody,
        extra: info?.until == null ? null : StatusChip(t.maintenanceUntil(info!.until!), icon: AppIcons.clock),
        primary: _RetryButton(label: t.retry),
      ),
    );
  }
}

/// This build is blocked: the only way forward is the store.
class UpdateRequiredScreen extends ConsumerWidget {
  const UpdateRequiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final update = ref.watch(settingsProvider)?.update;
    return _GateScaffold(
      child: MessageView(
        icon: AppIcons.update,
        title: t.updateRequiredTitle,
        body: t.updateRequiredBody,
        extra: update?.notes == null ? null : _Notes(title: t.whatsNew, notes: update!.notes!),
        primary: AppButton(
          label: t.updateNow,
          icon: AppIcons.update,
          onPressed: update?.storeUrl == null ? null : () => openStore(update!.storeUrl!),
        ),
        secondary: _RetryButton(label: t.retry, text: true),
      ),
    );
  }
}

/// No connection, or the server did not answer.
class OfflineScreen extends ConsumerWidget {
  const OfflineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final offline = ref.watch(startupProvider.select((s) => s.status)) == StartupStatus.offline;
    return _GateScaffold(
      child: MessageView(
        icon: offline ? AppIcons.offline : AppIcons.warning,
        title: offline ? t.offlineTitle : t.unavailableTitle,
        body: offline ? t.offlineBody : t.unavailableBody,
        primary: _RetryButton(label: t.retry),
      ),
    );
  }
}

/// Optional update offer, shown on top of the app until the person skips it.
class UpdateOfferBanner extends ConsumerWidget {
  const UpdateOfferBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startup = ref.watch(startupProvider);
    final update = startup.settings?.update;
    if (!startup.offerUpdate || update == null) return const SizedBox.shrink();
    final t = context.l10n;
    final from = update.requiredFrom;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: InlineBanner(
        icon: AppIcons.update,
        title: t.updateAvailableTitle,
        body: [
          t.updateAvailableBody(update.latestVersion ?? ''),
          if (from != null) t.updateRequiredFrom(t.date(from)),
        ].join('\n'),
        tone: from != null ? Tone.danger : Tone.info,
        onDismiss: from != null ? null : () => ref.read(startupProvider.notifier).skipUpdate(),
        action: update.storeUrl == null
            ? null
            : Align(
                alignment: AlignmentDirectional.centerStart,
                child: AppButton.text(label: t.updateNow, onPressed: () => openStore(update.storeUrl!)),
              ),
      ),
    );
  }
}

/// Backend announcements (home banner). Dismissed ones stay hidden until restart.
class AnnouncementBanners extends ConsumerStatefulWidget {
  const AnnouncementBanners({super.key});

  @override
  ConsumerState<AnnouncementBanners> createState() => _AnnouncementBannersState();
}

class _AnnouncementBannersState extends ConsumerState<AnnouncementBanners> {
  final _dismissed = <int>{};

  @override
  Widget build(BuildContext context) {
    final items = (ref.watch(settingsProvider)?.announcements ?? const <Announcement>[])
        .where((a) => !_dismissed.contains(a.id))
        .toList();
    return Column(
      children: [
        for (final a in items)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: InlineBanner(
              title: a.title,
              body: a.body,
              tone: a.warning ? Tone.danger : Tone.info,
              icon: a.warning ? AppIcons.warning : AppIcons.info,
              onDismiss: a.dismissible ? () => setState(() => _dismissed.add(a.id)) : null,
            ),
          ),
      ],
    );
  }
}

Future<void> openStore(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !(uri.scheme == 'https' || uri.scheme == 'market' || uri.scheme == 'itms-apps')) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class _GateScaffold extends StatelessWidget {
  const _GateScaffold({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: child));
}

class _RetryButton extends ConsumerWidget {
  const _RetryButton({required this.label, this.text = false});
  final String label;
  final bool text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void retry() => ref.read(startupProvider.notifier).load();
    return text
        ? AppButton.text(label: label, onPressed: retry, icon: AppIcons.refresh)
        : AppButton.secondary(label: label, onPressed: retry, icon: AppIcons.refresh);
  }
}

class _Notes extends StatelessWidget {
  const _Notes({required this.title, required this.notes});
  final String title;
  final String notes;

  @override
  Widget build(BuildContext context) => AppCard(
    color: context.colors.surfaceSunken,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.text.labelLarge),
        const SizedBox(height: Space.xxs),
        Text(notes, style: context.text.bodyMedium?.copyWith(color: context.colors.textMuted)),
      ],
    ),
  );
}
