"""Daira icon A2: eight softened ring segments, the first (amber) is "your turn"."""
import math

GAP = 3.6           # degrees each side of a segment
RO, RI, R = 31, 18.5, 2.0   # in a 100x100 app icon: outer, inner radius, corner softening
NAVY, AMBER, WHITE = '#1E2A4A', '#F0A202', '#FFFFFF'
GRAD = ('#27365F', '#19223D')


def seg_path(i, cx, cy, ro, ri, inset):
    a0 = math.radians(-90 + i * 45 + GAP)
    a1 = math.radians(-90 + (i + 1) * 45 - GAP)
    ro2, ri2 = ro - inset, ri + inset
    da, db = math.asin(inset / ro2), math.asin(inset / ri2)
    p = lambda r, a: (cx + r * math.cos(a), cy + r * math.sin(a))
    x0, y0 = p(ro2, a0 + da); x1, y1 = p(ro2, a1 - da); x2, y2 = p(ri2, a1 - db); x3, y3 = p(ri2, a0 + db)
    return (f'M{x0:.3f} {y0:.3f}A{ro2:.3f} {ro2:.3f} 0 0 1 {x1:.3f} {y1:.3f}'
            f'L{x2:.3f} {y2:.3f}A{ri2:.3f} {ri2:.3f} 0 0 0 {x3:.3f} {y3:.3f}Z')


def mark_geometry(scale_to=None):
    """Segments in a 100 box. scale_to: outer radius when the mark is drawn alone."""
    k = (scale_to / RO) if scale_to else 1
    return RO * k, RI * k, R * k


def svg_mark(colors, cx=50, cy=50, scale_to=None):
    ro, ri, r = mark_geometry(scale_to)
    out = []
    for i in range(8):
        c = colors[0] if i == 0 else colors[1]
        out.append(f'<path d="{seg_path(i, cx, cy, ro, ri, r)}" fill="{c}" stroke="{c}" stroke-width="{2 * r:.3f}" stroke-linejoin="round"/>')
    return ''.join(out)


def svg_icon(size=1024, rounded=0, bg='grad', ring=WHITE, accent=AMBER, extra=''):
    fill = 'url(#g)' if bg == 'grad' else bg
    defs = f'<defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{GRAD[0]}"/><stop offset="1" stop-color="{GRAD[1]}"/></linearGradient></defs>'
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="{size}" height="{size}">{defs}'
            f'<rect width="100" height="100" rx="{rounded}" fill="{fill}"/>{svg_mark((accent, ring))}{extra}</svg>')


def svg_mark_only(ring, accent, size=512):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="{size}" height="{size}">'
            f'{svg_mark((accent, ring), scale_to=47)}</svg>')


def vector_paths(colors, cx, cy, scale_to=None):
    ro, ri, r = mark_geometry(scale_to)
    out = []
    for i in range(8):
        c = colors[0] if i == 0 else colors[1]
        out.append(f'  <path android:fillColor="{c}" android:strokeColor="{c}" android:strokeWidth="{2 * r:.3f}" '
                   f'android:strokeLineJoin="round" android:pathData="{seg_path(i, cx, cy, ro, ri, r)}"/>')
    return '\n'.join(out)
