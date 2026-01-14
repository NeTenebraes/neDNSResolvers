#!/bin/bash
# /opt/neDNSR/lib/helpers.sh

cleanup() {
    # Enviamos el mensaje a stderr para no ensuciar posibles pipes
    echo -e "\n\n[!] Saliendo: Matando procesos de DNSValidator y Benchmark..." >&2
    
    # Eliminamos archivos temporales que se hayan definido en el script principal
    [[ -f "$TMP_VALIDATED" ]] && rm -f "$TMP_VALIDATED"
    
    # Matamos todos los procesos hijos del script actual ($$)
    # pkill -P busca los procesos cuyo parent PID sea el de este script
    pkill -P $$ 2>/dev/null
    
    # Salida forzada
    exit 1
}

# Exportamos la función para que sub-shells puedan verla si es necesario
export -f cleanup