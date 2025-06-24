#!/bin/bash
set -euo pipefail

echo "# Ejecutando con el usuario $OWNER_USER"
sudo -u "$OWNER_USER" bash <<'EOSU'

SSH_DIR="$HOME/.ssh"
KEY_FILE="$SSH_DIR/id_rsa"

# Crea el directorio si no existe
if [ ! -d "$SSH_DIR" ]; then
  echo "📂 Creando directorio $SSH_DIR"
  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"
fi

#!/bin/bash
set -euo pipefail

SSH_DIR="$HOME/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"

# Crear el directorio si no existe
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Crear el archivo con un header si no existe
if [ ! -f "$AUTHORIZED_KEYS" ]; then
    echo "# Archivo de llaves autorizadas SSH" > "$AUTHORIZED_KEYS"
    chmod 600 "$AUTHORIZED_KEYS"
    echo "✅ Archivo $AUTHORIZED_KEYS creado con header."
else
    echo "ℹ️  El archivo $AUTHORIZED_KEYS ya existe, no se modificó."
fi

# Verifica si ya existe la llave
if [ -f "$KEY_FILE" ]; then
  echo "✅ La clave SSH ya existe: $KEY_FILE"
else
  echo "🔑 Generando nueva clave SSH RSA en $KEY_FILE"
  ssh-keygen -t rsa -b 4096 -f "$KEY_FILE" -N "" -C "$USER@$(hostname)"
  echo "✅ Clave generada correctamente."
fi

echo "🔐 Tu clave pública es:"
cat "${KEY_FILE}.pub"

EOSU

