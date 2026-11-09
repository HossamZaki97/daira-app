"""Build editable SVG design frames. Standard library only; no backend access.

Re-run after visual design edits. This handoff canvas complements the interactive
HTML prototype; SVG groups remain editable vectors/text, not Auto Layout frames.
"""
from html import escape
from pathlib import Path
import json
import math
import re
import xml.etree.ElementTree as ET
from copy import deepcopy

ROOT = Path(__file__).resolve().parent
APP = ROOT.parent.parent
BRAND = ET.parse(ROOT.parent / 'brand/people-circle/daira-people-circle.svg').getroot()
BRAND_GROUP = next(node for node in BRAND if node.tag.endswith('}g'))
P = dict(bg='#F5F7FB', surface='#FFFFFF', soft='#EDF3FF', text='#182943',
         muted='#606F86', border='#E1E7F0', blue='#356DF3', primary='#285DD8',
         navy='#142C50', cyan='#087F8C', cyan_bg='#E8F6F8', good='#147449',
         good_bg='#E8F5ED', warn='#965C00', warn_bg='#FFF3DC', bad='#BB3544', bad_bg='#FFF0F1')
DARK = dict(P, bg='#101A2B', surface='#19263B', soft='#233759', text='#F1F5FC',
            muted='#AFBED2', border='#31425C', primary='#9BBCFF', navy='#203D67',
            cyan='#8CDBE1', cyan_bg='#173C48', good='#87DEAF', good_bg='#173F32',
            warn='#F5CE89', warn_bg='#443820', bad='#FFACB5', bad_bg='#4A2938')
ICONS = {
    'home': '<path d="m3 10 9-7 9 7v10H5V10M9 20v-7h6v7"/>',
    'people': '<circle cx="9" cy="8" r="3"/><path d="M3 21v-3a6 6 0 0 1 12 0v3M16 5a3 3 0 0 1 0 6M18 15a5 5 0 0 1 3 5"/>',
    'actions': '<rect x="5" y="4" width="14" height="17" rx="3"/><path d="M9 4V2h6v2M9 10h6M9 14h6M9 18h3"/>',
    'settings': '<circle cx="12" cy="12" r="3"/><path d="m9 3 1-1h4l1 3 3 1 2 2-1 3v3l1 2-2 3-3 1-1 2h-4l-1-3-3-1-2-2 1-3v-3L3 8l2-3 3-1Z"/>',
    'check': '<path d="m5 12 4 4L19 6"/>', 'plus': '<path d="M12 5v14M5 12h14"/>',
    'back': '<path d="m9 5 7 7-7 7M4 12h12"/>',
    'clock': '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
    'mail': '<rect x="3" y="5" width="18" height="14" rx="3"/><path d="m4 7 8 6 8-6"/>',
    'receipt': '<path d="M5 3h14v19l-3-2-4 2-4-2-3 2ZM9 8h6M9 12h6M9 16h3"/>',
    'share': '<path d="M12 16V3m-4 4 4-4 4 4M5 12v8h14v-8"/>',
    'copy': '<rect x="8" y="8" width="12" height="13" rx="2"/><path d="M15 8V3H3v13h5"/>',
    'info': '<circle cx="12" cy="12" r="9"/><path d="M12 11v6M12 7h.01"/>',
    'chevron': '<path d="m14 7-5 5 5 5"/>',
    'heart': '<path d="M12 21 3 12a6 6 0 0 1 9-8 6 6 0 0 1 9 8Z"/>',
    'link': '<path d="m10 14 4-4M9 16l-2 2a4 4 0 0 1-5-5l5-5a4 4 0 0 1 6 0M15 8l2-2a4 4 0 0 1 5 5l-5 5a4 4 0 0 1-6 0"/>',
    'eye': '<path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/>',
    'wifi': '<path d="M3 8a15 15 0 0 1 18 0M6 12a10 10 0 0 1 12 0M9 16a5 5 0 0 1 6 0M3 3l18 18"/>',
    'moon': '<path d="M20 15A9 9 0 0 1 9 3a9 9 0 1 0 11 12Z"/>',
    'calendar': '<rect x="3" y="5" width="18" height="16" rx="3"/><path d="M7 3v4M17 3v4M3 11h18M8 15h1M14 15h1"/>',
}


