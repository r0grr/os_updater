# OS Updater Pro

Eina automatitzada per a l'actualització segura de servidors Linux en entorns de producció (suporta Debian, Ubuntu, AlmaLinux, CentOS, RHEL).

## 🚀 Característiques

- **Multisistema:** Detecta automàticament si el servidor empra `apt` o `yum`/`dnf`.
- **Diagnòstic Previ i Posterior:** Captura l'estat del Kernel, els ports oberts, els processos actius i els contenidors Docker abans i després d'actualitzar.
- **Comparativa Intel·ligent:** Et mostra un `diff` en color de què ha canviat exactament al servidor (ideal per detectar serveis que no han arrencat correctament).
- **Detecció de Reinicis:** Analitza si l'actualització ha tocat el Kernel o si hi havia un reinici pendent al sistema per avisar-te.
- **Neteja Automàtica:** Executa `autoremove` post-actualització per mantenir l'espai net.
- **Exportació de Logs:** Descarrega un registre detallat en format `.txt` al teu ordinador local per adjuntar als tiquets de suport o als correus de clients.

## 🛠️ Prerequisits

- Accés **SSH** configurat per accedir al servidor destí (normalment amb l'usuari `root`).
- La màquina local ha de tenir utilitats bàsiques de xarxa integrades (com `scp`, `ssh`).

## 📦 Ús

1. Dóna-li permisos d'execució (només el primer cop):
   ```bash
   chmod +x os_updater.sh
   ```

2. Executa l'script:
   ```bash
   ./os_updater.sh
   ```
   *L'assistent et demanarà que introdueixis la IP o el nom de la màquina.*

   **Alternativa ràpida:** Pots passar-li el servidor directament per paràmetre:
   ```bash
   ./os_updater.sh srv-web-client
   ```

## 📂 On es guarden els logs?

Quan l'actualització s'ha completat, el log complet de l'operació es descarrega automàticament des del servidor remot i s'esborra de la màquina original. Es guardarà de forma local a:
`~/Descargas/logs-updates/[hostname]-[ip]/`
