import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/models/app_settings.dart';
import '../../core/models/circle.dart';
import '../../core/models/json.dart';
import '../../core/models/money.dart';
import '../../core/providers.dart';
import '../../design/design.dart';
import '../../l10n/messages.dart';
import '../common.dart';
import '../state.dart';

class _MemberDraft {
  _MemberDraft(this.id, {String name = '', this.shares = 1}) : name = TextEditingController(text: name);
  final int id;
  final TextEditingController name;
  int shares;
}

class _Turn {
  const _Turn(this.id, this.participant);
  final int id;

  /// 0 = organizer, 1.. = members in the order they were added.
  final int participant;
}

/// Four short steps: basics, members, turn order, review. Also edits a draft.
class CreateCircleScreen extends ConsumerStatefulWidget {
  const CreateCircleScreen({this.draftId, super.key});
  final String? draftId;

  @override
  ConsumerState<CreateCircleScreen> createState() => _CreateCircleScreenState();
}

class _CreateCircleScreenState extends ConsumerState<CreateCircleScreen> {
  static const _steps = 4;
  int _step = 0;
  int _nextId = 0;

  final _name = TextEditingController();
  final _amount = TextEditingController();
  String? _currency;
  Cadence _cadence = Cadence.month;
  int _interval = 1;
  DateTime _start = _today();
  int _myShares = 1;
  final _members = <_MemberDraft>[];
  List<_Turn> _order = [];
  bool _orderTouched = false;
  int _imported = 0;

  Circle? _draft;
  bool _loadingDraft = false;
  Object? _loadError;
  bool _busy = false;
  Object? _error;
  String _commandId = newCommandId();
  final _basicsForm = GlobalKey<FormState>();
  final _membersForm = GlobalKey<FormState>();

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool get _editing => widget.draftId != null;

