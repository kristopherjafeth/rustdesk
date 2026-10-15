# Jimka Offshore Soporte (RustDesk personalizado)

Cliente RustDesk con marca Jimka Offshore, conectado solo a nuestro servidor autohospedado, para que el equipo de tecnología dé soporte remoto.

| Pieza | Dónde |
|---|---|
| Servidor (hbbs + hbbr, Docker) | `server/docker-compose.yml`, `server/firewall_ufw.sh` |
| Branding (iconos, logos, nombre, servidor, clave) | `jimka/` (este directorio) |
| Script que aplica el branding al código de RustDesk | `jimka/apply_branding.py` |
| Datos del servidor para el cliente | `jimka/branding.json` |

Nombre de la app: **JimkaSoporte** (sin espacios porque se usa como nombre de servicio de Windows y de carpetas). Producto en Windows: "Jimka Offshore Soporte".

## 1. Servidor

Requisitos: VPS Linux con IP pública, Docker y un dominio (recomendado, ej. `soporte.jimkaoffshore.com` → IP del VPS).

```bash
mkdir -p /opt/rustdesk && cd /opt/rustdesk
# copiar server/docker-compose.yml aquí
docker compose up -d
sudo bash firewall_ufw.sh        # o abrir en el firewall del proveedor:
                                 # TCP 21115-21119, UDP 21116
cat data/id_ed25519.pub          # esta es la clave pública que va en branding.json
```

Respaldar `data/id_ed25519` y `data/id_ed25519.pub`. Si se pierden, hay que recompilar el cliente con la nueva clave.

## 2. Cliente con marca

`libs/hbb_common` es un submódulo de RustDesk, así que el servidor y la clave no se pueden commitear en el fork: el branding se aplica en cada build.

1. Fork de `rustdesk/rustdesk` en la cuenta de GitHub.
2. Copiar la carpeta `jimka/` (este directorio) al fork como `jimka/` y completar `jimka/branding.json`:
   ```json
   { "host": "soporte.jimkaoffshore.com", "key": "<contenido de id_ed25519.pub>" }
   ```
3. Parchear el workflow una sola vez y commitear:
   ```bash
   python3 jimka/apply_branding.py . --patch-workflow
   git add jimka .github/workflows/flutter-build.yml && git commit -m "Jimka branding" && git push
   ```
4. En el fork: Actions → habilitar workflows → **Flutter Nightly Build** → Run workflow.
5. Al terminar, el instalador de Windows (`.exe` / `.msi`) queda en la release `nightly` del fork.

Build local (opcional): `python3 jimka/apply_branding.py .` y luego `python3 build.py --flutter` según la guía oficial de RustDesk.

## 3. Uso por el equipo

- El cliente ya viene apuntando al servidor; no hay que configurar ID/Relay a mano.
- El usuario final abre JimkaSoporte y le dicta su ID y contraseña al técnico.
- Para equipos fijos, instalar como servicio (acceso desatendido) y poner contraseña permanente.

## Notas

- Sin firma de código, Windows SmartScreen mostrará advertencia al instalar. Se quita con un certificado de firma (EV u OV).
- RustDesk es AGPL-3.0: el código modificado debe estar disponible (el fork público cumple esto).
- Libreta de direcciones centralizada, consola web y gestión de usuarios requieren RustDesk Server Pro; el servidor OSS cubre conexión y relay.
