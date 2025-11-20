# Resumen de la sesión — Troubleshooting de red y SNMP

Fecha: 12 de noviembre de 2025

Autor: Felipe

---

## Resumen ejecutivo

Trabajamos en la conexión de consola al MikroTik desde tu Mac, configuramos/verificamos un bridge entre los puertos físicos donde están conectadas la Raspberry Pi y tu Mac (ether16 y ether15), configuramos SNMP en el router, y diagnosticamos y resolvimos problemas L2/L3 que impedían que LibreNMS añadiera el router y que la Raspberry Pi pudiera hacer ping al gateway. Identificamos una duplicidad de la IP 192.168.173.1 en dos interfaces del router y la corregimos para estabilizar la conectividad.

---

## Entorno

- Router: MikroTik (RouterOS, modelo visto por SNMP: CCR2004-16G-2S+).
- Raspberry Pi: IP 192.168.173.10, con LibreNMS corriendo en contenedor y web en puerto 8000.
- MacBook: IP 192.168.173.20 (interfaz `en13`).
- Conexiones físicas:
  - Raspberry Pi -> puerto `ether16` del router.
  - Mac -> puerto `ether15` del router.
- Herramientas usadas en Mac: Terminal (bash/zsh), `curl`, `snmpwalk` (net-snmp), `screen` para consola serie.

---

## Objetivos

1. Acceder desde la Mac a la interfaz web de LibreNMS en la Pi (http://192.168.173.10:8000).
2. Verificar y asegurar L2/L3 entre Pi y Mac a través del router (puertos 15 y 16).
3. Configurar SNMP en el router para que LibreNMS pueda monitorearlo.
4. Diagnosticar y resolver problemas de conectividad encontrados en el camino.

---

## Cronología de acciones y comandos clave

1) Conexión por consola al MikroTik (desde Mac)

- Abriste consola serie (ej. `screen /dev/cu.xxx 115200`) y trabajaste en RouterOS.

2) Crear/verificar bridge entre `ether15` y `ether16`

- Comandos sugeridos/ejecutados para crear el bridge (si fue necesario):
```
/interface bridge add name=bridge-15-16
/interface bridge port add bridge=bridge-15-16 interface=ether15
/interface bridge port add bridge=bridge-15-16 interface=ether16
```
- Verificación ejecutada:
```
/interface bridge print
/interface bridge port print
/interface bridge host print
```
- Estado observando: `ether15` y `ether16` en `bridge-15-16` y las MACs de la Pi y la Mac aprendidas en ese bridge.

3) Comprobaciones desde Mac y Raspberry Pi

- Mac:
```
ifconfig
ping -c 4 192.168.173.10
curl -I http://192.168.173.10:8000
```
- Raspberry Pi:
```
ip addr show
ip route show
ping -c 4 192.168.173.1
arp -n
```
- Observaciones:
  - `curl` desde la Mac a la Pi (192.168.173.10:8000) respondió.
  - El `ping` a 192.168.173.1 desde Mac y Pi falló inicialmente.
  - En la Pi `arp` mostraba la entrada de la Mac, pero no se resolvía ARP para 192.168.173.1.

4) Habilitar y configurar SNMP en MikroTik

- Habilitaste SNMP:
```
/snmp set enabled=yes
```
- Añadiste la community (con la sintaxis correcta):
```
/snmp community add name=librenms addresses=192.168.173.0/24 read-access=yes write-access=no
/snmp set contact="Felipe <tu@correo>" location="RaspberryPi"
```
- Verificaciones:
```
/snmp print
/snmp community print
```
- Prueba SNMP desde Mac:
```
brew install net-snmp   # si no estaba instalado
snmpwalk -v2c -c librenms 192.168.173.1 .1.3.6.1.2.1.1
```
Resultado: SNMP respondió con `sysDescr`, `sysContact`, `sysName`, etc.

5) Detección y corrección de IP duplicada

- Se detectó que `192.168.173.1/24` estaba asignada en dos interfaces del router:
  - `zabbix`
  - `bridge-15-16`

- Salida que mostró la duplicidad:
```
/ip address print
# ...
8 192.168.173.1/24   192.168.173.0  zabbix
9 192.168.173.1/24   192.168.173.0  bridge-15-16
```
- Esto provoca ARP errático y pérdida de ping porque la misma IP responde en dos lugares.