  @override
  void initState() {
    super.initState();
    if (_editing) {
      _loadDraft();
    } else {
      _members.add(_MemberDraft(_nextId++));
      _resetOrder();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    for (final m in _members) {
      m.name.dispose();
    }
    super.dispose();
  }

  AppSettings? get _settings => ref.read(settingsProvider);
  Limits get _limits => _settings?.limits ?? const Limits();
  Features get _features => _settings?.features ?? const Features();
  int get _maxShares => _features.multiShares ? _limits.maxShares : 1;

  Currency get _currencyInfo {
    final settings = _settings;
    final code = _currency ?? settings?.suggestedCurrency ?? 'EGP';
    return settings?.currency(code) ?? Currency(code: code, decimals: 2);
  }

  int get _totalShares => _myShares + _members.fold(0, (sum, m) => sum + m.shares);

  int? get _amountMinor => Money.parseMinor(_amount.text, _currencyInfo.decimals);

  String _participantName(int index) {
    final t = context.l10n;
    if (index == 0) return t.youName(ref.read(sessionProvider)?.profile.name ?? '');
    final name = _members[index - 1].name.text.trim();
    return name.isEmpty ? t.memberNumber(index) : name;
  }

  // ------------------------------------------------------------ draft
  Future<void> _loadDraft() async {
    setState(() {
      _loadingDraft = true;
      _loadError = null;
    });
    try {
      final c = await ref.read(circlesRepositoryProvider).get(widget.draftId!);
      if (!mounted) return;
      final organizer = c.members.where((m) => m.organizer).firstOrNull;
      final others = c.members.where((m) => !m.organizer).toList();
      final index = <String, int>{if (organizer != null) organizer.id: 0};
      for (final (i, m) in others.indexed) {
        index[m.id] = i + 1;
      }
      setState(() {
        _draft = c;
        _name.text = c.name;
        _amount.text = c.installment.toDecimalString();
        _currency = c.installment.currency;
        _cadence = c.cadence;
        _interval = c.interval;
        _start = c.startDate ?? _today();
        _myShares = organizer?.shares ?? 1;
        _members
          ..clear()
          ..addAll([for (final m in others) _MemberDraft(_nextId++, name: m.name, shares: m.shares)]);
        _order = [for (final r in c.rounds) _Turn(_nextId++, index[r.recipientId] ?? 0)];
        _orderTouched = true;
        _imported = c.rounds.where((r) => r.legacy).length;
      });
    } catch (error) {
      if (mounted) setState(() => _loadError = error);
    } finally {
      if (mounted) setState(() => _loadingDraft = false);
    }
  }

  // ------------------------------------------------------------ order
  void _resetOrder() {
    _order = [
      for (var i = 0; i < _members.length; i++)
        for (var s = 0; s < _members[i].shares; s++) _Turn(_nextId++, i + 1),
      for (var s = 0; s < _myShares; s++) _Turn(_nextId++, 0),
    ];
    _orderTouched = false;
    if (_imported >= _totalShares) _imported = 0;
  }

  /// Members or shares changed: the turn order must be rebuilt.
  void _membersChanged() => setState(_resetOrder);

  // ------------------------------------------------------------ navigation
  bool _validateStep() {
    final t = context.l10n;
    switch (_step) {
      case 0:
        return _basicsForm.currentState?.validate() ?? false;
      case 1:
        final ok = _membersForm.currentState?.validate() ?? false;
        if (!ok) return false;
        if (_totalShares < 2 || _totalShares > _limits.maxTotalShares) {
          showToast(context, t.sharesLimit(_limits.maxTotalShares), tone: Tone.danger);
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _next() {
    if (!_validateStep()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      if (_step == 1 && _order.length != _totalShares) _resetOrder();
      _step = (_step + 1).clamp(0, _steps - 1);
      _error = null;
    });
  }

  void _back() {
    if (_step == 0) {
      _close();
    } else {
      setState(() => _step--);
    }
  }

  Future<void> _close() async {
    final t = context.l10n;
    final dirty = _name.text.isNotEmpty || _amount.text.isNotEmpty || _members.any((m) => m.name.text.isNotEmpty);
    if (dirty && !_editing) {
      final ok = await confirmDialog(context, title: t.discardTitle, body: t.discardBody, confirm: t.discard, danger: true);
      if (!ok) return;
    }
    if (mounted) context.pop();
  }

  // ------------------------------------------------------------ save
  Json _plan({required bool activate}) => {
    'name': _name.text.trim(),
    'amount': Money(_amountMinor ?? 0, currency: _currencyInfo.code, decimals: _currencyInfo.decimals).toDecimalString(),
    'currency': _currencyInfo.code,
    'cadence': _cadence.name,
    'interval': _interval,
    'start_date': '${_start.year.toString().padLeft(4, '0')}-${_start.month.toString().padLeft(2, '0')}-${_start.day.toString().padLeft(2, '0')}',
    'organizer_shares': _myShares,
    'members': [
      for (final m in _members) {'name': m.name.text.trim(), 'shares': m.shares},
    ],
    if (_orderTouched && _features.turnOrder) 'order': [for (final turn in _order) turn.participant],
    if (_imported > 0) 'completed_rounds': _imported,
    'activate': activate,
  };

  Future<void> _save({required bool activate}) async {
    if (_busy) return;
    final t = context.l10n;
    if (activate) {
      final ok = await confirmDialog(context, title: t.startCircleTitle, body: t.startCircleBody, confirm: t.startCircle);
      if (!ok || !mounted) return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final repo = ref.read(circlesRepositoryProvider);
    try {
      Circle circle;
      final draft = _draft;
      if (draft != null) {
        circle = await repo.updateDraft(draft.id, {..._plan(activate: false), 'version': draft.version}, _commandId);
        _commandId = newCommandId();
        _draft = circle;
        if (activate) {
          circle = await repo.activate(circle.id, circle.version, _commandId);
          _commandId = newCommandId();
        }
      } else {
        circle = await repo.create(_plan(activate: activate), _commandId);
        _commandId = newCommandId();
      }
      refreshLists(ref.invalidate);
      ref.invalidate(circleProvider(circle.id));
      if (!mounted) return;
      showToast(context, activate ? t.circleStarted : t.draftSaved, tone: Tone.success);
      context.pushReplacement(Routes.circle(circle.id));
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        if (error.code == 'invalid_start_date' || error.field == 'name' || error.field == 'amount' || error.field == 'currency') {
          _step = 0;
        } else if (error.field == 'members') {
          _step = 1;
        } else if (error.field == 'order') {
          _step = 2;
        }
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _errorText(AppLocalizations t, Object error) {
    if (error is ApiException) {
      if (error.code == 'invalid_start_date') return t.startDatePast;
      if (error.code == 'feature_disabled') return t.featureDisabled;
      if (error.code == 'conflict') return t.draftChanged;
    }
    return t.error(error);
  }

  // ------------------------------------------------------------ build
  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final titles = [t.stepBasics, t.stepMembers, t.stepOrder, t.stepReview];
    if (_loadingDraft) return Scaffold(appBar: AppBar(), body: const LoadingView());
    if (_loadError != null) {
      return Scaffold(appBar: AppBar(), body: LoadError(_loadError!, onRetry: _loadDraft));
    }
    final error = _error;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            icon: const Icon(AppIcons.close),
            onPressed: _close,
          ),
          title: Text(_editing ? t.editDraft : t.newCircle),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(36),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.stepOf(_step + 1, _steps, titles[_step]), style: context.text.labelMedium),
                  const SizedBox(height: Space.xxs),
                  ProgressBar((_step + 1) / _steps),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            if (error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, 0),
                child: InlineBanner(title: _errorText(t, error), tone: Tone.danger),
              ),
            Expanded(
              child: switch (_step) {
                0 => _basics(context),
                1 => _membersStep(context),
                2 => _orderStep(context),
                _ => _review(context),
              },
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, Space.sm),
            child: _step < _steps - 1
                ? Row(
                    children: [
                      if (_step > 0) ...[
                        Expanded(child: AppButton.secondary(label: t.back, onPressed: _back)),
                        const SizedBox(width: Space.sm),
                      ],
                      Expanded(flex: 2, child: AppButton(label: t.next, onPressed: _next)),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppButton(label: t.startCircle, loading: _busy, onPressed: () => _save(activate: true)),
                      const SizedBox(height: Space.xs),
                      AppButton.secondary(
                        label: t.saveDraft,
                        onPressed: _busy ? null : () => _save(activate: false),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------ step 1
  Widget _basics(BuildContext context) {
    final t = context.l10n;
    final settings = ref.watch(settingsProvider);
    final currencies = settings?.currencies ?? const <Currency>[];
    final currency = _currencyInfo;
    return Form(
      key: _basicsForm,
      child: PageBody(
        children: [
          const SizedBox(height: Space.md),
          AppTextField(
            controller: _name,
            label: t.circleName,
            hint: t.circleNameHint,
            icon: AppIcons.circles,
            maxLength: 100,
            textInputAction: TextInputAction.next,
            validator: (v) => (v ?? '').trim().isEmpty ? t.requiredField : null,
          ),
          const SizedBox(height: Space.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: AppTextField(
                  controller: _amount,
                  label: t.installmentPerShare,
                  icon: AppIcons.pay,
                  keyboardType: TextInputType.numberWithOptions(decimal: currency.decimals > 0),
                  textDirection: TextDirection.ltr,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹.,٫٬]'))],
                  onChanged: (_) => setState(() {}),
                  validator: (v) => Money.parseMinor(v ?? '', currency.decimals) == null ? t.amountInvalid : null,
                ),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: currency.code,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: t.currency),
                  items: [
                    for (final c in currencies.isEmpty ? [currency] : currencies)
                      DropdownMenuItem(value: c.code, child: Text(c.code)),
                  ],
                  onChanged: _draft != null && _draft!.status != CircleStatus.draft
                      ? null
                      : (v) => setState(() => _currency = v),
                ),
              ),
            ],
          ),
          SectionHeader(t.cadence),
          SegmentedButton<Cadence>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: Cadence.day, label: Text(t.cadenceDays)),
              ButtonSegment(value: Cadence.week, label: Text(t.cadenceWeeks)),
              ButtonSegment(value: Cadence.month, label: Text(t.cadenceMonths)),
            ],
            selected: {_cadence},
            onSelectionChanged: (s) => setState(() => _cadence = s.first),
          ),
          const SizedBox(height: Space.sm),
          _Stepper(
            label: cadenceLabel(t, _cadence, _interval),
            value: _interval,
            min: 1,
            max: 365,
            onChanged: (v) => setState(() => _interval = v),
          ),
          SectionHeader(t.firstDueDate),
          AppCard(
            onTap: _pickDate,
            child: Row(
              children: [
                const Icon(AppIcons.calendar),
                const SizedBox(width: Space.sm),
                Expanded(child: Text(t.date(_start), style: context.text.bodyLarge)),
                Text(t.change, style: context.text.labelLarge?.copyWith(color: context.colors.primary)),
              ],
            ),
          ),
          const SizedBox(height: Space.xs),
          Text(t.firstDueDateHint, style: context.text.bodySmall),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final today = _today();
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: _features.importHistory ? DateTime(today.year - 10) : today,
      lastDate: DateTime(today.year + 3),
    );
    if (picked != null) setState(() => _start = picked);
  }

