#!/bin/bash
set -euo pipefail

echo "📂 Cambiando al directorio temporal /tmp..."
cd /tmp

# Verificar si unzip está instalado
if ! command -v unzip >/dev/null 2>&1; then
  echo "🔧 unzip no está instalado. Instalando unzip..."
  sudo apt-get update -y
  sudo apt-get install -y unzip
else
  echo "✅ unzip ya está instalado."
fi

echo "⬇️ Descargando AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

echo "📦 Descomprimiendo awscliv2.zip..."
unzip -q -o awscliv2.zip

echo "🚀 Instalando AWS CLI..."
sudo ./aws/install --update

echo "✔️ AWS CLI instalado. Versión actual:"
aws --version

# Ruta del archivo de configuración AWS
AWS_CONFIG_DIR="$HOME/.aws"
AWS_CONFIG_FILE="$AWS_CONFIG_DIR/config"

# Crear directorio si no existe
mkdir -p "$AWS_CONFIG_DIR"

if [ -f "$AWS_CONFIG_FILE" ]; then
  echo "ℹ️ Archivo $AWS_CONFIG_FILE ya existe, no se sobrescribirá."
else
  # Escribir configuración base
  cat > "$AWS_CONFIG_FILE" <<EOF
[default]
region = us-east-1
EOF

  echo "✅ Archivo AWS config creado en $AWS_CONFIG_FILE con región us-east-1."
fi

AWS_CREDENTIALS_FILE="$HOME/.aws/credentials"

if [ -f "$AWS_CREDENTIALS_FILE" ]; then
  echo "ℹ️ Archivo $AWS_CREDENTIALS_FILE ya existe, no se sobrescribirá."
else
  mkdir -p "$(dirname "$AWS_CREDENTIALS_FILE")"
  echo "# Archivo de credenciales AWS" > "$AWS_CREDENTIALS_FILE"
  echo "✅ Archivo AWS credentials creado en $AWS_CREDENTIALS_FILE."
fi

