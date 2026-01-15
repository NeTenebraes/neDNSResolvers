#!/bin/bash

measure_and_rank() {
    local input=$1; local output=$2; local limit=$3
    local threads=$4; local target=$5
    local tmp_bench=$(mktemp)

    # 1. Obtenemos la IP REAL del target (la verdad absoluta) para comparar
    local real_ip=$(dig @1.1.1.1 $target +short | tail -n1)
    
    log_status "La IP real de $target es $real_ip. Validando integridad y velocidad..."

    # 2. Benchmark + Verificación de Verdad
    cat "$input" | xargs -P "$threads" -I {} sh -c "
        # Consultamos al resolver
        res_data=\$(dig @{} $target +tries=1 +timeout=1)
        
        # Extraemos IP recibida y tiempo
        recv_ip=\$(echo \"\$res_data\" | grep -E '^[0-9.]+$' || echo \"\$res_data\" | grep 'IN A' | awk '{print \$5}' | tail -n1)
        ms=\$(echo \"\$res_data\" | grep 'Query time' | awk '{print \$4}')
        
        # FILTRO MILITAR: ¿Es la IP correcta Y respondió a tiempo?
        if [ \"\$recv_ip\" == \"$real_ip\" ] && [ ! -z \"\$ms\" ]; then
            echo \"\$ms {}\"
        fi
    " > "$tmp_bench"

    # 3. Ordenamiento por velocidad (el más rápido primero)
    sort -g "$tmp_bench" | awk '{print $2}' | head -n "$limit" > "$output"

    rm -f "$tmp_bench"
}
