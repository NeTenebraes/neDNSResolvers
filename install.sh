#!/bin/bash

# --- Configuración ---
REPO_RAW="https://raw.githubusercontent.com/NeTenebraes/neDNSResolvers/main"
FILES=("neDNSR" "lib/collector.sh" "lib/validator.sh")

echo -e "\e[1;34m[*] Verificando entorno para neDNSResolvers...\e[0m"

# 1. Descarga de archivos del proyecto si faltan
for file in "${FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "[*] Descargando: $file"
        mkdir -p $(dirname "$file")
        curl -sL "$REPO_RAW/$file" -o "$file"
    fi
done

# 2. Verificar MassDNS (Si no está en el PATH, lo buscamos o instalamos)
if ! command -v massdns &> /dev/null; then
    echo "[!] MassDNS no detectado. Intentando instalar..."
    sudo apt-get install -y -qq git build-essential > /dev/null
    TEMP_BUILD=$(mktemp -d)
    git clone --depth 1 https://github.com/blechschmidt/massdns.git "$TEMP_BUILD" > /dev/null
    cd "$TEMP_BUILD" && make -s && sudo cp bin/massdns /usr/local/bin/
    cd - && rm -rf "$TEMP_BUILD"
else
    echo "[+] MassDNS detectado en: $(which massdns)"
fi

# 3. Verificar PureDNS
if ! command -v puredns &> /dev/null; then
    echo "[!] PureDNS no detectado. Instalando vía Go..."
    go install github.com/d3mondev/puredns/v2@latest > /dev/null
    sudo ln -sf $(go env GOPATH)/bin/puredns /usr/local/bin/puredns
else
    echo "[+] PureDNS detectado en: $(which puredns)"
fi

# 4. Vincular neDNSR globalmente (Para que funcione el comando 'neDNSR')
chmod +x neDNSR
sudo ln -sf "$(pwd)/neDNSR" /usr/local/bin/neDNSR

# 5. Asegurar dnsvalidator
if ! command -v dnsvalidator &> /dev/null; then
    echo "[*] Configurando entorno para dnsvalidator..."
    python3 -m venv lib/dns_env
    source lib/dns_env/bin/activate
    pip install --quiet git+https://github.com/vortexau/dnsvalidator.git
    deactivate
    sudo ln -sf "$(pwd)/lib/dns_env/bin/dnsvalidator" /usr/local/bin/dnsvalidator
fi

echo -e "\e[1;32m[+] Configuración lista. Prueba ejecutando: neDNSR -h\e[0m"