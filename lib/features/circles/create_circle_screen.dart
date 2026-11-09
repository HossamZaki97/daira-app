import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/components.dart';
import '../../shared/formatters.dart';

class CreateCircleScreen extends ConsumerStatefulWidget {
  const CreateCircleScreen({this.draft, super.key});
  final Circle? draft;
  @override
  ConsumerState<CreateCircleScreen> createState() => _CreateCircleScreenState();
}

class _MemberInput {
  _MemberInput({String label = '', int count = 1})
    : name = TextEditingController(text: label),
      shares = TextEditingController(text: '$count');
  final TextEditingController name, shares;
  void dispose() {
    name.dispose();
    shares.dispose();
  }
}

class _CreateCircleScreenState extends ConsumerState<CreateCircleScreen> {
  var _form = GlobalKey<FormState>();
  final _scroll = ScrollController();
  final _name = TextEditingController(),
      _amount = TextEditingController(),
      _interval = TextEditingController(text: '1'),
      _shares = TextEditingController(text: '1');
  final _members = <_MemberInput>[];
  late final String _id;
  DateTime _start = DateTime.now();
  String _currency = 'EGP', _cadence = 'month';
  int _step = 0;
  bool _draft = false,
      _busy = false,
      _expanded = false,
      _confirming = false,
      _stale = false;
  Object? _failure;
  CommandRequest? _pending;
  bool get _locked => _busy || _pending != null;
  int get _decimals {
    final metadata = rows(
      ref.read(metadataProvider).asData?.value['currencies'],
    );
    return metadata
                .where((c) => c['code'] == _currency)
                .firstOrNull?['decimals']
            as int? ??
        (_currency == 'JPY'
            ? 0
            : _currency == 'KWD'
            ? 3
            : 2);
  }

  int get _total =>
      _countValue(_shares.text) +
      _members.fold(0, (n, m) => n + _countValue(m.shares.text));
  int _countValue(String value) => int.tryParse(normalizeNumber(value)) ?? 0;
  @override
  void initState() {
    super.initState();
    final draft = widget.draft;
    final unresolved = ref
        .read(pendingCommandsProvider)
        .values
        .where((r) => r.action == 'save' && r.body['version'] == null)
        .firstOrNull;
    _id = draft?.id ?? unresolved?.body['id'] as String? ?? commandId();
    if (draft != null) {
      _name.text = draft.name;
      _currency = draft.currency;
      _cadence = draft.data['cadence'] as String;
      _interval.text = '${draft.data['interval']}';
      _start = DateTime.parse(draft.data['start_date'] as String);
      final digits = (draft.data['installment_minor'] as int)
          .toString()
          .padLeft(draft.decimals + 1, '0');
      _amount.text = draft.decimals == 0
          ? digits
          : '${digits.substring(0, digits.length - draft.decimals)}.${digits.substring(digits.length - draft.decimals)}';
      _shares.text =
          '${draft.members.firstWhere((m) => m['organizer'] == true)['shares']}';
      for (final member in draft.members.where((m) => m['organizer'] != true)) {
        _members.add(
          _MemberInput(
            label: member['name'] as String,
            count: member['shares'] as int,
          ),
        );
      }
      _draft = true;
    }
    if (_members.isEmpty) _members.add(_MemberInput());
    _pending = ref.read(pendingCommandsProvider)['save:$_id'];
    if (_pending != null) {
      final body = _pending!.body;
      _name.text = body['name'] as String;
      _amount.text = body['amount'] as String;
      _currency = body['currency'] as String;
      _cadence = body['cadence'] as String;
      _interval.text = '${body['interval']}';
      _shares.text = '${body['organizer_shares']}';
      _start = DateTime.parse(body['start_date'] as String);
      _draft = body['activate'] != true;
      for (final m in _members) {
        m.dispose();
      }
      _members.clear();
      for (final m in rows(body['members'])) {
        _members.add(
          _MemberInput(label: m['name'] as String, count: m['shares'] as int),
        );
      }
      _step = 3;
      _failure = const ApiFailure('offline');
    }
  }

