# 🌐 Gestión de Redes - LibreNMS Docker

**Plataforma de monitoreo de red con LibreNMS enfocada en pequeños y medianos proveedores de servicios de internet (ISP)**

#### Proyecto de grado Ingenieria Telematica Universidad Icesi

Felipe Velasco Sanchez

Alexis Jaramillo

[![Docker](https://img.shields.io/badge/Docker-20.10+-blue.svg)](https://www.docker.com/)
[![LibreNMS](https://img.shields.io/badge/LibreNMS-Latest-green.svg)](https://www.librenms.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 📖 Descripción

Este repositorio contiene una implementación completa de **LibreNMS** usando Docker, optimizada para ISPs y empresas que necesitan monitorear su infraestructura de red. Incluye configuración automática, scripts de despliegue y documentación completa para implementación en entornos de producción.

### ✨ Características principales

- 🚀 **Despliegue automático** con un solo comando `script.sh`
- 🐳 **Configuración Docker optimizada** con `network_mode: host`
- 📊 **Base de datos MariaDB** preconfigurada para LibreNMS
- 🔧 **SNMP configurado** para automonitoreo del servidor
- 🌍 **Multi-ISP friendly** - fácil adaptación a diferentes redes
- 📚 **Documentación completa** con troubleshooting
- 🔄 **Scripts de backup** y mantenimiento
- ⚡ **Alta disponibilidad** con restart automático

---

## 🚀 Inicio Rápido

### Método 1: Despliegue Automático (Recomendado)

```bash
# Descargar y ejecutar script de instalación automática
curl -fsSL https://raw.githubusercontent.com/felipevelasco7/Gestion-de-Redes/main/script.sh -o script.sh
chmod +x script.sh
sudo ./script.sh
```

### Método 2: Instalación Manual

```bash
# 1. Clonar el repositorio
git clone https://github.com/felipevelasco7/Gestion-de-Redes.git
cd Gestion-de-Redes

    #Para obtener la IP del servidor:
    hostname -I

    #Cambiar las IPs en el docker docker-compose.yml
    vim docker-compose.yml   
    # Cambiar línea:
    BASE_URL=http://TU_IP_REAL:8000

# 2. Levantar los servicios
sudo docker compose up -d

# 3. Verificar el despliegue
sudo docker ps
```

### 🌐 Acceso

Una vez desplegado, accede a LibreNMS en: `http://TU_IP_SERVIDOR:8000`


---

## 📁 Estructura del Repositorio

```
Gestion-de-Redes/
├── 📜 README.md                              # Este archivo
├── 🚀 deployLibrenms.sh                      # Script de despliegue automático basico
├── 🐳 docker-compose.yml                     # Configuración Docker optimizada
├── 🚀🚀 deploy-Librenms-with-config.sh       # Script de despliegue automatico que incluye las configuraciones iniciales de SNMP
└── 📖 docs/                                  # Documentación adicional
    ├── 📋 GUIA DE DESPLIEGUE DOCKER LIBRENMS.md  # Guía básica de despliegue
    ├── ⚙️Configuraciones_Realizadas.md           # Guía de configuraciones, problemas encontrados, y soluciones aplicadas
    ├── 📑PDG1-Final.pdf                          # Documento preliminar del proyecto
    ├── 📑PDG2-FINAL.pdf                          # Documento formal del proyecto terminado
    └── 📄Plataforma de gestion de red para pequeños ISP.docx      # Documento formal en docx

```

---

## ⚙️ Configuración

### Configuración por Defecto

| Componente | Valor por Defecto | Personalizable |
|------------|-------------------|----------------|
| **Puerto Web** | `8000` | ✅ |
| **Base de Datos** | `librenms` | ✅ |
| **Usuario DB** | `librenms` | ✅ |
| **Password DB** | `password` | ⚠️ **Cambiar en producción** |
| **SNMP Community** | `librenmsdocker` | ✅ **Recomendado cambiar** |
| **Zona Horaria** | `America/Bogota` | ✅ |
| **BASE_URL** | `http://192.168.1.164:8000` | ⚠️ **Cambiar por tu IP** |

### 🔧 Personalización para tu Red

1. **Cambiar BASE_URL:**
   ```bash
   # Editar docker-compose.yml
   vim docker-compose.yml
   
   # Cambiar línea:
   - BASE_URL=http://TU_IP_REAL:8000
   ```

2. **Configurar SNMP personalizado:**
   ```bash
   # Acceder al contenedor
   sudo docker exec -it librenms /bin/bash
   
   # Editar configuración SNMP
   vi /etc/snmp/snmpd.conf
   ```

3. **Reiniciar servicios:**
   ```bash
   sudo docker-compose down
   sudo docker-compose up -d
   ```

---

## 🛠️ Comandos Útiles

### Gestión de Contenedores
```bash
# Ver estado de los contenedores
sudo docker ps

# Ver logs
sudo docker logs librenms
sudo docker logs librenms_db

# Reiniciar servicios
sudo docker-compose restart

# Detener/Iniciar todo
sudo docker-compose down
sudo docker-compose up -d
```

### Acceso al Contenedor LibreNMS
```bash
# Como root
sudo docker exec -it librenms /bin/bash

# Como usuario librenms (recomendado)
sudo docker exec -it --user librenms librenms /bin/bash

# Ejecutar comandos específicos
sudo docker exec --user librenms librenms php /opt/librenms/validate.php
```

### Troubleshooting SNMP
```bash
# Probar SNMP local
snmpwalk -v2c -c public 127.0.0.1 SNMPv2-MIB::sysDescr.0

# Probar SNMP hacia dispositivo
sudo docker exec -it librenms snmpwalk -v2c -c public IP_DISPOSITIVO SNMPv2-MIB::sysDescr.0

# Ver configuración SNMP actual
sudo docker exec librenms cat /etc/snmp/snmpd.conf
```

---

## 📚 Documentación

### Guías Disponibles

1. **[Guía de Despliegue Básica](GUIA%20DE%20DESPLIEGUE%20DOCKER%20LIBRENMS.md)**
   - Instalación rápida con script automático
   - Comandos básicos de Docker
   - Acceso inicial a LibreNMS

2. **[Guía Completa para ISPs](docs/Guia-Despliegue-LibreNMS-Completa.md)**
   - Configuración avanzada para ISPs
   - Discovery masivo de dispositivos
   - Configuración de múltiples community strings
   - Alertas y umbrales personalizados
   - Backup automatizado
   - Migración entre redes

3. **[Troubleshooting SNMP](docs/Resumen-i2t-raspberri.md)**
   - Solución de problemas SNMP
   - Configuración de automonitoreo
   - Resolución de conflictos de red
   - Casos de uso específicos

### 🎯 Para ISPs y Empresas

- **Descubrimiento automático** de dispositivos en red
- **Monitoreo de switches, routers y servidores**
- **Alertas configurable por email/Slack**
- **Dashboards personalizados**
- **Mapas de red automáticos**
- **Inventario de hardware**
- **Reportes de utilización**

---

## 🔧 Configuración Avanzada

### Para Múltiples Community Strings
```php
// Agregar en /opt/librenms/config.php
$config['snmp']['community'][] = "public";
$config['snmp']['community'][] = "private"; 
$config['snmp']['community'][] = "monitoring";
$config['snmp']['community'][] = "isp_readonly";
```

### Para Discovery Automático
```php
// Configurar redes de discovery
$config['nets'][] = "192.168.1.0/24";
$config['nets'][] = "10.0.0.0/8";
$config['nets'][] = "172.16.0.0/12";

// Habilitar autodiscovery
$config['discovery_by_ip'] = true;
$config['autodiscovery']['xdp'] = true;
```

### Configurar Poller Automático
```bash
# Agregar a crontab del sistema
sudo crontab -e

# Línea a agregar:
*/5 * * * * docker exec --user librenms librenms python3 /opt/librenms/poller-wrapper.py 4 >> /var/log/librenms-poller.log 2>&1
```

---

## 🌍 Adaptación para Diferentes ISPs

### Cambio de Red Completo
1. **Actualizar IPs en `docker-compose.yml`**
2. **Configurar nuevas redes de discovery**
3. **Ajustar community strings según estándares del ISP**
4. **Configurar VLANs si es necesario**
5. **Establecer umbrales específicos de alertas**

### Configuración Multi-Sede
- **Contenedores en cada sede** reportando a central
- **VPN/Túneles** para conectividad entre sedes
- **Discovery federado** por rangos de IP
- **Alertas centralizadas** con contexto por sede

---

## ❗ Troubleshooting Común

### LibreNMS no carga
```bash
# Verificar contenedores
sudo docker ps

# Ver logs detallados  
sudo docker logs librenms --tail 100

# Reiniciar servicios
sudo docker-compose restart
```

### Dispositivos no se agregan
```bash
# Probar conectividad
ping IP_DISPOSITIVO

# Probar SNMP
snmpwalk -v2c -c public IP_DISPOSITIVO SNMPv2-MIB::sysDescr.0

# Verificar community string
sudo docker exec librenms cat /etc/snmp/snmpd.conf
```

### Poller no funciona
```bash
# Verificar cron
sudo crontab -l | grep librenms

# Ejecutar manualmente
sudo docker exec --user librenms librenms python3 /opt/librenms/poller-wrapper.py 1

# Verificar validate.php
sudo docker exec --user librenms librenms php /opt/librenms/validate.php
```

---

## 🔐 Consideraciones de Seguridad

### Antes de Producción
- [ ] **Cambiar contraseñas** por defecto de base de datos
- [ ] **Configurar community strings** seguras (no usar 'public')
- [ ] **Habilitar firewall** para limitar acceso al puerto 8000
- [ ] **Configurar HTTPS** con certificados válidos
- [ ] **Programar backups** regulares
- [ ] **Monitorear logs** de acceso

### Recomendaciones de Red
- **Usar VLANs** dedicadas para gestión
- **Implementar SNMPv3** cuando sea posible  
- **Restringir acceso** por ACLs en dispositivos
- **Monitorear intentos** de acceso no autorizados

---

## 🤝 Contribuciones

¡Las contribuciones son bienvenidas! Si encuentras bugs o quieres agregar funcionalidades:

1. **Fork** el repositorio
2. **Crea una rama** para tu feature (`git checkout -b feature/nueva-funcionalidad`)
3. **Commit** tus cambios (`git commit -am 'Agregar nueva funcionalidad'`)
4. **Push** a la rama (`git push origin feature/nueva-funcionalidad`)
5. **Abre un Pull Request**

---

## 📄 Licencia

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles.

---

## 📞 Soporte

- **Documentación:** Revisa las guías en `/docs`
- **Issues:** [GitHub Issues](https://github.com/felipevelasco7/Gestion-de-Redes/issues)
- **LibreNMS Oficial:** [https://www.librenms.org/](https://www.librenms.org/)

---

## 🎯 Casos de Uso

### Para ISPs
- ✅ **Monitoreo de CPEs** (routers de clientes)
- ✅ **Supervisión de enlaces** (fibra, microondas)  
- ✅ **Control de ancho de banda** por cliente
- ✅ **Alertas de caídas** de servicio
- ✅ **Reportes de SLA** automáticos
- ✅ **Inventario de equipos** actualizado

### Para Empresas
- ✅ **Monitoreo de switches** de acceso
- ✅ **Supervisión de servidores** críticos
- ✅ **Control de utilización** de enlaces WAN
- ✅ **Alertas proactivas** de problemas
- ✅ **Dashboards ejecutivos** personalizados
- ✅ **Reportes de disponibilidad** de servicios

---

**🚀 ¡Empieza a monitorear tu red ahora mismo!**

```bash
curl -fsSL https://raw.githubusercontent.com/felipevelasco7/Gestion-de-Redes/main/deployLibrenms.sh -o deployLibrenms.sh && chmod +x deployLibrenms.sh && sudo ./deployLibrenms.sh
```
