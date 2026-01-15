measure_and_rank() {
    local input=$1; local output=$2; local limit=$3
    local threads=$4; local target=$5
    local tmp_bench=$(mktemp)

    # 1. Obtenemos la IP REAL
    local real_ip=$(dig @1.1.1.1 "$target" +short | grep -E '^[0-9.]+$' | tail -n1)
    
    if [ -z "$real_ip" ]; then
        echo -e "\e[1;31m[!]\e[0m No se pudo obtener la IP real de $target. Abortando."
        return
    fi

    echo -e "\e[1;34m[*]\e[0m Verdad absoluta ($target): $real_ip. Validando..."

    # 2. Benchmark con sintaxis POSIX compatible para sh
    cat "$input" | xargs -P "$threads" -I {} sh -c "
        res_data=\$(dig @{} $target +tries=1 +timeout=1)
        
        # Extraer IP de la sección ANSWER
        recv_ip=\$(echo \"\$res_data\" | awk '/^$target\./ || /^$target / {print \$NF}' | grep -E '^[0-9.]+$' | tail -n1)
        ms=\$(echo \"\$res_data\" | grep 'Query time' | awk '{print \$4}')
        
        # Usamos '=' simple para POSIX y verificamos que no estén vacíos
        if [ \"\$recv_ip\" = \"$real_ip\" ] && [ -n \"\$ms\" ]; then
            echo \"\$ms {}\"
        fi
    " > "$tmp_bench"

    # 3. Ordenar y guardar
    sort -g "$tmp_bench" | awk '{print $2}' | head -n "$limit" > "$output"
    rm -f "$tmp_bench"
}