  void _go(int step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _step = step;
      _form = GlobalKey<FormState>();
      _failure = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _next() {
    if (!_form.currentState!.validate()) return;
    if (_step == 1 && (_total < 2 || _total > 120)) {
      setState(() => _failure = const ApiFailure('invalid_shares'));
      return;
    }
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    if (_step == 2 &&
        _start.isBefore(today) &&
        !(widget.draft?.rounds.any((r) => r['legacy'] == true) ?? false)) {
      setState(() => _failure = const ApiFailure('invalid_start_date'));
      return;
    }
    _go(_step + 1);
  }

  String? _required(String? value) => value?.trim().isNotEmpty == true
      ? null
      : AppLocalizations.of(context).requiredField;
  String? _count(String? value) =>
      _countValue(value ?? '') >= 1 && _countValue(value ?? '') <= 20
      ? null
      : AppLocalizations.of(context).countInvalid(1, 20);
  Future<void> _save() async {
    if (_busy || _confirming || _stale) return;
    final t = AppLocalizations.of(context);
    if (_pending == null) {
      if (!_form.currentState!.validate() ||
          _total < 2 ||
          _total > 120 ||
          (parseMinor(_amount.text, _decimals) ?? 0) * _total >
              9000000000000000) {
        setState(() => _failure = const ApiFailure('invalid_amount'));
        return;
      }
      if (!_draft) {
        _confirming = true;
        final confirmed = await confirmAction(
          context,
          t.activate,
          t.activationNotice,
        );
        if (!mounted) return;
        _confirming = false;
        if (!confirmed) return;
      }
      _pending = CommandRequest('save', {
        'id': _id,
        if (widget.draft != null) 'version': widget.draft!.version,
        'name': _name.text.trim(),
        'amount': normalizeNumber(_amount.text),
        'currency': _currency,
        'cadence': _cadence,
        'interval': _countValue(_interval.text),
        'organizer_shares': _countValue(_shares.text),
        'start_date':
            '${_start.year}-${_start.month.toString().padLeft(2, '0')}-${_start.day.toString().padLeft(2, '0')}',
        'activate': !_draft,
        if (widget.draft != null)
          'completed_rounds': widget.draft!.rounds
              .where((r) => r['legacy'] == true)
              .length,
        'members': [
          for (final m in _members)
            {'name': m.name.text.trim(), 'shares': _countValue(m.shares.text)},
        ],
      });
      ref.read(pendingCommandsProvider.notifier).state = {
        ...ref.read(pendingCommandsProvider),
        'save:$_id': _pending!,
      };
    }
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      await ref
          .read(circlesProvider.notifier)
          .command(_pending!.action, _pending!.body);
      if (!mounted) return;
      ref.read(pendingCommandsProvider.notifier).state = {
        ...ref.read(pendingCommandsProvider),
      }..remove('save:$_id');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.saved)));
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      if (error is ApiFailure &&
          {
            'invalid_input',
            'invalid_start_date',
            'conflict',
            'forbidden',
            'rate_limited',
          }.contains(error.code)) {
        ref.read(pendingCommandsProvider.notifier).state = {
          ...ref.read(pendingCommandsProvider),
        }..remove('save:$_id');
        _pending = null;
        _stale = {'conflict', 'forbidden'}.contains(error.code);
      }
      setState(() => _failure = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _name.dispose();
    _amount.dispose();
    _interval.dispose();
    _shares.dispose();
    for (final m in _members) {
      m.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context),
        metadata = ref.watch(metadataProvider);
    final currencies = rows(metadata.asData?.value['currencies']);
    final titles = [t.basicsStep, t.membersStep, t.scheduleStep, t.reviewStep];
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: Text(t.createCircle)),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.stepOf(_step + 1, 4),
                      style: TextStyle(color: context.dairaColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (var i = 0; i < 4; i++)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsetsDirectional.only(end: 4),
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: i <= _step
                                      ? context.dairaColors.actionPrimary
                                      : context.dairaColors.borderSubtle,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      titles[_step],
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_step == 0) ...[
                          TextFormField(
                            key: const Key('circle-name'),
                            controller: _name,
                            enabled: !_locked,
                            maxLength: 100,
                            validator: _required,
                            decoration: InputDecoration(
                              labelText: t.circleName,
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const Key('circle-amount'),
                            controller: _amount,
                            enabled: !_locked,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (v) =>
                                parseMinor(v ?? '', _decimals) != null
                                ? null
                                : t.amountInvalid,
                            decoration: InputDecoration(
                              labelText: t.installment,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _currency,
                            isExpanded: true,
                            decoration: InputDecoration(labelText: t.currency),
                            items: [
                              for (final code in <String>{
                                _currency,
                                ...(currencies.isEmpty
                                    ? [
                                        'USD',
                                        'EGP',
                                        'SAR',
                                        'AED',
                                        'KWD',
                                        'EUR',
                                        'JPY',
                                      ]
                                    : currencies.map(
                                        (c) => c['code'] as String,
                                      )),
                              })
                                DropdownMenuItem(
                                  value: code,
                                  child: Text(code),
                                ),
                            ],
                            onChanged: _locked
                                ? null
                                : (v) => setState(() => _currency = v!),
                          ),
                        ],
                        if (_step == 1) ...[
                          TextFormField(
                            controller: _shares,
                            enabled: !_locked,
                            keyboardType: TextInputType.number,
                            validator: _count,
                            decoration: InputDecoration(
                              labelText: t.organizerShares,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            t.orderHint,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 16),
                          for (var i = 0; i < _members.length; i++)
                            SurfaceCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextFormField(
                                    controller: _members[i].name,
                                    enabled: !_locked,
                                    maxLength: 100,
                                    validator: _required,
                                    decoration: InputDecoration(
                                      labelText: '${t.memberName} ${i + 1}',
                                      counterText: '',
                                    ),
                                  ),
                                  TextFormField(
                                    controller: _members[i].shares,
                                    enabled: !_locked,
                                    keyboardType: TextInputType.number,
                                    validator: _count,
                                    decoration: InputDecoration(
                                      labelText: t.shares,
                                    ),
                                  ),
                                  if (_members.length > 1)
                                    Align(
                                      alignment: AlignmentDirectional.centerEnd,
                                      child: IconButton(
                                        tooltip: t.deleteMember,
                                        onPressed: _locked
                                            ? null
                                            : () => setState(
                                                () => _members
                                                    .removeAt(i)
                                                    .dispose(),
                                              ),
                                        icon: const Icon(
                                          Icons.person_remove_outlined,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          TextButton.icon(
                            onPressed: _locked || _members.length >= 60
                                ? null
                                : () => setState(
                                    () => _members.add(_MemberInput()),
                                  ),
                            icon: const Icon(Icons.person_add_alt),
                            label: Text(t.addMember),
                          ),
                        ],
                        if (_step == 2) ...[
                          DropdownButtonFormField<String>(
                            initialValue: _cadence,
                            isExpanded: true,
                            decoration: InputDecoration(labelText: t.cadence),
                            items: [
                              DropdownMenuItem(
                                value: 'day',
                                child: Text(t.days),
                              ),
                              DropdownMenuItem(
                                value: 'week',
                                child: Text(t.weeks),
                              ),
                              DropdownMenuItem(
                                value: 'month',
                                child: Text(t.months),
                              ),
                            ],
                            onChanged: _locked
                                ? null
                                : (v) => setState(() => _cadence = v!),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _interval,
                            enabled: !_locked,
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                _countValue(v ?? '') >= 1 &&
                                    _countValue(v ?? '') <= 365
                                ? null
                                : t.countInvalid(1, 365),
                            decoration: InputDecoration(labelText: t.interval),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _locked
                                ? null
                                : () async {
                                    final now = DateTime.now(),
                                        today = DateTime(
                                          DateTime.now().year,
                                          DateTime.now().month,
                                          DateTime.now().day,
                                        );
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _start.isBefore(today)
                                          ? today
                                          : _start,
                                      firstDate: today,
                                      lastDate: DateTime(
                                        now.year + 10,
                                        now.month,
                                        now.day,
                                      ),
                                    );
                                    if (picked != null && mounted) {
                                      setState(() => _start = picked);
                                    }
                                  },
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: Text(
                              '${t.startDate}: ${dateLabel(_start.toIso8601String(), t.localeName)}',
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._schedule(t),
                        ],
                        if (_step == 3) ...[
                          SurfaceCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  _name.text,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                InfoLine(
                                  t.installment,
                                  money(
                                    parseMinor(_amount.text, _decimals) ?? 0,
                                    _currency,
                                    _decimals,
                                    t.localeName,
                                  ),
                                ),
                                InfoLine(
                                  t.roundAmount,
                                  money(
                                    (parseMinor(_amount.text, _decimals) ?? 0) *
                                        _total,
                                    _currency,
                                    _decimals,
                                    t.localeName,
                                  ),
                                ),
                                InfoLine(
                                  t.members,
                                  t.memberCount(_members.length + 1),
                                ),
                                InfoLine(t.shares, t.shareCount(_total)),
                                InfoLine(t.rounds, '$_total'),
                                TextButton(
                                  onPressed: _locked ? null : () => _go(0),
                                  child: Text(t.edit),
                                ),
                              ],
                            ),
                          ),
                          SectionHeading(t.membersStep),
                          for (final entry in [
                            (
                              ref.read(authProvider).profile?['name']
                                      as String? ??
                                  '',
                              _countValue(_shares.text),
                            ),
                            ..._members.map(
                              (m) => (m.name.text, _countValue(m.shares.text)),
                            ),
                          ])
                            InfoLine(entry.$1, t.shareCount(entry.$2)),
                          TextButton(
                            onPressed: _locked ? null : () => _go(1),
                            child: Text(t.edit),
                          ),
                          SectionHeading(t.schedulePreview),
                          ..._schedule(t),
                          TextButton(
                            onPressed: _locked ? null : () => _go(2),
                            child: Text(t.edit),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(t.saveDraft),
                            value: _draft,
                            onChanged: _locked
                                ? null
                                : (v) => setState(() => _draft = v),
                          ),
                        ],
                        if (_failure != null)
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              _pending != null
                                  ? t.unknownOutcome
                                  : errorText(t, _failure!),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PrimaryButton(
                      key: const Key('create-next'),
                      label: _pending != null
                          ? t.resolveRequest
                          : _step < 3
                          ? t.continueLabel
                          : _draft
                          ? t.saveDraft
                          : t.activate,
                      loading: _busy,
                      onPressed: _stale
                          ? null
                          : _step < 3
                          ? _locked
                                ? null
                                : _next
                          : _save,
                    ),
                    if (_step > 0)
                      TextButton(
                        onPressed: _locked ? null : () => _go(_step - 1),
                        child: Text(t.back),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _schedule(AppLocalizations t) {
    final interval = _countValue(_interval.text);
    if (interval < 1 || interval > 365 || _total < 2 || _total > 120) return [];
    final names = [
      for (final m in _members)
        for (var i = 0; i < _countValue(m.shares.text); i++) m.name.text,
      for (var i = 0; i < _countValue(_shares.text); i++)
        ref.read(authProvider).profile?['name'] as String? ?? '',
    ];
    return [
      for (var i = 0; i < names.length && (_expanded || i < 3); i++)
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${t.round} ${i + 1} · ${names[i]}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                dateLabel(
                  scheduleDate(_start, _cadence, interval, i).toIso8601String(),
                  t.localeName,
                ),
              ),
            ],
          ),
        ),
      if (names.length > 3)
        TextButton(
          onPressed: () => setState(() => _expanded = !_expanded),
          child: Text(_expanded ? t.hideSchedule : t.viewSchedule),
        ),
    ];
  }
}
