#!/bin/bash
# /opt/neDNSR/lib/validator.sh

measure_and_rank() {
    local input=$1; local output=$2; local limit=$3
    local threads=$4; local target=$5
    local tmp_bench=$(mktemp)

    # 1. Obtenemos la IP de referencia (Verdad Absoluta)
    local real_ip=$(dig @1.1.1.1 "$target" +short +tries=1 +timeout=2 | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$' | tail -n1)
    
    if [ -z "$real_ip" ]; then
        echo -e "\n\e[1;31m[!]\e[0m Error: No se pudo resolver la IP real para \e[1m$target\e[0m."
        return
    fi

    # --- PAUSA---
    echo -e "\n\e[1;34m[➔]\e[0m Target: \e[1;37m$target\e[0m"
    echo -e "\e[1;34m[➔]\e[0m IP de referencia: \e[1;32m$real_ip\e[0m"
    echo -e "\e[1;33m[!]\e[0m Verificando integridad de resolvers en 1.5s...\e[0m"
    sleep 1.5
    # ----------------------------

    log_status "Iniciando ranking con $threads hilos..."

    # 2. Benchmark con validación de IP recibida
    cat "$input" | sort -u | xargs -P "$threads" -I {} sh -c "
        res_data=\$(dig @{} $target +tries=1 +timeout=1)
        
        # Extraer IP de la respuesta y latencia
        recv_ip=\$(echo \"\$res_data\" | grep -A1 'ANSWER SECTION' | grep -v 'ANSWER SECTION' | awk '{print \$NF}' | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}\$' | tail -n1)
        ms=\$(echo \"\$res_data\" | grep 'Query time' | awk '{print \$4}')
        
        # Si la IP es la correcta, guardamos para el ranking
        if [ \"\$recv_ip\" = \"$real_ip\" ] && [ -n \"\$ms\" ]; then
            printf \"\e[32m[+]\e[0m {} | \${ms}ms | \e[32mVALID\e[0m\n\" > /dev/tty
            echo \"\$ms {}\"
        elif [ -n \"\$ms\" ]; then
            # Si responde pero la IP no coincide
            printf \"\e[31m[-]\e[0m {} | \${ms}ms | \e[31mSPOOFED (\$recv_ip)\e[0m\n\" > /dev/tty
        fi
    " > "$tmp_bench"

    # 3. Lógica de guardado (Solo IPs, ordenadas por velocidad)
    if [[ "$limit" == "all" ]]; then
        sort -n "$tmp_bench" | awk '{print $2}' > "$output"
    else
        sort -n "$tmp_bench" | awk '{print $2}' | head -n "$limit" > "$output"
    fi
    
    local final_count=$(wc -l < "$output")
    echo -e "\n\e[1;32m[✔]\e[0m Finalizado: $final_count resolvers pasaron el test de integridad."
    
    rm -f "$tmp_bench"
}