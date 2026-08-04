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
echo -e "${c_main}│${c_accent}         🚀 REMOTE LINUX OS UPDATER V1.0          ${c_main}│${c_reset}"
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
    echo -e "\n${c_error}  ❌ [ ERROR ] $target no respon al port SSH ($real_port).${c_reset}\n"
    exit 1
fi

echo -e "${c_accent} 🔍 Detectant sistema operatiu i host...${c_reset}"
sleep 1
# 2. Obtenim tota la info en una sola connexió (super ràpid)
initial_info=$(ssh $ssh_port_flag -o ConnectTimeout=5 -o BatchMode=yes "root@$target" "hostname; ip=\$(hostname -I 2>/dev/null | awk '{print \$1}'); echo \"\$ip\"; if command -v apt >/dev/null; then echo apt; elif command -v yum >/dev/null; then echo yum; else echo unknown; fi" 2>/dev/null)

if [ -z "$initial_info" ]; then
    echo -e "  ${c_error}✖ No s'ha pogut accedir per SSH com a root.${c_reset}"
    exit 1
fi

remote_host=$(echo "$initial_info" | sed -n '1p')
remote_ip=$(echo "$initial_info" | sed -n '2p')
pkg_mgr=$(echo "$initial_info" | sed -n '3p')

if [ "$pkg_mgr" == "unknown" ]; then
    echo -e "${c_error}  ❌ [ ERROR ] No s'ha detectat 'apt' ni 'yum' a la màquina remota.${c_reset}"
    exit 1
fi

echo -e "${c_success}  ✔ Sistema detectat: $pkg_mgr ($remote_host)${c_reset}"

# 3. Crear carpeta local amb el nom desitjat
[ -z "$remote_ip" ] && remote_ip="$target"
dest_dir="$HOME/Descargas/logs-updates/${remote_host}-${remote_ip}"
mkdir -p "$dest_dir"

# 1. DIAGNÒSTIC PREVI
echo -e "\n${c_dim}┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${c_reset}"
echo -e "${c_accent} 📊 Recopilant dades de diagnòstic PRE-actualització...${c_reset}"
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
echo -e "${c_success}  ✔ Diagnòstic previ completat i guardat.${c_reset}"

# 2. ACTUALITZACIÓ
echo -e "\n${c_dim}┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${c_reset}"
echo -e "${c_accent} ⚙️  Iniciant actualització de sistema...${c_reset}"
echo -e "${c_dim} (Veuràs la sortida en directe de l'actualització per pantalla)${c_reset}\n"
sleep 1


log_name="log-update-${remote_host}-$(date +%d-%m-%Y_%H-%M-%S).txt"
local_log_tmp="$dest_dir/update_live_capture.tmp"

if [ "$pkg_mgr" == "apt" ]; then
    update_cmd="DEBIAN_FRONTEND=noninteractive apt upgrade -y 2>&1 | tee /root/$log_name"
else
    update_cmd="yum update -y 2>&1 | tee /root/$log_name"
fi

# Usem -t per obrir un terminal interactiu virtual i capturem en directe per si falla el reinici
ssh -t $ssh_port_flag "root@$target" "$update_cmd" | tee >(sed 's/\r$//' > "$local_log_tmp")

# 3. REINICI SI CAL
echo -e "\n${c_dim}┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${c_reset}"
echo -e "${c_accent} 🔄 Comprovant necessitat de reinici (Kernel/Core)...${c_reset}"
sleep 1
needs_reboot="no"

if [ "$pkg_mgr" == "apt" ]; then
    # Busquem al log si s'ha instal·lat algun linux-image o headers, i comprovem també el fitxer oficial de reboot-required d'Ubuntu/Debian
    reboot_flag=$(ssh $ssh_port_flag "root@$target" "([ -f /var/run/reboot-required ] || grep -iE '(setting up|inst).*(linux-image|linux-headers|linux-modules)-[0-9]' /root/$log_name >/dev/null 2>&1) && echo yes || echo no")
    if [ "$reboot_flag" == "yes" ]; then needs_reboot="yes"; fi