class Canvas:
    sequence = 0
    def __init__(self, dark=False, english=False):
        self.p = DARK if dark else P
        self.en = english
        self.parts = []
        self.clipped = False

    def add(self, value): self.parts.append(value)

    def box(self, x, y, w, h, fill=None, r=16, stroke=None, opacity=1):
        self.add(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill or self.p["surface"]}" opacity="{opacity}"' +
                 (f' stroke="{stroke}"' if stroke else '') + '/>')

    def circle(self, x, y, radius, fill, stroke=None, width=1):
        self.add(f'<circle cx="{x}" cy="{y}" r="{radius}" fill="{fill}"' +
                 (f' stroke="{stroke}" stroke-width="{width}"' if stroke else '') + '/>')

    def line(self, x, y, x2, y2, color=None, width=1):
        self.add(f'<path d="M{x} {y}H{x2}" fill="none" stroke="{color or self.p["border"]}" stroke-width="{width}"/>' if y == y2 else
                 f'<path d="M{x} {y}L{x2} {y2}" fill="none" stroke="{color or self.p["border"]}" stroke-width="{width}"/>')

    def text(self, label, x, y, size=14, color=None, weight=400, rtl=True, center=False):
        # Right anchor plus Unicode shaping keeps editable Arabic text aligned.
        anchor = 'middle' if center else 'end' if rtl else 'start'
        label = str(label)
        if re.search(r'[\u0600-\u06ff]', label):
            label = '\u2067' + label + '\u2069'
        self.add(f'<text x="{x}" y="{y}" font-family="Cairo" font-size="{size}" font-weight="{weight}" fill="{color or self.p["text"]}" text-anchor="{anchor}">{escape(str(label))}</text>')

    def logo(self,x,y,size):
        self.box(x,y,size,size,'#FFFFFF',size*.28,self.p['border'])
        self.add(f'<g transform="translate({x} {y}) scale({size/512})">')
        self.add(ET.tostring(deepcopy(BRAND_GROUP),encoding='unicode'))
        self.add('</g>')

    def para(self, lines, x, y, size=12, color=None, line_height=23, center=False):
        for i, label in enumerate(lines): self.text(label, x, y + i * line_height, size, color or self.p['muted'], center=center)

    def icon(self, name, x, y, color=None, size=22):
        self.add(f'<g transform="translate({x} {y}) scale({size / 24})" fill="none" stroke="{color or self.p["text"]}" stroke-width="1.65" stroke-linecap="round" stroke-linejoin="round">{ICONS.get(name, ICONS["info"])}</g>')

    def card(self, y, h, x=22, w=346): self.box(x, y, w, h, r=21, stroke=self.p['border'])

    def pill(self, label, x, y, w, tone='soft'):
        foreground = {'soft':'primary','good_bg':'good','warn_bg':'warn','bad_bg':'bad','cyan_bg':'cyan'}.get(tone, 'muted')
        self.box(x, y, w, 25, self.p.get(tone, tone), 8)
        self.text(label, x+w/2, y+17, 10, self.p[foreground], 600, center=True)

    def btn(self, label, y, secondary=False, x=22, w=346, icon=None):
        self.box(x, y, w, 52, self.p['surface'] if secondary else self.p['blue'], 15, self.p['border'] if secondary else None)
        self.text(label, x+w/2, y+33, 14, self.p['primary'] if secondary else '#FFFFFF', 700, center=True)
        if icon: self.icon(icon, x+w-42, y+16, self.p['primary'] if secondary else '#FFFFFF', 19)

    def avatar(self, label, x, y, color='soft', size=42):
        self.box(x, y, size, size, self.p[color], 14)
        self.text(label, x+size/2, y+size*.65, 15, self.p['cyan'] if color=='cyan_bg' else self.p['primary'], 700, center=True)

    def field(self, label, value, y, x=22, w=346, password=False):
        self.text(label, x+w, y, 12, weight=600)
        self.box(x, y+12, w, 54, self.p['surface'], 13, self.p['border'])
        if password:
            self.text('••••••••••', x+w-14, y+46, 16)
            self.icon('eye', x+15, y+29, self.p['muted'], 19)
        else:
            latin=bool(re.match(r'^[A-Za-z0-9@ ]+$',value))
            self.text(value,x+14 if latin else x+w-14,y+46,13,self.p['muted'],rtl=not latin)

    def note(self, lines, y, tone='soft', height=None):
        h=height or (30+22*(len(lines)-1)+18)
        fg=self.p['primary'] if tone=='soft' else self.p['good'] if tone=='good_bg' else self.p['warn']
        self.box(22,y,346,h,self.p[tone],13)
        self.icon('info',335,y+15,fg,16)
        self.para(lines,324,y+28,11,fg,22)

    def shell(self, title=None, subtitle=None, back=False, nav=None):
        Canvas.sequence += 1
        clip = f'phone-clip-{Canvas.sequence}'
        self.add(f'<defs><clipPath id="{clip}"><rect width="390" height="844" rx="32"/></clipPath></defs><g clip-path="url(#{clip})">')
        self.clipped = True
        self.box(0,0,390,844,self.p['bg'],32)
        self.text('9:41',27,25,12,weight=600,rtl=False)
        for i,height in enumerate((3,5,8,11)):
            self.box(317+4*i,25-height,2.5,height,self.p['text'],.7)
        self.box(341,15,21,10,'none',2,self.p['text'])
        self.box(343,17,15,6,self.p['text'],1)
        self.box(363,18,2,4,self.p['text'],.5)
        if title:
            self.text(title,368 if not back else 324,82,24,weight=700)
            if subtitle:self.text(subtitle,368 if not back else 324,105,11,self.p['muted'])
            if back:self.icon('back',342,60,size=24)
        if nav:self.nav(nav)
        self.box(138,832,114,4,self.p['text'],2)

    def nav(self, active='home', badge=1):
        self.box(0,758,390,86,self.p['surface'],0)
        self.line(0,758,390,758)
        names=[('home','home','الرئيسية','Home'),('circles','people','جمعياتي','Circles'),('actions','actions','الإجراءات','Actions'),('settings','settings','الإعدادات','Settings')]
        for i,(key,icon,ar,en) in enumerate(names):
            x=341-97*i if not self.en else 49+97*i
            if key==active:self.box(x-28,767,56,29,self.p['soft'],10)
            self.icon(icon,x-11,771,self.p['primary'] if key==active else self.p['muted'])
            self.text(en if self.en else ar,x,814,10,self.p['primary'] if key==active else self.p['muted'],700 if key==active else 400,center=True)
            if key=='actions' and badge:
                self.circle(x+13,770,7,self.p['blue'],self.p['surface'],2)
                self.text(str(badge),x+13,773,7,'#FFFFFF',600,center=True,rtl=False)

    def amount(self,value,x,y,size=38,color=None,currency='ج.م',center=False):
        self.text(f'{value:,}',x,y,size,color,700,rtl=False,center=center)
        self.text(currency,x-8 if not center else x+76,y,12,color,rtl=True)

    def progress(self,y,value=50):
        self.box(40,y,310,6,self.p['soft'],3)
        self.box(350-310*value/100,y,310*value/100,6,self.p['blue'],3)

    def circle_card(self,y,travel=False):
        self.card(y,158)
        self.box(306,y+17,44,44,self.p['cyan_bg'] if travel else self.p['soft'],14)
        self.icon('people' if travel else 'heart',317,y+28,self.p['cyan'] if travel else self.p['primary'])
        self.text('جمعية السفر' if travel else 'جمعية الأهل',294,y+34,15,weight=700)
        self.text('5 أعضاء · شهرية' if travel else '6 أعضاء · شهرية',294,y+55,10,self.p['muted'])
        self.pill('نشطة',40,y+23,45)
        self.line(40,y+76,350,y+76)
        self.text('القسط لكل سهم',350,y+98,12,self.p['muted'])
        self.text('500 SAR' if travel else '1,000 EGP',40,y+98,14,weight=700,rtl=False)
        self.text('مستفيد الدور: علي يوسف' if travel else 'مستفيد الدور: مريم علي',350,y+120,12,weight=600)
        self.text('الدور 2 من 5' if travel else 'الدور 2 من 6',350,y+140,10,self.p['muted'])
        self.text('20 يناير' if travel else '15 يناير',40,y+140,10,self.p['muted'],rtl=False)

    def member(self,index,y,status=True,self_member=False,organizer=False,invite=False):
        names=['سارة أحمد','مريم علي','حسن محمود','علي يوسف','هبة سامي','نور حسن']
        if self_member:self.box(30,y-5,330,67,self.p['soft'],14)
        self.avatar(names[index][0],310,y+6,'cyan_bg' if index%2 else 'soft',36)
        self.text(names[index],298,y+24,13,weight=600)
        self.text('سهم واحد · الدور '+str([6,2,1,3,4,5][index]) if invite else ('أبلغ اليوم، 10:30 ص' if index==2 else 'لم يُبلغ بالدفع' if index in (1,5) else 'تم الاعتماد'),298,y+46,10,self.p['muted'])
        if self_member:self.pill('أنت',176,y+6,31)
        if organizer:self.pill('المنظّمة',115,y+6,56,'cyan_bg')
        if invite:
            if index==5:self.text('دعوة',50,y+32,12,self.p['primary'],600,rtl=False)
            else:self.pill('منضم',43,y+14,42,'good_bg')
        elif status:
            if index==2:self.text('مراجعة',43,y+32,12,self.p['primary'],600,rtl=False)
            elif index not in (1,5):
                self.circle(56,y+28,11,self.p['good_bg'])
                self.icon('check',49,y+21,self.p['good'],14)
            else:self.pill('بانتظار الدفع',40,y+15,76,'warn_bg')
        if index<5:self.line(40,y+67,350,y+67)

    def lifecycle(self,y,stage=0):
        self.line(62,y+12,328,y+12,width=2)
        for i,label in enumerate(['التحصيل','جاهز','التسليم','الاستلام']):
            x=328-88*i
            color=self.p['good'] if i<stage else self.p['blue'] if i==stage else self.p['border']
            self.circle(x,y+12,12,self.p['surface'],color,2)
            if i<stage:self.icon('check',x-7,y+5,self.p['good'],14)
            elif i==stage:self.circle(x,y+12,7,color)
            self.text(label,x,y+43,9,self.p['muted'],600 if i==stage else 400,center=True)

    def tabs(self,which='round'):
        for x,label,key in [(314,'الدور الحالي','round'),(194,'الأعضاء','members'),(78,'النشاط','activity')]:
            self.text(label,x,146,12,self.p['primary'] if key==which else self.p['muted'],600 if key==which else 400,center=True)
            if key==which:self.line(x-43,161,x+43,161,self.p['primary'],2)
        self.line(22,163,368,163)

    def sheet(self,title,kind='receipt',top=295):
        self.box(0,39,390,805,'#13243C',0,opacity=.48)
        self.box(0,top,390,844-top,self.p['surface'],28)
        self.box(177,top+10,36,4,self.p['border'],2)
        self.box(322,top+34,46,46,self.p['soft'],16)
        self.icon(kind,334,top+46,self.p['primary'])
        self.text(title,368,top+112,23,weight=700)

    def markup(self): return ''.join(self.parts)+('</g>' if self.clipped else '')


