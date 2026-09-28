# Changelog

Tots els canvis notables d'aquest projecte es documenten en aquest fitxer.

## [2.0.0] - 2026-09-28

### ✨ Novetats i Millores
- **Doble confirmació de seguretat:**
  - Confirmació obligatòria de creació de snapshot abans de començar.
  - Doble confirmació abans de procedir amb el reinici del servidor.
- **Gestió avançada d'errors i avisos:**
  - Bloqueig automàtic del reinici si es detecten fallades crítiques durant l'actualització.
  - Banner groc amb desglossament net d'avisos (*warnings*) no crítics per a la seva revisió.
- **Diferenciació de motius de reinici:**
  - Distinció clara entre actualització del Kernel en la sessió actual vs reinici pendent previ a la intervenció.
- **Auto-reparació de repositoris (YUM/DNF):**
  - Detecció automàtica de repositoris inaccessibles o obsolets amb opció de desactivar-los i reintentar l'actualització.
- **Neteja preventiva de memòria cau i metadades:**
  - Execució de `yum clean metadata` / `apt-get clean` abans del diagnòstic previ per evitar falsos positius de "sistema actualitzat".
- **Registre complet de sessió:**
  - El fitxer de log descarregat a local conté tota la traça de la sessió (diagnòstic previ, actualització en directe i comparativa post-actualització).

---

## [1.1.0] - 2026-08-24

### ⚙️ Millores d'Estabilitat i Xarxa
- Suport per a ports SSH personalitzats mitjançant el paràmetre `-p`.
- Timeout de reconnexió post-reinici ampliat a 60 segons, amb prompt interactiu per afegir 30 segons addicionals si cal.
- Detecció d'errors d'scriptlets / POSTTRANS en paquets RPM.
- Confirmació explícita de l'usuari abans d'executar `autoremove` després de validar el sistema.

---

## [1.0.0] - 2026-07-29

### 🚀 Llençament Inicial
- Diagnòstic previ i posterior complet (kernel, ports oberts, processos, contenidors Docker).
- Suport automàtic per a sistemes basats en Debian/Ubuntu (`apt`) i RHEL/CentOS/AlmaLinux (`yum`/`dnf`).
- Comparativa visual (`diff`) de serveis abans i després de l'actualització.
- Verificació de necessitat de reinici del sistema per canvis de nucli.
- Descàrrega automàtica del fitxer de registre al PC local.
