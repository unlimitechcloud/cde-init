#!/bin/bash
set -euo pipefail

# Detecta el usuario real incluso si se usa sudo
if [ "$EUID" -eq 0 ]; then
  USER_HOME="/home/${SUDO_USER:-$USER}"
  REAL_USER="${SUDO_USER:-$USER}"
else
  USER_HOME="$HOME"
  REAL_USER="$USER"
fi

CADDY_SERVICE_DIR="$USER_HOME/.caddy"
CADDYFILE_SRC="$CADDY_SERVICE_DIR/Caddyfile"
CADDYFILE_DEST="/etc/caddy/Caddyfile"

# Instala dependencias si son necesarias
if ! command -v curl >/dev/null 2>&1; then
  echo "🔧 Instalando curl..."
  sudo apt-get update -y
  sudo apt-get install -y curl
fi

# Instala Caddy si no está
if ! command -v caddy >/dev/null 2>&1; then
  echo "🌱 Instalando Caddy (web server moderno)..."
  sudo apt-get install -y debian-keyring debian-archive-keyring apt-transport-https
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
  sudo apt-get update -y
  sudo apt-get install -y caddy
else
  echo "✅ Caddy ya está instalado."
fi

# Crea ~/services si no existe
mkdir -p "$CADDY_SERVICE_DIR/config"

# Si no existe el archivo de config, crea uno básico
if [ ! -f "$CADDYFILE_SRC" ]; then
  cat > "$CADDYFILE_SRC" <<EOF
{\$CLOUDNS_DOMAIN} {
    respond "Hello World!"
}
EOF
  echo "📝 Caddyfile inicial creado en $CADDYFILE_SRC"
fi

# Enlaza el archivo de config como /etc/caddy/Caddyfile
if [ -L "$CADDYFILE_DEST" ] && [ "$(readlink -f "$CADDYFILE_DEST")" != "$CADDYFILE_SRC" ]; then
  echo "🔗 Eliminando symlink previo en $CADDYFILE_DEST"
  sudo rm -f "$CADDYFILE_DEST"
fi
if [ ! -L "$CADDYFILE_DEST" ]; then
  echo "🔗 Creando symlink $CADDYFILE_DEST → $CADDYFILE_SRC"
  sudo ln -sf "$CADDYFILE_SRC" "$CADDYFILE_DEST"
else
  echo "✅ El symlink $CADDYFILE_DEST ya existe y es correcto."
fi

# Asigna permisos apropiados
sudo chown $REAL_USER:caddy "$CADDYFILE_SRC"
sudo chmod 644 "$CADDYFILE_SRC"

# Crear drop-in para systemd y carga de variables desde /etc/environment
SYSTEMD_DROPIN_DIR="/etc/systemd/system/caddy.service.d"
SYSTEMD_DROPIN_FILE="$SYSTEMD_DROPIN_DIR/envfile.conf"

sudo mkdir -p "$SYSTEMD_DROPIN_DIR"

if [ ! -f "$SYSTEMD_DROPIN_FILE" ]; then
  echo "💡 Creando drop-in para systemd y carga de variables desde /etc/environment"
  echo -e "[Service]\nEnvironmentFile=/etc/environment" | sudo tee "$SYSTEMD_DROPIN_FILE" >/dev/null
  sudo systemctl daemon-reload
else
  echo "✅ Drop-in de systemd para /etc/environment ya existe."
fi

# Reiniciar Caddy para aplicar cambios
sudo systemctl restart caddy

echo "✅ Configuración de Caddy enlazada: $CADDYFILE_DEST → $CADDYFILE_SRC"
echo "👉 Edita tu configuración en: $CADDYFILE_SRC"
echo "🔄 Recarga Caddy con: sudo systemctl reload caddy"
echo "🌍 Verifica con: curl localhost (o tu dominio configurado)"
echo "ℹ️  Si usas variables de entorno como {\$MY_VAR}, ponlas en /etc/environment y reinicia Caddy."
