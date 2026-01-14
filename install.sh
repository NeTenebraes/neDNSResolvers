#!/bin/bash

INSTALL_DIR="/opt/neDNSR"
REPO_RAW="https://raw.githubusercontent.com/NeTenebraes/neDNSResolvers/main"
FILES=("neDNSR" "lib/collector.sh" "lib/validator.sh")

echo "[*] Instalación Global de neDNSResolvers..."

# 1. Preparar estructura
sudo mkdir -p "$INSTALL_DIR/lib"
sudo chown -R $USER:$USER "$INSTALL_DIR"

# 2. Descargar archivos (Recursividad simulada en descarga)
for file in "${FILES[@]}"; do
    mkdir -p "$INSTALL_DIR/$(dirname "$file")"
    curl -sL "$REPO_RAW/$file" -o "$INSTALL_DIR/$file"
done

# 3. Dependencias base
sudo apt-get update -qq
sudo apt-get install -y -qq git build-essential python3-venv golang-go wget > /dev/null

# 4. Verificar o Compilar MassDNS (Corregido)
if ! command -v massdns &> /dev/null; then
    echo "[*] MassDNS no detectado. Compilando..."
    TEMP_BUILD=$(mktemp -d)
    git clone --depth 1 https://github.com/blechschmidt/massdns.git "$TEMP_BUILD" > /dev/null
    cd "$TEMP_BUILD" && make -s && sudo cp bin/massdns /usr/local/bin/
    cd - && rm -rf "$TEMP_BUILD"
else
    echo "[+] MassDNS ya está instalado."
fi

# 5. PureDNS
if ! command -v puredns &> /dev/null; then
    go install github.com/d3mondev/puredns/v2@latest > /dev/null
    sudo ln -sf $(go env GOPATH)/bin/puredns /usr/local/bin/puredns
fi

# 6. Entorno dnsvalidator
if [ ! -d "$INSTALL_DIR/lib/dns_env" ]; then
    python3 -m venv "$INSTALL_DIR/lib/dns_env"
    "$INSTALL_DIR/lib/dns_env/bin/pip" install --quiet git+https://github.com/vortexau/dnsvalidator.git
fi
sudo ln -sf "$INSTALL_DIR/lib/dns_env/bin/dnsvalidator" /usr/local/bin/dnsvalidator

# 7. Permisos y Enlace Final
chmod +x "$INSTALL_DIR/neDNSR"
find "$INSTALL_DIR/lib" -name "*.sh" -exec chmod +x {} +
sudo ln -sf "$INSTALL_DIR/neDNSR" /usr/local/bin/neDNSR
[ ! -f "$INSTALL_DIR/master_resolvers.txt" ] && touch "$INSTALL_DIR/master_resolvers.txt"
sudo chmod 666 "$INSTALL_DIR/master_resolvers.txt"

echo "[+] Instalación finalizada sin errores."