#!/bin/bash
# /opt/neDNSR/lib/validator.sh

measure_and_rank() {
    local input=$1
    local output=$2
    local limit=$3
    local threads=$4
    local target=$5
    local tmp_bench=$(mktemp)

    echo "[*] Rankeando Top $limit resolvers más rápidos para $target..." >&2

    # Benchmark paralelo: mide tiempo de respuesta real
    cat "$input" | xargs -P "$threads" -I {} sh -c '
        # Extraemos el Query time en ms usando dig
        ms=$(dig @{} '$target' +tries=1 +timeout=1 | grep "Query time" | awk "{print \$4}")
        if [ ! -z "$ms" ]; then
            echo "$ms {}"
        fi
    ' > "$tmp_bench"

    # Ordenar: Menor latencia primero -> Tomar el límite -> Limpiar para dejar solo la IP
    sort -n "$tmp_bench" | head -n "$limit" | awk '{print $2}' > "$output"
    
    local final_count=$(wc -l < "$output")
    rm -f "$tmp_bench"
    echo "$final_count"
}