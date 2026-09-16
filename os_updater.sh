#!/bin/bash
# auto_update.sh - Automatització completa d'actualitzacions per Servidors (Debian/Ubuntu & CentOS/RHEL)

# Colors per la interfície
c_main="\e[1;36m"
c_accent="\e[1;34m"
c_success="\e[1;32m"
c_warning="\e[1;33m"
c_error="\e[1;31m"
c_dim="\e[90m"
c_reset="\e[0m"

clear
echo -e "${c_main}╭──────────────────────────────────────────────────╮${c_reset}"
echo -e "${c_main}│${c_accent}          🚀 REMOTE LINUX OS UPDATER V2           ${c_main}│${c_reset}"
echo -e "${c_main}╰──────────────────────────────────────────────────╯${c_reset}"
echo -e ""

target=""
custom_port=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -p)
            custom_port="$2"
            shift 2
            ;;
        *)
            if [ -z "$target" ]; then
                target="$1"
            fi
            shift
            ;;
    esac
done

if [ -z "$target" ]; then
    echo -ne " ${c_accent}❯${c_reset} Introdueix el nom de la MV o IP: ${c_main}"
    read target
    echo -ne "${c_reset}"
fi

if [ -z "$target" ]; then
    echo -e "\n${c_error}  ❌ [ ERROR ] Cal un servidor.${c_reset}\n"
    exit 1
fi

echo -ne "  ${c_warning}⚠️  Has fet una snapshot? [s/N]: ${c_reset}"
read -r resp_snap1
if [[ ! "$resp_snap1" =~ ^[SsYy] ]]; then
    echo -e "\n${c_error}  ❌ Fes la snapshot i llavors torna a executar l'script.${c_reset}\n"
    exit 1
fi

echo -ne "  ${c_warning}⚠️  Segona confirmació: Has fet una snapshot? [s/N]: ${c_reset}"
read -r resp_snap2
if [[ ! "$resp_snap2" =~ ^[SsYy] ]]; then
    echo -e "\n${c_error}  ❌ Fes la snapshot i llavors torna a executar l'script.${c_reset}\n"
    exit 1
fi

init_log="/tmp/os_updater_init_$$.log"
rm -f "$init_log"

log() {
    echo -e "$@"
    local target_log="${session_log:-$init_log}"
    echo -e "$@" | sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g; s/\r$//' >> "$target_log"
}

log_prompt() {
    echo -ne "$@"
    local target_log="${session_log:-$init_log}"
    echo -ne "$@" | sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g; s/\r$//' >> "$target_log"
}

log_input() {
    local target_log="${session_log:-$init_log}"
    echo "$1" >> "$target_log"
}

echo -e "\n${c_dim}┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${c_reset}"
echo -e "${c_accent} 📡 Connectant amb $target...${c_reset}"

ssh_port_flag=""
scp_port_flag=""
if [ -n "$custom_port" ]; then
    ssh_port_flag="-p $custom_port"
    scp_port_flag="-P $custom_port"
fi

# 1. Comprovació de port (fast ping) usant la config de SSH
real_host=$(ssh -G $ssh_port_flag "$target" 2>/dev/null | awk '/^hostname / {print $2}')
if [ -n "$custom_port" ]; then
    real_port="$custom_port"
else
    real_port=$(ssh -G "$target" 2>/dev/null | awk '/^port / {print $2}')
    [ -z "$real_port" ] && real_port=22
fi
[ -z "$real_host" ] && real_host="$target"

if ! timeout 2 bash -c "</dev/tcp/$real_host/$real_port" 2>/dev/null; then
    log "\n${c_error}  ❌ [ ERROR ] $target no respon al port SSH ($real_port).${c_reset}\n"
    exit 1
fi

echo -e "${c_accent} 🔍 Detectant sistema operatiu i host...${c_reset}"
sleep 1
# 2. Obtenim tota la info en una sola connexió (super ràpid)
initial_info=$(ssh $ssh_port_flag -o ConnectTimeout=5 -o BatchMode=yes "root@$target" "hostname; ip=\$(hostname -I 2>/dev/null | awk '{print \$1}'); echo \"\$ip\"; if command -v apt >/dev/null; then echo apt; elif command -v yum >/dev/null; then echo yum; else echo unknown; fi" 2>/dev/null)

