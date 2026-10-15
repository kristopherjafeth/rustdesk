#!/usr/bin/env python3
"""Aplica el branding Jimka Offshore a un checkout de rustdesk/rustdesk.

Uso:
    python3 apply_branding.py <ruta_checkout_rustdesk>            # usa branding.json
    python3 apply_branding.py <ruta> --host X --key Y              # sobreescribe
    python3 apply_branding.py <ruta> --patch-workflow              # inyecta este paso en CI

hbb_common es un submodulo: sus cambios no se pueden commitear en el fork,
por eso el branding se aplica en cada build (--patch-workflow lo deja automatico).

Requiere que el submodulo libs/hbb_common este inicializado
(git submodule update --init --recursive).
"""
import argparse
import json
import re
import shutil
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ASSETS = HERE / "assets"

APP_NAME = "JimkaSoporte"          # sin espacios: se usa en nombre de servicio y rutas
PRODUCT = "Jimka Offshore Soporte"
DESCRIPTION = "Jimka Offshore - Soporte Remoto"
COPYRIGHT = "Copyright (c) 2026 Jimka Offshore. Basado en RustDesk (AGPL-3.0)."

# destino -> archivo en assets/
ICONS = {
    "res/icon.png": "icon.png",
    "res/mac-icon.png": "mac-icon.png",
    "res/32x32.png": "32x32.png",
    "res/64x64.png": "64x64.png",
    "res/128x128.png": "128x128.png",
    "res/128x128@2x.png": "128x128@2x.png",
    "res/icon.ico": "icon.ico",
    "res/tray-icon.ico": "tray-icon.ico",
    "flutter/windows/runner/resources/app_icon.ico": "app_icon.ico",
    "flutter/assets/icon.png": "icon.png",
    "flutter/assets/logo.png": "logo.png",
    "flutter/assets/logo_light.png": "logo_light.png",
    "flutter/assets/logo_dark.png": "logo_dark.png",
}


def sub(path: Path, pattern: str, repl: str, count: int = 1):
    text = path.read_text(encoding="utf-8")
    new, n = re.subn(pattern, repl, text, count=count)
    if n == 0:
        sys.exit(f"ERROR: patron no encontrado en {path}: {pattern}")
    path.write_text(new, encoding="utf-8")
    print(f"  ok {path.relative_to(ROOT)}")


STEP = """\
      - name: Apply Jimka branding
        shell: bash
        run: |
          if command -v python >/dev/null 2>&1; then PY=python; else PY=python3; fi
          $PY jimka/apply_branding.py .
"""


def patch_workflow():
    wf = ROOT / ".github/workflows/flutter-build.yml"
    text = wf.read_text(encoding="utf-8")
    if "Apply Jimka branding" in text:
        print("workflow ya parcheado")
        return
    anchor = "          submodules: recursive\n"
    n = text.count(anchor)
    if n == 0:
        sys.exit("ERROR: no se encontro el checkout con submodules en flutter-build.yml")
    wf.write_text(text.replace(anchor, anchor + "\n" + STEP), encoding="utf-8")
    print(f"workflow parcheado en {n} jobs")


def main():
    global ROOT
    ap = argparse.ArgumentParser()
    ap.add_argument("repo")
    ap.add_argument("--host", help="dominio o IP del servidor hbbs")
    ap.add_argument("--key", help="clave publica (id_ed25519.pub)")
    ap.add_argument("--patch-workflow", action="store_true")
    a = ap.parse_args()
    ROOT = Path(a.repo).resolve()
    if a.patch_workflow:
        return patch_workflow()
    conf = json.loads((HERE / "branding.json").read_text(encoding="utf-8"))
    host = a.host or conf["host"]
    key = (a.key or conf["key"]).strip()
    if "CAMBIAR" in host or "CAMBIAR" in key:
        sys.exit("ERROR: completa host y key en branding.json")

    cfg = ROOT / "libs/hbb_common/src/config.rs"
    print("Servidor y clave:")
    sub(cfg, r'pub const RENDEZVOUS_SERVERS: &\[&str\] = &\[[^\]]*\];',
        f'pub const RENDEZVOUS_SERVERS: &[&str] = &["{host}"];')
    sub(cfg, r'pub const RS_PUB_KEY: &str = "[^"]*";',
        f'pub const RS_PUB_KEY: &str = "{key}";')
    sub(cfg, r'pub static ref APP_NAME: RwLock<String> = RwLock::new\("[^"]*"\.to_owned\(\)\);',
        f'pub static ref APP_NAME: RwLock<String> = RwLock::new("{APP_NAME}".to_owned());')

    print("Metadatos Windows:")
    cargo = ROOT / "Cargo.toml"
    sub(cargo, r'ProductName = "[^"]*"', f'ProductName = "{PRODUCT}"')
    sub(cargo, r'FileDescription = "[^"]*"', f'FileDescription = "{DESCRIPTION}"')
    sub(cargo, r'LegalCopyright = "[^"]*"', f'LegalCopyright = "{COPYRIGHT}"')
    rc = ROOT / "flutter/windows/runner/Runner.rc"
    sub(rc, r'VALUE "FileDescription", "[^"]*"', f'VALUE "FileDescription", "{DESCRIPTION}"')
    sub(rc, r'VALUE "LegalCopyright", "[^"]*"', f'VALUE "LegalCopyright", "{COPYRIGHT}"')
    sub(rc, r'VALUE "ProductName", "[^"]*"', f'VALUE "ProductName", "{PRODUCT}"')

    print("Iconos y logos:")
    for dst, src in ICONS.items():
        shutil.copyfile(ASSETS / src, ROOT / dst)
        print(f"  ok {dst}")
    print(f"\nListo. App: {APP_NAME} -> {host}")


if __name__ == "__main__":
    main()
