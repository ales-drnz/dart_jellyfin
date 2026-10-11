"""Generates the package icon (imgs/dart_jellyfin.png) and the README
diagrams in imgs/diagrams, as PNG only, in the style of mpv_audio_kit's.

The branding is two flat colors: the icon's navy plate and light blue glyph.
Library nodes take the navy and your code's nodes the light blue. The
PNGs are transparent, so they sit on the page's own ground: text inside a
node relies on the node's fill, and the free text, arrows and bands use mid
tones that read on white and on GitHub's dark ground alike. The SVGs are drawn in a temporary directory and
exported at 2x with rsvg-convert.

Run from the repository root: python3 tool/diagrams/generate.py
"""
import os, subprocess, tempfile

OUT = os.path.join('imgs', 'diagrams')
ICON = os.path.join('imgs', 'dart_jellyfin.png')
NAVY = '#0D2A75'
LIGHT_BLUE = '#A8EDFA'
SANS = "Noto Sans, system-ui, -apple-system, Segoe UI, sans-serif"
MONO = "Noto Sans Mono, ui-monospace, SFMono-Regular, Menlo, monospace"

PAL = {
    # ink: text inside neutral nodes, on their own fill. label, muted, line,
    # main, fail and band sit on the page ground, light or dark.
    'light': dict(ink='#1F2328', label='#6B7689', muted='#6B7689', line='#7D8796', main='#2F6FD6',
                  fail='#D1392B', failSoft='#FDE3E0', neutral='#E6EBF3', band='#7D8796'),
}


def esc(t):
    return t.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')


