#!/bin/bash
set -euo pipefail

echo "# Ejecutando con el usuario $OWNER_USER"
sudo -u "$OWNER_USER" bash <<'EOSU'

# 1. Detectar y agregar dependencias necesarias
NEEDED_PKGS=()
command -v curl >/dev/null 2>&1 || NEEDED_PKGS+=("curl")
command -v unzip >/dev/null 2>&1 || NEEDED_PKGS+=("unzip")

if [ "${#NEEDED_PKGS[@]}" -gt 0 ]; then
  echo "🔧 Instalando dependencias necesarias: ${NEEDED_PKGS[*]}"
  sudo apt-get update -y
  sudo apt-get install -y "${NEEDED_PKGS[@]}"
else
  echo "✅ Todas las dependencias necesarias ya están instaladas."
fi

# 2. Verificar si fnm ya está instalado
if command -v fnm >/dev/null 2>&1; then
  echo "✅ fnm ya está instalado en: $(command -v fnm)"
  exit 0
fi

# 3. Instalar fnm
echo "➡️  Instalando fnm (Fast Node Manager)..."
curl -fsSL https://fnm.vercel.app/install | bash

# 4. Detectar shell y archivo RC
if [ -n "${ZSH_VERSION:-}" ]; then
  SHELL_RC="$HOME/.zshrc"
elif [ -n "${BASH_VERSION:-}" ]; then
  SHELL_RC="$HOME/.bashrc"
else
  SHELL_RC="$HOME/.bashrc"
fi

# 5. Añadir inicialización de fnm solo si falta
FNM_INIT_LINE='eval "$(fnm env)"'
if ! grep -Fxq "$FNM_INIT_LINE" "$SHELL_RC"; then
  echo -e "\n# Inicialización automática de fnm" >> "$SHELL_RC"
  echo "$FNM_INIT_LINE" >> "$SHELL_RC"
  echo "➡️  Se agregó la inicialización de fnm a $SHELL_RC"
else
  echo "✅ La inicialización de fnm ya estaba presente en $SHELL_RC"
fi

# 6. Hacer source del archivo RC para que fnm esté disponible ya
echo "🔄 Puedes ejecutar ahora: source $SHELL_RC"
# shellcheck disable=SC1090

echo "✅ fnm instalado y disponible en esta terminal."
echo "Prueba ahora con: fnm --version"

EOSU