#!/bin/bash
set -euo pipefail

echo "# Ejecutando con el usuario $OWNER_USER"
sudo -u "$OWNER_USER" bash <<'EOSU'

# 1. Detectar usuario interactivo (no root)
if [ "$EUID" -eq 0 ]; then
    # SUDO_USER solo existe si ejecutas con sudo, sino será root
    USER_TO_ADD="${SUDO_USER:-$(logname)}"
else
    USER_TO_ADD="$USER"
fi

echo "Configurando Docker para el usuario: $USER_TO_ADD"

DOCKER_GPG_DIR="/etc/apt/keyrings"
DOCKER_GPG_KEY="$DOCKER_GPG_DIR/docker.asc"
DOCKER_REPO_LIST="/etc/apt/sources.list.d/docker.list"

# 2. Instala dependencias necesarias
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# 3. Agrega el GPG key de Docker (idempotente)
sudo mkdir -p "$DOCKER_GPG_DIR"
if ! [ -f "$DOCKER_GPG_KEY" ]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee "$DOCKER_GPG_KEY" > /dev/null
fi

# 4. Agrega el repo de Docker si no existe (idempotente)
ARCH=$(dpkg --print-architecture)
CODENAME=$(lsb_release -cs)
if ! grep -q "^deb .*download.docker.com" "$DOCKER_REPO_LIST" 2>/dev/null; then
  echo \
    "deb [arch=$ARCH signed-by=$DOCKER_GPG_KEY] https://download.docker.com/linux/ubuntu $CODENAME stable" \
    | sudo tee "$DOCKER_REPO_LIST" > /dev/null
fi

# 5. Instala Docker si no está instalado
if ! dpkg -s docker-ce >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
else
  echo "Docker ya está instalado."
fi

# 6. Asegúrate de que el grupo docker existe
if ! getent group docker >/dev/null; then
  sudo groupadd docker
fi

# 7. Añade el usuario correcto al grupo docker
if id "$USER_TO_ADD" | grep -qw docker; then
  echo "El usuario $USER_TO_ADD ya está en el grupo docker."
else
  sudo usermod -aG docker "$USER_TO_ADD"
  echo "Usuario $USER_TO_ADD añadido al grupo docker."
fi

echo "-------------------------------------------------------------"
echo "IMPORTANTE:"
echo "1. Cierra **todas** las sesiones y vuelve a entrar para activar el grupo docker."
echo "   O ejecuta: 'newgrp docker' para una shell temporal con el grupo activo."
echo "2. Para verificar, corre: 'id $USER_TO_ADD' y revisa que aparezca 'docker'."
echo "3. Prueba: 'docker ps'"
echo "-------------------------------------------------------------"

EOSU