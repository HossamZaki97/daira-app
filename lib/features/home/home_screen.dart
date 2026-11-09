import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/components.dart';
import '../circles/circle_details_screen.dart';
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
  bool _logoutBusy = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _pending(ref.read(pendingInviteProvider)),
    );
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final user = ref.watch(authProvider).profile!;
    final data = ref.watch(circlesProvider);
    ref.listen(pendingInviteProvider, (_, next) => _pending(next));
    final actions = actionsFor(data.asData?.value ?? [], user['id'] as String);
    final titles = [t.home, t.circles, t.actions, t.settings];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_tab]),
        actions: [
          if (_tab != 3)
            IconButton(
              tooltip: t.retry,
              onPressed: ref.read(circlesProvider.notifier).refresh,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: t.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.groups_outlined),
            selectedIcon: const Icon(Icons.groups),
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
            selectedIcon: const Icon(Icons.settings),
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
                  child: FailureView(
                    error,
                    ref.read(circlesProvider.notifier).refresh,
                  ),
                ),
                data: (circles) => RefreshIndicator(
                  onRefresh: ref.read(circlesProvider.notifier).refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (_tab == 0) ...[
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: context.dairaColors.heroSurface,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.welcome,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: context.dairaColors.onHero,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                user['name'] as String,
                                style: TextStyle(
                                  color: context.dairaColors.onHero,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                t.homeBody,
                                style: TextStyle(
                                  color: context.dairaColors.onHeroMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (actions.isEmpty)
                          SurfaceCard(child: Text(t.nothingRequired)),
                        for (final action in actions.take(3))
                          _actionCard(t, action),
                        if (actions.length > 3)
                          TextButton(
                            onPressed: () => setState(() => _tab = 2),
                            child: Text(t.allActions),
                          ),
                      ],
                      if (_tab != 2) ...[
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            FilledButton.icon(
                              onPressed: () => Navigator.push<void>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CreateCircleScreen(),
                                ),
                              ),
                              icon: const Icon(Icons.add),
                              label: Text(t.createCircle),
                            ),
                            OutlinedButton(
                              onPressed: () => openJoin(context),
                              child: Text(t.joinInvite),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (circles.isEmpty)
                          SurfaceCard(child: Text(t.noCircles)),
                        for (final circle in circles) _circleCard(t, circle),
                      ],
                      if (_tab == 2) ...[
                        if (actions.isNotEmpty)
                          Text(
                            t.requiredActions,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        for (final action in actions) _actionCard(t, action),
                        ..._waitingAndCompleted(
                          t,
                          circles,
                          user['id'] as String,
                        ),
                        if (actions.isEmpty &&
                            _waitingAndCompleted(
                              t,
                              circles,
                              user['id'] as String,
                            ).isEmpty)
                          SurfaceCard(child: Text(t.nothingRequired)),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _actionCard(AppLocalizations t, ActionItem action) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          action.circle.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          '${t.round} ${action.round['number']} • ${action.round['due_date']}',
        ),
        if (action.obligation != null)
          Text(action.obligation!['member'] as String),
        Text(
          action.circle.amount(
            (action.obligation?['amount_minor'] ??
                    action.round['expected_minor'])
                as int,
            t.localeName,
          ),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        TextButton(
          onPressed: () => openAction(context, action),
          child: Text(actionLabel(t, action.action)),
        ),
      ],
    ),
  );
  Widget _circleCard(AppLocalizations t, Circle circle) => SurfaceCard(
    child: InkWell(
      onTap: () => Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => CircleDetailsScreen(id: circle.id)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(circle.name, style: Theme.of(context).textTheme.titleLarge),
          Text(switch (circle.status) {
            'draft' => t.draft,
            'completed' => t.completed,
            _ => t.active,
          }),
          Text(
            '${t.members}: ${circle.members.length} • ${t.rounds}: ${circle.rounds.length}',
          ),
          Text(
            circle.amount(
              circle.data['installment_minor'] as int,
              t.localeName,
            ),
          ),
        ],
      ),
    ),
  );
  List<Widget> _waitingAndCompleted(
    AppLocalizations t,
    List<Circle> circles,
    String user,
  ) {
    final waiting = <Widget>[], completed = <Widget>[];
    for (final circle in circles) {
      for (final round in circle.rounds) {
        for (final obligation in rows(round['obligations'])) {
          if (obligation['state'] == 'reported' &&
                  obligation['member_id'] == circle.actor &&
                  !circle.isOrganizer(user) ||
              obligation['state'] == 'pending' &&
                  obligation['member_id'] != circle.actor &&
                  circle.isOrganizer(user) &&
                  round['number'] == circle.current?['number']) {
            waiting.add(
              SurfaceCard(
                child: Text(
                  '${circle.name} • ${obligation['member']}\n${installmentStatus(t, obligation['state'] as String)}',
                ),
              ),
            );
          }
          if (obligation['state'] == 'approved' &&
              obligation['historical'] != true &&
              completed.length < 5) {
            completed.add(
              SurfaceCard(
                child: Text(
                  '${circle.name} • ${obligation['member']}\n${circle.amount(obligation['amount_minor'] as int, t.localeName)}',
                ),
              ),
            );
          }
        }
      }
    }
    return [
      if (waiting.isNotEmpty) ...[
        Text(t.waitingOthers, style: Theme.of(context).textTheme.titleLarge),
        ...waiting,
      ],
      if (completed.isNotEmpty) ...[
        Text(
          t.recentlyCompleted,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        ...completed,
      ],
    ];
  }

  Widget _settings(AppLocalizations t, Json user) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
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
