#!/bin/bash

# Configuración de rutas
INSTALL_DIR="/opt/neDNSR"
REPO_RAW="https://raw.githubusercontent.com/NeTenebraes/neDNSResolvers/main"
REPO_API="https://api.github.com/repos/NeTenebraes/neDNSResolvers/contents"

# Manejo de interrupciones (Ctrl+C)
trap 'echo -e "\n[!] Instalación cancelada por el usuario."; exit 1' SIGINT

echo "[*] Iniciando instalación técnica de neDNSR..."

# 1. Preparar estructura (Único paso con sudo obligatorio)
if [ ! -d "$INSTALL_DIR" ]; then
    sudo mkdir -p "$INSTALL_DIR/lib"
    sudo chown -R $USER:$USER "$INSTALL_DIR"
fi

# 2. Descarga de archivos (Sin sudo)
echo "[*] Descargando componentes..."
curl -sL "$REPO_RAW/neDNSR" -o "$INSTALL_DIR/neDNSR"

# Obtener lista de módulos lib/
LIB_FILES=$(curl -s "$REPO_API/lib" | grep '"name":' | cut -d'"' -f4)
for file in $LIB_FILES; do
    if [[ $file == *.sh ]]; then
        curl -sL "$REPO_RAW/lib/$file" -o "$INSTALL_DIR/lib/$file"
    fi
done

# 3. Compilación selectiva de MassDNS
if ! command -v massdns &> /dev/null; then
    echo "[*] MassDNS no encontrado. Compilando en /tmp..."
    TEMP_BUILD=$(mktemp -d)
    git clone --depth 1 https://github.com/blechschmidt/massdns.git "$TEMP_BUILD" &> /dev/null
    (cd "$TEMP_BUILD" && make -s && sudo cp bin/massdns /usr/local/bin/)
    rm -rf "$TEMP_BUILD"
fi

# 4. Entorno de Python (Aislado)
if [ ! -d "$INSTALL_DIR/lib/dns_env" ]; then
    echo "[*] Configurando entorno para DNSValidator..."
    # Solo instalamos venv si el comando falla
    python3 -m venv "$INSTALL_DIR/lib/dns_env" || (sudo apt update && sudo apt install -y python3-venv && python3 -m venv "$INSTALL_DIR/lib/dns_env")
    "$INSTALL_DIR/lib/dns_env/bin/pip" install --quiet git+https://github.com/vortexau/dnsvalidator.git
fi

# 5. Finalización de permisos y enlaces simbólicos
chmod +x "$INSTALL_DIR/neDNSR"
find "$INSTALL_DIR/lib" -name "*.sh" -exec chmod +x {} +

# Enlaces globales
sudo ln -sf "$INSTALL_DIR/neDNSR" /usr/local/bin/neDNSR
sudo ln -sf "$INSTALL_DIR/lib/dns_env/bin/dnsvalidator" /usr/local/bin/dnsvalidator

# Archivo de persistencia
touch "$INSTALL_DIR/master_resolvers.txt"
chmod 666 "$INSTALL_DIR/master_resolvers.txt"
echo "[+] Instalación finalizada en $INSTALL_DIR"