if [ -z "$initial_info" ]; then
    log "  ${c_error}✖ No s'ha pogut accedir per SSH com a root.${c_reset}"
    exit 1
fi

remote_host=$(echo "$initial_info" | sed -n '1p')
remote_ip=$(echo "$initial_info" | sed -n '2p')
pkg_mgr=$(echo "$initial_info" | sed -n '3p')

if [ "$pkg_mgr" == "unknown" ]; then
    log "${c_error}  ❌ [ ERROR ] No s'ha detectat 'apt' ni 'yum' a la màquina remota.${c_reset}"
    exit 1
fi

log "${c_success}  ✔ Sistema detectat: $pkg_mgr ($remote_host)${c_reset}"

# 3. Crear carpeta local amb el nom desitjat
[ -z "$remote_ip" ] && remote_ip="$target"
dest_dir="$HOME/Descargas/logs-updates/${remote_host}-${remote_ip}"
mkdir -p "$dest_dir"

log_name="log-update-${remote_host}-$(date +%d-%m-%Y_%H-%M-%S).txt"
session_log="$dest_dir/$log_name"

if [ -f "$init_log" ]; then
    cat "$init_log" > "$session_log"
    rm -f "$init_log"
fi

# 1. DIAGNÒSTIC PREVI
log "\n${c_dim}┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${c_reset}"
log "${c_accent} 📊 Recopilant dades de diagnòstic PRE-actualització...${c_reset}"
sleep 1
diag_pre="/tmp/diag_pre_${target}.txt"

if [ "$pkg_mgr" == "apt" ]; then
    pkg_mgr_check="apt update >/dev/null 2>&1 && apt list --upgradable 2>/dev/null"
    netstat_flags="-ntlepu"
else
    pkg_mgr_check="yum check-update 2>/dev/null"
    netstat_flags="-ntlep"
fi

diag_cmd='echo -e "\n[+] Paquets a actualitzar\n"; '"$pkg_mgr_check"'; echo -e "\n[+] Ports\n"; p=$(netstat '"$netstat_flags"' 2>/dev/null | tail -n +3 | sort -t: -k2 -n); [ -z "$p" ] && echo "  (Cap port obert detectat)" || echo "$p"; echo -e "\n[+] Processos\n"; pstree 2>/dev/null; echo -e "\n[+] Kernel\n"; uname -r; echo -e "\n[+] Contenidors\n"; c=$(docker ps -a 2>/dev/null | tail -n +2); [ -z "$c" ] && echo "  (Cap contenidor Docker)" || docker ps -a 2>/dev/null'

# Executar diagnòstic, guardar a local i mostrar per pantalla alhora
ssh $ssh_port_flag "root@$target" "$diag_cmd" | tee "$diag_pre"
sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g; s/\r$//' "$diag_pre" >> "$session_log"
log "${c_success}  ✔ Diagnòstic previ completat i guardat.${c_reset}"

# 2. ACTUALITZACIÓ
log "\n${c_dim}┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${c_reset}"
log "${c_accent} ⚙️  Iniciant actualització de sistema...${c_reset}"
log "${c_dim} (Veuràs la sortida en directe de l'actualització per pantalla)${c_reset}\n"
sleep 1


local_log_tmp="$dest_dir/update_live_capture.tmp"

if [ "$pkg_mgr" == "apt" ]; then
    update_cmd="DEBIAN_FRONTEND=noninteractive apt upgrade -y 2>&1 | tee /root/$log_name"
else
    update_cmd="yum update -y 2>&1 | tee /root/$log_name"
fi

# Usem -t per obrir un terminal interactiu virtual i capturem en directe per si falla el reinici
ssh -t $ssh_port_flag "root@$target" "$update_cmd" | tee >(sed 's/\r$//' > "$local_log_tmp")
update_exit_code=${PIPESTATUS[0]}

# Afegir sortida neta de l'actualització al log global de la sessió
sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g; s/\r$//' "$local_log_tmp" >> "$session_log"

