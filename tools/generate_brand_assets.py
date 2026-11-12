"""Render the source SVG, then run the project's launcher/splash generators.

Usage: python tools/generate_brand_assets.py
Requires Pillow and Chrome (or set CHROME_BINARY to a Chromium executable).
"""

import base64
import copy
import html
import io
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import xml.etree.ElementTree as ET

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
ICON_DIR = ROOT / "assets/icon"
SVG_NS = "{http://www.w3.org/2000/svg}"


def main():
    source = ET.parse(ICON_DIR / "sparkio_svg.svg").getroot()
    background = source.find(f"{SVG_NS}rect").get("fill")
    foreground = copy.deepcopy(source)
    foreground.remove(foreground.find(f"{SVG_NS}rect"))
    monochrome = copy.deepcopy(foreground)
    for element in monochrome.iter():
        for attribute in ("fill", "stroke"):
            if element.get(attribute) not in (None, "none"):
                element.set(attribute, "#FFFFFF")

    variants = {}
    for name, svg in (("icon", source), ("foreground", foreground), ("monochrome", monochrome)):
        svg.set("width", "1024")
        svg.set("height", "1024")
        encoded = base64.b64encode(ET.tostring(svg)).decode()
        variants[name] = f"data:image/svg+xml;base64,{encoded}"

    chrome_candidates = [
        os.environ.get("CHROME_BINARY"),
        shutil.which("google-chrome"),
        shutil.which("chromium"),
        r"C:\Program Files\Google\Chrome\Application\chrome.exe",
        r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    ]
    chrome = next((path for path in chrome_candidates if path and Path(path).is_file()), None)
    if not chrome:
        raise SystemExit("Set CHROME_BINARY to a Chrome/Chromium executable.")

    with tempfile.TemporaryDirectory(prefix="sparkio-logo-") as temp:
        temp_dir = Path(temp)
        page = temp_dir / "render.html"
        page.write_text(
            "<!doctype html><body><script>"
            f"const variants = {json.dumps(variants)};"
            "Promise.all(Object.entries(variants).map(async ([name, src]) => {"
            "const img = new Image(); img.src = src; await img.decode();"
            "const canvas = document.createElement('canvas');"
            "canvas.width = canvas.height = 1024;"
            "canvas.getContext('2d').drawImage(img, 0, 0, 1024, 1024);"
            "return [name, canvas.toDataURL('image/png').split(',')[1]];"
            "})).then(entries => {"
            "document.body.innerHTML = '<pre id=rendered></pre>';"
            "document.getElementById('rendered').textContent = JSON.stringify(Object.fromEntries(entries));"
            "});</script>",
            encoding="utf-8",
        )
        rendered = subprocess.run(
            [chrome, "--headless", "--disable-gpu", "--no-first-run",
             "--no-default-browser-check", f"--user-data-dir={temp_dir / 'profile'}",
             "--virtual-time-budget=2000", "--dump-dom", page.as_uri()],
            capture_output=True, text=True, check=True, timeout=45,
            creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0,
        )
        match = re.search(r'<pre id="rendered">(.*?)</pre>', rendered.stdout, re.S)
        if not match:
            raise SystemExit("Chromium did not finish rendering the SVG variants.")
        images = {
            name: Image.open(io.BytesIO(base64.b64decode(data))).convert("RGBA")
            for name, data in json.loads(html.unescape(match.group(1))).items()
        }

    images["icon"].save(ICON_DIR / "sparkio_icon.png")
    images["foreground"].save(ICON_DIR / "sparkio_foreground.png")
    images["monochrome"].save(ICON_DIR / "sparkio_monochrome.png")

    # iOS launcher icons must be opaque, including the SVG's rounded corners.
    opaque = Image.new("RGBA", (1024, 1024), background)
    opaque.alpha_composite(images["icon"])
    opaque.convert("RGB").save(ICON_DIR / "sparkio_icon_ios.png")

    # Keep the launch logo compact across the native splash density variants.
    splash = images["icon"].resize((288, 288), Image.Resampling.LANCZOS)
    splash.save(ROOT / "assets/splash_screen/sparkio_splash.png")
    android12 = Image.new("RGBA", (960, 960))
    android12.alpha_composite(images["icon"].resize((480, 480), Image.Resampling.LANCZOS), (240, 240))
    android12.save(ICON_DIR / "sparkio_android12_splash.png")

    # Android status-bar icons use the mark's alpha mask without a background.
    mark = images["monochrome"].crop(images["monochrome"].getbbox())
    mark.thumbnail((80, 80), Image.Resampling.LANCZOS)
    notification = Image.new("RGBA", (96, 96))
    notification.alpha_composite(mark, ((96 - mark.width) // 2, (96 - mark.height) // 2))
    drawable = ROOT / "android/app/src/main/res/drawable"
    for name in ("ic_notification.png", "sparkio_notification.png"):
        notification.save(drawable / name)

    dart = shutil.which("dart")
    if not dart:
        raise SystemExit("Dart was not found on PATH.")
    for package in ("flutter_launcher_icons", "flutter_native_splash:create"):
        subprocess.run([dart, "run", package], cwd=ROOT, check=True)
    web_index = ROOT / "web/index.html"
    web_index.write_text(
        "\n".join(line.rstrip() for line in web_index.read_text(encoding="utf-8").splitlines()) + "\n",
        encoding="utf-8",
    )
    print("Generated launcher icons, launch screens and notification icons from sparkio_svg.svg.")


if __name__ == "__main__":
    main()
