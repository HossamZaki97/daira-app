import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_tokens.dart';
import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/components.dart';
import '../../shared/formatters.dart';
import '../../shared/identity.dart';
import '../circles/circle_details_screen.dart';
import '../circles/circle_presentation.dart';
import '../circles/create_circle_screen.dart';
import '../circles/payment_sheet.dart';
import '../invitations/invitation_sheets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  int _tab = 0;
  String? _filter;
  bool _logoutBusy = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pending(ref.read(pendingInviteProvider));
    });
  }

  void _pending(String? code) {
    if (!mounted || code == null) return;
    ref.read(pendingInviteProvider.notifier).state = null;
    openJoin(context, code: code);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref.read(circlesProvider.notifier).refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _open(Circle circle) => Navigator.push<void>(
    context,
    MaterialPageRoute(builder: (_) => CircleDetailsScreen(id: circle.id)),
  );
  void _create() => Navigator.push<void>(
    context,
    MaterialPageRoute(builder: (_) => const CreateCircleScreen()),
  );

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final user = ref.watch(authProvider).profile;
    if (user == null) return const SizedBox.shrink();
    final data = ref.watch(circlesProvider);
    final sync = ref.watch(syncStatusProvider);
    final circles = data.asData?.value ?? <Circle>[];
    final actions = actionsFor(circles, user['id'] as String);
    ref.listen(pendingInviteProvider, (_, next) => _pending(next));
    final titles = [t.appName, t.circles, t.actions, t.settings];
    return Scaffold(
      appBar: AppBar(
        title: _tab == 0
            ? Row(
                children: [
                  const DairaMark(size: 40),
                  const SizedBox(width: 8),
                  Expanded(child: Text(t.appName)),
                ],
              )
            : Text(titles[_tab]),
        actions: [
          if (_tab != 3)
            IconButton(
              tooltip: t.retry,
              onPressed: sync.refreshing
                  ? null
                  : ref.read(circlesProvider.notifier).refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        height: MediaQuery.textScalerOf(context).scale(14) > 18
            ? AppSizes.navigationHeightLargeText
            : AppSizes.navigationHeight,
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: t.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.groups_outlined),
            selectedIcon: const Icon(Icons.groups_rounded),
            label: t.circles,
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: actions.isNotEmpty,
              label: Text('${actions.length}'),
              child: const Icon(Icons.inbox_outlined),
            ),
            label: t.actions,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: t.settings,
          ),
        ],
      ),
      body: SafeArea(
        child: _tab == 3
            ? _settings(t, user)
            : data.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: SingleChildScrollView(
                    child: FailureView(
                      error,
                      ref.read(circlesProvider.notifier).refresh,
                    ),
                  ),
                ),
                data: (circles) {
                  final ordered = [...circles]
                    ..sort((a, b) {
                      int rank(Circle c) => c.status == 'active'
                          ? 0
                          : c.status == 'draft'
                          ? 1
                          : 2;
                      final rankOrder = rank(a).compareTo(rank(b));
                      return rankOrder != 0
                          ? rankOrder
                          : a.name.compareTo(b.name);
                    });
                  final visible = _tab == 0
                      ? ordered.take(3)
                      : ordered.where(
                          (c) => _filter == null || c.status == _filter,
                        );
                  return RefreshIndicator(
                    onRefresh: ref.read(circlesProvider.notifier).refresh,
                    child: ListView(
                      key: PageStorageKey('home-tab-$_tab'),
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        if (sync.error != null)
                          SurfaceCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(t.syncPending),
                                TextButton(
                                  onPressed: ref
                                      .read(circlesProvider.notifier)
                                      .refresh,
                                  child: Text(t.retry),
                                ),
                              ],
                            ),
                          ),
                        if (_tab == 0) ...[
                          Text(
                            t.greeting(user['name'] as String),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          if (sync.updated != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 4,
                                bottom: 16,
                              ),
                              child: Text(
                                t.lastSync(
                                  DateUtils.isSameDay(
                                        sync.updated,
                                        DateTime.now(),
                                      )
                                      ? timeLabel(sync.updated!, t.localeName)
                                      : timestampLabel(
                                          sync.updated!.toIso8601String(),
                                          t.localeName,
                                        ),
                                ),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: context.dairaColors.textMuted,
                                    ),
                              ),
                            ),
                          if (circles.isNotEmpty && actions.isEmpty)
                            SurfaceCard(child: Text(t.nothingRequired)),
                          for (var i = 0; i < actions.length && i < 3; i++)
                            _actionCard(t, actions[i], primary: i == 0),
                          if (actions.length > 3)
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: TextButton(
                                onPressed: () => setState(() => _tab = 2),
                                child: Text(t.allActions),
                              ),
                            ),
                        ],
                        if (_tab != 2) ...[
                          if (circles.isEmpty) ...[
                            const SizedBox(height: 28),
                            Text(
                              t.noCirclesTitle,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            const SizedBox(height: 16),
                          ],
                          if (_tab == 1 || circles.isEmpty) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                FilledButton.icon(
                                  onPressed: _create,
                                  icon: const Icon(Icons.add),
                                  label: Text(t.createCircle),
                                ),
                                OutlinedButton(
                                  onPressed: () => openJoin(context),
                                  child: Text(t.joinInvite),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_tab == 0 && circles.isNotEmpty)
                            SectionHeading(
                              t.circles,
                              action: t.allCircles(circles.length),
                              onPressed: () => setState(() => _tab = 1),
                            ),
                          if (_tab == 1)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final entry in [
                                    (null, t.allFilter),
                                    ('active', t.activeFilter),
                                    ('draft', t.draftFilter),
                                    ('completed', t.completedFilter),
                                  ])
                                    FilterChip(
                                      label: Text(
                                        t.filterCount(
                                          entry.$2,
                                          circles
                                              .where(
                                                (c) =>
                                                    entry.$1 == null ||
                                                    c.status == entry.$1,
                                              )
                                              .length,
                                        ),
                                      ),
                                      selected: _filter == entry.$1,
                                      onSelected: (_) =>
                                          setState(() => _filter = entry.$1),
                                    ),
                                ],
                              ),
                            ),
                          for (final circle in visible) _circleCard(t, circle),
                        ],
                        if (_tab == 2)
                          ..._actions(
                            t,
                            circles,
                            user['id'] as String,
                            actions,
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _actionCard(
    AppLocalizations t,
    ActionItem action, {
    bool primary = false,
  }) {
    final colors = context.dairaColors;
    final amount = action.circle.amount(
      (action.obligation?['amount_minor'] ?? action.round['expected_minor'])
          as int,
      t.localeName,
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (primary)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              t.requiredActions,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: colors.onHeroMuted),
            ),
          ),
        Text(
          action.circle.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: primary ? colors.onHero : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${t.roundOf(action.round['number'] as int, action.circle.rounds.length)} · ${dateLabel(action.round['due_date'] as String, t.localeName)}',
          style: TextStyle(
            color: primary ? colors.onHeroMuted : colors.textMuted,
          ),
        ),
        if (action.action == 'report' &&
            overdue(action.round['due_date'] as String))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: StatusPill(t.overdue, tone: StatusTone.danger),
            ),
          ),
        if (action.obligation != null &&
            action.obligation!['member_id'] != action.circle.actor)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              action.obligation!['member'] as String,
              style: TextStyle(color: primary ? colors.onHero : null),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          amount,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: primary ? colors.onHero : null,
          ),
        ),
        const SizedBox(height: 16),
        if (primary)
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.onHero,
              foregroundColor: colors.heroSurface,
            ),
            onPressed: () => openAction(context, action),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                actionLabel(t, action.action),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          OutlinedButton(
            onPressed: () => openAction(context, action),
            child: Text(
              actionLabel(t, action.action),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
    return primary
        ? Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: colors.heroSurface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: content,
          )
        : SurfaceCard(child: content);
  }

  Widget _circleCard(AppLocalizations t, Circle circle) {
    final view = CirclePresentation(circle);
    final own = view.ownObligation;
    return Semantics(
      button: true,
      child: SurfaceCard(
        child: InkWell(
          onTap: () => _open(circle),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Text(
                    circle.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  StatusPill(
                    switch (circle.status) {
                      'draft' => t.draft,
                      'completed' => t.completed,
                      _ => t.active,
                    },
                    tone: circle.status == 'completed'
                        ? StatusTone.success
                        : circle.status == 'draft'
                        ? StatusTone.neutral
                        : StatusTone.info,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (view.current != null) ...[
                Text(
                  view.receiving ? t.yourReceivingTurn : t.currentRecipient,
                  style: TextStyle(color: context.dairaColors.textMuted),
                ),
                Text(
                  view.current!['recipient'] as String,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '${t.roundOf(view.current!['number'] as int, circle.rounds.length)} · ${dateLabel(view.current!['due_date'] as String, t.localeName)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                if (own != null)
                  InfoLine(
                    t.ownContribution,
                    own['state'] == 'approved'
                        ? t.approved
                        : own['state'] == 'reported'
                        ? t.reported
                        : circle.amount(
                            own['amount_minor'] as int,
                            t.localeName,
                          ),
                  ),
              ] else
                Text(
                  circle.status == 'draft' ? t.continueSetup : t.circleFinished,
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _actions(
    AppLocalizations t,
    List<Circle> circles,
    String user,
    List<ActionItem> actions,
  ) {
    final waiting = waitingObligations(circles, user),
        recent = recentApprovals(circles);
    final roundWaiting = circles
        .where(
          (c) =>
              c.status == 'active' &&
              c.current?['state'] == 'payoutReported' &&
              c.current?['recipient_id'] != c.actor,
        )
        .toList();
    Widget summary(ObligationSummary item) => SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            item.circle.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(item.obligation['member'] as String),
          InfoLine(
            installmentStatus(t, item.obligation['state'] as String),
            item.circle.amount(
              item.obligation['amount_minor'] as int,
              t.localeName,
            ),
          ),
        ],
      ),
    );
    return [
      if (actions.isEmpty &&
          waiting.isEmpty &&
          recent.isEmpty &&
          roundWaiting.isEmpty) ...[
        const SizedBox(height: 32),
        Icon(
          Icons.task_alt_rounded,
          size: 48,
          color: context.dairaColors.actionPrimary,
        ),
        const SizedBox(height: 16),
        Text(t.noActionsTitle, style: Theme.of(context).textTheme.titleLarge),
        Text(t.nothingRequired),
      ],
      if (actions.isNotEmpty) SectionHeading(t.requiredActions),
      for (final action in actions) _actionCard(t, action),
      if (waiting.isNotEmpty || roundWaiting.isNotEmpty)
        SectionHeading(t.waitingOthers),
      for (final item in waiting) summary(item),
      for (final circle in roundWaiting)
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(circle.name, style: Theme.of(context).textTheme.titleMedium),
              Text(t.awaitingReceipt),
              Text(circle.current!['recipient'] as String),
            ],
          ),
        ),
      if (recent.isNotEmpty) SectionHeading(t.recentlyCompleted),
      for (final item in recent) summary(item),
    ];
  }

  Widget _settings(AppLocalizations t, Json user) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      SectionHeading(t.settingsAccount),
      SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              user['name'] as String,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(user['email'] as String, textDirection: TextDirection.ltr),
            TextButton(
              onPressed: _logoutBusy
                  ? null
                  : () async {
                      setState(() => _logoutBusy = true);
                      try {
                        ref.read(pendingInviteProvider.notifier).state = null;
                        await ref.read(authProvider.notifier).logout();
                      } catch (_) {
                        /* Local credentials have been cleared even if remote logout is offline. */
                      } finally {
                        if (mounted) setState(() => _logoutBusy = false);
                      }
                    },
              child: Text(t.logout),
            ),
          ],
        ),
      ),
      SectionHeading(t.appearance),
      SurfaceCard(
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t.darkMode),
              value: ref.watch(themeProvider) == ThemeMode.dark,
              onChanged: (value) {
                ref.read(themeProvider.notifier).state = value
                    ? ThemeMode.dark
                    : ThemeMode.light;
                savePreference('dark', value);
              },
            ),
            const Divider(),
            DropdownButtonFormField<String>(
              initialValue: ref.watch(localeProvider).languageCode,
              isExpanded: true,
              decoration: InputDecoration(labelText: t.language),
              items: [
                DropdownMenuItem(value: 'ar', child: Text(t.arabic)),
                DropdownMenuItem(value: 'en', child: Text(t.english)),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(localeProvider.notifier).state = Locale(value);
                  savePreference('language', value);
                }
              },
            ),
          ],
        ),
      ),
    ],
  );
}