# COMPROVACIÓ D'ERRORS I AVISOS D'ACTUALITZACIÓ (scriptlets RPM, dpkg, warnings, etc.)
clean_log_file="$dest_dir/update_clean.tmp"
sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g; s/\r$//' "$local_log_tmp" > "$clean_log_file"

# Extreure errors concrets
errors_list=$(grep -E -i "(scriptlet failed|Error in POSTTRANS|Error in %posttrans|dpkg: error|(sub-process|subprocess).*error|No space left on device|Transaction failed|grub2-probe: error|grub-install: error|^E: |^Error: |Failed to synchronize cache|GPG check FAILED)" "$clean_log_file" | grep -v -i "No error reported" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' | awk '!seen[$0]++')

update_has_error="no"
if [ $update_exit_code -ne 0 ]; then
    update_has_error="yes"
    if [ -z "$errors_list" ]; then
        errors_list="La comanda d'actualització ($pkg_mgr) ha retornat un codi d'error ($update_exit_code)."
    fi
elif [ -n "$errors_list" ]; then
    update_has_error="yes"
fi

# Extreure avisos (warns) concrets, ignorant advertències benignes habituals de sistema
warnings_list=$(grep -E -i "(^W: |dpkg: warning|^Warning: |^warning: |^WARN: |RPM: warning:|dracut.*WARN)" "$clean_log_file" | grep -v -E -i "(stable CLI interface|os-prober will not be executed|start and stop actions are no longer supported)" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' | awk '!seen[$0]++')

update_has_warning="no"
if [ -n "$warnings_list" ]; then
    update_has_warning="yes"
fi

rm -f "$clean_log_file"

if [ "$update_has_error" == "yes" ]; then
    log "\n${c_error}╭─────────────────────────────────────────────────────────────────╮${c_reset}"
    log "${c_error}│ ❌ [ ERROR CRÍTIC D'ACTUALITZACIÓ DETECTAT ]                    │${c_reset}"
    log "${c_error}╰─────────────────────────────────────────────────────────────────╯${c_reset}"
    log "${c_warning}  ⚠️  PER SEGURETAT, S'HA BLOQUEJAT EL REINICI I L'AUTOREMOVE.${c_reset}\n"
    log "${c_error}  No es permet reiniciar perquè s'han detectat els següents errors:${c_reset}"
    idx=1
    while IFS= read -r err_line; do
        if [ -n "$err_line" ]; then
            log "  ${c_error}${idx}.${c_reset} $err_line"
            ((idx++))
        fi
    done <<< "$errors_list"

    if [ "$update_has_warning" == "yes" ]; then
        log "\n${c_warning}  També s'han detectat els següents avisos:${c_reset}"
        idx=1
        while IFS= read -r warn_line; do
            if [ -n "$warn_line" ]; then
                log "  ${c_warning}${idx}.${c_reset} $warn_line"
                ((idx++))
            fi
        done <<< "$warnings_list"
    fi
    
    err_log="$dest_dir/${log_name%.txt}_ERROR_ACTUALITZACIO.txt"
    echo "=================================================" > "$err_log"
    echo "   ERROR CRÍTIC DURANT L'ACTUALITZACIÓ DE PAQUETS   " >> "$err_log"
    echo "=================================================" >> "$err_log"
    echo -e "\nErrors detectats:\n$errors_list" >> "$err_log"
    if [ "$update_has_warning" == "yes" ]; then
        echo -e "\nAvisos detectats:\n$warnings_list" >> "$err_log"
    fi
    echo -e "\nDiagnòstic previ:" >> "$err_log"
    cat "$diag_pre" >> "$err_log"
    echo -e "\n=================================================" >> "$err_log"
    echo "Registre detallat de l'actualització amb fallada:" >> "$err_log"
    cat "$local_log_tmp" >> "$err_log"
    
    # Intentar copiar el log remot si existeix
    scp $scp_port_flag -q "root@${target}:/root/$log_name" "$dest_dir/" 2>/dev/null
    
    log "\n${c_success}  ✔ S'ha guardat l'informe d'error a:${c_reset} $err_log"
    log "${c_warning}  📌 Revisa els errors manualment abans de reiniciar.${c_reset}\n"
    rm -f "$local_log_tmp"
    exit 1
fi

if [ "$update_has_warning" == "yes" ]; then
    log "\n${c_warning}╭─────────────────────────────────────────────────────────────────╮${c_reset}"
    log "${c_warning}│ ⚠️  [ AVISOS (WARNS) D'ACTUALITZACIÓ DETECTATS ]                │${c_reset}"
    log "${c_warning}╰─────────────────────────────────────────────────────────────────╯${c_reset}"
    log "${c_warning}  ⚠️  PER SEGURETAT, S'HA BLOQUEJAT EL REINICI I L'AUTOREMOVE.${c_reset}\n"
    log "${c_warning}  No es permet reiniciar perquè s'han detectat els següents avisos:${c_reset}"
    idx=1
    while IFS= read -r warn_line; do
        if [ -n "$warn_line" ]; then
            log "  ${c_warning}${idx}.${c_reset} $warn_line"
            ((idx++))
        fi
    done <<< "$warnings_list"

    warn_log="$dest_dir/${log_name%.txt}_AVISOS_ACTUALITZACIO.txt"
    echo "=================================================" > "$warn_log"
    echo "   AVISOS DETECTATS DURANT L'ACTUALITZACIÓ          " >> "$warn_log"
    echo "=================================================" >> "$warn_log"
    echo -e "\nAvisos detectats:\n$warnings_list" >> "$warn_log"
    echo -e "\nDiagnòstic previ:" >> "$warn_log"
    cat "$diag_pre" >> "$warn_log"
    echo -e "\n=================================================" >> "$warn_log"
    echo "Registre de l'actualització:" >> "$warn_log"
    cat "$local_log_tmp" >> "$warn_log"

    # Intentar copiar el log remot si existeix
    scp $scp_port_flag -q "root@${target}:/root/$log_name" "$dest_dir/" 2>/dev/null

    log "\n${c_success}  ✔ S'ha guardat l'informe d'avisos a:${c_reset} $warn_log"
    log "${c_warning}  📌 Revisa els avisos manualment abans de procedir amb qualsevol reinici.${c_reset}\n"
    rm -f "$local_log_tmp"
    exit 1
fi

log "${c_success}  ✔ Actualització de paquets finalitzada sense errors ni avisos.${c_reset}"

# 3. REINICI SI CAL
log "\n${c_dim}┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${c_reset}"
log "${c_accent} 🔄 Comprovant necessitat de reinici (Kernel/Core)...${c_reset}"
sleep 1
if [ "$pkg_mgr" == "apt" ]; then
    reboot_info=$(ssh $ssh_port_flag "root@$target" '
        if grep -qiE "(setting up|inst).*(linux-image|linux-headers|linux-modules)-[0-9]" /root/'"$log_name"' 2>/dev/null || ([ -f /var/run/reboot-required ] && [ -f /root/'"$log_name"' ] && [ /var/run/reboot-required -nt /root/'"$log_name"' ]); then
            echo "session"
        elif [ -f /var/run/reboot-required ]; then
            r_date=$(date -r /var/run/reboot-required +"%d/%m/%Y" 2>/dev/null)
            echo "pending_old:$r_date"
        else
            echo "none"
        fi
    ')
else
    reboot_info=$(ssh $ssh_port_flag "root@$target" '
        if grep -qiE "(install|updat|upgrad|instaland|actualizand).*(kernel|kernel-core|kernel-modules)-[0-9]" /root/'"$log_name"' 2>/dev/null; then
            echo "session"
        elif command -v needs-restarting >/dev/null 2>&1 && ! needs-restarting -r >/dev/null 2>&1; then
            echo "pending_old:"
        else
            echo "none"
        fi
    ')
fi

reboot_type=$(echo "$reboot_info" | cut -d: -f1)
reboot_date=$(echo "$reboot_info" | cut -d: -f2)

if [ "$reboot_type" == "session" ] || [ "$reboot_type" == "pending_old" ]; then
    if [ "$reboot_type" == "session" ]; then
        log "${c_warning}  ⚠️ S'ha actualitzat el Kernel o un servei core en aquesta sessió i es recomana reiniciar la MV.${c_reset}"
        log_prompt "  Vols reiniciar el servidor ara mateix? [S/n]: "
    else
        if [ -n "$reboot_date" ]; then
            log "${c_warning}  ⚠️ No s'ha actualitzat cap paquet nou, però el servidor tenia un reinici pendent previ (fitxer reboot-required del ${reboot_date}).${c_reset}"
        else
            log "${c_warning}  ⚠️ No s'ha actualitzat cap paquet nou, però el servidor tenia un reinici pendent previ.${c_reset}"
        fi
        log_prompt "  Vols reiniciar el servidor igualment? [S/n]: "
    fi
    read -r resp_reboot
    log_input "$resp_reboot"
    
    do_reboot=false
    if [[ ! "$resp_reboot" =~ ^[Nn] ]]; then
        log_prompt "${c_warning}  ⚠️  Segona confirmació: N'estàs segur que vols reiniciar el servidor ara mateix? [S/n]: ${c_reset}"
        read -r resp_reboot2
        log_input "$resp_reboot2"
        if [[ ! "$resp_reboot2" =~ ^[Nn] ]]; then
            do_reboot=true
        fi
    fi

    if [ "$do_reboot" = false ]; then
        log "${c_warning}  S'ha omès el reinici.${c_reset}"
        log_prompt "  Vols continuar amb el següent pas (4. Comprovació post-actualització)? [S/n]: "
        read -r resp_cont
        log_input "$resp_cont"
        if [[ "$resp_cont" =~ ^[Nn] ]]; then
            log "\n${c_error}  Abortant el procés per petició de l'usuari.${c_reset}"
            rm -f "$local_log_tmp"
            exit 1
        fi
    else
        log "${c_accent}  Reiniciant el servidor...${c_reset}"
        ssh $ssh_port_flag "root@$target" "reboot"
        
        log "${c_dim}  Esperant que el servidor es desconnecti...${c_reset}"
        sleep 5
        
        log "${c_dim}  Esperant que torni a estar online (màxim 60 segons)...${c_reset}"
        wait_time=0
        server_up=false
        max_wait=60
        extra_wait_prompted=false
        
        while [ $wait_time -lt $max_wait ]; do
            if timeout 2 bash -c "</dev/tcp/$real_host/$real_port" 2>/dev/null; then
                server_up=true
                break
            fi
            sleep 3
            wait_time=$((wait_time + 3))
            
            if [ "$server_up" = false ] && [ $wait_time -ge 60 ] && [ "$extra_wait_prompted" = false ]; then
                log "${c_warning}  ⚠️ El servidor porta 60s sense respondre.${c_reset}"
                log_prompt "  Vols donar-li 30 segons extra de marge? [S/n]: "
                read -r resp_wait
                log_input "$resp_wait"
                extra_wait_prompted=true
                if [[ ! "$resp_wait" =~ ^[Nn] ]]; then
                    log "${c_dim}  Esperant 30 segons addicionals...${c_reset}"
                    max_wait=90
                else
                    break
                fi
            fi
        done
        
        if [ "$server_up" = true ]; then
            # Donar-li un marge al procés SSH i als serveis perquè s'aixequin del tot
            sleep 10
            log "${c_success}  ✔ Servidor online de nou!${c_reset}"
        else
            log "${c_error}  💥 [ ERROR CRÍTIC ] El servidor no ha tornat a respondre!${c_reset}"
            log "${c_warning}  És possible que hi hagi hagut un 'Kernel Panic' o s'hagi quedat sense espai.${c_reset}"
            
            err_log="$dest_dir/${log_name%.txt}_error.txt"
            echo "=================================================" > "$err_log"
            echo "   ERROR CRÍTIC: EL SERVIDOR NO HA REARRENCAT    " >> "$err_log"
            echo "=================================================" >> "$err_log"
            echo "Diagnòstic previ a l'actualització:" >> "$err_log"
            cat "$diag_pre" >> "$err_log"
            echo -e "\n=================================================" >> "$err_log"
            echo "Darrer registre d'actualització capturat:" >> "$err_log"
            cat "$local_log_tmp" >> "$err_log"
            
            log "\n${c_success}  S'ha guardat un informe d'error a: ${c_reset}$err_log"
            log "${c_error}  Tancant el procés de forma segura.${c_reset}"
            rm -f "$local_log_tmp"
            exit 1
        fi
    fi
else
    log "${c_success}  ✔ No cal reinici.${c_reset}"
fi

# 4. DIAGNÒSTIC POST-ACTUALITZACIÓ I COMPARACIÓ (Es fa SEMPRE)
log "\n${c_dim}┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${c_reset}"
log "${c_accent} 📊 Generant diagnòstic POST-actualització...${c_reset}"
sleep 1
diag_post="/tmp/diag_post_${target}.txt"
ssh $ssh_port_flag "root@$target" "$diag_cmd" > "$diag_post"

log "\n${c_warning} 🔍 COMPARATIVA DE DIAGNÒSTIC (Abans vs Ara) ${c_reset}"
log "${c_dim} Les línies en - han desaparegut, les en + són noves.${c_reset}"
sleep 1

# Retallem els fitxers per comparar només des de "[+] Ports" en endavant (ignorant la llista de paquets que es mostraria com a eliminada)
sed -n '/\[+\] Ports/,$p' "$diag_pre" > "${diag_pre}_clean"
sed -n '/\[+\] Ports/,$p' "$diag_post" > "${diag_post}_clean"

diff -U 1 "${diag_pre}_clean" "${diag_post}_clean" | grep -E '^\+|^\-' | grep -v '^+++' | grep -v '^---' | while read -r line; do
    if [[ "$line" == +* ]]; then
        log "    ${c_success}${line}${c_reset}"
    elif [[ "$line" == -* ]]; then
        log "    ${c_warning}${line}${c_reset}"
    else
        log "    $line"
    fi
done
log "${c_dim} (Si no surt res, vol dir que el kernel, ports, processos i contenidors estan IDÈNTICS)${c_reset}"

# 5. NETEJA DE PAQUETS (POST-VERIFICACIÓ)
log "\n${c_dim}┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${c_reset}"
log "${c_accent} 🧹 Neteja de paquets sobrants (Autoremove)...${c_reset}"
log_prompt "  Vols executar 'autoremove' ara que el sistema està verificat? [S/n]: "
read -r resp_autoremove
log_input "$resp_autoremove"

if [[ ! "$resp_autoremove" =~ ^[Nn] ]]; then
    if [ "$pkg_mgr" == "apt" ]; then
        ssh $ssh_port_flag -t "root@$target" "DEBIAN_FRONTEND=noninteractive apt-get autoremove -y" 2>&1 | tee >(sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g; s/\r$//' >> "$session_log")
    else
        ssh $ssh_port_flag -t "root@$target" "yum autoremove -y" 2>&1 | tee >(sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g; s/\r$//' >> "$session_log")
    fi
    log "${c_success}  ✔ Neteja de la MV completada.${c_reset}"
else
    log "${c_warning}  S'ha omès la neteja d'autoremove per seguretat.${c_reset}"
fi

# 6. RECOLLIDA DEL LOG
echo -e "\n${c_dim}┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${c_reset}"
echo -e "${c_accent} 📥 Descarregant log al teu PC...${c_reset}"
sleep 1

# Esborrem el log temporal del servidor
ssh $ssh_port_flag "root@$target" "rm -f /root/$log_name" >/dev/null 2>&1

echo -e "    ${c_success}✔${c_reset} $log_name"
echo -e "${c_success}  ✨ [ ÈXIT ] Log descarregat i eliminat del servidor!${c_reset}"
echo -e "     ${c_dim}📂 Guardat a:${c_reset} $dest_dir"
rm -f "$local_log_tmp"

# FI DE PROCÉS I RECORDATORIS MANUALS
echo -e "\n${c_main}╭──────────────────────────────────────────────────╮${c_reset}"
echo -e "${c_main}│${c_success}              🎯 PROCÉS COMPLETAT!                ${c_main}│${c_reset}"
echo -e "${c_main}╰──────────────────────────────────────────────────╯${c_reset}"
sleep 1
echo -e "${c_warning}  [ SEGÜENTS PASSOS ]${c_reset}"
echo -e "  1. Revisar errors a la comparativa i obrir ticket si cal."
echo -e "  2. Enviar correu al client (plantilla) amb el log adjunt."
echo -e "  3. Esborrar la Snapshot de Proxmox en 24h.\n"