def home(c,organizer=False):
    c.shell(nav='home')
    c.logo(328,48,40)
    c.text('دايرة',315,79,28,weight=700);c.avatar('س' if organizer else 'م',22,48)
    c.text('أهلًا، سارة' if organizer else 'أهلًا، مريم',368,134,26,weight=700)
    c.text('هذه آخر مستجدات جمعياتك.',368,159,12,c.p['muted'])
    c.box(22,181,346,219,c.p['navy'],24)
    c.circle(66,251,41,'none','#FFFFFF18');c.circle(66,251,26,'none','#FFFFFF12')
    c.circle(100,228,4,'#70D3DF')
    c.pill('يحتاج مراجعتك' if organizer else 'قسطك القادم',252,199,96)
    c.text('15 يناير',43,217,11,'#D7E4F5',rtl=False)
    if organizer:
        c.text('إقرار واحد بانتظارك',348,268,25,'#FFFFFF',700)
        c.para(['حسن أبلغ بدفع قسطه في','جمعية الأهل.'],348,298,12,'#D7E4F5',22)
        c.box(42,341,306,44,'#FFFFFF',13);c.text('مراجعة الإقرار',195,369,14,'#244E9D',700,center=True)
    else:
        c.text('جمعية الأهل · الدور 2 من 6',348,253,12,'#D7E4F5')
        c.text('1,000',348,302,42,'#FFFFFF',700);c.text('ج.م',224,302,13,'#D7E4F5')
        c.text('مستحق بعد يومين',348,326,11,'#D7E4F5');c.icon('calendar',231,313,'#D7E4F5',15)
        c.box(42,341,306,44,'#FFFFFF',13);c.text('أبلغت بالدفع',195,369,14,'#244E9D',700,center=True)
    c.text('آخر تحديث الآن',368,430,10,c.p['muted']);c.text('كل الإجراءات',22,431,11,c.p['primary'],600,rtl=False)
    c.text('جمعياتك',368,472,17,weight=700);c.text('عرض الكل (2)',22,472,11,c.p['primary'],600,rtl=False)
    c.circle_card(489)
    c.box(22,660,346,74,c.p['surface'],20,c.p['border']);c.box(309,675,43,43,c.p['cyan_bg'],14);c.icon('people',320,686,c.p['cyan'])
    c.text('جمعية السفر',296,694,14,weight=700);c.text('قسط 500 SAR · الدور 2 من 5',296,716,11,c.p['muted'])
    c.pill('نشطة',40,683,45,'good_bg')