  // ------------------------------------------------------------ step 2
  Widget _membersStep(BuildContext context) {
    final t = context.l10n;
    final canAdd = _members.length < _limits.maxMembers;
    return Form(
      key: _membersForm,
      child: PageBody(
        children: [
          const SizedBox(height: Space.md),
          Text(t.membersStepBody, style: context.text.bodyMedium?.copyWith(color: context.colors.textMuted)),
          const SizedBox(height: Space.md),
          AppCard(
            child: Row(
              children: [
                InitialsAvatar(ref.read(sessionProvider)?.profile.name ?? '', highlight: true),
                const SizedBox(width: Space.sm),
                Expanded(child: Text(_participantName(0), style: context.text.titleSmall)),
                if (_maxShares > 1)
                  _SharesControl(
                    value: _myShares,
                    max: _maxShares,
                    onChanged: (v) {
                      _myShares = v;
                      _membersChanged();
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: Space.sm),
          for (final (i, m) in _members.indexed)
            Padding(
              key: ValueKey(m.id),
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: m.name,
                      label: t.memberNumber(i + 1),
                      icon: AppIcons.user,
                      maxLength: 100,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v ?? '').trim().isEmpty ? t.requiredField : null,
                    ),
                  ),
                  if (_maxShares > 1) ...[
                    const SizedBox(width: Space.xs),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: _SharesControl(
                        value: m.shares,
                        max: _maxShares,
                        onChanged: (v) {
                          m.shares = v;
                          _membersChanged();
                        },
                      ),
                    ),
                  ],
                  IconButton(
                    tooltip: t.removeMember,
                    onPressed: _members.length <= 1
                        ? null
                        : () {
                            final removed = _members.removeAt(i);
                            WidgetsBinding.instance.addPostFrameCallback((_) => removed.name.dispose());
                            _membersChanged();
                          },
                    icon: Icon(AppIcons.delete, color: context.colors.textMuted),
                  ),
                ],
              ),
            ),
          AppButton.secondary(
            label: t.addMember,
            icon: AppIcons.add,
            onPressed: canAdd
                ? () {
                    _members.add(_MemberDraft(_nextId++));
                    _membersChanged();
                  }
                : null,
          ),
          const SizedBox(height: Space.md),
          InlineBanner(
            title: t.totalShares(_totalShares),
            body: t.payoutPerRound(
              Money((_amountMinor ?? 0) * _totalShares, currency: _currencyInfo.code, decimals: _currencyInfo.decimals)
                  .format(context.localeName),
            ),
            icon: AppIcons.info,
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ step 3
  Widget _orderStep(BuildContext context) {
    final t = context.l10n;
    final canReorder = _features.turnOrder;
    final colors = context.colors;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.gutter, Space.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(canReorder ? t.orderBody : t.orderFixedBody, style: context.text.bodyMedium?.copyWith(color: colors.textMuted)),
              if (_orderTouched && !_editing)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AppButton.text(label: t.resetOrder, icon: AppIcons.refresh, onPressed: () => setState(_resetOrder)),
                ),
              if (_features.importHistory) ...[
                const SizedBox(height: Space.xs),
                _Stepper(
                  label: _imported == 0 ? t.noImportedRounds : t.importedRounds(_imported),
                  value: _imported,
                  min: 0,
                  max: _totalShares - 1,
                  onChanged: (v) => setState(() => _imported = v),
                ),
                Text(t.importedHint, style: context.text.bodySmall),
              ],
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.xl),
            buildDefaultDragHandles: false,
            itemCount: _order.length,
            onReorderItem: (from, to) {
              if (!canReorder) return;
              setState(() {
                final turn = _order.removeAt(from);
                _order.insert(to, turn);
                _orderTouched = true;
              });
            },
            itemBuilder: (context, i) {
              final turn = _order[i];
              final done = i < _imported;
              return Padding(
                key: ValueKey(turn.id),
                padding: const EdgeInsets.only(bottom: Space.xs),
                child: AppCard(
                  color: done ? colors.surfaceSunken : null,
                  padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm),
                  child: Row(
                    children: [
                      SizedBox(width: 28, child: Text('${i + 1}', style: context.text.labelLarge)),
                      InitialsAvatar(_participantName(turn.participant), size: 32, highlight: turn.participant == 0),
                      const SizedBox(width: Space.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_participantName(turn.participant), style: context.text.titleSmall),
                            Text(t.date(_dueDate(i)), style: context.text.bodySmall),
                          ],
                        ),
                      ),
                      if (done) StatusChip(t.importedRound, tone: Tone.info),
                      if (canReorder)
                        ReorderableDragStartListener(
                          index: i,
                          child: Padding(
                            padding: const EdgeInsets.all(Space.xs),
                            child: Icon(AppIcons.drag, color: colors.textMuted, semanticLabel: t.dragToReorder),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Same rule as the server: months keep the start day (capped at month end).
  DateTime _dueDate(int index) {
    switch (_cadence) {
      case Cadence.day:
        return _start.add(Duration(days: index * _interval));
      case Cadence.week:
        return _start.add(Duration(days: index * _interval * 7));
      case Cadence.month:
        final months = _start.month - 1 + index * _interval;
        final year = _start.year + months ~/ 12;
        final month = months % 12 + 1;
        final last = DateTime(year, month + 1, 0).day;
        return DateTime(year, month, _start.day > last ? last : _start.day);
    }
  }

  // ------------------------------------------------------------ step 4
  Widget _review(BuildContext context) {
    final t = context.l10n;
    final currency = _currencyInfo;
    final perShare = Money(_amountMinor ?? 0, currency: currency.code, decimals: currency.decimals);
    final payout = perShare.times(_totalShares);
    final rows = <(String, String)>[
      (t.installmentPerShare, perShare.format(context.localeName)),
      (t.cadence, cadenceLabel(t, _cadence, _interval)),
      (t.membersLabel, '${_members.length + 1}'),
      (t.roundsLabel, '$_totalShares'),
      (t.firstDueDate, t.date(_start)),
      (t.lastDueDate, t.date(_dueDate(_totalShares - 1))),
      if (_imported > 0) (t.importedLabel, '$_imported'),
    ];
    return PageBody(
      children: [
        const SizedBox(height: Space.md),
        HeroCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_name.text.trim(), style: context.text.titleLarge?.copyWith(color: context.colors.onHero)),
              const SizedBox(height: Space.xs),
              Text(t.eachRoundCollects, style: context.text.bodySmall?.copyWith(color: context.colors.onHeroMuted)),
              AmountText(payout, large: true, color: context.colors.onHero),
            ],
          ),
        ),
        const SizedBox(height: Space.md),
        AppCard(
          child: Column(
            children: [
              for (final (label, value) in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Space.xs),
                  child: Row(
                    children: [
                      Expanded(child: Text(label, style: context.text.bodyMedium?.copyWith(color: context.colors.textMuted))),
                      Text(value, style: context.text.titleSmall),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: Space.md),
        InlineBanner(title: t.reviewNoteTitle, body: t.reviewNoteBody, icon: AppIcons.info),
      ],
    );
  }
}

/// − value + control for counts (interval, imported rounds).
class _Stepper extends StatelessWidget {
  const _Stepper({required this.label, required this.value, required this.min, required this.max, required this.onChanged});
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.xxs),
    child: Row(
      children: [
        Expanded(child: Text(label, style: context.text.bodyLarge)),
        _SharesControl(value: value, min: min, max: max, onChanged: onChanged),
      ],
    ),
  );
}

class _SharesControl extends StatelessWidget {
  const _SharesControl({required this.value, required this.max, required this.onChanged, this.min = 1});
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: t.decrease,
          visualDensity: VisualDensity.compact,
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(AppIcons.remove, size: 18),
        ),
        SizedBox(
          width: 28,
          child: Text('$value', textAlign: TextAlign.center, style: context.text.titleSmall),
        ),
        IconButton(
          tooltip: t.increase,
          visualDensity: VisualDensity.compact,
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(AppIcons.add, size: 18),
        ),
      ],
    );
  }
}