else
    # Busquem al log de yum/dnf si s'ha tocat el kernel (ignorant colors/ANSI amb .*)
    reboot_flag=$(ssh $ssh_port_flag "root@$target" "grep -iE '(install|updat|upgrad|instaland|actualizand).*(kernel|kernel-core|kernel-modules)-[0-9]' /root/$log_name >/dev/null 2>&1 && echo yes || echo no")
    if [ "$reboot_flag" == "yes" ]; then needs_reboot="yes"; fi
fi

if [ "$needs_reboot" == "yes" ]; then
    echo -e "${c_warning}  ⚠️ S'ha actualitzat el Kernel o un servei core i es recomana reiniciar la MV.${c_reset}"
    echo -ne "  Vols reiniciar el servidor ara mateix? [S/n]: "
    read -r resp_reboot
    
    if [[ "$resp_reboot" =~ ^[Nn] ]]; then
        echo -e "${c_warning}  S'ha omès el reinici.${c_reset}"
        echo -ne "  Vols continuar amb el següent pas (4. Comprovació post-actualització)? [S/n]: "
        read -r resp_cont
        if [[ "$resp_cont" =~ ^[Nn] ]]; then
            echo -e "\n${c_error}  Abortant el procés per petició de l'usuari.${c_reset}"
            exit 1
        fi
    else
        echo -e "${c_accent}  Reiniciant el servidor...${c_reset}"
        ssh $ssh_port_flag "root@$target" "reboot"
        
        echo -e "${c_dim}  Esperant que el servidor es desconnecti...${c_reset}"
        sleep 5
        
        echo -e "${c_dim}  Esperant que torni a estar online (màxim 60 segons)...${c_reset}"
        wait_time=0
        server_up=false
        while [ $wait_time -lt 60 ]; do
            if timeout 2 bash -c "</dev/tcp/$real_host/$real_port" 2>/dev/null; then
                server_up=true
                break
            fi
            sleep 3
            wait_time=$((wait_time + 3))
        done
        
        if [ "$server_up" = true ]; then
            # Donar-li un marge al procés SSH i als serveis perquè s'aixequin del tot
            sleep 10
            echo -e "${c_success}  ✔ Servidor online de nou!${c_reset}"
        else
            echo -e "${c_error}  💥 [ ERROR CRÍTIC ] El servidor no ha tornat a respondre després de 60 segons!${c_reset}"
            echo -e "${c_warning}  És possible que hi hagi hagut un 'Kernel Panic' o s'hagi quedat sense espai.${c_reset}"
            
            err_log="$dest_dir/${log_name%.txt}_error.txt"
            echo "=================================================" > "$err_log"
            echo "   ERROR CRÍTIC: EL SERVIDOR NO HA REARRENCAT    " >> "$err_log"
            echo "=================================================" >> "$err_log"
            echo "Diagnòstic previ a l'actualització:" >> "$err_log"
            cat "$diag_pre" >> "$err_log"
            echo -e "\n=================================================" >> "$err_log"
            echo "Darrer registre d'actualització capturat:" >> "$err_log"
            cat "$local_log_tmp" >> "$err_log"
            
            echo -e "\n${c_success}  S'ha guardat un informe d'error a: ${c_reset}$err_log"
            echo -e "${c_error}  Tancant el procés de forma segura.${c_reset}"
            rm -f "$local_log_tmp"
            exit 1
        fi
    fi
else
    echo -e "${c_success}  ✔ No cal reinici.${c_reset}"
fi

