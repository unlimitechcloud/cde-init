#!/bin/bash
set -euo pipefail

echo "# Ejecutando con el usuario $OWNER_USER"
sudo -u "$OWNER_USER" bash <<'EOSU'

# fnm
FNM_PATH="/home/coder/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "`fnm env`"
fi

# Inicialización automática de fnm
eval "$(fnm env)"

for dep in curl jq fnm; do
  if ! command -v "$dep" >/dev/null 2>&1; then
    echo "❌ Falta dependencia: $dep"
    exit 1
  fi
done

echo "⏳ Obteniendo lista de ramas LTS activas de Node.js desde endoflife.date..."

NODE_JSON=$(curl -fsSL https://endoflife.date/api/nodejs.json)
TODAY=$(date +%Y-%m-%d)

# Filtra ramas:
# - lts distinto de false Y lts <= hoy
# - eol >= hoy
LTS_BRANCH_LATEST=$(echo "$NODE_JSON" | jq -r --arg today "$TODAY" '
  [.[] 
    | select(
        (.lts != false) and
        (.lts <= $today) and
        (.eol >= $today)
      )
  ] 
  | sort_by(.cycle|tonumber) 
  | .[] 
  | "\(.cycle) \(.latest) \(.lts) \(.eol)"
')

if [ -z "$LTS_BRANCH_LATEST" ]; then
  echo "❌ No se encontraron ramas LTS activas."
  exit 1
fi

echo "🔎 Instalando solo la última versión de cada rama LTS activa:"
echo "$LTS_BRANCH_LATEST"

INSTALLED=()
while read -r cycle version ltsdate eoldate; do
  echo "➡️  Instalando Node.js $version (rama $cycle, LTS desde $ltsdate, EOL $eoldate)..."
  fnm install "$version"
  INSTALLED+=("$version")
done <<< "$LTS_BRANCH_LATEST"

LATEST_VERSION=$(printf "%s\n" "${INSTALLED[@]}" | sort -V | tail -n 1)
echo "🔗 Configurando Node.js $LATEST_VERSION como versión predeterminada..."
fnm default "$LATEST_VERSION"

echo ""
echo "✅ Listo. Versiones instaladas:"
fnm list

echo ""
echo "La versión predeterminada actual es:"
fnm current

EOSU