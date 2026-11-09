'use strict';
// Rendering only for the design prototype's four-step setup journey.
window.DairaCreate = ({state, X, E, I, field, note, act, pill, person, initials, appHeader, bottom}) => {
  const f = state.form;
  const ux = window.DairaUX;
  const members = ux.members(f);
  const totalShares = 1 + members.reduce((sum, member) => sum + member.shares, 0);
  const amount = ux.minorAmount(f.amount, f.currency);
  const format = value => E(ux.formatAmount(value, f.currency, state.lang));
  const date = value => value ? new Intl.DateTimeFormat(state.lang, {
    day: 'numeric', month: 'long', year: 'numeric', timeZone: 'UTC',
  }).format(value) : '—';
  const input = (label, options) => field(label, {
    ...options,
    error: state.invalidField === options.key ? state.error : undefined,
  });
  let body = '';

  if (state.step === 1) body = `
    <h2 class="auth-heading" style="margin-top:0">${X('نبدأ بالأساسيات','Start with the basics')}</h2>
    <p class="subtitle">${X('اسم يميّز الجمعية، وقيمة ثابتة لكل سهم.','A recognizable name and a fixed amount per share.')}</p>
    ${input(X('اسم الجمعية','Circle name'), {key:'name',value:f.name,max:100,placeholder:X('مثلًا: جمعية الأهل','e.g. Family circle')})}
    <div class="two-fields">
      ${input(X('القسط لكل سهم','Amount per share'), {key:'amount',value:f.amount,dir:'ltr',hint:X('يمكنك إدخال الأرقام بالعربية أو الإنجليزية.','Arabic and English numerals both work.')})}
      <label class="field"><span>${X('العملة','Currency')}</span><select data-form="currency">${['EGP','SAR','USD','AED','KWD','JPY'].map(code=>`<option ${code===f.currency?'selected':''}>${code}</option>`).join('')}</select></label>
    </div>
    ${note(X('السهم يعني قسطًا واحدًا ودور استلام واحدًا. لو كان لك سهمان، يتضاعف قسطك ويكون لك دوران.','One share means one installment and one receiving turn. Two shares mean double the installment and two turns.'))}`;

  if (state.step === 2) body = `
    <h2 class="auth-heading" style="margin-top:0">${X('مَن معك في الجمعية؟','Who’s in your circle?')}</h2>
    <p class="subtitle">${X('أضف الأسماء الآن، وادعُ الأعضاء لربط حساباتهم بعد التفعيل.','Add names now. Invite members to link accounts after activation.')}</p>
    <div class="spacer"></div>
    <div class="card"><div class="row"><div class="cluster"><span class="avatar">${initials()}</span><div><b>${person()}</b><div class="tiny muted">${X('أنت · منظّم هذه الجمعية','You · Organizer of this circle')}</div></div></div>${pill(X('سهم واحد','One share'),'neutral')}</div></div>
    ${members.map((member,index)=>`<section class="card" aria-label="${X('العضو ','Member ')+(index+2)}">
      <div class="row"><b class="small">${X('العضو ','Member ')+(index+2)}</b>${index?act('remove-member-'+(index-1),X('حذف','Remove'),'link danger'):''}</div>
      ${input(X('اسم العضو','Member name'), {key:index?'extra-'+(index-1):'member',value:member.name,max:100})}
      <div class="row wrap"><span class="small">${X('عدد الأسهم','Shares')}</span><span class="share-count">
        ${act(index?'extra-minus-'+(index-1):'share-minus','−','icon-btn','',member.shares<=1)}
        <b aria-live="polite">${member.shares}</b>
        ${act(index?'extra-plus-'+(index-1):'share-plus','+','icon-btn','',member.shares>=20)}
      </span></div>
      <div class="divider"></div><div class="tiny muted">${X('قسط العضو: ','Member installment: ')}<bdi>${format(amount===null?null:amount*BigInt(member.shares))}</bdi> · ${X('أدوار استلامه: ','Receiving turns: ')}${member.shares}</div>
    </section>`).join('')}
    ${act('add-member',X('إضافة عضو آخر','Add another member'),'btn secondary','plus',members.length>=59)}
    <div class="spacer"></div>${note(X('عدد الأعضاء مختلف عن عدد الأسهم؛ كل سهم له قسط ودور استلام.','Member count and share count are different. Each share has an installment and a receiving turn.'))}`;

  if (state.step === 3) {
    const plan = ux.schedule(f, X('دورك','Your turn'));
    const shown = state.showSchedule ? plan : plan.slice(0,3);
    body = `<h2 class="auth-heading" style="margin-top:0">${X('متى يبدأ أول دور؟','When does the first round start?')}</h2>
      <p class="subtitle">${X('راجع المواعيد هنا قبل التفعيل.','Review the dates here before activating.')}</p>
      <div class="field"><span>${X('الوحدة الزمنية','Time unit')}</span><div class="choice">${[['day',X('يوم','Day')],['week',X('أسبوع','Week')],['month',X('شهر','Month')]].map(([key,label])=>`<button type="button" data-cadence="${key}" class="${key===f.cadence?'active':''}" aria-pressed="${key===f.cadence}">${label}</button>`).join('')}</div></div>
      <div class="two-fields">${input(X('كل كم '+(f.cadence==='month'?'شهر':f.cadence==='week'?'أسبوع':'يوم')+'؟','Repeat interval'), {key:'interval',value:f.interval,dir:'ltr'})}${input(X('أول استحقاق','First due date'), {key:'date',value:f.date,type:'date'})}</div>
      <section class="card schedule-preview" aria-live="polite"><div class="row"><b class="small">${X('معاينة الجدول','Schedule preview')}</b>${pill(X('الأدوار: ','Rounds: ')+plan.length,'neutral')}</div><div class="divider"></div>
        ${shown.length&&shown.every(round=>round.date)?shown.map(round=>`<div class="kv"><span>${round.number} · ${E(round.name)}</span><b>${E(date(round.date))}</b></div>`).join(''):`<p class="subtitle">${X('أكمل تاريخًا صحيحًا والفاصل لعرض المواعيد.','Enter a valid first date and interval to preview dates.')}</p>`}
        ${plan.length>3?act('toggle-schedule',state.showSchedule?X('إخفاء التفاصيل','Show less'):X('عرض الجدول كاملًا','View the full schedule'),'link'):''}
      </section>
      ${note(X('الأدوار حسب ترتيب الأعضاء، وأدوارك كمنظّم تأتي أخيرًا. في الأشهر الأقصر، يُستخدم آخر يوم متاح.','Turns follow member order, with the organizer last. Shorter months use their last available day.'))}`;
  }

  if (state.step === 4) {
    const cadence = f.cadence==='month'?X('شهر','month'):f.cadence==='week'?X('أسبوع','week'):X('يوم','day');
    const rows = [
      [X('القسط لكل سهم','Amount per share'),format(amount)],
      [X('عدد الأعضاء','Members'),members.length+1],
      [X('الأسهم = أدوار الاستلام','Shares = receiving turns'),totalShares],
      [X('قيمة كل دور','Amount per round'),format(amount===null?null:amount*BigInt(totalShares))],
      [X('الدورية','Cadence'),X('كل ','Every ')+E(f.interval)+' '+cadence],
      [X('أول استحقاق','First due date'),E(date(ux.date(f.date)))],
    ];
    body = `<h2 class="auth-heading" style="margin-top:0">${X('نراجعها مرة أخيرة','One last look')}</h2>
      <p class="subtitle">${X('راجع الأسماء والأسهم والمواعيد قبل بدء الالتزامات.','Review names, shares and dates before obligations begin.')}</p>
      <div class="spacer"></div><section class="card"><div class="row wrap"><b>${E(f.name)}</b>${act('edit-create',X('تعديل الأساسيات','Edit basics'),'link')}</div><div class="divider"></div>
      ${rows.map(([label,value])=>`<div class="kv"><span>${label}</span><b><bdi>${value}</bdi></b></div>`).join('')}
      <div class="divider"></div>${act('edit-members',X('مراجعة الأعضاء والأسهم','Review members and shares'),'link')}${act('edit-schedule',X('مراجعة المواعيد','Review dates'),'link')}</section>
      ${note(X('التفعيل يبدأ خطة المتابعة فقط. لا يحدث دفع أو تحويل داخل دايرة.','Activation starts tracking only. Daira does not make payments or transfers.'))}
      ${act('save-draft',X('حفظ كمسودة والمتابعة لاحقًا','Save draft and continue later'),'btn quiet')}`;
  }
  const error = state.error ? `<div class="info-line bad form-error" role="alert" tabindex="-1">${E(state.error)}</div>` : '';
  return `${appHeader(X('إنشاء جمعية','Create circle'),'',state.step===1?'circles':null,state.step>1?act('create-back',I('back','back-icon'),'icon-btn'):'')}
    <div class="scroll create-scroll"><div class="step-label">${X('الخطوة '+state.step+' من 4','Step '+state.step+' of 4')}</div><div class="stepper">${[1,2,3,4].map(step=>`<i class="${step<=state.step?'done':''}"></i>`).join('')}</div>${error}${body}</div>
    ${bottom(state.step===4?X('تفعيل الجمعية','Activate circle'):X('متابعة','Continue'),state.step===4?'activate':'create-next')}`;
};