def auth(c,mode):
    c.shell()
    c.logo(324,61,44);c.text('دايرة',311,96,28,weight=700)
    if mode=='verify':
        c.text('تأكيد بريدك',368,174,26,weight=700)
        c.para(['إذا كان البريد مؤهلًا، تصلك رسالة برابط ورمز.','استخدم أيهما. لديك حساب مؤكد؟','سجّل الدخول أو استعد كلمة المرور.'],368,208,12,line_height=24)
        c.field('البريد الإلكتروني','mariam@example.com',296)
        c.field('رمز تأكيد البريد','',397)
        c.text('8 أرقام · صالح 10 دقائق',368,484,11,c.p['muted'])
        c.btn('تأكيد الرمز',516)
        c.text('إعادة إرسال التأكيد (60)',195,603,12,c.p['muted'],center=True)
        c.btn('تسجيل الدخول',631,True)
        c.text('نسيت كلمة المرور؟',279,728,11,c.p['primary'],center=True)
        c.text('استخدام بريد آخر',112,728,11,c.p['primary'],center=True)
        return
    if mode=='forgot':
        c.text('استعادة كلمة المرور',368,190,26,weight=700)
        c.field('البريد الإلكتروني','mariam@example.com',252)
        c.btn('إرسال رابط الاستعادة',363)
        c.note(['إذا كان البريد مؤهلًا، تصلك تعليمات الاستعادة','أو رسالة لاستكمال تأكيد البريد أولًا.'],444,'good_bg')
        c.btn('تسجيل الدخول',551,True)
        c.text('استكمال تأكيد البريد',195,653,12,c.p['primary'],center=True)
        return
    if mode=='reset':
        c.text('كلمة مرور جديدة',368,191,28,weight=700)
        c.field('كلمة المرور الجديدة','',279,password=True)
        c.field('تأكيد كلمة المرور','',390,password=True)
        c.btn('حفظ كلمة المرور',515)
        c.note(['صفحة Odoo الآمنة.','بعد الحفظ، سجّل الدخول من التطبيق.'],609)
        return
    signup=mode=='signup'
    c.text('ابدأ مع دايرة' if signup else 'أهلًا بعودتك',368,185,28,weight=700)
    y=245
    if signup:c.field('اسمك','',y);y+=105
    c.field('البريد الإلكتروني','mariam@example.com',y);y+=105
    c.field('كلمة المرور','',y,password=True);y+=96
    if not signup:c.text('نسيت كلمة المرور؟',368,y+10,12,c.p['primary'],600);y+=42
    c.btn('إنشاء حساب' if signup else 'تسجيل الدخول',y+10)
    c.btn('تسجيل الدخول' if signup else 'إنشاء حساب',y+86,True)
    if not signup:c.text('استكمال تأكيد البريد',195,y+191,12,c.p['primary'],center=True)


def round_screen(c,which='round',stage=0):
    c.shell('جمعية الأهل','6 أعضاء · 1,000 ج.م شهريًا',back=True);c.tabs(which)
    if which=='members':
        c.text('أهل الجمعية',368,204,17,weight=700);c.text('5 منضمين من 6',22,204,10,c.p['muted'],rtl=False)
        c.card(223,428)
        for i in range(6):c.member(i,238+68*i,invite=True,self_member=i==0,organizer=i==0)
        c.note(['شارك دعوة كل عضو معه فقط.','سيظهر له اسمه والجمعية قبل قبول الدعوة.'],680)
        return
    if which=='activity':
        c.text('اليوم',368,204,17,weight=700);c.card(226,245)
        events=[('حسن أبلغ بدفع قسطه','10:30 ص · الدور 2','receipt'),('سارة اعتمدت قسط هبة','9:15 ص · 1,000 ج.م','check'),('هبة أبلغت بدفع قسطها','9:02 ص · الدور 2','receipt')]
        for i,(label,time,icon) in enumerate(events):
            y=247+i*76;c.box(314,y,34,34,c.p['soft'],12);c.icon(icon,323,y+9,c.p['primary'],16)
            c.text(label,302,y+15,13,weight=600);c.text(time,302,y+40,10,c.p['muted'])
            if i<2:c.line(40,y+58,348,y+58)
        c.text('الدور السابق',368,514,17,weight=700);c.card(534,92)
        c.text('علي أكد استلام الدور',348,570,13,weight=600);c.text('15 ديسمبر 2026 · 6,000 ج.م',348,596,10,c.p['muted'])
        c.note(['الأدوار التاريخية المستوردة لا تعني','أن التسليم أو الاستلام حدث فعلًا.'],660)
        return
    c.pill(['جارٍ التحصيل','جاهز للتسليم','بانتظار الاستلام','اكتمل الاستلام'][stage],242,182,126,'warn_bg' if stage==0 else 'good_bg')
    c.text('الدور 2 من 6',22,201,11,c.p['muted'],rtl=False)
    c.card(224,302)
    c.avatar('م',308,243,'cyan_bg');c.text('المستفيدة هذا الدور',296,260,10,c.p['muted']);c.text('مريم علي',296,282,15,weight=700)
    c.line(40,302,350,302);c.text('قيمة الدور',350,329,12,c.p['muted'])
    c.text('6,000',350,369,35,weight=700);c.text('ج.م',249,369,12,c.p['muted'])
    c.text('15 يناير 2027',350,398,11,c.p['muted']);c.icon('calendar',235,385,c.p['muted'],16)
    c.lifecycle(414,stage)
    c.text('المعتمد تحصيله',350,487,11,c.p['muted']);c.text('3,000 EGP' if not stage else '6,000 EGP',40,487,14,weight=700,rtl=False)
    c.progress(500,50 if not stage else 100)
    if stage==0:
        c.text('أقساط الأعضاء',368,567,17,weight=700);c.text('3 / 6',22,567,11,c.p['muted'],rtl=False)
        c.card(584,150);c.member(2,595);c.member(1,665,self_member=True)
    else:
        c.note(['اكتمل اعتماد جميع الأقساط.','المنظّمة تسجل التسليم والمستفيدة تؤكد الاستلام.'],554,'good_bg')
        c.box(0,742,390,102,c.p['surface'],0);c.line(0,742,390,742)
        c.btn('تسجيل تسليم الدور' if stage==1 else 'تأكيد الاستلام',764)


