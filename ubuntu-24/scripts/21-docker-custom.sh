#!/usr/bin/env bash
set -e

NEW_DOCKER_ROOT="$HOME/.docker"
DOCKER_DAEMON_CONFIG="/etc/docker/daemon.json"

mkdir -p "$NEW_DOCKER_ROOT"

# Detect running user of dockerd, or default to root if not running
DOCKERD_USER=$(ps -o user= -C dockerd 2>/dev/null | head -n1)
if [[ -z "$DOCKERD_USER" ]]; then
  DOCKERD_USER="root"
fi

if [[ "$DOCKERD_USER" == "root" ]]; then
  PERMS="root:root"
else
  # Usa el grupo docker si existe, si no, el grupo primario del usuario
  if getent group docker >/dev/null; then
    PERMS="$DOCKERD_USER:docker"
  else
    USER_GROUP=$(id -gn "$DOCKERD_USER")
    PERMS="$DOCKERD_USER:$USER_GROUP"
  fi
fi

echo "🔍 Docker daemon user detectado: $DOCKERD_USER"
echo "🔧 El data-root se ajustará a: $PERMS"

# 1. Actualiza daemon.json (idempotente)
if sudo test -f "$DOCKER_DAEMON_CONFIG"; then
  if sudo grep -q '"data-root"' "$DOCKER_DAEMON_CONFIG"; then
    tmp=$(sudo mktemp)
    sudo jq '.["data-root"] = "'"$NEW_DOCKER_ROOT"'"' "$DOCKER_DAEMON_CONFIG" | sudo tee "$tmp" >/dev/null
    sudo mv "$tmp" "$DOCKER_DAEMON_CONFIG"
    echo "📝 data-root actualizado en $DOCKER_DAEMON_CONFIG"
  else
    tmp=$(sudo mktemp)
    sudo jq '. + {"data-root":"'"$NEW_DOCKER_ROOT"'"}' "$DOCKER_DAEMON_CONFIG" | sudo tee "$tmp" >/dev/null
    sudo mv "$tmp" "$DOCKER_DAEMON_CONFIG"
    echo "📝 data-root agregado en $DOCKER_DAEMON_CONFIG"
  fi
else
  echo '{ "data-root": "'"$NEW_DOCKER_ROOT"'" }' | sudo tee "$DOCKER_DAEMON_CONFIG" >/dev/null
  echo "📝 Creado $DOCKER_DAEMON_CONFIG con data-root"
fi

# 2. Detén Docker antes de cambiar el storage
echo "🛑 Deteniendo servicio Docker..."
sudo systemctl stop docker

# 3. Asigna permisos apropiados
sudo chown -R "$PERMS" "$NEW_DOCKER_ROOT"

# 4. Inicia Docker con la nueva configuración
echo "🔄 Iniciando servicio Docker con data-root en $NEW_DOCKER_ROOT"
sudo systemctl start docker

# 5. Verifica el data-root
echo "📂 Nuevo data-root Docker:"
sudo docker info | grep 'Docker Root Dir'

echo "✅ Listo. Los datos de Docker ahora persisten en $NEW_DOCKER_ROOT y el dueño es $PERMS"
