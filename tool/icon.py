"""Generates the package icon (imgs/dart_jellyfin.png).

The same look as mpv_audio_kit's and mpv_studio's: one flat light-blue
glyph on a full navy disc. The glyph is the original mark's path, not a
redrawing: only scaled and centred. Run from the package
root (needs rsvg-convert):

    python3 tool/icon.py
"""
import os, subprocess, tempfile

NAVY = '#0D2A75'
LIGHT_BLUE = '#A8EDFA'
ICON = os.path.join('imgs', 'dart_jellyfin.png')


# Jellyfin's mark, exactly as the Simple Icons Jellyfin logo draws it
# (flumael/assets/icons/svg/jellyfin.svg), in its 24-unit box.
MARK = ('M12 .002C8.826.002-1.398 18.537.16 21.666c1.56 3.129 22.14 3.094 23.682 0'
        'C25.384 18.573 15.177 0 12 0zm7.76 18.949c-1.008 2.028-14.493 2.05-15.514 0'
        'C3.224 16.9 9.92 4.755 12.003 4.755c2.081 0 8.77 12.166 7.759 14.196zM12 9.198'
        'c-1.054 0-4.446 6.15-3.93 7.189.518 1.04 7.348 1.027 7.86 0 .511-1.027-2.874-7.19-3.93-7.19z')
BBOX = (0.0, 0.0, 24.0, 24.0)  # the mark fills its box edge to edge
SIZE = 600  # on the 1024 canvas, as tall as mpv_audio_kit's bars


def icon_svg():
    """The Jellyfin mark, unaltered, scaled to [SIZE] and centred on a
    full navy disc."""
    x0, y0, x1, y1 = BBOX
    s = SIZE / (y1 - y0)
    tx, ty = 512 - s * (x0 + x1) / 2, 512 - s * (y0 + y1) / 2
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024" '
            'role="img" aria-label="dart_jellyfin">\n'
            f'<circle cx="512" cy="512" r="512" fill="{NAVY}"/>\n'
            f'<path transform="translate({tx:.3f} {ty:.3f}) scale({s:.4f})" d="{MARK}" fill="{LIGHT_BLUE}"/>\n'
            '</svg>\n')

if __name__ == '__main__':
    with tempfile.TemporaryDirectory() as tmp:
        svg = os.path.join(tmp, 'icon.svg')
        with open(svg, 'w') as fh:
            fh.write(icon_svg())
        subprocess.run(['rsvg-convert', svg, '-o', ICON], check=True)
    print(f'wrote {ICON}')