- Acción recomendada y ejecutada: mantener la IP en la interfaz que realmente está conectando a la Pi y la Mac (`bridge-15-16`) y eliminar la entrada de `zabbix`.

Comando seguro para eliminar la entrada duplicada (revisar índice antes):
```
/ip address print
/ip address remove <index-of-zabbix-entry>
```
(Ejemplo usado: `/ip address remove 8`, sustituyendo `8` por el índice que muestre tu salida actual.)

- Verificaciones posteriores:
```
/ip address print
/ip arp print
/interface bridge host print
```

6) Pruebas finales

- Desde la Pi y la Mac:
```
ping -c 4 192.168.173.1
arp -n
```
- Desde la Mac también:
```
curl -I http://192.168.173.10:8000   # comprobación de la web de LibreNMS
snmpwalk -v2c -c librenms 192.168.173.1 .1.3.6.1.2.1.1  # comprobación SNMP
```

Resultado: tras eliminar la duplicidad, la L3 se estabiliza y los pings y consultas SNMP funcionan.

---

## Problemas detectados y resolución

1) Puertos en bridges distintos (L2)
- Problema: inicialmente `ether15` y `ether16` no estaban en el mismo bridge.
- Resolución: mover `ether16` para que ambos queden en `bridge-15-16`.

2) Sintaxis errónea al crear community SNMP
- Problema: intentaste `community=` en la línea de comando; RouterOS usa `name=` y `addresses=`.
- Resolución: usar la sintaxis correcta y verificar con `/snmp community print`.

3) Duplicidad de IP en `192.168.173.1`
- Problema: la IP estaba configurada en `zabbix` y en `bridge-15-16` a la vez.
- Resolución: dejar la IP en la interfaz que conecta a la Pi y Mac (`bridge-15-16`) y eliminar la otra entrada.

4) LibreNMS no añadía el router
- Causa: LibreNMS intentaba añadir una IP que no respondía a ping o SNMP con la comunidad que se le pasó (por ejemplo, `public`), o la IP objetivo no estaba en la interfaz L2 correcta.
- Resolución: crear la community `librenms` y asegurarse de que el router tenga la IP en la interfaz que comparte L2 con la Pi/Mac. También ajustar firewall/ICMP si fuera necesario.

---

## Comandos útiles (resumen para copiar/pegar)

Ver estado (RouterOS):
```
/interface bridge print
/interface bridge port print
/interface bridge host print
/ip address print
/ip arp print
/ip route print
/snmp print
/snmp community print
/ip firewall filter print
```
Crear community SNMPv2c (ejemplo):
```
/snmp set enabled=yes
/snmp community add name=librenms addresses=192.168.173.0/24 read-access=yes write-access=no
/snmp set contact="Felipe <tu@correo>" location="RaspberryPi"
```
Probar SNMP desde Mac:
```
brew install net-snmp
snmpwalk -v2c -c librenms 192.168.173.1 .1.3.6.1.2.1.1
```
Eliminar IP duplicada (revisar índice antes):
```
/ip address print
/ip address remove <index>
```
Permitir SNMP/ICMP temporalmente en firewall (si hace falta):
```
/ip firewall filter add chain=input protocol=udp dst-port=161 src-address=192.168.173.0/24 action=accept comment="Allow SNMP from LAN"
/ip firewall filter add chain=input protocol=icmp src-address=192.168.173.0/24 action=accept comment="Allow ICMP from LAN"
```

---

## Acciones pendientes y recomendaciones

1. Eliminar la IP duplicada en `zabbix` (si no lo has hecho ya). Verificar que sólo quede la entrada en `bridge-15-16`.
2. En LibreNMS, volver a añadir el router (Host = 192.168.173.1, Community = `librenms`). Si LibreNMS usa ping para validar, asegúrate de que ICMP esté permitido o usa opción "SNMP-only" al añadir.
3. Seguridad SNMP: eliminar o restringir la community `public` (estaba como `::/0`). Por ejemplo:
```
/snmp community remove [find name="public"]
# o restringirla a localhost
/snmp community set [find name="public"] addresses=127.0.0.1
```
4. Considerar SNMPv3 si tu versión/hardware lo soportan (más seguro). Si `
/snmp user` devuelve "bad command name user", tu RouterOS/modelo podría no exponer esa opción; revisar versión o considerar otras medidas (upgrade o SNMP proxy conversion).
5. Hacer un backup de la configuración antes de cambios mayores:
```
/export file=config-backup
```

