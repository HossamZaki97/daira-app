'use strict';
// Design-only form and schedule previews. Never imports or calls the app backend.
window.DairaUX = (() => {
  const digits = value => String(value ?? '').trim()
    .replace(/[٠-٩]/g, ch => String(ch.charCodeAt(0) - 0x660))
    .replace(/[۰-۹]/g, ch => String(ch.charCodeAt(0) - 0x6f0))
    .replace(/٫/g, '.').replace(/٬/g, ',');

  function minorAmount(value, currency) {
    const precision = currency === 'KWD' ? 3 : currency === 'JPY' ? 0 : 2;
    let input = digits(value);
    if (input.includes(',')) {
      if (!/^\d{1,3}(,\d{3})+(\.\d+)?$/.test(input)) return null;
      input = input.replace(/,/g, '');
    }
    if (!/^\d+(\.\d+)?$/.test(input)) return null;
    const [whole, fraction = ''] = input.split('.');
    if (fraction.length > precision || input.length > 24) return null;
    const factor = 10n ** BigInt(precision);
    const result = BigInt(whole) * factor + BigInt(fraction.padEnd(precision, '0') || '0');
    return result > 0n && result <= 9000000000000000n ? result : null;
  }

  function formatAmount(minor, currency, language) {
    if (minor === null) return '—';
    const precision = currency === 'KWD' ? 3 : currency === 'JPY' ? 0 : 2;
    const factor = 10n ** BigInt(precision);
    const whole = new Intl.NumberFormat(language).format(minor / factor);
    const decimal = new Intl.NumberFormat(language).formatToParts(1.1).find(part => part.type === 'decimal')?.value || '.';
    const numeral = new Intl.NumberFormat(language, { useGrouping: false });
    const fraction = (minor % factor).toString().padStart(precision, '0')
      .replace(/\d/g, digit => numeral.format(Number(digit)));
    return whole + (precision ? decimal + fraction : '') + ' ' + currency;
  }

  function date(value) {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return null;
    const [year, month, day] = value.split('-').map(Number);
    if (year < 2000 || year > 2100) return null;
    const parsed = new Date(Date.UTC(year, month - 1, day));
    return parsed.getUTCFullYear() === year && parsed.getUTCMonth() === month - 1 && parsed.getUTCDate() === day ? parsed : null;
  }

  function dueDate(first, cadence, interval, index) {
    const start = date(first);
    if (!start || !Number.isInteger(interval) || interval < 1 || interval > 365 || !['day', 'week', 'month'].includes(cadence)) return null;
    if (cadence === 'month') {
      const month = start.getUTCMonth() + interval * index;
      const last = new Date(Date.UTC(start.getUTCFullYear(), month + 1, 0)).getUTCDate();
      return new Date(Date.UTC(start.getUTCFullYear(), month, Math.min(start.getUTCDate(), last)));
    }
    const result = new Date(start);
    result.setUTCDate(result.getUTCDate() + index * interval * (cadence === 'week' ? 7 : 1));
    return result;
  }

  function members(form) {
    return [{ name: form.member, shares: form.shares }, ...(form.extraMembers || [])];
  }

  function schedule(form, organizer) {
    const recipients = [];
    for (const member of members(form)) {
      if (!Number.isInteger(member.shares) || member.shares < 1 || member.shares > 20) return [];
      for (let i = 0; i < member.shares; i++) recipients.push(member.name);
    }
    recipients.push(organizer);
    if (recipients.length > 120) return [];
    return recipients.map((name, index) => ({
      name, number: index + 1,
      date: dueDate(form.date, form.cadence, Number(digits(form.interval)), index),
    }));
  }

  function validate(form, step) {
    if (step === 1) {
      if (!form.name.trim()) return { field: 'name', code: 'name' };
      if (minorAmount(form.amount, form.currency) === null) return { field: 'amount', code: 'amount' };
    }
    if (step === 2) {
      const missing = members(form).findIndex(member => !member.name.trim());
      if (missing >= 0) return { field: missing === 0 ? 'member' : 'extra-' + (missing - 1), code: 'member' };
      const plan = schedule({ ...form, date: '2027-01-01', interval: '1' }, 'Organizer');
      if (!plan.length) return { field: 'member', code: 'shares' };
      const amount = minorAmount(form.amount, form.currency);
      if (amount !== null && amount * BigInt(plan.length) > 9000000000000000n) return { field:'member', code:'total' };
    }
    if (step === 3) {
      const interval = Number(digits(form.interval));
      if (!Number.isInteger(interval) || interval < 1 || interval > 365) return { field: 'interval', code: 'interval' };
      if (!date(form.date)) return { field: 'date', code: 'date' };
    }
    return null;
  }
  return Object.freeze({ digits, minorAmount, formatAmount, date, dueDate, members, schedule, validate });
})();
