#!/bin/bash
set -euo pipefail

# Valor deseado (puedes ajustar aquí o pasar como argumento)
NEW_VALUE=1000000

echo "🔍 Valor deseado: $NEW_VALUE"

# Busca el valor actual en /proc
CURRENT_VALUE=$(cat /proc/sys/fs/inotify/max_user_watches)

if [[ "$CURRENT_VALUE" == "$NEW_VALUE" ]]; then
  echo "✅ El valor ya está en $NEW_VALUE. No se requiere acción."
else
  # Reemplaza o agrega la línea en /etc/sysctl.conf
  if grep -q "^fs.inotify.max_user_watches" /etc/sysctl.conf; then
    echo "✏️  Actualizando línea en /etc/sysctl.conf..."
    sudo sed -i "s/^fs.inotify.max_user_watches=.*/fs.inotify.max_user_watches=$NEW_VALUE/" /etc/sysctl.conf
  else
    echo "➕ Agregando línea a /etc/sysctl.conf..."
    echo "fs.inotify.max_user_watches=$NEW_VALUE" | sudo tee -a /etc/sysctl.conf > /dev/null
  fi

  # Aplica el cambio inmediatamente
  echo "⚡ Aplicando cambio inmediato..."
  sudo sysctl -w fs.inotify.max_user_watches=$NEW_VALUE

  # Vuelve a cargar la configuración para asegurarse
  sudo sysctl -p

  # Confirma el resultado
  FINAL_VALUE=$(cat /proc/sys/fs/inotify/max_user_watches)
  if [[ "$FINAL_VALUE" == "$NEW_VALUE" ]]; then
    echo "✅ fs.inotify.max_user_watches actualizado correctamente a $FINAL_VALUE"
  else
    echo "❌ Hubo un problema, el valor actual es $FINAL_VALUE"
  fi
fi


