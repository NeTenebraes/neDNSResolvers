#!/bin/bash

# --- Configuración del Repositorio ---
REPO_RAW="https://raw.githubusercontent.com/NeTenebraes/neDNSResolvers/main"
FILES=("neDNSR" "lib/collector.sh" "lib/validator.sh")

echo -e "\e[1;34m[*] Configurando neDNSResolvers de NeTenebraes...\e[0m"

# 1. Asegurar la presencia de los archivos del core
for file in "${FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "[*] Descargando componente faltante: $file"
        mkdir -p $(dirname "$file")
        curl -sL "$REPO_RAW/$file" -o "$file" || { echo "[-] Error al descargar $file"; exit 1; }
    fi
done

# 2. Instalación de dependencias base
echo "[*] Instalando dependencias base (apt)..."
sudo apt-get update -qq
sudo apt-get install -y -qq git build-essential python3-venv golang-go wget curl > /dev/null

# 3. Compilación manual de MassDNS (Crucial para que puredns funcione)
if ! command -v massdns &> /dev/null; then
    echo "[*] Compilando MassDNS desde el código fuente..."
    TEMP_BUILD=$(mktemp -d)
    git clone --depth 1 https://github.com/blechschmidt/massdns.git "$TEMP_BUILD" > /dev/null
    cd "$TEMP_BUILD" && make -s && sudo cp bin/massdns /usr/local/bin/
    cd - && rm -rf "$TEMP_BUILD"
fi

# 4. Instalación de PureDNS
if ! command -v puredns &> /dev/null; then
    echo "[*] Instalando PureDNS..."
    go install github.com/d3mondev/puredns/v2@latest > /dev/null
    sudo ln -sf $(go env GOPATH)/bin/puredns /usr/local/bin/puredns
fi

# 5. Configuración de dnsvalidator
echo "[*] Configurando dnsvalidator..."
mkdir -p lib
python3 -m venv lib/dns_env
source lib/dns_env/bin/activate
pip install --quiet git+https://github.com/vortexau/dnsvalidator.git
deactivate
sudo ln -sf "$(pwd)/lib/dns_env/bin/dnsvalidator" /usr/local/bin/dnsvalidator

# 6. Registro Global del comando neDNSR
chmod +x neDNSR
chmod +x lib/*.sh
sudo ln -sf "$(pwd)/neDNSR" /usr/local/bin/neDNSR
touch master_resolvers.txt
chmod 666 master_resolvers.txt

echo -e "\e[1;32m[+] Instalación finalizada.\e[0m"
echo -e "\e[1;33m[!] Ahora puedes usar 'neDNSR' desde cualquier lugar.\e[0m"