class D:
    def __init__(self, name, w, h, theme, label):
        self.name, self.w, self.h, self.t, self.c = name, w, h, theme, PAL[theme]
        self.label = label
        self.body = []

    def add(self, s):
        self.body.append(s)

    def svg(self):
        c = self.c
        defs = f'''<defs>
{''.join(f'<marker id="m{n}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="10" markerHeight="10" markerUnits="userSpaceOnUse" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="{col}"/></marker>' for n, col in (('main', c['main']), ('sec', c['line']), ('fail', c['fail'])))}
</defs>'''
        return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {self.w} {self.h}" width="{self.w}" height="{self.h}" '
                f'role="img" aria-label="{esc(self.label)}">\n{defs}\n' + '\n'.join(self.body) + '\n</svg>\n')

    # role: lib (navy), app (cyan), neutral, fail, ghost (dimmed text)
    def node(self, x, y, w, h, title, sub=None, role='lib', mono=True, r=None, sub2=None, size=15):
        c = self.c
        r = 10 if r is None else r
        if role == 'lib':
            fill, tc, sc, op = NAVY, '#FFFFFF', '#C9DBFF', 1
        elif role == 'app':
            fill, tc, sc, op = LIGHT_BLUE, NAVY, '#1D3F7E', 1
        elif role == 'fail':
            fill, tc, sc, op = c['failSoft'], '#B42318', '#59636E', 1
        elif role == 'ghost':
            fill, tc, sc, op = c['neutral'], '#59636E', '#59636E', 1
        else:
            fill, tc, sc, op = c['neutral'], c['ink'], '#59636E', 1
        self.add(f'<rect x="{x - w / 2}" y="{y - h / 2}" width="{w}" height="{h}" rx="{r}" fill="{fill}" fill-opacity="{op}"/>')
        lines = [s for s in (sub, sub2) if s]
        ty = y + 5 - 9 * len(lines)
        self.add(f'<text x="{x}" y="{ty}" text-anchor="middle" font-family="{MONO if mono else SANS}" font-size="{size}" font-weight="600" fill="{tc}">{esc(title)}</text>')
        for i, s in enumerate(lines):
            self.add(f'<text x="{x}" y="{ty + 19 + 16 * i}" text-anchor="middle" font-family="{SANS}" font-size="12" fill="{sc}">{esc(s)}</text>')

    def arrow(self, d, kind='main', dash=False, head=True, width=None):
        c = self.c
        col = {'main': c['main'], 'sec': c['line'], 'fail': c['fail']}[kind]
        w = width or (2.2 if kind == 'main' else 1.7)
        dsh = ' stroke-dasharray="5 5"' if dash else ''
        mk = f' marker-end="url(#m{kind})"' if head else ''
        self.add(f'<path d="{d}" fill="none" stroke="{col}" stroke-width="{w}"{dsh}{mk}/>')

    def text(self, x, y, t, anchor='middle', color='muted', size=12, mono=False, weight=400):
        col = self.c.get(color, color)
        self.add(f'<text x="{x}" y="{y}" text-anchor="{anchor}" font-family="{MONO if mono else SANS}" font-size="{size}" font-weight="{weight}" fill="{col}">{esc(t)}</text>')

    def band(self, x, y, w, h, title):
        self.add(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="14" fill="{self.c["band"]}" fill-opacity="0.12"/>')
        self.text(x + 16, y + 24, title, anchor='start', color='muted', size=12, weight=600)


def architecture(t):
    d = D('architecture', 900, 470, t, 'Architecture: your code, the client, the shared transport and the servers')
    d.band(20, 20, 860, 150, 'Your app, calling isolate')
    d.node(170, 105, 230, 64, 'Your code', 'widgets, services', role='app', mono=False)
    d.node(450, 105, 230, 64, 'JellyfinClient', 'one sub-API per domain', role='lib')
    d.node(730, 105, 230, 64, 'Typed models', 'each with its raw map', role='lib', mono=False)
    d.arrow('M285,105 L333,105'); d.text(310, 92, 'calls', size=11)
    d.arrow('M730,73 L730,55 L170,55 L170,71', kind='sec'); d.text(450, 43, 'answers', size=11)
    d.band(20, 200, 860, 110, 'Transport, the same in dart_plex and dart_jellyfin')
    d.node(170, 265, 230, 60, 'http.Client', 'dart:io, cupertino, cronet', role='neutral', mono=False)
    d.node(450, 265, 210, 60, 'JellyfinConnection', 'cancel token, retry policy', role='lib')
    d.node(730, 265, 230, 60, 'Parsing isolate', 'gunzip, JSON, models', role='lib', mono=False)
    d.arrow('M450,137 L450,233'); d.text(462, 190, 'requests', anchor='start', size=11)
    d.arrow('M345,265 L287,265'); d.text(316, 252, 'send', size=11)
    d.arrow('M555,265 L613,265'); d.text(584, 252, '50 KB+', size=11)
    d.arrow('M730,233 L730,139', kind='sec'); d.text(742, 190, 'models', anchor='start', size=11)
    d.text(450, 322, 'smaller answers are parsed in place', size=11)
    d.node(170, 400, 230, 56, 'Jellyfin server', '12.2', role='neutral', mono=False)
    d.arrow('M170,297 L170,370', kind='sec')
    return d


def client_lifecycle(t):
    d = D('client_lifecycle', 1150, 150, t, 'Client lifecycle')
    steps = [('JellyfinClient(...)', 'credentials, once', 'lib'), ('sign in', 'setSession()', 'app'), ('sub-APIs', 'items, audio, ...', 'app'), ('withCancelToken()', "a page's calls", 'app'), ('close()', 'releases the client', 'lib')]
    for i, (a, b, role) in enumerate(steps):
        x = 115 + i * 230
        d.node(x, 75, 190, 64, a, b, role=role, size=14)
        if i:
            d.arrow(f'M{x - 230 + 95},75 L{x - 97},75')
    return d

def sign_in_flow(t):
    d = D('sign_in_flow', 900, 290, t, 'Sign-in by name, or with Quick Connect')
    d.node(170, 70, 250, 60, 'authenticateByName()', 'user name and password', role='lib', size=14)
    d.node(780, 70, 170, 60, 'setSession()', 'token and user id', role='app')
    d.arrow('M295,70 L693,70')
    d.band(20, 130, 860, 140, 'Quick Connect')
    d.node(105, 215, 150, 60, 'initiate()', 'code and secret', role='lib')
    d.node(280, 215, 170, 60, 'the code', 'approved by the user', role='neutral', mono=False, size=14)
    d.node(455, 215, 150, 60, 'state(secret:)', 'polled until done', role='lib', size=14)
    d.node(705, 215, 270, 60, 'authenticateWithQuickConnect()', 'the secret', role='lib', size=12)
    d.arrow('M180,215 L193,215'); d.arrow('M365,215 L378,215'); d.arrow('M530,215 L568,215')
    d.arrow('M780,183 L780,102')
    return d


def play_reporting(t):
    d = D('play_reporting', 900, 300, t, 'Playback reports over one track')
    x0, x1 = 120, 860
    d.add(f'<line x1="{x0}" y1="150" x2="{x1}" y2="150" stroke="{d.c["line"]}" stroke-width="2"/>')
    d.text(x0, 182, '0', size=11); d.text(x1, 182, 'end', size=11)
    reports = [(120, 'start'), (230, 'progress'), (340, 'progress'), (440, 'isPaused'), (560, 'progress'), (700, 'progress'), (820, 'stopped')]
    for x, s in reports:
        col = d.c['line'] if s == 'isPaused' else d.c['main']
        d.add(f'<circle cx="{x}" cy="150" r="6" fill="{col}"/>')
        d.text(x, 128, s, mono=True, size=11, color='label')
    d.add(f'<path d="M440,95 L440,105 L560,105 L560,95" fill="none" stroke="{d.c["line"]}" stroke-width="1.5"/>')
    d.text(500, 82, 'ping() keeps an HLS job alive', size=11)
    d.band(120, 205, 740, 70, '')
    d.text(490, 235, 'playback.start(), progress(position:, isPaused:), stopped()', mono=True, size=12, color='label')
    d.text(490, 258, 'one play session id from start to stop', size=12)
    return d


def hls_playlists(t):
    d = D('hls_playlists', 900, 300, t, 'HLS: master playlist, variant playlist, segments')
    d.node(150, 80, 220, 64, 'master.m3u8', 'hls.audioMasterUrl()', role='lib', size=15)
    d.node(450, 80, 220, 64, 'main.m3u8', 'hls.audioVariantUrl()', role='lib', size=15)
    d.node(750, 80, 220, 64, 'segments', 'hls1/main/0.ts, 1.ts, ...', role='neutral')
    d.arrow('M260,80 L338,80'); d.arrow('M560,80 L638,80')
    d.text(299, 68, 'lists', size=11); d.text(599, 68, 'lists', size=11)
    d.node(450, 220, 300, 64, 'Your player', 'opens the master or the variant', role='app', mono=False)
    d.arrow('M450,188 L450,114', kind='sec')
    d.text(450, 280, 'DeviceId and PlaySessionId ride every URL: the job is filed under them', size=12)
    return d


def events(t):
    d = D('events', 900, 320, t, 'Socket frames decoded into typed events')
    d.node(180, 60, 280, 60, 'notifications.connect()', 'the /socket WebSocket', role='lib', size=14)
    d.node(560, 60, 260, 60, 'JellyfinNotification', 'one frame, raw', role='lib', size=14)
    d.arrow('M320,60 L428,60'); d.text(374, 47, 'frames', size=11)
    items = [(100, 'UserDataChanged', 'favourite, played', 'lib'), (280, 'LibraryChanged', 'added, updated, removed', 'lib'),
             (460, 'Sessions', 'now playing', 'lib'), (640, 'Play, Playstate', 'remote control', 'lib'),
             (815, 'Unknown', 'anything else', 'ghost')]
    for x, a, b, role in items:
        d.node(x, 215, 168, 64, a, b, role=role, size=13)
        d.arrow(f'M560,92 L560,140 L{x},140 L{x},181', kind='main' if role == 'lib' else 'sec')
    d.text(572, 125, 'events()', anchor='start', mono=True, size=12, color='label')
    d.text(450, 290, 'switch over the sealed JellyfinEvent: Jellyfin...Event subtypes', size=12)
    return d


def icon_svg():
    """The package icon: the Jellyfin mark, the original path only scaled
    and centred, in light blue on a full navy disc."""
    mark = ('M12 .002C8.826.002-1.398 18.537.16 21.666c1.56 3.129 22.14 3.094 23.682 0'
            'C25.384 18.573 15.177 0 12 0zm7.76 18.949c-1.008 2.028-14.493 2.05-15.514 0'
            'C3.224 16.9 9.92 4.755 12.003 4.755c2.081 0 8.77 12.166 7.759 14.196zM12 9.198'
            'c-1.054 0-4.446 6.15-3.93 7.189.518 1.04 7.348 1.027 7.86 0 .511-1.027-2.874-7.19-3.93-7.19z')
    s = 600 / 24  # its box is exactly 24 units; as tall as mpv_audio_kit's bars
    # The centre of the inner triangle, the core of the concentric mark (the
    # centre of the smallest circle around it), sits on the disc's centre,
    # as the Plex chevron's inner vertex does. Centred on its box the mark
    # sat 52 px low: a triangle holds its weight in its base.
    cx, cy = 12.0, 13.8674
    tx, ty = 512 - s * cx, 512 - s * cy
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024" '
            'role="img" aria-label="dart_jellyfin">\n'
            f'<circle cx="512" cy="512" r="512" fill="{NAVY}"/>\n'
            f'<path transform="translate({tx:.3f} {ty:.3f}) scale({s:.4f})" d="{mark}" fill="{LIGHT_BLUE}"/>\n</svg>\n')


ALL = [architecture, client_lifecycle, sign_in_flow, play_reporting, hls_playlists, events]

os.makedirs(OUT, exist_ok=True)
with tempfile.TemporaryDirectory() as tmp:
    for f in ALL:
        d = f('light')
        svg = os.path.join(tmp, f'{d.name}.svg')
        with open(svg, 'w') as fh:
            fh.write(d.svg())
        png = os.path.join(OUT, f'{d.name}.png')
        subprocess.run(['rsvg-convert', '-z', '2', svg, '-o', png], check=True)
    svg = os.path.join(tmp, 'icon.svg')
    with open(svg, 'w') as fh:
        fh.write(icon_svg())
    subprocess.run(['rsvg-convert', svg, '-o', ICON], check=True)
print('Icon written to', ICON, 'and', len(ALL), 'diagrams to', OUT)