def create(c,step):
    c.shell('إنشاء جمعية',back=True)
    c.text(f'الخطوة {step} من 4',368,126,11,c.p['muted'])
    for i in range(4):c.box(22+88*i,142,82,4,c.p['blue'] if 4-i<=step else c.p['border'],2)
    titles=['نبدأ بالأساسيات','مَن معك في الجمعية؟','متى يبدأ أول دور؟','نراجعها مرة أخيرة']
    c.text(titles[step-1],368,195,26,weight=700)
    descriptions=[['اسم يميّز الجمعية، وقيمة ثابتة لكل سهم.'],['أضف الأسماء الآن، وادعهم بعد التفعيل.'],['نفس الموعد يتكرر حسب الدورية.'],['كل التفاصيل أمامك قبل إنشاء الالتزامات.']]
    c.para(descriptions[step-1],368,228,12)
    if step==1:
        c.field('اسم الجمعية','جمعية الأهل',286)
        c.field('القسط لكل سهم','1000',397,x=195,w=173)
        c.field('العملة','EGP',397,x=22,w=160)
        c.note(['السهم يعني قسطًا واحدًا ودور استلام واحدًا.','سهمان = ضعف القسط ودورا استلام.'],513)
    elif step==2:
        c.card(265,83);c.avatar('س',308,285);c.text('سارة أحمد',296,308,14,weight=700);c.pill('أنت · المنظّمة',40,295,86)
        c.card(367,214);c.field('اسم العضو','نور حسن',395,x=40,w=310)
        c.text('عدد الأسهم',350,522,12);c.box(40,491,48,48,c.p['surface'],11,c.p['border']);c.icon('plus',53,504,c.p['primary'])
        c.text('1',111,522,16,weight=700,center=True);c.box(134,491,48,48,c.p['surface'],11,c.p['border']);c.text('−',158,522,21,c.p['muted'],center=True)
        c.text('قسط العضو: 1,000 ج.م · دور استلام واحد',350,560,10,c.p['muted'])
        c.btn('إضافة عضو آخر',600,True,icon='plus');c.note(['ترتيب الأعضاء يحدد أدوار الاستلام.','أدوارك كمنظّم تأتي أخيرًا.'],672)
    elif step==3:
        c.text('يتكرر كل',368,282,12,weight=600)
        for x,label,active in [(22,'يوم',False),(142,'أسبوع',False),(262,'شهر',True)]:
            c.box(x,300,106,48,c.p['soft'] if active else c.p['surface'],13,c.p['primary'] if active else c.p['border']);c.text(label,x+53,330,13,c.p['primary'] if active else c.p['muted'],600,center=True)
        c.field('كل كم شهر؟','1',395,x=262,w=106);c.field('أول استحقاق','2027-01-15',395,x=22,w=226)
        c.card(502,151);c.text('معاينة الجدول',350,535,15,weight=700);c.line(40,552,350,552)
        c.text('1 · نور حسن',350,582,12);c.text('15 يناير 2027',40,582,12,rtl=False)
        c.text('2 · دورك',350,622,12);c.text('15 فبراير 2027',40,622,12,rtl=False)
    else:
        c.card(263,340);c.text('جمعية الأهل',350,299,17,weight=700);c.text('تعديل',40,299,12,c.p['primary'],rtl=False);c.line(40,319,350,319)
        for i,(label,value) in enumerate([('القسط لكل سهم','1,000 EGP'),('عدد الأعضاء','2'),('الأسهم / أدوار الاستلام','2 / 2'),('قيمة كل دور','2,000 EGP'),('الدورية','كل شهر'),('أول استحقاق','15 يناير 2027')]):
            c.text(label,350,352+43*i,12,c.p['muted']);c.text(value,40,352+43*i,13,weight=600,rtl=False)
        c.note(['التفعيل يبدأ المتابعة فقط. لا يحدث أي','دفع أو تحويل داخل دايرة.'],627)
        c.text('حفظ كمسودة والمتابعة لاحقًا',195,713,12,c.p['primary'],600,center=True)
    c.box(0,750,390,94,c.p['surface'],0);c.line(0,750,390,750)
    c.btn('تفعيل الجمعية' if step==4 else 'متابعة',770)


def transaction_sheet(c,kind):
    round_screen(c)
    titles={'report':'تسجيل إبلاغك بالدفع','review':'راجع الإقرار','reject':'ما الذي يحتاج تصحيحًا؟','payout':'تسجيل تسليم دور مريم','receipt':'استلمت المبلغ كاملًا؟'}
    top=266 if kind in ('report','review','reject') else 245
    c.sheet(titles[kind], 'receipt' if kind in ('report','review') else 'check' if kind=='receipt' else 'info',top)
    y=top+146
    if kind=='reject':
        c.para(['سيظهر السبب لحسن ليصحح إقراره','ويبلغ مجددًا.'],368,y,12,line_height=24)
        c.text('سبب الرفض',368,y+85,12,weight=600)
        c.box(22,y+99,346,115,c.p['surface'],13,c.p['bad'])
        c.text('اكتب سببًا واضحًا ومختصرًا',352,y+131,13,c.p['muted'])
        c.text('سبب الرفض مطلوب · حتى 500 حرف',368,y+239,11,c.p['bad'])
        c.btn('رفض وإرسال السبب',top+421);c.text('إلغاء',195,top+504,13,c.p['muted'],center=True)
        return
    c.text('جمعية الأهل · الدور 2',368,y,12,c.p['muted'])
    if kind=='review':c.text('حسن محمود',368,y+34,15,weight=600)
    c.text('6,000' if kind in ('payout','receipt') else '1,000',368,y+96,43,weight=700)
    c.text('ج.م',230,y+96,13,c.p['muted'])
    c.line(22,y+119,368,y+119)
    c.text('وقت الإبلاغ' if kind=='review' else 'المستفيدة' if kind in ('payout','receipt') else 'موعد الاستحقاق',368,y+149,12,c.p['muted'])
    c.text('اليوم، 10:30 ص' if kind=='review' else 'مريم علي' if kind in ('payout','receipt') else '15 يناير 2027',22,y+149,12,weight=600,rtl=False)
    note_lines={'report':['الدفع يتم خارج دايرة. هذا إقرار منك،','ويحتاج اعتماد المنظّمة.'],'review':['الاعتماد يحدّث سجل التحصيل،','ولا ينفذ تحويلًا ماليًا.'],'payout':['إقرار منك بالتسليم، وليس تحويلًا بنكيًا','أو تأكيد استلام صادرًا من مريم.'],'receipt':['أكد فقط بعد استلام قيمة الدور كاملة','خارج التطبيق. يُسجّل اسمك والتوقيت.']}
    c.note(note_lines[kind],y+176)
    button={'report':'تأكيد الإبلاغ','review':'اعتماد القسط','payout':'تأكيد تسجيل التسليم','receipt':'نعم، استلمت المبلغ كاملًا'}[kind]
    c.btn(button,top+421)
    if kind=='review':c.btn('رفض وطلب تصحيح',top+484,True)
    else:c.text('إلغاء',195,top+504,13,c.p['muted'],center=True)


def invite(c,lost=False):
    round_screen(c,'members');c.sheet('دعوة نور لجمعيتك','link',280)
    c.text('جمعية الأهل · عضوية نور حسن',368,427,12,c.p['muted'])
    if lost:
        c.pill('دعوة فعالة',285,454,83,'good_bg')
        c.para(['الرمز السابق ما زال صالحًا لمن استلمه.','لا يمكن استرجاعه بعد انتهاء جلسة الإنشاء.'],368,518,13,line_height=26)
        c.text('تنتهي في 18 يناير، 10:30 ص',368,603,12,c.p['muted'])
        c.btn('إلغاء وإصدار رمز جديد',651,True)
    else:
        c.box(22,460,346,77,c.p['bg'],14,c.p['border']);c.text('ABCD 2345 EFGH',195,508,24,c.p['text'],700,rtl=False,center=True)
        c.text('صالحة لمدة 72 ساعة',368,566,11,c.p['muted']);c.text('تنتهي 18 يناير',22,566,11,c.p['muted'],rtl=False)
        c.btn('مشاركة الدعوة',603,icon='share');c.btn('نسخ الرمز',667,True,icon='copy')
    c.text('إلغاء الدعوة',195,754,12,c.p['bad'],600,center=True)
    c.text('تم',195,800,13,c.p['primary'],600,center=True)


