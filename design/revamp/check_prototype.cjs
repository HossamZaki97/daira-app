/* Optional design-only QA. Run with JSDOM_PATH pointing to an external jsdom
 * installation. This does not add any dependency to the Flutter application. */
const fs=require('node:fs');
const path=require('node:path');
const assert=require('node:assert/strict');
const {JSDOM,VirtualConsole}=require(process.env.JSDOM_PATH||'jsdom');
const root=__dirname;
const html=fs.readFileSync(path.join(root,'index.html'),'utf8');
const source=fs.readFileSync(path.join(root,'prototype.js'),'utf8');
const uxSource=fs.readFileSync(path.join(root,'prototype-ux.js'),'utf8');
const createSource=fs.readFileSync(path.join(root,'create-preview.js'),'utf8');
let checks=0;
async function check(name,work){
 const errors=[];
 const virtualConsole=new VirtualConsole();virtualConsole.on('jsdomError',error=>errors.push(error.message));
 const dom=new JSDOM(html,{runScripts:'dangerously',url:'http://localhost/design/revamp/index.html',pretendToBeVisual:true,virtualConsole});
 const w=dom.window;
 for(const code of [uxSource,createSource,source]){const script=w.document.createElement('script');script.textContent=code;w.document.body.append(script);}
 assert.equal(errors.length,0,'Classic-script startup failed: '+errors.join('; '));
 const api=w.DairaDesign;assert(api,'Prototype did not initialize');
 try{await work(api,w);checks++;console.log('PASS '+name);}finally{w.close();}
}
const wait=()=>new Promise(resolve=>setTimeout(resolve,620));
const app=w=>w.document.getElementById('app');
const click=(w,selector)=>{const node=w.document.querySelector(selector);assert(node,'Missing control: '+selector);node.click();};
async function main(){
 await check('classic browser script starts and a real button click opens the payment sheet',(api,w)=>{
  assert.equal(Object.getOwnPropertyDescriptor(w,'top').configurable,false);
  click(w,'[data-action="report"]');assert.equal(api.state.sheet,'report');
  assert(app(w).querySelector('[data-action="confirm-report"]'));
  click(w,'[data-action="close-sheet"]');assert.equal(api.state.sheet,null);
  click(w,'[data-go="circles"]');assert.equal(api.state.screen,'circles');
 });
 await check('all 28 screen entries render in Arabic/English and Light/Dark',(api,w)=>{
  assert.equal(api.screens.length,28);
  for(const lang of ['ar','en'])for(const dark of [false,true])for(const [screen] of api.screens){
   api.state.lang=lang;api.state.dark=dark;api.screenJump(screen);
   assert(!/undefined|NaN|\[object Object\]/.test(app(w).textContent),screen);
   assert.equal(w.document.getElementById('device').dir,lang==='ar'?'rtl':'ltr');
   assert(app(w).querySelector('button'),screen+' has no path forward');
  }
 });
 await check('member report updates Home and actionable badge after the mock acknowledgement',async(api,w)=>{
  assert(app(w).querySelector('.nav-badge'));api.handle('report');api.handle('confirm-report');
  assert.equal(api.state.busy,true);assert.equal(api.state.memberStatus,'pending');
  await wait();assert.equal(api.state.memberStatus,'reported');
  assert(!app(w).querySelector('.nav-badge'));assert(app(w).textContent.includes('بانتظار الاعتماد'));
 });
 await check('ordinary member cannot open organizer approval or handover',(api,w)=>{
  api.handle('review');assert.equal(api.state.sheet,null);api.handle('payout');assert.equal(api.state.sheet,null);
 });
 await check('organizer approval is a separate confirmation and updates Actions',async(api,w)=>{
  api.state.role='organizer';api.render();api.handle('review');api.handle('approve');
  assert.equal(api.state.hassanStatus,'reported');api.handle('confirm-approve');await wait();
  assert.equal(api.state.hassanStatus,'approved');assert.equal(api.state.screen,'actions');
  assert(!app(w).querySelector('.nav-badge'));
 });
 await check('rejection requires a reason before the report returns to pending',async(api,w)=>{
  api.state.role='organizer';api.handle('review');api.handle('reject');api.handle('confirm-reject');
  assert(api.state.error);assert.equal(api.state.hassanStatus,'reported');
  w.document.querySelector('[data-field="reason"]').value='راجع المبلغ ثم أبلغ مجددًا';
  api.handle('confirm-reject');await wait();assert.equal(api.state.hassanStatus,'pending');
 });
 await check('collection, handover and recipient confirmation remain distinct',async(api,w)=>{
  api.state.role='organizer';api.state.round='ready';api.navigate('round');
  assert(app(w).querySelector('[data-action="payout"]'));assert(!app(w).querySelector('[data-action="receipt"]'));
  api.handle('payout');api.handle('confirm-payout');await wait();assert.equal(api.state.round,'payout');
  assert(!app(w).querySelector('[data-action="receipt"]'));
  api.state.role='member';api.render();assert(app(w).querySelector('[data-action="receipt"]'));
  api.handle('receipt');api.handle('confirm-receipt');await wait();assert.equal(api.state.round,'completed');
 });
 await check('lost invitation stays active and replacement requires explicit confirmation',async(api,w)=>{
  api.screenJump('invite-lost');assert.equal(api.state.inviteActive,true);assert.equal(api.state.secret,false);
  assert(!app(w).querySelector('[data-action="share-invite"]'));
  api.handle('replace-invite');assert.equal(api.state.secret,false);
  api.handle('close-sheet');assert.equal(api.state.inviteActive,true);
  const previous=api.state.inviteCode;
  api.handle('invite');api.handle('replace-invite');api.handle('confirm-replace');await wait();
  assert.equal(api.state.secret,true);assert.equal(api.state.inviteActive,true);
  assert.notEqual(api.state.inviteCode,previous);
  api.navigate('join');w.document.querySelector('[data-field="code"]').value=previous;
  api.handle('check-code');assert.equal(api.state.sheet,null);assert(api.state.error);
  w.document.querySelector('[data-field="code"]').value=api.state.inviteCode;
  api.handle('check-code');assert.equal(api.state.sheet,'join-preview');
 });
 await check('join has a membership preview, then waits for simulated server acceptance',async(api,w)=>{
  api.navigate('join');api.handle('check-code');assert.equal(api.state.sheet,'join-preview');
  assert(!app(w).querySelector('.sheet').textContent.includes('1,000'));
  api.handle('confirm-join');assert.equal(api.state.joined,false);await wait();assert.equal(api.state.joined,true);
 });
 await check('invalid invitation shows recovery guidance without a success state',(api,w)=>{
  api.navigate('join');w.document.querySelector('[data-field="code"]').value='INVALID';
  api.handle('check-code');assert.equal(api.state.sheet,null);assert(api.state.error);assert.equal(api.state.joined,false);
 });
 await check('sign-up uses neutral confirmation text and a disabled 60-second resend',(api,w)=>{
  api.navigate('signup');w.document.querySelector('[data-field="auth-name"]').value='Test User';
  w.document.querySelector('[data-field="password"]').value='prototype-only';api.handle('auth-submit');
  assert.equal(api.state.screen,'verify');assert.equal(api.state.cooldown,60);
  assert(app(w).textContent.includes('إذا كان البريد مؤهلًا'));
  assert(w.document.querySelector('[data-action="resend"]').disabled);
  api.handle('another-email');assert.equal(api.state.email,'');assert.equal(api.state.screen,'signup');
 });
 await check('verification preview offers a code and preserves sign-in as a separate step',(api,w)=>{
  api.navigate('verify');api.handle('confirm-code');assert.equal(api.state.screen,'verify');assert(api.state.error);
  w.document.querySelector('[data-field="verification-code"]').value='12345678';api.handle('confirm-code');assert.equal(api.state.screen,'login');
  assert.equal(w.document.querySelectorAll('#app img').length,1);
 });
 await check('four-step creation reviews before opening activation confirmation',(api,w)=>{
  api.navigate('create');for(let i=0;i<3;i++)api.handle('create-next');assert.equal(api.state.step,4);
  assert.equal(api.state.sheet,null);api.handle('activate');assert.equal(api.state.sheet,'activate');
 });
 await check('approved identity uses one mark per Home and Auth screen',(api,w)=>{
  assert(w.document.querySelector('#app img').getAttribute('src').includes('design')===false);
  assert(w.document.querySelector('#app img').getAttribute('src').endsWith('brand/people-circle/daira-app-icon.svg'));
  api.navigate('login');assert(w.document.querySelector('#app img').getAttribute('src').endsWith('daira-people-circle.svg'));assert.equal(w.document.querySelectorAll('#app img').length,1);
 });
 await check('adding members changes the form and missing names stop progression',(api,w)=>{
  api.navigate('create');api.handle('create-next');api.handle('add-member');
  assert.equal(api.state.form.extraMembers.length,1);
  api.handle('create-next');assert.equal(api.state.step,2);assert.equal(api.state.invalidField,'extra-0');
  const name=w.document.querySelector('[data-field="extra-0"]');name.value='New member';name.dispatchEvent(new w.Event('input',{bubbles:true}));
  api.handle('create-next');assert.equal(api.state.step,3);
  assert.equal(w.DairaUX.schedule(api.state.form,'Organizer').length,3);
 });
 await check('share controls have meaningful accessible names and update the installment summary',(api,w)=>{
  api.navigate('create');api.handle('create-next');
  const plus=w.document.querySelector('[data-action="share-plus"]');
  assert.equal(plus.getAttribute('aria-label'),'زيادة الأسهم');plus.click();
  assert.equal(api.state.form.shares,2);
  assert(app(w).textContent.includes(w.DairaUX.formatAmount(200000n,'EGP','ar')));
 });
 await check('schedule is anchored at month end and supports week/day intervals',(api,w)=>{
  const ux=w.DairaUX;
  assert.equal(ux.dueDate('2027-01-31','month',1,1).toISOString().slice(0,10),'2027-02-28');
  assert.equal(ux.dueDate('2027-01-31','month',1,2).toISOString().slice(0,10),'2027-03-31');
  assert.equal(ux.dueDate('2027-01-15','week',2,1).toISOString().slice(0,10),'2027-01-29');
  assert.equal(ux.dueDate('2027-01-15','day',3,1).toISOString().slice(0,10),'2027-01-18');
  assert.equal(ux.date('2027-02-31'),null);
 });
 await check('live schedule updates without discarding the date field or focus',(api,w)=>{
  api.navigate('create');api.handle('create-next');api.handle('create-next');
  const date=w.document.querySelector('[data-field="date"]');date.focus();date.value='2027-01-31';
  date.dispatchEvent(new w.Event('input',{bubbles:true}));
  assert.equal(w.document.activeElement,date);assert.equal(w.document.querySelector('[data-field="date"]'),date);
  assert(app(w).textContent.includes('فبراير'));assert(/28|٢٨/.test(app(w).textContent));
 });
 await check('Arabic numerals and currency precision preserve exact preview amounts',(api,w)=>{
  const ux=w.DairaUX;
  assert.equal(ux.minorAmount('١٬٠٠٠٫٢٥','EGP'),100025n);
  assert.equal(ux.minorAmount('0.10','EGP')*3n,30n);
  assert.equal(ux.minorAmount('1.234','KWD'),1234n);
  assert.equal(ux.minorAmount('1.234','EGP'),null);
  assert.equal(ux.minorAmount('1.5','JPY'),null);
  assert.equal(ux.minorAmount('1,23','EGP'),null);
 });
 await check('invalid intervals and dates keep the user at the relevant step',(api,w)=>{
  api.navigate('create');api.handle('create-next');api.handle('create-next');
  api.state.form.interval='0';api.handle('create-next');assert.equal(api.state.step,3);assert.equal(api.state.invalidField,'interval');
  api.state.form.interval='1';api.state.form.date='';api.handle('create-next');assert.equal(api.state.invalidField,'date');
 });
 await check('review distinguishes people, shares and receiving turns',(api,w)=>{
  api.navigate('create');api.state.form.amount='0.10';api.state.form.shares=2;
  for(let i=0;i<3;i++)api.handle('create-next');
  assert.equal(api.state.step,4);assert(app(w).textContent.includes('عدد الأعضاء'));
  assert(app(w).textContent.includes('الأسهم = أدوار الاستلام'));
  assert(app(w).textContent.includes(w.DairaUX.formatAmount(30n,'EGP','ar')));
  api.handle('edit-members');assert.equal(api.state.step,2);assert.equal(api.state.form.shares,2);
 });
 await check('user-entered circle names remain text rather than executable markup',(api,w)=>{
  api.state.circleName='<img src=x onerror=alert(1)>';api.navigate('round');
  assert(!app(w).querySelector('img[src=x]'));assert(app(w).textContent.includes('<img'));
 });
 await check('compact width, text scale and theme controls preserve the full scrollable structure',(api,w)=>{
  api.state.width=320;api.state.scale=1.5;api.state.dark=true;api.navigate('round');
  const device=w.document.getElementById('device');assert.equal(device.style.width,'320px');
  assert.equal(device.style.height,'568px');assert.equal(device.style.getPropertyValue('--f'),'1.5');
  assert(device.classList.contains('dark'));assert(app(w).querySelector('.scroll'));assert(app(w).querySelector('.footer-action'));
 });
 await check('dialog Escape and keyboard focus trap are present',(api,w)=>{
  api.handle('report');assert(app(w).querySelector('[role="dialog"][aria-modal="true"]'));
  w.document.dispatchEvent(new w.KeyboardEvent('keydown',{key:'Escape',bubbles:true}));assert.equal(api.state.sheet,null);
 });
 await check('offline state never shows a financial success',(api,w)=>{
  api.navigate('offline');assert(app(w).textContent.includes('لم نؤكد أي عملية'));
  assert(!app(w).querySelector('[data-action="confirm-approve"]'));
 });
 await check('normal text semantic color pairs meet 4.5:1 contrast',()=>{
  const tokens=JSON.parse(fs.readFileSync(path.join(root,'design-tokens.json'),'utf8'));
  const linear=v=>{v=parseInt(v,16)/255;return v<=.04045?v/12.92:((v+.055)/1.055)**2.4;};
  const lum=c=>{const a=c.slice(1).match(/../g).map(linear);return .2126*a[0]+.7152*a[1]+.0722*a[2];};
  const ratio=(a,b)=>{const x=lum(a),y=lum(b);return(Math.max(x,y)+.05)/(Math.min(x,y)+.05);};
  for(const [theme,p]of Object.entries(tokens.color))for(const [fg,bg]of [['text','bg'],['text','surface'],['muted','surface'],['primary','soft'],['good','good_bg'],['warn','warn_bg'],['bad','bad_bg']])assert(ratio(p[fg],p[bg])>=4.5,theme+':'+fg+'/'+bg);
  assert(ratio('#FFFFFF',tokens.color.light.blue)>=4.5);
 });
 console.log('\n'+checks+' design-only QA checks passed. DOM tests do not establish browser layout or device accessibility.');
}
main().catch(error=>{console.error(error.message);process.exitCode=1;});