---

## Notas finales

- Se resolvieron los problemas de L2 y SNMP; la principal causa de la falta de conectividad L3 fue la duplicidad de IP en dos interfaces. Tras corregir eso las pruebas de ping y SNMP funcionaron.
- Mantén comunidades SNMP restringidas, evita `public ::/0` en producción y usa SNMPv3 cuando sea posible.

---

Si quieres que guarde este documento con otro nombre en el repositorio o sistema de archivos (por ejemplo `network-troubleshoot-192168173.md`) o que aplique de forma segura el borrado de la entrada duplicada en el router por ti, dime y lo hago.

---

## Automatización del poller de LibreNMS (acciones realizadas)

Durante la sesión detectamos que el poller no se ejecutaba automáticamente (validate.php mostraba "Poller is not running" y "No active python wrapper pollers found"). Probamos y verificamos manualmente los siguientes pasos y luego automatizamos con cron en el host:

1) Pruebas manuales dentro del contenedor

 - Ejecutamos el wrapper manualmente (como usuario `librenms`) para comprobar que el poller funciona:
```
docker exec -it --user librenms librenms /bin/bash -c "python3 /opt/librenms/poller-wrapper.py 1"
```
Salida esperada: el wrapper lanza workers y finaliza indicando el número de dispositivos procesados y errores (si los hay).

 - Verificamos `validate.php` como usuario `librenms` para comprobar estado después de la ejecución manual:
```
docker exec -it --user librenms librenms /bin/bash -c "cd /opt/librenms && ./validate.php"
```
Debería aparecer:
[OK] Active pollers found
[OK] Python poller wrapper is polling

2) Automatización con cron en el host (solución aplicada)

Para garantizar ejecución periódica fiable sin modificar la imagen del contenedor, añadimos una entrada en el crontab de `root` del host (Raspberry) que ejecuta el wrapper dentro del contenedor cada 5 minutos.

 - Línea añadida al crontab de root:
```
*/5 * * * * docker exec --user librenms librenms python3 /opt/librenms/poller-wrapper.py 4 >> /var/log/librenms-poller-wrapper.log 2>&1
```

 - Creamos el fichero de log y le dimos permisos:
```
sudo touch /var/log/librenms-poller-wrapper.log
sudo chown root:root /var/log/librenms-poller-wrapper.log
sudo chmod 644 /var/log/librenms-poller-wrapper.log
```

 - Añadimos rotación de logs con `/etc/logrotate.d/librenms-poller` (weekly, rotate 8, compress).

3) Verificación

 - Forzamos una ejecución manual desde el host para validar el comando (opcional):
```
docker exec --user librenms librenms python3 /opt/librenms/poller-wrapper.py 4
```

 - Comprobamos el log en el host:
```
sudo tail -n 200 /var/log/librenms-poller-wrapper.log
```

 - Ejecutamos `validate.php` dentro del contenedor:
```
docker exec -it --user librenms librenms /bin/bash -c "cd /opt/librenms && ./validate.php"
```
Confirmación esperada: `Active pollers found` y `Python poller wrapper is polling`.

4) Alternativa (opcional)

Si prefieres ejecutar el poller desde dentro del contenedor usando su `crond` interno, se puede añadir un script en `/etc/periodic/15min/` o `/etc/periodic/5min/` para lanzar `python3 /opt/librenms/poller-wrapper.py 4`. En nuestro caso elegimos host-cron por simplicidad y resiliencia ante reinicios del contenedor.

5) Recomendaciones

- Empezar con 1-2 workers si la Raspberry tiene recursos limitados; ajustar a 4 si el rendimiento lo permite.
- Monitorizar `/var/log/librenms-poller-wrapper.log` y los logs internos `/opt/librenms/logs/poller.log` y `librenms.log` para detectar timeouts SNMP o errores repetidos.
- Implementar rotación de logs (ya añadida) para evitar llenar disco.