def miscellaneous(c,kind):
    if kind=='brand':
        c.shell('هوية تجمع، ولا تزاحم');c.card(126,114)
        c.logo(289,151,55)
        c.text('دايرة',273,182,31,weight=700);c.text('كل دور واضح.',273,213,12,c.p['muted'])
        c.text('الألوان',368,280,18,weight=700)
        for i,(name,code) in enumerate([('Modern Blue',P['blue']),('Ink Navy',P['navy']),('Circle Teal',P['cyan']),('Calm Canvas',P['bg'])]):
            x=22+(i%2)*180;y=301+(i//2)*123;c.box(x,y,166,108,c.p['surface'],16,c.p['border']);c.box(x+10,y+10,146,43,code,10,c.p['border'] if i==3 else None);c.text(name,x+83,y+77,12,center=True,rtl=False);c.text(code,x+83,y+96,10,c.p['muted'],center=True,rtl=False)
        c.text('الحالة تُقرأ، لا تُخمن',368,593,18,weight=700)
        c.pill('معتمد',306,617,62,'good_bg');c.pill('قيد المراجعة',196,617,98,'warn_bg');c.pill('متأخر',125,617,61,'bad_bg');c.pill('مسودة',54,617,61)
        c.btn('تأكيد الإجراء',681);c.text('Cairo · 48px touch · 8pt grid',195,790,12,c.p['muted'],center=True,rtl=False)
    elif kind=='circles':
        c.shell('جمعياتي','كل جمعية، بتفاصيلها',nav='circles');c.icon('plus',25,63,c.p['primary'])
        for x,w,label,active in [(278,90,'الكل (3)',True),(174,95,'النشطة (2)',False),(22,143,'المسودات (1)',False)]:
            c.box(x,130,w,43,c.p['soft'] if active else c.p['surface'],12,None if active else c.p['border']);c.text(label,x+w/2,157,11,c.p['primary'] if active else c.p['muted'],600,center=True)
        c.circle_card(193);c.circle_card(364,True);c.card(537,132)
        c.text('جمعية الأصدقاء',350,573,15,weight=700);c.pill('مسودة',40,551,58)
        c.text('أكمل الأعضاء والجدول قبل التفعيل.',350,608,12,c.p['muted']);c.text('متابعة الإعداد',350,646,12,c.p['primary'],600)
        c.btn('الانضمام لجمعية بدعوة',691,True,icon='link')
    elif kind=='empty':
        c.shell('أهلًا بك في دايرة',nav='home',subtitle='خطوتك الأولى تبدأ من هنا.')
        c.circle(195,276,71,'none',c.p['border']);c.circle(195,276,47,'none',c.p['border'])
        for angle,color in [(270,c.p['blue']),(30,c.p['cyan']),(150,c.p['primary'])]:
            x=195+71*math.cos(math.radians(angle));y=276+71*math.sin(math.radians(angle));c.circle(x,y,13,color,c.p['surface'],5)
        c.icon('people',177,258,c.p['primary'],36)
        c.text('لمة تبدأ بخطوة',195,411,27,weight=700,center=True)
        c.para(['أنشئ جمعية مع من تثق بهم،','أو انضم لجمعية دُعيت إليها.'],195,449,13,line_height=27,center=True)
        c.btn('أنشئ جمعيتك الأولى',530,icon='plus');c.btn('الانضمام برمز دعوة',596,True,icon='link')
        c.para(['دايرة ينظّم المتابعة. الدفع والاستلام','يتمان خارج التطبيق.'],195,706,11,center=True)
    elif kind=='join':
        c.shell('الانضمام بدعوة',back=True);c.box(306,151,62,62,c.p['soft'],22);c.icon('link',322,167,c.p['primary'],29)
        c.text('عندك مكان في الدايرة',368,264,28,weight=700)
        c.para(['أدخل الرمز الذي أرسله لك منظّم الجمعية.','سنُظهر الاسم والجمعية قبل الانضمام.'],368,301,13,line_height=27)
        c.field('رمز الدعوة','ABCD 2345 EFGH',410);c.text('المسافات والشرطات لا تفرق.',368,501,11,c.p['muted'])
        c.btn('عرض الدعوة',552,icon='back');c.note(['تأكد أن الاسم في الدعوة يمثل عضويتك.','لن تنضم قبل مراجعة التفاصيل وقبولها.'],653)
    elif kind=='join-preview':
        miscellaneous(c,'join');c.sheet('جمعية الأهل','people',340)
        c.text('أنت مدعو إلى هذه الجمعية',368,486,12,c.p['muted']);c.card(517,93)
        c.text('الاسم الذي أضافته المنظّمة',350,548,11,c.p['muted']);c.text('مريم علي',350,580,18,weight=700)
        c.note(['تأكد أن هذه عضويتك. عند القبول','ترتبط بحسابك الحالي بعد تأكيد الخادم.'],631)
        c.btn('نعم، هذه عضويتي · انضمام',740)
    elif kind=='offline':
        c.shell('تعذر تحديث البيانات');c.circle(195,271,63,'none',c.p['border']);c.icon('wifi',174,249,c.p['primary'],42)
        c.text('الاتصال انقطع',195,413,28,weight=700,center=True)
        c.para(['لم نستطع الوصول إلى الخادم.','لم نؤكد أي إبلاغ أو اعتماد.','حاول عندما يعود الاتصال.'],195,455,13,line_height=27,center=True)
        c.btn('إعادة المحاولة',589);c.text('الرجوع للرئيسية',195,693,13,c.p['primary'],600,center=True)
    elif kind=='expired':
        c.shell('رابط التأكيد',back=True);c.box(163,203,64,64,c.p['soft'],23);c.icon('clock',180,220,c.p['primary'],30)
        c.text('الرابط لم يعد صالحًا',195,350,26,weight=700,center=True)
        c.para(['قد يكون انتهى أو استُخدم من قبل.','اطلب رسالة جديدة، أو سجّل الدخول','إذا أكدت بريدك بالفعل.'],195,394,13,line_height=27,center=True)
        c.btn('طلب رسالة جديدة',545);c.btn('تسجيل الدخول',610,True)
    elif kind=='settings':
        c.shell('الإعدادات',nav='settings');c.card(129,121);c.avatar('م',306,150);c.text('مريم علي',294,174,16,weight=700);c.text('mariam@example.com',294,199,11,c.p['muted']);c.pill('بريد مؤكد',43,209,79,'good_bg')
        c.text('اضبط التجربة كما تحب',368,292,17,weight=700);c.card(311,125)
        for y,name,value,icon in [(346,'اللغة','العربية','people'),(406,'المظهر','فاتح','moon')]:
            c.icon(icon,325,y-14,c.p['muted'],19);c.text(name,310,y+1,13);c.text(value,54,y+1,12,c.p['muted'],rtl=False);c.icon('chevron',35,y-14,c.p['muted'],18)
        c.line(40,374,350,374);c.text('حسابك',368,482,17,weight=700);c.card(502,126)
        c.text('استعادة كلمة المرور',350,540,13);c.line(40,563,350,563);c.text('تسجيل الخروج',350,603,13,c.p['bad'])
        c.note(['دورك وصلاحياتك يختلفان حسب','العضوية المرتبطة بكل جمعية.'],655)
    elif kind=='complete':
        c.shell('جمعية الأهل','اكتملت الجمعية',True);c.circle(195,221,39,c.p['good_bg']);c.icon('check',179,205,c.p['good'],32)
        c.text('كل دور وصل لصاحبه',195,328,27,weight=700,center=True)
        c.para(['سُجل تأكيد الاستلام لآخر دور.','تبقى التفاصيل والسجل متاحين.'],195,369,13,line_height=27,center=True)
        c.card(446,162)
        for i,(label,value) in enumerate([('الأدوار المكتملة','6 / 6'),('قيمة كل دور','6,000 EGP'),('آخر استلام','15 يونيو 2027')]):
            c.text(label,350,482+44*i,12,c.p['muted']);c.text(value,40,482+44*i,13,weight=600,rtl=False)
        c.btn('عرض سجل النشاط',640,True);c.text('العودة لجمعياتي',195,746,13,c.p['primary'],600,center=True)
    elif kind=='english':
        c.shell(nav='home');c.text('Daira',22,83,29,weight=700,rtl=False);c.avatar('M',326,48)
        c.text('Hello, Mariam',22,137,27,weight=700,rtl=False);c.text('Here’s where your circles stand.',22,163,12,c.p['muted'],rtl=False)
        c.box(22,186,346,224,c.p['navy'],24);c.text('YOUR NEXT INSTALLMENT',42,222,10,'#D7E4F5',600,rtl=False)
        c.text('Family circle · Round 2 of 6',42,259,12,'#D7E4F5',rtl=False);c.text('1,000',42,310,42,'#FFFFFF',700,rtl=False);c.text('EGP',168,309,13,'#D7E4F5',rtl=False)
        c.text('Due in 2 days · 15 January',42,339,12,'#D7E4F5',rtl=False);c.box(42,355,306,40,'#FFFFFF',12);c.text('I have paid',195,381,14,'#244E9D',700,center=True,rtl=False)
        c.text('Your circles',22,470,18,weight=700,rtl=False);c.text('View all (2)',368,470,11,c.p['primary'])
        c.card(492,162);c.text('Family circle',42,529,17,weight=700,rtl=False);c.text('6 members · Monthly',42,555,11,c.p['muted'],rtl=False)
        c.pill('Active',296,510,54,'good_bg');c.line(40,572,350,572);c.text('Per share',42,600,12,c.p['muted'],rtl=False);c.text('1,000 EGP',350,600,14,weight=700)
        c.progress(617,33);c.text('Round 2 of 6',42,644,10,c.p['muted'],rtl=False)
        c.btn('Join with an invitation',680,True)
    elif kind=='actions':
        c.shell('الإجراءات','الخطوة الصحيحة، في وقتها',nav='actions')
        for x,w,label,active in [(252,116,'مطلوب منك (1)',True),(121,122,'بانتظار الآخرين',False),(22,90,'أُنجز مؤخرًا',False)]:
            c.box(x,131,w,45,c.p['soft'] if active else c.p['surface'],12,None if active else c.p['border']);c.text(label,x+w/2,159,10,c.p['primary'] if active else c.p['muted'],600,center=True)
        c.card(198,293);c.pill('يحتاج مراجعتك',245,217,105)
        c.text('راجع إقرار حسن',350,278,22,weight=700)
        c.text('جمعية الأهل · الدور 2',350,310,12,c.p['muted'])
        c.text('أبلغ حسن اليوم، 10:30 ص',350,341,12,c.p['muted'])
        c.text('1,000',350,399,37,weight=700);c.text('ج.م',241,399,12,c.p['muted'])
        c.btn('مراجعة الإقرار',423,x=40,w=310)
    elif kind=='loading':
        c.shell('جمعياتي',nav='circles',subtitle='جارٍ تحميل أحدث البيانات…')
        for base in (153,352):
            c.card(base,174);c.box(305,base+18,44,44,c.p['soft'],14)
            c.box(170,base+26,121,13,c.p['soft'],6);c.box(205,base+49,86,9,c.p['soft'],4)
            c.line(40,base+81,350,base+81);c.box(232,base+103,118,11,c.p['soft'],5)
            c.box(40,base+139,310,6,c.p['soft'],3)
        c.text('نحمّل جمعياتك وحالاتها الحالية.',195,611,12,c.p['muted'],center=True)
    elif kind=='session':
        c.shell();c.logo(324,61,44);c.text('دايرة',311,96,30,weight=700)
        c.text('نرجع لحسابك بأمان',368,191,28,weight=700)
        c.note(['انتهت جلستك. سجّل الدخول للمتابعة.','لا تُعرض بيانات الحساب السابق هنا.'],233)
        c.field('البريد الإلكتروني','',360);c.field('كلمة المرور','',469,password=True)
        c.btn('تسجيل الدخول',588);c.text('نسيت كلمة المرور؟',195,691,13,c.p['primary'],600,center=True)


SPECS = [
 ('00 · Foundations','brand',{}),('01 · Sign in','login',{}),('02 · Create account','signup',{}),('03 · Confirm email','verify',{}),
 ('04 · Recovery','forgot',{}),('05 · New password / Odoo','reset',{}),('06 · First circle','empty',{}),('07 · Member home','home',{}),
 ('08 · Organizer home','home',{'organizer':True}),('09 · My circles','circles',{}),('10 · Setup / Basics','create',{'step':1}),('11 · Setup / Members','create',{'step':2}),
 ('12 · Setup / Schedule','create',{'step':3}),('13 · Setup / Review','create',{'step':4}),('14 · Current round','round',{}),('15 · Members / You + Organizer','members',{}),
 ('16 · Activity','activity',{}),('17 · Report payment','transaction',{'kind':'report'}),('18 · Review report','transaction',{'kind':'review'}),('19 · Reject / Required reason','transaction',{'kind':'reject'}),
 ('20 · Record handover','transaction',{'kind':'payout'}),('21 · Confirm receipt','transaction',{'kind':'receipt'}),('22 · Share invitation','invite',{}),('23 · Active / Secret unavailable','invite',{'lost':True}),
 ('24 · Enter invitation','join',{}),('25 · Review membership','join-preview',{}),('26 · Offline / No false success','offline',{}),('27 · Expired link','expired',{}),
 ('28 · Settings','settings',{}),('29 · Circle complete','complete',{}),('30 · Dark / Member home','home',{'dark':True}),('31 · English / LTR','english',{'english':True}),
 ('32 · Actions / Organizer','actions',{}),('33 · Loading','loading',{}),('34 · Session expired','session',{}),('35 · Ready for handover','round',{'stage':1}),
]


def draw(kind,options=None):
    options=dict(options or {});c=Canvas(options.pop('dark',False),options.pop('english',False))
    if kind=='home':home(c,**options)
    elif kind in ('login','signup','verify','forgot','reset'):auth(c,kind)
    elif kind=='create':create(c,**options)
    elif kind in ('round','members','activity'):round_screen(c,kind,**options)
    elif kind=='transaction':transaction_sheet(c,**options)
    elif kind=='invite':invite(c,**options)
    else:miscellaneous(c,kind)
    return c.markup()


def svg_document(width,height,content):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}"><title>Daira / Odoo App Revamp — editable design handoff</title><desc>Illustrative, non-production UI. Amounts, people and dates are fictional. Text and vector groups are editable; these are not Figma Auto Layout components.</desc>{content}</svg>'


