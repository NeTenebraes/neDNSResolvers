#!/bin/bash

fetch_public_resolvers() {
    local output_file=$1
    echo "[*] Descargando candidatos externos..."
    curl -sL https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt \
             https://public-dns.info/nameservers.txt | \
             grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sort -u > "$output_file"
}