# 4. DIAGNÒSTIC POST-ACTUALITZACIÓ I COMPARACIÓ (Es fa SEMPRE)
echo -e "\n${c_dim}┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${c_reset}"
echo -e "${c_accent} 📊 Generant diagnòstic POST-actualització...${c_reset}"
sleep 1
diag_post="/tmp/diag_post_${target}.txt"
ssh $ssh_port_flag "root@$target" "$diag_cmd" > "$diag_post"

echo -e "\n${c_warning} 🔍 COMPARATIVA DE DIAGNÒSTIC (Abans vs Ara) ${c_reset}"
echo -e "${c_dim} Les línies en - han desaparegut, les en + són noves.${c_reset}"
sleep 1

# Retallem els fitxers per comparar només des de "[+] Ports" en endavant (ignorant la llista de paquets que es mostraria com a eliminada)
sed -n '/\[+\] Ports/,$p' "$diag_pre" > "${diag_pre}_clean"
sed -n '/\[+\] Ports/,$p' "$diag_post" > "${diag_post}_clean"

diff -U 1 "${diag_pre}_clean" "${diag_post}_clean" | grep -E '^\+|^\-' | grep -v '^+++' | grep -v '^---' | while read -r line; do
    if [[ "$line" == +* ]]; then
        echo -e "    ${c_success}${line}${c_reset}"
    elif [[ "$line" == -* ]]; then
        echo -e "    ${c_warning}${line}${c_reset}"
    else
        echo -e "    $line"
    fi
done
echo -e "${c_dim} (Si no surt res, vol dir que el kernel, ports, processos i contenidors estan IDÈNTICS)${c_reset}"

# 5. NETEJA DE PAQUETS
echo -e "\n${c_dim}┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${c_reset}"
echo -e "${c_accent} 🧹 Netejant paquets sobrants (Autoremove)...${c_reset}"
sleep 1
if [ "$pkg_mgr" == "apt" ]; then
    ssh $ssh_port_flag -t "root@$target" "DEBIAN_FRONTEND=noninteractive apt-get autoremove -y"
else
    ssh $ssh_port_flag -t "root@$target" "yum autoremove -y"
fi
echo -e "${c_success}  ✔ Neteja de la MV completada.${c_reset}"

# 6. RECOLLIDA DEL LOG
echo -e "\n${c_dim}┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${c_reset}"
echo -e "${c_accent} 📥 Descarregant log al teu PC...${c_reset}"
sleep 1
err_file=$(mktemp)
scp $scp_port_flag -q "root@${target}:/root/$log_name" "$dest_dir/" 2> "$err_file"
scp_exit=$?

if [ $scp_exit -eq 0 ]; then
    # Si s'ha descarregat correctament, l'esborrem del servidor
    ssh $ssh_port_flag "root@$target" "rm -f /root/$log_name" >/dev/null 2>&1
    echo -e "    ${c_success}✔${c_reset} $log_name"
    echo -e "${c_success}  ✨ [ ÈXIT ] Log descarregat i eliminat del servidor!${c_reset}"
    echo -e "     ${c_dim}📂 Guardat a:${c_reset} $dest_dir"
    rm -f "$local_log_tmp"
else
    echo -e "${c_error}  💥 [ ERROR ] Problema al descarregar el log:${c_reset}"
    cat "$err_file" | sed "s/^/     /"
fi
rm -f "$err_file"

# FI DE PROCÉS I RECORDATORIS MANUALS
echo -e "\n${c_main}╭──────────────────────────────────────────────────╮${c_reset}"
echo -e "${c_main}│${c_success}              🎯 PROCÉS COMPLETAT!                ${c_main}│${c_reset}"
echo -e "${c_main}╰──────────────────────────────────────────────────╯${c_reset}"
sleep 1
echo -e "${c_warning}  [ SEGÜENTS PASSOS ]${c_reset}"
echo -e "  1. Revisar errors a la comparativa i obrir ticket si cal."
echo -e "  2. Enviar correu al client (plantilla) amb el log adjunt."
echo -e "  3. Esborrar la Snapshot de Proxmox en 24h.\n"
