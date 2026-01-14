#!/bin/bash

INSTALL_DIR="/opt/neDNSR"
REPO_RAW="https://raw.githubusercontent.com/NeTenebraes/neDNSResolvers/main"
FILES=("neDNSR" "lib/collector.sh" "lib/validator.sh")

echo "[*] Instalación Global de neDNSResolvers..."

# Preparar carpetas
sudo mkdir -p "$INSTALL_DIR/lib"
sudo chown -R $USER:$USER "$INSTALL_DIR"

# Descargar archivos
for file in "${FILES[@]}"; do
    mkdir -p "$INSTALL_DIR/$(dirname "$file")"
    curl -sL "$REPO_RAW/$file" -o "$INSTALL_DIR/$file"
done

# Dependencias
sudo apt-get update -qq && sudo apt-get install -y -qq git build-essential python3-venv golang-go massdns > /dev/null

# PureDNS
if ! command -v puredns &> /dev/null; then
    go install github.com/d3mondev/puredns/v2@latest > /dev/null
    sudo ln -sf $(go env GOPATH)/bin/puredns /usr/local/bin/puredns
fi

# Entorno dnsvalidator
python3 -m venv "$INSTALL_DIR/lib/dns_env"
"$INSTALL_DIR/lib/dns_env/bin/pip" install --quiet git+https://github.com/vortexau/dnsvalidator.git
sudo ln -sf "$INSTALL_DIR/lib/dns_env/bin/dnsvalidator" /usr/local/bin/dnsvalidator

# Permisos y Enlace Final
chmod +x "$INSTALL_DIR/neDNSR"
find "$INSTALL_DIR/lib" -name "*.sh" -exec chmod +x {} +
sudo ln -sf "$INSTALL_DIR/neDNSR" /usr/local/bin/neDNSR
touch "$INSTALL_DIR/master_resolvers.txt"
chmod 666 "$INSTALL_DIR/master_resolvers.txt"

echo "[+] Instalado. Prueba con el comando: neDNSR -d google.com -n 50"