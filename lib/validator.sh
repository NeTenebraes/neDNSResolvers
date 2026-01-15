#!/bin/bash
# /opt/neDNSR/lib/validator.sh

measure_and_rank() {
    local input=$1; local output=$2; local limit=$3
    local threads=$4; local target=$5; local mode=$6
    local filtered_list=$(mktemp)
    local tmp_bench=$(mktemp)

    # 1. Obtener la "Verdad Absoluta" (IP real)
    local real_ip=$(dig @1.1.1.1 "$target" +short +tries=1 +timeout=2 | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$' | tail -n1)
    
    if [ -z "$real_ip" ]; then
        echo -e "\n\e[1;31m[!]\e[0m Error: No se pudo resolver la IP real para \e[1m$target\e[0m."
        return
    fi

    echo -e "\n\e[1;34m[➔]\e[0m Target: \e[1;37m$target\e[0m | IP: \e[1;32m$real_ip\e[0m"
    echo -e "\e[1;34m[➔]\e[0m Fase 1: Filtrado de Integridad (Modo: \e[1;35m${mode^^}\e[0m)"

    # --- FASE 1: FILTRADO SEGÚN MODO ---
    if [ "$mode" = "direct" ]; then
        echo -e "\e[1;33m[*] Verificando IPs exactas contra $target...\e[0m"
        # Filtro rápido: Solo los que devuelven la IP exacta
        cat "$input" | xargs -P "$threads" -I {} sh -c "
            recv_ip=\$(dig @{} $target +short +tries=1 +timeout=1 | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}\$' | tail -n1)
            if [ \"\$recv_ip\" = \"$real_ip\" ]; then
                echo \"{}\"
                printf \"\e[32m[+]\e[0m {} | \e[32mIntegridad OK\e[0m\n\" > /dev/tty
            fi
        " > "$filtered_list"

    elif [ "$mode" = "full" ]; then
        echo -e "\e[1;33m[*] Ejecutando DNSValidator (Filtro de Protocolo Profundo)...\e[0m"
        # Filtro profundo: Usamos dnsvalidator sobre el LIVE.txt
        dnsvalidator -tL "$input" -threads "$threads" -o "$filtered_list"
    fi

    # --- FASE 2: RANKING POR VELOCIDAD ---
    local count=$(wc -l < "$filtered_list")
    if [ "$count" -eq 0 ]; then
        echo -e "\e[1;31m[!] Ningún resolver pasó la fase de integridad.\e[0m"
        return
    fi

    echo -e "\n\e[1;34m[➔]\e[0m Fase 2: Ranking de Velocidad ($count resolvers supervivientes)"
    
    cat "$filtered_list" | xargs -P "$threads" -I {} sh -c "
        ms=\$(dig @{} $target +tries=1 +timeout=1 | grep 'Query time' | awk '{print \$4}')
        if [ -n \"\$ms\" ]; then
            echo \"\$ms {}\"
            printf \"\e[36m[·]\e[0m {} | \${ms}ms\n\" > /dev/tty
        fi
    " > "$tmp_bench"

    # --- FASE 3: GUARDADO Y LIMITACIÓN ---
    sort -n "$tmp_bench" | awk '{print $2}' | { [[ "$limit" == "all" ]] && cat || head -n "$limit"; } > "$output"

    echo -e "\n\e[1;32m[✔]\e[0m Proceso terminado. Lista final en: \e[1m$output\e[0m"
    
    rm -f "$filtered_list" "$tmp_bench"
}