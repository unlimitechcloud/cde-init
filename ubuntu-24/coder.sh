#!/bin/bash

# Nombre del repositorio y carpeta de destino
REPO_SSH="git@github.com:unlimitechcloud/cde-init.git"
REPO_HTTPS="https://github.com/unlimitechcloud/cde-init.git"
FOLDER_NAME="cde-init"

# Clonar repositorio
echo "Clonando repositorio con SSH..."
git clone "$REPO_SSH" "$FOLDER_NAME" 2>/dev/null

# Verificar si el clon falló
if [ $? -ne 0 ]; then
    echo "Fallo clonando con SSH. Probando con HTTPS..."
    git clone "$REPO_HTTPS" "$FOLDER_NAME"
    if [ $? -ne 0 ]; then
        echo "Error: No se pudo clonar el repositorio."
        exit 1
    fi
fi

# Crear archivo cde-init.sh
echo "Creando archivo cde-init.sh..."
cat << 'EOF' > cde-init.sh
#!/bin/bash
cd "$(dirname "$0")/cde-init/ubuntu-24"
./run.sh
EOF

chmod +x cde-init.sh

# Otorgar permisos de ejecución al run.sh y a los scripts dentro de /scripts
echo "Otorgando permisos de ejecución..."
chmod +x "$FOLDER_NAME/ubuntu-24/run.sh"
chmod +x "$FOLDER_NAME/ubuntu-24/scripts/"*.sh

echo "Instalación completada. Ahora puedes ejecutar ./cde-init.sh"