Con esto el polling automático queda solucionado y LibreNMS reporta pollers activos.

---

## Solución del problema SNMP para automonitoreo de la Raspberry Pi

Fecha: 19 de noviembre de 2025

### Problema detectado

Al intentar agregar la propia Raspberry Pi como dispositivo en LibreNMS (IP 192.168.173.10) obtenía el siguiente error:

```
Could not connect to 192.168.173.10, please check the snmp details and snmp reachability
SNMP v2c: No reply with community public
```

### Diagnóstico paso a paso

1) **Verificación del servicio SNMP**
   - Confirmé que `snmpd` estaba corriendo pero el `systemctl restart snmpd` fallaba con "Error opening specified endpoint udp:161"

2) **Identificación del conflicto**
   - Descubrí que había dos procesos SNMP:
     - Un `snmpd` del host (gestionado por systemd)  
     - Un `snmpd` dentro del contenedor LibreNMS (gestionado por s6-supervise)
   
   - El contenedor LibreNMS usa `network_mode: host`, por lo que su `snmpd` ocupaba el puerto 161 del host

3) **Análisis de la configuración**
   ```bash
   # Proceso que ocupaba el puerto
   sudo ss -ulpn | grep :161
   # Output: users:(("snmpd",pid=2089136,fd=7))
   
   # Identificación del contenedor
   sudo ps -fp 2089136
   # Output: /usr/sbin/snmpd -f -c /etc/snmp/snmpd.conf (dentro del contenedor LibreNMS)
   ```

4) **Configuración incorrecta detectada**
   - El `snmpd` del contenedor tenía configurada la community `librenmsdocker` en lugar de `public`
   - El archivo `/etc/snmp/snmpd.conf` del contenedor contenía:
   ```
   com2sec readonly default librenmsdocker
   ```

### Solución implementada

Decidí configurar SNMP dentro del contenedor LibreNMS en lugar de usar el del host, ya que:
- El contenedor usa `network_mode: host` (comparte la red del host directamente)
- Es más simple mantener una sola configuración SNMP
- No interrumpe el funcionamiento de LibreNMS

**Pasos ejecutados:**

1) **Acceder al contenedor LibreNMS**
   ```bash
   sudo docker exec -it librenms /bin/bash
   ```

2) **Verificar configuración actual**
   ```bash
   cat /etc/snmp/snmpd.conf
   # Community configurada: librenmsdocker
   ```

3) **Modificar la configuración SNMP**
   ```bash
   cp /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.bak
   vi /etc/snmp/snmpd.conf
   ```
   
   Cambié la configuración para usar community `public`:
   ```
   # Línea modificada:
   com2sec readonly default public
   
   # También actualicé la información del sistema:
   syslocation Raspberry Pi 4 - LibreNMS Container
   syscontact Felipe <email@correo>
   ```

4) **Reiniciar el servicio SNMP**
   ```bash
   # Dentro del contenedor
   pkill -HUP snmpd
   ```

5) **Verificar funcionamiento**
   ```bash
   # Desde dentro del contenedor
   snmpwalk -v2c -c public 127.0.0.1 SNMPv2-MIB::sysDescr.0
   snmpwalk -v2c -c public 192.168.173.10 SNMPv2-MIB::sysDescr.0
   
   # Salir del contenedor
   exit
   
   # Desde el host
   snmpwalk -v2c -c public 192.168.173.10 SNMPv2-MIB::sysDescr.0
   ```

### Resultado

✅ SNMP responde correctamente con community `public`
✅ LibreNMS puede agregar la Raspberry Pi como dispositivo
✅ No se interrumpió el funcionamiento de LibreNMS
✅ Una sola configuración SNMP para todo el sistema

### Verificación en LibreNMS

En la interfaz web de LibreNMS, ahora se puede agregar el dispositivo con:
- **IP/Hostname:** `192.168.173.10` (o `127.0.0.1`)
- **SNMP Version:** `v2c` 
- **Community:** `public`

---

## Comandos útiles para mantenimiento del contenedor LibreNMS

