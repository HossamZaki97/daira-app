import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/models.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/components.dart';

class CreateCircleScreen extends ConsumerStatefulWidget {
  const CreateCircleScreen({super.key});
  @override
  ConsumerState<CreateCircleScreen> createState() => _CreateCircleScreenState();
}

class _MemberInput {
  final name = TextEditingController(),
      shares = TextEditingController(text: '1');
  void dispose() {
    name.dispose();
    shares.dispose();
  }
}

class _CreateCircleScreenState extends ConsumerState<CreateCircleScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _amount = TextEditingController(),
      _interval = TextEditingController(text: '1'),
      _shares = TextEditingController(text: '1');
  final _members = [_MemberInput()];
  DateTime _start = DateTime.now();
  String _currency = 'USD', _cadence = 'month';
  bool _draft = false, _busy = false;
  Object? _failure;
  final _id = commandId();
  String? _command;
  String? _submitted;
  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    final body = <String, dynamic>{
      'id': _id,
      'name': _name.text.trim(),
      'amount': _amount.text.trim(),
      'currency': _currency,
      'cadence': _cadence,
      'interval': int.parse(_interval.text),
      'organizer_shares': int.parse(_shares.text),
      'start_date':
          '${_start.year}-${_start.month.toString().padLeft(2, '0')}-${_start.day.toString().padLeft(2, '0')}',
      'activate': !_draft,
      'members': [
        for (final member in _members)
          {
            'name': member.name.text.trim(),
            'shares': int.parse(member.shares.text),
          },
      ],
    };
    final signature = body.toString();
    if (_submitted != signature) {
      _submitted = signature;
      _command = commandId();
    }
    try {
      await ref.read(circlesProvider.notifier).command('save', {
        ...body,
        'command_id': _command,
      });
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) setState(() => _failure = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _required(String? value) => value?.trim().isNotEmpty == true
      ? null
      : AppLocalizations.of(context).requiredField;
  String? _count(String? value) {
    final count = int.tryParse(value ?? '');
    return count != null && count >= 1 && count <= 20
        ? null
        : AppLocalizations.of(context).requiredField;
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _interval.dispose();
    _shares.dispose();
    for (final member in _members) {
      member.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final currencies = rows(
      ref.watch(metadataProvider).asData?.value['currencies'],
    );
    return Scaffold(
      appBar: AppBar(title: Text(t.createCircle)),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _name,
                enabled: !_busy,
                maxLength: 100,
                validator: _required,
                decoration: InputDecoration(labelText: t.circleName),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amount,
                enabled: !_busy,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) =>
                    RegExp(r'^\d+(\.\d{1,3})?$').hasMatch(value ?? '') &&
                        (num.tryParse(value!) ?? 0) > 0
                    ? null
                    : t.requiredField,
                decoration: InputDecoration(labelText: t.installment),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _currency,
                isExpanded: true,
                decoration: InputDecoration(labelText: t.currency),
                items: [
                  for (final code
                      in currencies.isEmpty
                          ? ['USD', 'EGP', 'SAR', 'AED', 'KWD', 'EUR', 'JPY']
                          : currencies.map((c) => c['code'] as String))
                    DropdownMenuItem(value: code, child: Text(code)),
                ],
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _currency = value!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _cadence,
                isExpanded: true,
                decoration: InputDecoration(labelText: t.cadence),
                items: [
                  DropdownMenuItem(value: 'day', child: Text(t.days)),
                  DropdownMenuItem(value: 'week', child: Text(t.weeks)),
                  DropdownMenuItem(value: 'month', child: Text(t.months)),
                ],
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _cadence = value!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _interval,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                validator: (value) =>
                    int.tryParse(value ?? '') != null &&
                        int.parse(value!) >= 1 &&
                        int.parse(value) <= 365
                    ? null
                    : t.requiredField,
                decoration: InputDecoration(labelText: t.interval),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _start,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 1),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 3650),
                          ),
                        );
                        if (picked != null && mounted) {
                          setState(() => _start = picked);
                        }
                      },
                child: Text(
                  '${t.startDate}: ${MaterialLocalizations.of(context).formatMediumDate(_start)}',
                ),
              ),
              TextFormField(
                controller: _shares,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                validator: _count,
                decoration: InputDecoration(labelText: t.organizerShares),
              ),
              const SizedBox(height: 20),
              Text(t.members, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(t.orderHint),
              const SizedBox(height: 12),
              for (var index = 0; index < _members.length; index++)
                SurfaceCard(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _members[index].name,
                        enabled: !_busy,
                        maxLength: 100,
                        validator: _required,
                        decoration: InputDecoration(
                          labelText: '${t.memberName} ${index + 1}',
                        ),
                      ),
                      TextFormField(
                        controller: _members[index].shares,
                        enabled: !_busy,
                        keyboardType: TextInputType.number,
                        validator: _count,
                        decoration: InputDecoration(labelText: t.shares),
                      ),
                      if (_members.length > 1)
                        IconButton(
                          tooltip: t.cancel,
                          onPressed: _busy
                              ? null
                              : () => setState(
                                  () => _members.removeAt(index).dispose(),
                                ),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                    ],
                  ),
                ),
              TextButton.icon(
                onPressed: _busy || _members.length >= 59
                    ? null
                    : () => setState(() => _members.add(_MemberInput())),
                icon: const Icon(Icons.person_add_alt),
                label: Text(t.addMember),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.saveDraft),
                value: _draft,
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _draft = value),
              ),
              if (_failure != null) Text(errorText(t, _failure!)),
              const SizedBox(height: 12),
              PrimaryButton(
                label: t.saveCircle,
                loading: _busy,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
