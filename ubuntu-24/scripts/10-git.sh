#!/bin/bash
set -euo pipefail

# Verifica variables de entorno
if [ -z "${OWNER_EMAIL:-}" ]; then
  echo "❌ La variable de entorno OWNER_EMAIL no está definida."
  exit 1
fi

if [ -z "${OWNER_NAME:-}" ]; then
  echo "❌ La variable de entorno OWNER_NAME no está definida."
  exit 1
fi

echo "📧 Configurando git user.email como: $OWNER_EMAIL"
git config --global user.email "$OWNER_EMAIL"

echo "🧑‍ Configurando git user.name como: $OWNER_NAME"
git config --global user.name "$OWNER_NAME"

git config --global pull.rebase false

echo "✅ Configuración de Git actual:"
git config --global --get user.email | xargs -I {} echo "   - Email: {}"
git config --global --get user.name | xargs -I {} echo "   - Nombre: {}"