def build():
    atlas=[];columns=4;width=columns*430+40;height=240+math.ceil(len(SPECS)/columns)*920
    atlas.append(f'<rect width="{width}" height="{height}" fill="#EAEFF6"/>')
    c=Canvas();c.text('DAIRA / PRODUCT EXPERIENCE',40,65,13,'#607390',600,rtl=False)
    c.text('كل دور واضح.',width-40,116,41,weight=700);c.text('تصميم مقترح · نسخة Odoo · شاشات قابلة للتحرير · بيانات توضيحية',width-40,156,14,P['muted'])
    atlas.append(c.markup())
    for index,(title,kind,options) in enumerate(SPECS):
        col=3-index%columns;row=index//columns;x=40+col*430;y=224+row*920
        atlas.append(f'<g id="frame-{index:02d}" data-name="{escape(title)}" transform="translate({x} {y})">')
        atlas.append(f'<title>{escape(title)}</title><text x="0" y="-16" font-family="Cairo" font-size="13" font-weight="600" fill="#344963">{escape(title)}</text>')
        atlas.append(draw(kind,options));atlas.append('</g>')
    (ROOT/'screen-atlas.svg').write_text(svg_document(width,height,''.join(atlas)),encoding='utf-8')
    review=[];w=1740;h=1136
    review.append(f'<rect width="{w}" height="{h}" fill="#EDF1F6"/>')
    c=Canvas();c.text('DAIRA / A CLEARER CIRCLE',40,57,11,'#657996',600,rtl=False)
    c.text('كل دور واضح.',1700,95,43,weight=700)
    c.text('هوية متصلة. خطوات قصيرة. وقرار واحد واضح في كل لحظة.',1700,131,14,P['muted'])
    c.text('تصميم مقترح للمراجعة · بيانات توضيحية',40,126,12,P['muted'],rtl=False)
    review.append(c.markup())
    for index,(title,kind,opts) in enumerate([
        ('01 / خطوتك التالية','home',{}),('02 / الدور من أول نظرة','round',{}),
        ('03 / كل عضو يعرف مكانه','members',{}),('04 / إعداد بلا تعقيد','create',{'step':1}),
    ]):
        x=40+(3-index)*425;y=211
        review.append(f'<g transform="translate({x} {y})"><text x="390" y="-17" font-family="Cairo" font-size="13" font-weight="600" fill="#304662" text-anchor="end">{escape(title)}</text>{draw(kind,opts)}</g>')
    c=Canvas();c.line(40,1080,1700,1080,'#D2DDEB');c.text('Modern Blue / Ink Navy / Circle Teal',40,1112,11,P['muted'],rtl=False);c.text('التحصيل ≠ التسليم ≠ تأكيد الاستلام',1700,1112,12,P['muted']);review.append(c.markup())
    (ROOT/'design-preview.svg').write_text(svg_document(w,h,''.join(review)),encoding='utf-8')
    tokens={
        'name':'Daira / Every turn, clear','status':'implemented-refined-ux',
        'brand':{'status':'approved','symbol':'../brand/people-circle/daira-people-circle.svg','icon':'../brand/people-circle/daira-app-icon.svg','referenceSize':512,'preferredInAppSize':40,'clearSpaceInReferenceUnits':30.5},
        'figmaTarget':'https://www.figma.com/design/fygsh7qTdLuTvd0nqwSpV3/Daira---Odoo-App-Revamp',
        'color':{'light':P,'dark':DARK},
        'type':{'family':'Cairo','weights':[400,600,700],'display':28,'title':24,'section':18,'body':15,'supporting':12,'caption':11,'money':38},
        'spacing':[4,8,12,16,20,24,32,40,48],
        'radius':{'field':13,'button':15,'card':21,'hero':24,'sheet':28},
        'minimumTapTarget':48,'textScale':[1,1.5],
        'motionMs':{'feedback':150,'sheet':180},
        'breakpoints':{'compact':320,'reference':390,'tablet':700},
        'frames':[{'name':name,'kind':kind,'options':options} for name,kind,options in SPECS],
    }
    (ROOT/'design-tokens.json').write_text(json.dumps(tokens,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(f'Generated {len(SPECS)} editable SVG screen groups, one review board and design tokens')


if __name__=='__main__':build()
