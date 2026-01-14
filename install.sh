#!/bin/bash

INSTALL_DIR="/opt/neDNSR"
REPO_USER="NeTenebraes"
REPO_NAME="neDNSResolvers"
REPO_RAW="https://raw.githubusercontent.com/$REPO_USER/$REPO_NAME/main"
REPO_API="https://api.github.com/repos/$REPO_USER/$REPO_NAME/contents"

echo "[*] Instalación Global de neDNSResolvers (Detección Automática)..."

# 1. Preparar carpetas
sudo mkdir -p "$INSTALL_DIR/lib"
sudo chown -R $USER:$USER "$INSTALL_DIR"

# 2. Descargar el script principal
echo "[*] Descargando neDNSR..."
curl -sL "$REPO_RAW/neDNSR" -o "$INSTALL_DIR/neDNSR"

# 3. DETECCIÓN AUTOMÁTICA DE LIBRERÍAS
# Usamos la API de GitHub para listar archivos en la carpeta 'lib'
echo "[*] Detectando módulos en la carpeta lib/..."
LIB_FILES=$(curl -s "$REPO_API/lib" | grep '"name":' | cut -d'"' -f4)

for file in $LIB_FILES; do
    if [[ $file == *.sh ]]; then
        echo "[*] Descargando módulo detectado: $file"
        curl -sL "$REPO_RAW/lib/$file" -o "$INSTALL_DIR/lib/$file"
    fi
done

# 4. Dependencias de Sistema
echo "[*] Instalando dependencias de sistema..."
sudo apt-get update -qq && sudo apt-get install -y -qq git build-essential python3-venv golang-go wget curl > /dev/null

# 5. Compilación de MassDNS (Si no existe)
if ! command -v massdns &> /dev/null; then
    echo "[*] MassDNS no detectado. Compilando..."
    TEMP_BUILD=$(mktemp -d)
    git clone --depth 1 https://github.com/blechschmidt/massdns.git "$TEMP_BUILD" > /dev/null
    cd "$TEMP_BUILD" && make -s && sudo cp bin/massdns /usr/local/bin/
    cd - && rm -rf "$TEMP_BUILD"
fi

# 6. Instalación de PureDNS y DNSValidator (Lógica de enlaces)
# PureDNS
if ! command -v puredns &> /dev/null; then
    go install github.com/d3mondev/puredns/v2@latest > /dev/null
    sudo ln -sf $(go env GOPATH)/bin/puredns /usr/local/bin/puredns
fi

# DNSValidator (Entorno virtual)
if [ ! -d "$INSTALL_DIR/lib/dns_env" ]; then
    python3 -m venv "$INSTALL_DIR/lib/dns_env"
    "$INSTALL_DIR/lib/dns_env/bin/pip" install --quiet git+https://github.com/vortexau/dnsvalidator.git
fi
sudo ln -sf "$INSTALL_DIR/lib/dns_env/bin/dnsvalidator" /usr/local/bin/dnsvalidator

# 7. Permisos y Enlaces Finales
chmod +x "$INSTALL_DIR/neDNSR"
find "$INSTALL_DIR/lib" -name "*.sh" -exec chmod +x {} +
sudo ln -sf "$INSTALL_DIR/neDNSR" /usr/local/bin/neDNSR
[ ! -f "$INSTALL_DIR/master_resolvers.txt" ] && touch "$INSTALL_DIR/master_resolvers.txt"
chmod 666 "$INSTALL_DIR/master_resolvers.txt"

echo -e "\n[+] Instalación completada. Se detectaron $(echo "$LIB_FILES" | wc -w) módulos."