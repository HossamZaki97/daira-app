"""Approved editable logo based on the user's three-people circle reference.

No launcher resources are changed. Standard library generation; optional resvg
rendering is a separate design-tool step, not an app dependency.
"""
from pathlib import Path
from html import escape
import math
import xml.etree.ElementTree as ET
import json

ROOT = Path(__file__).resolve().parent
APP = ROOT.parents[2]
BLUE = '#356DF3'
INK = '#142C50'
OUTER = 140
INNER = 113
BODY_CENTER = 116
BODY_RADIUS = 50
HEAD_CENTER = 185
HEAD_RADIUS = 30.5
# Balance the actual visible bounds, not the center of the construction circle.
RAW_TOP = 256 - HEAD_CENTER - HEAD_RADIUS
RAW_BOTTOM = 256 + OUTER
OPTICAL_Y = 256 - (RAW_TOP + RAW_BOTTOM) / 2
ADAPTIVE_SCALE = 0.65
SMALL_PIXEL_SHIFT = -0.25
SMALL_OPTICAL_Y = OPTICAL_Y + SMALL_PIXEL_SHIFT * 512 / 24


def point(radius, angle):
    angle = math.radians(angle)
    return (256 + radius * math.cos(angle), 256 + radius * math.sin(angle))


def xy(value): return f'{value[0]:.5f} {value[1]:.5f}'


def body_path():
    # A true circular outer contour. Three identical chest curves shape the
    # shared space, with a 120-degree rotation between each pair of people.
    delta = math.degrees(math.acos((INNER**2 + BODY_CENTER**2 - BODY_RADIUS**2) /
                                   (2 * INNER * BODY_CENTER)))
    outer = f'M 256 {256-OUTER} A {OUTER} {OUTER} 0 1 1 256 {256+OUTER} A {OUTER} {OUTER} 0 1 1 256 {256-OUTER} Z'
    inner = 'M ' + xy(point(INNER, -150))
    for angle in (-90, 30, 150):
        inner += f' A {INNER} {INNER} 0 0 1 ' + xy(point(INNER, angle-delta))
        inner += f' A {BODY_RADIUS} {BODY_RADIUS} 0 0 0 ' + xy(point(INNER, angle+delta))
    inner += f' A {INNER} {INNER} 0 0 1 ' + xy(point(INNER, 210)) + ' Z'
    return outer + ' ' + inner


def mark(color=BLUE, optical_y=OPTICAL_Y):
    heads = ''.join(f'<circle cx="256" cy="{256-HEAD_CENTER}" r="{HEAD_RADIUS}" transform="rotate({angle} 256 256)"/>'
                    for angle in (0, 120, 240))
    return (f'<g fill="{color}" transform="translate(0 {optical_y})">'
            f'<path d="{body_path()}" fill-rule="evenodd"/>{heads}</g>')


def text(label, x, y, size=16, color=INK, weight=400, anchor='end'):
    return f'<text x="{x}" y="{y}" font-family="Cairo" font-size="{size}" font-weight="{weight}" text-anchor="{anchor}" fill="{color}">{escape(label)}</text>'


def tile(x, y, side, color=BLUE, bg='#FFFFFF', rounded=True, circular=False):
    shape = f'<circle cx="256" cy="256" r="256" fill="{bg}"/>' if circular else f'<rect width="512" height="512" rx="{105 if rounded else 0}" fill="{bg}"/>'
    return f'<g transform="translate({x} {y}) scale({side/512})">{shape}{mark(color,SMALL_OPTICAL_Y if side==24 else OPTICAL_Y)}</g>'


