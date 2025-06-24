#!/bin/bash
set -euo pipefail
source ~/.bashrc

NPMRC_FILE="$HOME/.npmrc"
TOKEN="${NPM_REGISTRY_TOKEN_UCLOUD:-}"

if [ -z "$TOKEN" ]; then
  echo "❌ La variable de entorno NPM_REGISTRY_TOKEN_UCLOUD no está definida. No se puede configurar .npmrc"
  exit 1
fi

# Crear archivo si no existe
if [ ! -f "$NPMRC_FILE" ]; then
  touch "$NPMRC_FILE"
  echo "ℹ️ Archivo $NPMRC_FILE creado."
fi

# Función para agregar o actualizar una clave=valor en el archivo
add_or_update_config() {
  local key="$1"
  local value="$2"
  if grep -q "^$key=" "$NPMRC_FILE"; then
    sed -i "s|^$key=.*|$key=$value|" "$NPMRC_FILE"
    echo "♻️ Actualizado: $key=$value"
  else
    echo "$key=$value" >> "$NPMRC_FILE"
    echo "➕ Agregado: $key=$value"
  fi
}

# Agregar o actualizar configuraciones
add_or_update_config "strict-ssl" "true"
add_or_update_config "@unlimitechcloud:registry" "https://npm.unlimitech.cloud"
add_or_update_config "//npm.unlimitech.cloud/:_authToken" "$TOKEN"

echo "✅ Configuración de $NPMRC_FILE completada."
