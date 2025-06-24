#!/bin/bash
set -euo pipefail

echo "# Ejecutando con el usuario $OWNER_USER"
sudo -u "$OWNER_USER" bash <<'EOSU'

# Carpeta de scripts relativa a la ubicación de este script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_FOLDER="$SCRIPT_DIR/scripts"

if [ ! -d "$SCRIPTS_FOLDER" ]; then
  echo "❌ No se encontró la carpeta $SCRIPTS_FOLDER"
  exit 1
fi

# Buscar scripts que cumplan el patrón NN-nombre.sh
mapfile -t SCRIPTS < <(find "$SCRIPTS_FOLDER" -maxdepth 1 -type f -name '[0-9][0-9]-*.sh' | sort)

if [ "${#SCRIPTS[@]}" -eq 0 ]; then
  echo "⚠️  No se encontraron scripts en $SCRIPTS_FOLDER con el patrón NN-nombre.sh"
  exit 0
fi

echo "➡️  Ejecutando scripts en $SCRIPTS_FOLDER:"
for script in "${SCRIPTS[@]}"; do
  echo ""
  echo "--------------------------------------------------"
  echo "▶️  Ejecutando: $(basename "$script")"
  echo "--------------------------------------------------"
  bash "$script"
  echo "✅ Completado: $(basename "$script")"
done

echo ""
echo "✅ Todos los scripts ejecutados correctamente."

EOSU