def build():
    root = '<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512" role="img" aria-labelledby="title description">'
    meta = '<title id="title">Daira — approved three-people circle</title><desc id="description">Approved identity. Three equal heads and rounded bodies at 120-degree intervals surround a shared space. Flat Daira blue, transparent background. Optically centered. Integrated with the Daira application.</desc>'
    (ROOT/'daira-people-circle.svg').write_text(root + meta + mark() + '</svg>\n', encoding='utf-8')
    icon_meta = meta.replace('transparent background', 'opaque white background')
    (ROOT/'daira-app-icon.svg').write_text(root + icon_meta + '<rect width="512" height="512" fill="#FFFFFF"/>' + mark() + '</svg>\n', encoding='utf-8')
    small_root = root.replace('width="512" height="512"','width="24" height="24"')
    small_meta = meta.replace('Optically centered.', 'Pixel-grid aligned at 24 pixels; the same geometry is shifted vertically by -0.25 output pixels.')
    (ROOT/'daira-people-circle-24.svg').write_text(small_root + small_meta + mark(optical_y=SMALL_OPTICAL_Y) + '</svg>\n',encoding='utf-8')
    half_width = HEAD_CENTER*math.cos(math.radians(30)) + HEAD_RADIUS
    worst_radius = max(math.hypot(HEAD_CENTER*math.cos(math.radians(a)), HEAD_CENTER*math.sin(math.radians(a))+OPTICAL_Y)+HEAD_RADIUS for a in (-90,30,150))
    specs = {
        'status':'approved-identity-integrated', 'viewBox':[0,0,512,512],
        'primaryColor':BLUE, 'background':'white for app icon; transparent for symbol',
        'equalPeople':3, 'rotationDegrees':120, 'headRadius':HEAD_RADIUS,
        'visibleBounds':{'left':256-half_width,'top':RAW_TOP+OPTICAL_Y,'right':256+half_width,'bottom':RAW_BOTTOM+OPTICAL_Y},
        'opticalTranslationY':OPTICAL_Y, 'clearSpaceMinimum':HEAD_RADIUS,
        'preferredInAppSizes':[32,40,48], 'smallUtilitySize':24,
        'previewSizes':[24,32,48,96,192,512],
        'smallRasterAlignment':{'size':24,'asset':'daira-people-circle-24.svg','verticalPixelShift':SMALL_PIXEL_SHIFT,'geometryChanged':False},
        'circularMask':{'radius':256,'artworkMaximumRadius':worst_radius,'minimumClearance':256-worst_radius},
        'adaptiveDesignGuide':{'canvasDp':108,'safeCircleDiameterDp':66,'foregroundScaleWithin512Canvas':ADAPTIVE_SCALE,
                               'maximumArtworkRadiusDp':worst_radius*ADAPTIVE_SCALE*108/512,
                               'source':'https://developer.android.com/develop/ui/compose/system/icon_design_adaptive'},
        'launcherResourcesChanged':True,
    }
    (ROOT/'logo-specs.json').write_text(json.dumps(specs,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    preview = ['<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="1440" height="1080" viewBox="0 0 1440 1080">',
               '<title>Daira — approved identity and sizing</title>',
               '<rect width="1440" height="1080" fill="#EFF3F9"/>',
               text('DAIRA / IDENTITY REFINEMENT',64,58,11,'#6D7D94',600,'start'),
               text('ثلاثة أشخاص. دايرة واحدة.',1376,108,43,weight=700),
               text('شعار معتمد · تمركز بصري دقيق · أصول التصميم فقط',1376,150,16,'#65758C')]
    # Main icon: no material, gradient or heavy shadow in the underlying asset.
    preview += [text('الأيقونة المعتمدة',1186,210,16,weight=600,anchor='middle'),tile(996,235,380),
                text('مساحة مشتركة تحيط بها ثلاثة أفراد متساوين',1186,650,13,'#65758C',anchor='middle')]
    # Brand lockup uses the same mark, without putting text inside the launcher.
    preview += [tile(753,245,112),text('دايرة',725,335,96,weight=700),
                text('جمعياتك، دورًا بدور',725,384,23,'#65758C'),
                '<path d="M64 424H865" stroke="#D9E2EF"/>',
                text('نفس الرمز، عبر استخدامات الهوية',865,462,14,'#65758C',600),
                tile(742,486,112,circular=True),tile(517,486,112,color='#FFFFFF',bg=BLUE),tile(292,486,112,color=INK),
                text('قص دائري',798,629,13,'#65758C',anchor='middle'),
                text('نسخة معكوسة',573,629,13,'#65758C',anchor='middle'),
                text('أحادي اللون',348,629,13,'#65758C',anchor='middle')]
    preview += ['<rect x="64" y="704" width="1312" height="290" rx="25" fill="#FFFFFF"/>',
                text('المقارنة مع الأيقونة الحالية',1338,749,15,weight=600),
                '<path d="M867 738V958" stroke="#E1E7F0"/>']
    old = ET.parse(APP/'assets/brand/daira_icon.svg').getroot()
    # Inline the old vector as read-only reference. Its app source stays intact.
    old.set('x','1184');old.set('y','784');old.set('width','112');old.set('height','112')
    preview.append(ET.tostring(old,encoding='unicode'))
    preview += [tile(968,784,112),text('داخل التطبيق حاليًا',1240,931,13,'#65758C',anchor='middle'),text('الشعار المعتمد',1024,931,13,BLUE,600,'middle'),
                text('اختبار الوضوح بالحجم الصغير',821,749,15,weight=600),
                tile(726,806,48),tile(601,818,24),tile(458,806,48,color=INK),
                text('48 px',750,898,12,'#65758C',anchor='middle'),text('24 px',613,898,12,'#65758C',anchor='middle'),
                text('48 px / لون واحد',482,898,12,'#65758C',anchor='middle'),
                text('المقاسات فعلية عند فتح الصورة بتكبير 100٪',821,949,11,'#8190A5'),
                text('الأيقونة الحالية وواجهات التطبيق لم تتغير',1376,1040,13,'#65758C'),
                text('Flat color / Editable SVG / 120° symmetry',64,1040,11,'#65758C',anchor='start'),'</svg>']
    board='\n'.join(line.rstrip() for line in ''.join(preview).splitlines())+'\n'
    (ROOT/'logo-review.svg').write_text(board,encoding='utf-8')
    print('Generated approved symbol, design icon, sizing specification and review board; app assets unchanged')


if __name__=='__main__': build()
