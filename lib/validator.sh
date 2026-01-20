#!/bin/bash
# /opt/neDNSR/lib/validator.sh

measure_and_rank() {
    local input=$1; local output=$2; local limit=$3
    local threads=$4; local target=$5; local mode=$6
    local tmp_bench=$(mktemp)
    local filtered_list=$(mktemp)

    # 1. Obtener IP real de referencia
    local real_ip=$(dig @1.1.1.1 "$target" +short +tries=1 +timeout=2 | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$' | tail -n1)
    
    if [ -z "$real_ip" ]; then
        echo -e "\n\e[1;31m[!]\e[0m Error: No se pudo resolver la IP real para \e[1m$target\e[0m."
        return
    fi

    echo -e "\n\e[1;34m[➔]\e[0m Target: \e[1;37m$target\e[0m | IP: \e[1;32m$real_ip\e[0m"
    echo -e "\e[1;34m[➔]\e[0m Ejecutando en modo: \e[1;35m${mode^^}\e[0m"

    # --- CAMINO A: MODO DIRECT ---
if [ "$mode" = "direct" ]; then
    echo -e "\e[1;33m[*] Validando Integridad (A) y Velocidad...\e[0m"
    cat "$input" | xargs -P "$threads" -I {} sh -c '
        target="$0"
        real_ip="$1"
        res_ip=$(dig @"{}" "$target" +short +tries=1 +timeout=1 | grep -E "^([0-9]{1,3}\.){3}[0-9]{1,3}$" | tail -n1)
        ms=$(dig @"{}" "$target" +tries=1 +timeout=1 2>/dev/null | grep "Query time" | awk "{print \$4}")

        # Opción 1: SOLO exigir IP válida (no igual a real_ip)
        if [ -n "$res_ip" ] && [ -n "$ms" ]; then
            echo "$ms {}"
            printf "\033[32m[+]\033[0m {} | ${ms}ms | \033[32mOK\033[0m\n" > /dev/tty
        fi

        # Si quieres seguir exigiendo misma IP, cambia la condición por:
        # if [ "$res_ip" = "$real_ip" ] && [ -n "$ms" ]; then
    ' "$target" "$real_ip" > "$tmp_bench"


    # --- CAMINO B: MODO FULL (Doble Paso) ---
    else
        echo -e "\e[1;33m[*] Paso 1: Filtrado profundo con DNSValidator...\e[0m"
        dnsvalidator -tL "$input" -threads "$threads" -o "$filtered_list"
        
        local count=$(wc -l < "$filtered_list")
        echo -e "\e[1;33m[*] Paso 2: Ranking de velocidad sobre $count resolvers...\e[0m"
        
        cat "$filtered_list" | xargs -P "$threads" -I {} sh -c "
            ms=\$(dig @{} $target +tries=1 +timeout=1 | grep 'Query time' | awk '{print \$4}')
            if [ -n \"\$ms\" ]; then
                echo \"\$ms {}\"
                printf \"\e[36m[·]\e[0m {} | \${ms}ms\n\" > /dev/tty
            fi
        " > "$tmp_bench"
    fi

    # --- FINALIZACIÓN COMÚN (Ordenar y Limpiar) ---
    sort -n "$tmp_bench" | awk '{print $2}' | { [[ "$limit" == "all" ]] && cat || head -n "$limit"; } > "$output"

    echo -e "\n\e[1;32m[✔]\e[0m Proceso terminado. Lista final: \e[1m$output\e[0m (\e[1m$(wc -l < "$output")\e[0m resolvers)"
    
    rm -f "$tmp_bench" "$filtered_list"
}