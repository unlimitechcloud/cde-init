#!/bin/bash
set -euo pipefail

# Detectar el usuario real (incluso si se usa sudo)
if [ "$EUID" -eq 0 ]; then
  USER_HOME="/home/${SUDO_USER:-$USER}"
else
  USER_HOME="$HOME"
fi

SRC_CONF="$USER_HOME/services/nginx.conf"
DEST_CONF="/usr/local/openresty/nginx/conf.d/env.conf"

# Instala dependencias necesarias
NEEDED_PKGS=()
command -v curl >/dev/null 2>&1 || NEEDED_PKGS+=("curl")
command -v lsb_release >/dev/null 2>&1 || NEEDED_PKGS+=("lsb-release")
if [ "${#NEEDED_PKGS[@]}" -gt 0 ]; then
  echo "🔧 Instalando dependencias: ${NEEDED_PKGS[*]}"
  sudo apt-get update -y
  sudo apt-get install -y "${NEEDED_PKGS[@]}"
fi

# Instala OpenResty si no está
if ! command -v openresty >/dev/null 2>&1; then
  echo "➡️  Instalando OpenResty (Nginx con soporte Lua)..."
  CODENAME=$(lsb_release -cs)
  sudo apt-get install -y gnupg2
  curl -fsSL https://openresty.org/package/pubkey.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/openresty.gpg
  echo "deb http://openresty.org/package/ubuntu $CODENAME main" | sudo tee /etc/apt/sources.list.d/openresty.list
  sudo apt-get update -y
  sudo apt-get install -y openresty
  sudo systemctl enable openresty
  sudo systemctl start openresty
else
  echo "✅ OpenResty (Nginx+Lua) ya está instalado."
fi

# Crea el directorio ~/services si no existe
mkdir -p "$USER_HOME/services"

# Si no existe ~/services/nginx.conf, lo crea con un '#'
if [ ! -f "$SRC_CONF" ]; then
  echo "# Nginx environment config" > "$SRC_CONF"
  echo "📝 Creado $SRC_CONF con contenido mínimo."
fi

# Linkear como env.conf (elimina symlink si apunta a otro lado)
sudo mkdir -p "$(dirname "$DEST_CONF")"
if [ -L "$DEST_CONF" ] && [ "$(readlink -f "$DEST_CONF")" != "$SRC_CONF" ]; then
  echo "🔗 Eliminando symlink previo en $DEST_CONF"
  sudo rm -f "$DEST_CONF"
fi
if [ ! -L "$DEST_CONF" ]; then
  echo "🔗 Creando symlink $DEST_CONF → $SRC_CONF"
  sudo ln -sf "$SRC_CONF" "$DEST_CONF"
else
  echo "✅ El symlink $DEST_CONF ya existe y es correcto."
fi

echo "✅ Configuración enlazada: $DEST_CONF → $SRC_CONF"
echo "👉 Puedes editar tu archivo en: $SRC_CONF"
echo "🔄 Recarga OpenResty con: sudo systemctl reload openresty"

# Crea un alias de servicio: nginx → openresty
if [ ! -L "/etc/systemd/system/nginx.service" ]; then
  sudo ln -s /lib/systemd/system/openresty.service /etc/systemd/system/nginx.service
  sudo systemctl daemon-reload
  echo "✅ Ahora puedes usar: sudo systemctl restart nginx"
else
  echo "✅ El alias de servicio nginx ya existe."
fi