# Manejo de interrupciones (Ctrl+C)
cleanup() {
    echo -e "\n\n[!] Interrupción detectada. Limpiando procesos y archivos temporales..." >&2
    # Mata a todos los procesos hijos del grupo actual
    kill -TERM -$$ 2>/dev/null
    exit 1
}