### Acceso y navegación
```bash
# Acceder al contenedor como root
sudo docker exec -it librenms /bin/bash

# Acceder como usuario librenms (recomendado para tareas de LibreNMS)
sudo docker exec -it --user librenms librenms /bin/bash

# Ejecutar comando único desde el host
sudo docker exec --user librenms librenms php /opt/librenms/validate.php

# Ver logs del contenedor
sudo docker logs librenms
sudo docker logs -f librenms  # seguir logs en tiempo real
```

### Monitoreo del sistema
```bash
# Ver procesos dentro del contenedor
sudo docker exec librenms ps aux

# Ver uso de recursos del contenedor
sudo docker stats librenms

# Verificar configuración de red
sudo docker exec librenms ip addr show
sudo docker exec librenms ss -ulpn | grep :161
```

### Gestión de servicios dentro del contenedor
```bash
# Listar servicios s6 (supervisor usado por LibreNMS)
sudo docker exec librenms ls -la /etc/services.d/

# Ver estado de snmpd
sudo docker exec librenms ps aux | grep snmpd

# Reiniciar snmpd (método suave)
sudo docker exec librenms pkill -HUP snmpd

# Ver configuración SNMP actual
sudo docker exec librenms cat /etc/snmp/snmpd.conf
```

### Mantenimiento de LibreNMS
```bash
# Ejecutar validación completa
sudo docker exec --user librenms librenms php /opt/librenms/validate.php

# Ver estado del poller
sudo docker exec --user librenms librenms python3 /opt/librenms/poller-wrapper.py 1

# Limpiar logs antiguos
sudo docker exec --user librenms librenms php /opt/librenms/daily.sh

# Acceder a la base de datos (si necesario)
sudo docker exec -it librenms_db mysql -u librenms -p librenms
```

### Backup y restauración
```bash
# Backup de configuración SNMP
sudo docker exec librenms cp /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.backup.$(date +%Y%m%d)

# Backup de la base de datos (ejecutar desde el host)
sudo docker exec librenms_db mysqldump -u librenms -p librenms > librenms_backup_$(date +%Y%m%d).sql

# Ver volúmenes de datos
sudo docker volume ls | grep librenms
sudo docker inspect gestion-de-redes_librenms-data
```

### Troubleshooting común
```bash
# Si SNMP no responde, verificar proceso y configuración
sudo docker exec librenms ps aux | grep snmpd
sudo docker exec librenms netstat -ulpn | grep :161

# Si LibreNMS no puede conectar a dispositivos, verificar conectividad desde el contenedor
sudo docker exec librenms ping -c 3 192.168.173.1
sudo docker exec librenms snmpwalk -v2c -c public 192.168.173.1 system

# Verificar logs de LibreNMS
sudo docker exec librenms tail -f /opt/librenms/logs/librenms.log
sudo docker exec librenms tail -f /opt/librenms/logs/poller.log

# Reiniciar completamente el stack LibreNMS (cuidado: puede interrumpir monitoreo)
sudo docker-compose down && sudo docker-compose up -d
# O si usas docker run:
sudo docker restart librenms librenms_db
```

### Notas importantes para el próximo desarrollador

1. **El contenedor LibreNMS usa `network_mode: host`** - esto significa que comparte la red directamente con el host, por eso su SNMP responde en la IP del host.

2. **No modificar el `snmpd` del host** - el contenedor tiene prioridad sobre el puerto 161. Si necesitas cambios en SNMP, hazlos dentro del contenedor.

3. **Community strings** - actualmente configurado con `public`. Para mayor seguridad considera cambiar a una community personalizada y actualizar todos los dispositivos que consulten SNMP de esta Raspberry.

4. **Persistencia de datos** - los datos de LibreNMS están en volúmenes Docker. Los cambios en `/etc/snmp/snmpd.conf` dentro del contenedor pueden perderse si se recrea el contenedor sin volumen persistente para `/etc`.

5. **Monitoreo de recursos** - la Raspberry Pi tiene recursos limitados. Monitorea el uso de CPU/memoria del contenedor y ajusta el número de workers del poller si es necesario.

6. **Backup regular** - programa backups automáticos de la base de datos y configuraciones importantes, especialmente antes de actualizaciones del contenedor.

# Descubrir una subred completa
```bash
./discovery.php -h all
# O para un rango específico
./addhost.php <ip-o-hostname> <community> v2c
```
