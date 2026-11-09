"""Loopback-only review server. Exposes only design files and approved assets."""
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote, urlsplit

DESIGN = Path(__file__).resolve().parent
APP = DESIGN.parent.parent
PUBLIC = {
    '/design/revamp/' + name: DESIGN / name for name in (
        'index.html', 'studio.css', 'prototype-ux.js', 'create-preview.js', 'prototype.js', 'screen-atlas.svg',
        'design-preview.svg', 'design-preview.png', 'design-tokens.json', 'README.md',
    )
}
PUBLIC['/'] = PUBLIC['/design/revamp/index.html']
PUBLIC['/design/revamp/'] = PUBLIC['/design/revamp/index.html']
for name in ('Cairo-Regular.ttf', 'Cairo-SemiBold.ttf', 'Cairo-Bold.ttf', 'OFL.txt'):
    PUBLIC['/assets/fonts/' + name] = APP / 'assets/fonts' / name
PUBLIC['/assets/brand/daira_icon.svg'] = APP / 'assets/brand/daira_icon.svg'
for name in ('daira-people-circle.svg', 'daira-people-circle-24.svg', 'daira-app-icon.svg', 'logo-review.svg', 'logo-review.png', 'logo-specs.json'):
    PUBLIC['/design/brand/people-circle/' + name] = DESIGN.parent / 'brand/people-circle' / name


class ReviewHandler(SimpleHTTPRequestHandler):
    def translate_path(self, path):
        return str(PUBLIC.get(unquote(urlsplit(path).path), DESIGN / '.not-public'))

    def list_directory(self, path):
        self.send_error(404)
        return None

    def end_headers(self):
        self.send_header('Cache-Control', 'no-store')
        self.send_header('X-Content-Type-Options', 'nosniff')
        self.send_header('Referrer-Policy', 'no-referrer')
        self.send_header('Content-Security-Policy',
                         "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; "
                         "font-src 'self'; img-src 'self'; connect-src 'none'; "
                         "frame-ancestors 'none'; base-uri 'none'; form-action 'none'")
        super().end_headers()


if __name__ == '__main__':
    print('Daira design review: http://127.0.0.1:8096/design/revamp/index.html', flush=True)
    ThreadingHTTPServer(('127.0.0.1', 8096), ReviewHandler).serve_forever()
