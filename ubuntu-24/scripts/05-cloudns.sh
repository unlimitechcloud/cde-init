#!/bin/bash
set -euo pipefail

USER_HOME=$(getent passwd "$USER" | cut -d: -f6)
CLOUDNS_DIR="$USER_HOME/.cloudns"
LOGFILE="$CLOUDNS_DIR/cloudns.log"
UPDATER="$CLOUDNS_DIR/update.sh"
CRONFILE="$CLOUDNS_DIR/cloudns.cron"
CRONSYM="/etc/cron.d/cloudns"
MAXSIZE=1048576  # 1MB en bytes

# Prepara el directorio .cloudns
mkdir -p "$CLOUDNS_DIR"
chmod 700 "$CLOUDNS_DIR"

echo "📝 (Re)generando el script que ejecuta el cron: $UPDATER"
cat > "$UPDATER" <<"EOF"
#!/bin/bash
set -euo pipefail

LOGFILE="$HOME/.cloudns/cloudns.log"
MAXSIZE=1048576

die() {
    echo "❌ $*" >&2
    exit 1
}

# Rotar log si supera 1MB, dejar últimas 10 líneas
if [ -f "$LOGFILE" ] && [ "$(stat --format=%s "$LOGFILE")" -gt "$MAXSIZE" ]; then
    tail -n 10 "$LOGFILE" > "${LOGFILE}.tmp"
    mv -f "${LOGFILE}.tmp" "$LOGFILE"
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] Log rotado. Solo se conservan las últimas 10 líneas." >> "$LOGFILE"
fi

# Cargar variable de entorno si no está en entorno actual
if [ -z "${CLOUDNS_RECORD_DYNAMIC_URL:-}" ]; then
    if grep -q '^CLOUDNS_RECORD_DYNAMIC_URL=' /etc/environment; then
        # shellcheck disable=SC1091
        . /etc/environment
    fi
fi
[ -n "${CLOUDNS_RECORD_DYNAMIC_URL:-}" ] || die "La variable CLOUDNS_RECORD_DYNAMIC_URL no está definida."

# Detecta interfaz de internet
NET_INTERFACE=$(ip route get 1.1.1.1 | awk '/dev/ {for (i=1;i<=NF;i++) if ($i=="dev") print $(i+1)}' | head -n1)
[ -n "$NET_INTERFACE" ] || die "No se pudo detectar la interfaz de red de salida."

TS="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "[$TS] Usando interfaz: $NET_INTERFACE" >> "$LOGFILE"
curl --fail --interface "$NET_INTERFACE" "$CLOUDNS_RECORD_DYNAMIC_URL" >> "$LOGFILE" 2>&1
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
  echo "[$TS] Actualización exitosa" >> "$LOGFILE"
else
  echo "[$TS] Error al actualizar" >> "$LOGFILE"
  exit 1
fi
EOF

chmod 700 "$UPDATER"
echo "✅ Script generado: $UPDATER"

echo "📝 (Re)generando el archivo cron: $CRONFILE"

REBOOTLINE="@reboot $USER . /etc/environment; $UPDATER >> $LOGFILE 2>&1"
EVERY5LINE="*/5 * * * * $USER . /etc/environment; $UPDATER >> $LOGFILE 2>&1"

sudo tee "$CRONFILE" > /dev/null <<EOF
$REBOOTLINE
$EVERY5LINE
EOF

sudo chmod 644 "$CRONFILE"
echo "✅ Archivo cron generado: $CRONFILE"

# ----- Crea o actualiza el symlink en /etc/cron.d -----
if [ -L "$CRONSYM" ] && [ "$(readlink -f "$CRONSYM")" != "$CRONFILE" ]; then
    sudo rm -f "$CRONSYM"
fi
if [ ! -L "$CRONSYM" ]; then
    sudo ln -sf "$CRONFILE" "$CRONSYM"
    echo "🔗 Symlink creado: $CRONSYM → $CRONFILE"
else
    echo "✅ Symlink ya existe y es correcto."
fi

sudo chmod 644 "$CRONSYM"
sudo chown root:root "$CRONSYM"

# --- Recarga cron de forma robusta, sin errores visibles ---
if sudo systemctl status cron >/dev/null 2>&1; then
    if systemctl show -p CanReload cron | grep -q 'CanReload=yes'; then
        sudo systemctl reload cron
    else
        sudo systemctl restart cron
    fi
elif sudo service cron status >/dev/null 2>&1; then
    sudo service cron reload
fi

echo ""
echo "✅ Instalación/actualización completa:"
echo "- Script principal: $UPDATER"
echo "- Log: $LOGFILE"
echo "- Cron: $CRONFILE (enlazado desde $CRONSYM)"
echo ""
echo "Puedes editar el script y el cron en $CLOUDNS_DIR. Para eliminar todo, basta con borrar esa carpeta y el symlink en /etc/cron.d."
