# Remote Linux OS Updater

[🇬🇧 English](#-english) | [🇪🇸 Español](#-español) | [🏴󠁥󠁳󠁣󠁴󠁿 Català](#-català)

---

## 🇬🇧 English

Automated tool for secure Linux server updates in production environments (supports Debian, Ubuntu, AlmaLinux, CentOS, RHEL).

### 🚀 Features
- **Multi-system:** Automatically detects whether the server uses `apt` or `yum`/`dnf`.
- **Pre & Post Diagnostics:** Captures the state of the Kernel, open ports, active processes, and Docker containers before and after updating.
- **Smart Comparison:** Shows a colorized `diff` of what has exactly changed on the server (ideal for detecting services that failed to start).
- **Reboot Detection:** Analyzes if the update touched the Kernel or if there was a pending system reboot to warn you.
- **Auto Cleanup:** Runs `autoremove` post-update to keep disk space clean.
- **Log Export:** Downloads a detailed log file in `.txt` format to your local computer to attach to support tickets or customer emails.

### 🛠️ Prerequisites
- **SSH** access configured to reach the target server (usually with the `root` user).
- The local machine must have basic integrated network utilities (`scp`, `ssh`).

### 📦 Usage
1. Grant execution permissions (only the first time):
   ```bash
   chmod +x os_updater.sh
   ```
2. Run the script:
   ```bash
   ./os_updater.sh
   ```
   *The assistant will ask you to enter the IP or hostname of the machine.*

   **Quick alternative:** You can pass the server and custom port directly as parameters:
   ```bash
   ./os_updater.sh srv-web-client
   ./os_updater.sh -p 2222 srv-web-client
   ```

3. **Create a Global Alias (Recommended)**
   To execute the tool by just typing `update` from any folder, you can create a terminal alias. Be sure to use the path where you downloaded the repository:

   **For Bash (`~/.bashrc`):**
   ```bash
   echo "alias update='~/Scripts/os_updater/os_updater.sh'" >> ~/.bashrc
   source ~/.bashrc
   ```
   **For Zsh (`~/.zshrc`):**
   ```bash
   echo "alias update='~/Scripts/os_updater/os_updater.sh'" >> ~/.zshrc
   source ~/.zshrc
   ```
   **For Fish Shell:**
   ```fish
   alias update="~/Scripts/os_updater/os_updater.sh"
   funcsave update
   ```

### 📂 Where are logs saved?
When the update is complete, the full operation log is automatically downloaded from the remote server and deleted from the original machine. It will be saved locally at:
`~/Descargas/logs-updates/[hostname]-[ip]/`

---

## 🇪🇸 Español

Herramienta automatizada para la actualización segura de servidores Linux en entornos de producción (soporta Debian, Ubuntu, AlmaLinux, CentOS, RHEL).

### 🚀 Características
- **Multisistema:** Detecta automáticamente si el servidor utiliza `apt` o `yum`/`dnf`.
- **Diagnóstico Previo y Posterior:** Captura el estado del Kernel, puertos abiertos, procesos activos y contenedores Docker antes y después de actualizar.
- **Comparativa Inteligente:** Te muestra un `diff` en color de qué ha cambiado exactamente en el servidor (ideal para detectar servicios que no han arrancado).
- **Detección de Reinicios:** Analiza si la actualización ha tocado el Kernel o si había un reinicio pendiente en el sistema para avisarte.
- **Limpieza Automática:** Ejecuta `autoremove` tras la actualización para mantener el espacio limpio.
- **Exportación de Logs:** Descarga un registro detallado en formato `.txt` a tu ordenador local para adjuntar a tickets de soporte o correos de clientes.

### 🛠️ Prerrequisitos
- Acceso **SSH** configurado para acceder al servidor destino (normalmente con el usuario `root`).
- La máquina local debe tener utilidades básicas de red integradas (como `scp`, `ssh`).

### 📦 Uso
1. Dale permisos de ejecución (solo la primera vez):
   ```bash
   chmod +x os_updater.sh
   ```
2. Ejecuta el script:
   ```bash
   ./os_updater.sh
   ```
   *El asistente te pedirá que introduzcas la IP o el nombre de la máquina.*

   **Alternativa rápida:** Puedes pasarle el servidor y un puerto específico directamente:
   ```bash
   ./os_updater.sh srv-web-client
   ./os_updater.sh -p 2222 srv-web-client
   ```

3. **Crear un Alias Global (Recomendado)**
   Para poder ejecutar la herramienta escribiendo solo `update` desde cualquier carpeta, puedes crear un alias. Asegúrate de poner la ruta donde hayas descargado el repositorio:

   **Para Bash (`~/.bashrc`):**
   ```bash
   echo "alias update='~/Scripts/os_updater/os_updater.sh'" >> ~/.bashrc
   source ~/.bashrc
   ```
   **Para Zsh (`~/.zshrc`):**
   ```bash
   echo "alias update='~/Scripts/os_updater/os_updater.sh'" >> ~/.zshrc
   source ~/.zshrc
   ```
   **Para Fish Shell:**
   ```fish
   alias update="~/Scripts/os_updater/os_updater.sh"
   funcsave update
   ```

### 📂 ¿Dónde se guardan los logs?
Cuando la actualización se ha completado, el log completo de la operación se descarga automáticamente desde el servidor remoto y se borra de la máquina original. Se guardará de forma local en:
`~/Descargas/logs-updates/[hostname]-[ip]/`

---

## 🏴󠁥󠁳󠁣󠁴󠁿 Català

Eina automatitzada per a l'actualització segura de servidors Linux en entorns de producció (suporta Debian, Ubuntu, AlmaLinux, CentOS, RHEL).

### 🚀 Característiques
- **Multisistema:** Detecta automàticament si el servidor empra `apt` o `yum`/`dnf`.
- **Diagnòstic Previ i Posterior:** Captura l'estat del Kernel, els ports oberts, els processos actius i els contenidors Docker abans i després d'actualitzar.
- **Comparativa Intel·ligent:** Et mostra un `diff` en color de què ha canviat exactament al servidor (ideal per detectar serveis que no han arrencat correctament).
- **Detecció de Reinicis:** Analitza si l'actualització ha tocat el Kernel o si hi havia un reinici pendent al sistema per avisar-te.
- **Neteja Automàtica:** Executa `autoremove` post-actualització per mantenir l'espai net.
- **Exportació de Logs:** Descarrega un registre detallat en format `.txt` al teu ordinador local per adjuntar als tiquets de suport o als correus de clients.

### 🛠️ Prerequisits
- Accés **SSH** configurat per accedir al servidor destí (normalment amb l'usuari `root`).
- La màquina local ha de tenir utilitats bàsiques de xarxa integrades (com `scp`, `ssh`).

### 📦 Ús
1. Dóna-li permisos d'execució (només el primer cop):
   ```bash
   chmod +x os_updater.sh
   ```
2. Executa l'script:
   ```bash
   ./os_updater.sh
   ```
   *L'assistent et demanarà que introdueixis la IP o el nom de la màquina.*

   **Alternativa ràpida:** Pots passar-li el servidor i un port específic directament:
   ```bash
   ./os_updater.sh srv-web-client
   ./os_updater.sh -p 2222 srv-web-client
   ```

3. **Crear un Àlies Global (Recomanat)**
   Per poder executar l'eina escrivint només `update` des de qualsevol carpeta sense haver de buscar on està l'script, pots crear un àlies al teu terminal. Assegura't de posar la ruta on hagis descarregat el repositori:

   **Per a Bash (`~/.bashrc`):**
   ```bash
   echo "alias update='~/Scripts/os_updater/os_updater.sh'" >> ~/.bashrc
   source ~/.bashrc
   ```
   **Per a Zsh (`~/.zshrc`):**
   ```bash
   echo "alias update='~/Scripts/os_updater/os_updater.sh'" >> ~/.zshrc
   source ~/.zshrc
   ```
   **Per a Fish Shell:**
   ```fish
   alias update="~/Scripts/os_updater/os_updater.sh"
   funcsave update
   ```

### 📂 On es guarden els logs?
Quan l'actualització s'ha completat, el log complet de l'operació es descarrega automàticament des del servidor remot i s'esborra de la màquina original. Es guardarà de forma local a:
`~/Descargas/logs-updates/[hostname]-[ip]/`
