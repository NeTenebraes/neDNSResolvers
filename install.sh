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

# 2. Instalación de dependencias binarias (Requiere Sudo)
echo "[*] Instalando dependencias del sistema (apt, massdns, puredns)..."
sudo apt-get update -qq
sudo apt-get install -y -qq git build-essential python3-venv golang-go massdns > /dev/null

# 3. Instalación de PureDNS (vía Go)
if ! command -v puredns &> /dev/null; then
    echo "[*] Instalando PureDNS..."
    go install github.com/d3mondev/puredns/v2@latest > /dev/null
    # Crear enlace simbólico para acceso global
    sudo ln -sf $(go env GOPATH)/bin/puredns /usr/local/bin/puredns
fi

# 4. Aislamiento de dnsvalidator (Evita conflictos de Python)
echo "[*] Creando entorno virtual para dnsvalidator..."
mkdir -p lib
python3 -m venv lib/dns_env
source lib/dns_env/bin/activate
pip install --quiet git+https://github.com/vortexau/dnsvalidator.git
deactivate

# Enlace simbólico para el binario de dnsvalidator
sudo ln -sf "$(pwd)/lib/dns_env/bin/dnsvalidator" /usr/local/bin/dnsvalidator

# 5. Permisos y Persistencia
chmod +x neDNSR
chmod +x lib/*.sh
touch master_resolvers.txt
chmod 666 master_resolvers.txt

echo -e "\e[1;32m[+] Instalación finalizada con éxito.\e[0m"
echo -e "\e[1;33m[!] Uso: ./neDNSR -d dominio.com -n 200\e[0m"