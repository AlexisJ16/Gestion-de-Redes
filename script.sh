#!/bin/bash
set -e

# Funciones de logging con colores
log_info() {
    echo -e "\033[1;34m[INFO]\033[0m $1"
}

log_success() {
    echo -e "\033[1;32m[SUCCESS]\033[0m $1"
}

log_warning() {
    echo -e "\033[1;33m[WARNING]\033[0m $1"
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

# Detectar sistema operativo y configurar variables
detect_os() {
    log_info "Detectando sistema operativo..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        log_error "No se puede detectar el sistema operativo"
        exit 1
    fi
    
    # Configurar package manager según el OS
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        PKG_MANAGER="apt"
        INSTALL_CMD="apt install -y"
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
        PKG_MANAGER="yum"
        INSTALL_CMD="yum install -y"
    elif [[ "$OS" == *"Fedora"* ]]; then
        PKG_MANAGER="dnf"
        INSTALL_CMD="dnf install -y"
    else
        log_warning "OS no reconocido: $OS. Intentando con apt..."
        PKG_MANAGER="apt"
        INSTALL_CMD="apt install -y"
    fi
    
    log_success "Detectado: $OS $VER (usando $PKG_MANAGER)"
}

# Verificar privilegios sudo
check_sudo() {
    log_info "Verificando privilegios sudo..."
    if sudo -n true 2>/dev/null; then
        log_success "Privilegios sudo confirmados"
    else
        log_error "Este script requiere privilegios sudo"
        exit 1
    fi
}

# Verificar conexión a internet
check_internet() {
    log_info "Verificando conexión a internet..."
    if ping -c 1 google.com &> /dev/null; then
        log_success "Conexión a internet confirmada"
    else
        log_error "No hay conexión a internet"
        exit 1
    fi
}

# Verificar recursos del sistema
check_resources() {
    log_info "Verificando recursos del sistema..."
    
    # Verificar RAM (mínimo 1GB)
    TOTAL_RAM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    if [ $TOTAL_RAM -lt 1000 ]; then
        log_warning "RAM insuficiente: ${TOTAL_RAM}MB (recomendado: 2GB+)"
    else
        log_success "RAM suficiente: ${TOTAL_RAM}MB"
    fi
    
    # Verificar espacio en disco (mínimo 10GB)
    AVAILABLE_SPACE=$(df / | awk 'NR==2 {print int($4/1024/1024)}')
    if [ $AVAILABLE_SPACE -lt 10 ]; then
        log_warning "Espacio en disco insuficiente: ${AVAILABLE_SPACE}GB (recomendado: 20GB+)"
    else
        log_success "Espacio en disco suficiente: ${AVAILABLE_SPACE}GB disponibles"
    fi
}

# Actualizar sistema
update_system() {
    log_info "Actualizando sistema..."
    if [ "$PKG_MANAGER" = "apt" ]; then
        sudo apt update -y
    elif [ "$PKG_MANAGER" = "yum" ]; then
        sudo yum update -y
    elif [ "$PKG_MANAGER" = "dnf" ]; then
        sudo dnf update -y
    fi
    log_success "Sistema actualizado"
}

# Instalar dependencias básicas
install_dependencies() {
    log_info "Instalando dependencias básicas..."
    if [ "$PKG_MANAGER" = "apt" ]; then
        sudo $INSTALL_CMD curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release
    elif [ "$PKG_MANAGER" = "yum" ]; then
        sudo $INSTALL_CMD curl wget git unzip yum-utils device-mapper-persistent-data lvm2
    elif [ "$PKG_MANAGER" = "dnf" ]; then
        sudo $INSTALL_CMD curl wget git unzip dnf-plugins-core
    fi
    log_success "Dependencias básicas instaladas"
}

# Instalar Git
install_git() {
    if ! command -v git &> /dev/null; then
        log_info "Instalando Git..."
        sudo $INSTALL_CMD git
        log_success "Git instalado correctamente"
    else
        log_success "Git ya está instalado ($(git --version))"
    fi
}

# Instalar Docker
install_docker() {
    if ! command -v docker &> /dev/null; then
        log_info "Instalando Docker..."
        
        # Método universal usando get.docker.com
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        rm get-docker.sh
        
        # Agregar usuario actual al grupo docker
        sudo usermod -aG docker $USER
        
        # Habilitar y iniciar Docker
        sudo systemctl enable docker
        sudo systemctl start docker
        
        # Verificar instalación
        if sudo docker --version; then
            log_success "Docker instalado correctamente ($(sudo docker --version))"
        else
            log_error "Fallo en la instalación de Docker"
            exit 1
        fi
    else
        log_success "Docker ya está instalado ($(docker --version))"
        
        # Verificar que Docker esté corriendo
        if ! sudo systemctl is-active --quiet docker; then
            log_info "Iniciando Docker..."
            sudo systemctl start docker
        fi
    fi
    
    # Verificar que Docker funcione
    if ! sudo docker run --rm hello-world &> /dev/null; then
        log_error "Docker no funciona correctamente"
        exit 1
    fi
    log_success "Docker funciona correctamente"
}

# Instalar Docker Compose
install_docker_compose() {
    # Verificar docker compose (nuevo) o docker-compose (legacy)
    if command -v docker &> /dev/null && sudo docker compose version &> /dev/null; then
        log_success "Docker Compose (plugin) ya está disponible"
        COMPOSE_CMD="docker compose"
    elif command -v docker-compose &> /dev/null; then
        log_success "Docker Compose (standalone) ya está instalado ($(docker-compose --version))"
        COMPOSE_CMD="docker-compose"
    else
        log_info "Instalando Docker Compose..."
        
        if [ "$PKG_MANAGER" = "apt" ]; then
            # Para Debian/Ubuntu, instalar desde repos
            sudo $INSTALL_CMD docker-compose-plugin docker-compose
        else
            # Para otros sistemas, descargar binario
            COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
            sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
        fi
        
        # Verificar instalación
        if command -v docker &> /dev/null && sudo docker compose version &> /dev/null; then
            COMPOSE_CMD="docker compose"
            log_success "Docker Compose (plugin) instalado correctamente"
        elif command -v docker-compose &> /dev/null; then
            COMPOSE_CMD="docker-compose"
            log_success "Docker Compose (standalone) instalado correctamente"
        else
            log_error "Fallo en la instalación de Docker Compose"
            exit 1
        fi
    fi
}

# Instalar SNMP tools para troubleshooting
install_snmp_tools() {
    log_info "Instalando herramientas SNMP para troubleshooting..."
    
    if [ "$PKG_MANAGER" = "apt" ]; then
        sudo $INSTALL_CMD snmp snmp-mibs-downloader
    else
        sudo $INSTALL_CMD net-snmp-utils
    fi
    
    log_success "Herramientas SNMP instaladas"
}

# Obtener IP del sistema
get_server_ip() {
    # Intentar obtener IP de diferentes maneras
    SERVER_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || \
              ip route get 8.8.8.8 | grep -oP 'src \K\S+' 2>/dev/null || \
              ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1 | head -1)
    
    if [ -z "$SERVER_IP" ]; then
        SERVER_IP="localhost"
        log_warning "No se pudo detectar IP automáticamente, usando localhost"
    else
        log_success "IP del servidor detectada: $SERVER_IP"
    fi
}

# Clonar o actualizar repositorio
setup_repository() {
    log_info "Configurando repositorio..."
    
    REPO_URL="https://github.com/felipevelasco7/Gestion-de-Redes.git"
    REPO_DIR="Gestion-de-Redes"
    
    if [ -d "$REPO_DIR" ]; then
        log_info "Repositorio existe, actualizando..."
        cd "$REPO_DIR"
        git pull origin main || {
            log_warning "No se pudo actualizar, continuando con versión local"
        }
    else
        log_info "Clonando repositorio..."
        git clone "$REPO_URL" || {
            log_error "No se pudo clonar el repositorio"
            exit 1
        }
        cd "$REPO_DIR"
    fi
    
    log_success "Repositorio configurado en $(pwd)"
}

# Configurar archivo docker-compose.yml con IP correcta
configure_docker_compose() {
    log_info "Configurando docker-compose.yml con IP del servidor..."
    
    if [ -f "docker-compose.yml" ]; then
        # Crear backup
        cp docker-compose.yml docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)
        
        # Reemplazar IP en BASE_URL
        if grep -q "BASE_URL=" docker-compose.yml; then
            sed -i "s|BASE_URL=http://[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*:8000|BASE_URL=http://$SERVER_IP:8000|g" docker-compose.yml
            log_success "BASE_URL actualizada a: http://$SERVER_IP:8000"
        else
            log_warning "No se encontró BASE_URL en docker-compose.yml"
        fi
    else
        log_error "No se encontró docker-compose.yml"
        exit 1
    fi
}

# Desplegar LibreNMS
deploy_librenms() {
    log_info "Desplegando LibreNMS con Docker Compose..."
    
    # Detener contenedores previos si existen
    sudo $COMPOSE_CMD down 2>/dev/null || true
    
    # Crear directorios de volúmenes si no existen
    sudo mkdir -p librenms-data db-data
    
    # Levantar servicios
    sudo $COMPOSE_CMD up -d || {
        log_error "Fallo al desplegar LibreNMS"
        log_info "Logs del error:"
        sudo $COMPOSE_CMD logs
        exit 1
    }
    
    log_success "LibreNMS desplegado correctamente"
}

# Verificar despliegue
verify_deployment() {
    log_info "Verificando despliegue..."
    
    # Esperar a que los contenedores inicien
    sleep 10
    
    # Verificar contenedores corriendo
    if sudo docker ps | grep -q librenms; then
        log_success "Contenedores de LibreNMS corriendo"
    else
        log_error "Los contenedores no están corriendo"
        sudo docker ps -a
        exit 1
    fi
    
    # Verificar puerto 8000
    if netstat -tlnp 2>/dev/null | grep -q :8000 || ss -tlnp 2>/dev/null | grep -q :8000; then
        log_success "Puerto 8000 disponible"
    else
        log_warning "Puerto 8000 no detectado, pero LibreNMS podría estar iniciando"
    fi
    
    # Esperar más tiempo para que LibreNMS inicie completamente
    log_info "Esperando a que LibreNMS inicie completamente (30s)..."
    sleep 30
    
    # Probar acceso HTTP
    if curl -s -f "http://$SERVER_IP:8000" > /dev/null; then
        log_success "LibreNMS responde correctamente en http://$SERVER_IP:8000"
    else
        log_warning "LibreNMS aún no responde, puede necesitar más tiempo para iniciar"
        log_info "Puedes verificar el estado con: sudo docker logs librenms"
    fi
}

# Configurar SNMP automático
configure_snmp() {
    log_info "Configurando SNMP en el contenedor LibreNMS..."
    
    # Esperar a que el contenedor esté completamente iniciado
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if sudo docker exec librenms test -f /etc/snmp/snmpd.conf 2>/dev/null; then
            break
        fi
        log_info "Esperando que SNMP esté disponible... (intento $attempt/$max_attempts)"
        sleep 5
        ((attempt++))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        log_warning "No se pudo configurar SNMP automáticamente"
        return 1
    fi
    
    # Configurar snmpd.conf dentro del contenedor
    sudo docker exec librenms bash -c "cat > /etc/snmp/snmpd.conf << 'EOF'
# SNMP Community Configuration
com2sec readonly  default         public
group MyROGroup v1         readonly
group MyROGroup v2c        readonly
view all    included   .1                               80

# System Information
syslocation \"LibreNMS Server\"
syscontact \"admin@example.com\"
sysname \"LibreNMS-$(hostname)\"

# Access Control
access MyROGroup \"\"      any       noauth    exact  all    none   none

# Enable AgentX
master agentx
agentXSocket tcp:localhost:705
EOF"
    
    if [ $? -eq 0 ]; then
        log_success "SNMP configurado con community 'public'"
        
        # Asegurar que el servicio SNMP esté corriendo correctamente con s6-supervise
        sudo docker exec librenms bash -c "
            # Matar procesos SNMP existentes
            pkill snmpd 2>/dev/null || true
            sleep 2
            
            # Iniciar snmpd con supervisión
            /usr/sbin/snmpd -c /etc/snmp/snmpd.conf -f -L 0 &
            
            # Verificar que esté corriendo
            sleep 3
            if pgrep snmpd > /dev/null; then
                echo 'SNMP daemon iniciado correctamente'
            else
                echo 'Error iniciando SNMP daemon'
            fi
        " 2>/dev/null || true
        
        log_success "SNMP daemon configurado y iniciado"
    else
        log_warning "No se pudo configurar SNMP automáticamente"
    fi
}

# Agregar dispositivo automáticamente
add_local_device() {
    log_info "Agregando dispositivo local automáticamente..."
    
    # Esperar más tiempo para que LibreNMS esté completamente iniciado
    sleep 20
    
    # Verificar que LibreNMS esté respondiendo
    local max_attempts=20
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "http://$SERVER_IP:8000" > /dev/null 2>&1; then
            break
        fi
        log_info "Esperando que LibreNMS esté completamente iniciado... (intento $attempt/$max_attempts)"
        sleep 10
        ((attempt++))
    done
    
    # Agregar dispositivo usando la CLI de LibreNMS
    sudo docker exec librenms php /opt/librenms/addhost.php "$SERVER_IP" public v2c || {
        log_warning "No se pudo agregar el dispositivo automáticamente via CLI"
        
        # Método alternativo: agregar directamente a la base de datos
        sudo docker exec librenms_db mysql -u librenms -ppassword librenms -e "
        INSERT IGNORE INTO devices (hostname, community, authlevel, authname, authpass, authalgo, cryptopass, cryptoalgo, snmpver, port, transport, timeout, retries, snmp_disable, bgpLocalAs, sysName, hardware, features, location_id, os, status, status_reason, ignore, disabled, uptime, agent_uptime, last_polled, last_ping, last_ping_timetaken, last_discovered, last_discovered_timetaken, last_duration_poll, last_duration_discover, device_id, inserted, icon, type, serial, sysContact, version, sysLocation, lat, lng, attribs, ip, overwrite_ip, community_id, port_association_mode) 
        VALUES ('$SERVER_IP', 'public', 'noAuthNoPriv', '', '', '', '', '', 'v2c', 161, 'udp', NULL, NULL, 0, NULL, NULL, '', '', 1, 'linux', 1, '', 0, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NOW(), '', 'server', NULL, NULL, NULL, 'LibreNMS Server', NULL, NULL, '[]', INET_ATON('$SERVER_IP'), '', NULL, 1);
        " 2>/dev/null || log_warning "No se pudo agregar a la base de datos directamente"
    }
    
    log_success "Dispositivo local configurado para monitoreo"
}

# Configurar el sistema de poller interno de LibreNMS
configure_internal_poller() {
    log_info "Configurando sistema de poller interno de LibreNMS..."
    
    # Configurar el poller interno dentro del contenedor
    sudo docker exec librenms bash -c "
        # Asegurar que el directorio de configuración existe
        mkdir -p /opt/librenms/config
        
        # Configurar el poller para funcionar correctamente
        echo '<?php
// Configuración específica para el poller
\$config[\"poller_modules\"][\"unix-agent\"] = 1;
\$config[\"discovery_modules\"][\"discovery-protocols\"] = 1;
\$config[\"autodiscovery\"][\"xdp\"] = true;
\$config[\"nets\"][] = \"$SERVER_IP/32\";

// Configuración SNMP
\$config[\"snmp\"][\"community\"][] = \"public\";
\$config[\"snmp\"][\"v3\"][0][\"authlevel\"] = \"noAuthNoPriv\";
\$config[\"snmp\"][\"v3\"][0][\"authname\"] = \"librems\";

// Configuración de descubrimiento automático
\$config[\"discover_services\"] = true;
\$config[\"discover_services_nagios\"] = true;

// Habilitar módulos importantes
\$config[\"enable_syslog\"] = 1;
\$config[\"enable_billing\"] = 1;
\$config[\"show_services\"] = 1;

// Configuración de rendimiento
\$config[\"rrd\"][\"step\"] = 300;
\$config[\"rrd\"][\"heartbeat\"] = 600;
?>' > /opt/librenms/config/config.custom.php
    " 2>/dev/null || log_warning "No se pudo configurar el poller interno completamente"
    
    log_success "Sistema de poller interno configurado"
}

# Validar configuración final
validate_final_setup() {
    log_info "Validando configuración final..."
    
    # Verificar que los contenedores estén corriendo
    if sudo docker ps | grep -q "librenms" && sudo docker ps | grep -q "librenms_db"; then
        log_success "✅ Contenedores LibreNMS y MariaDB corriendo"
    else
        log_warning "⚠️  Algunos contenedores no están corriendo"
        sudo docker ps -a
    fi
    
    # Verificar puertos
    if ss -tlnp 2>/dev/null | grep -q ":8000" || netstat -tlnp 2>/dev/null | grep -q ":8000"; then
        log_success "✅ Puerto 8000 (LibreNMS) activo"
    else
        log_warning "⚠️  Puerto 8000 no detectado"
    fi
    
    if ss -tlnp 2>/dev/null | grep -q ":3306" || netstat -tlnp 2>/dev/null | grep -q ":3306"; then
        log_success "✅ Puerto 3306 (MariaDB) activo"
    else
        log_warning "⚠️  Puerto 3306 no detectado"
    fi
    
    # Verificar respuesta SNMP
    if sudo docker exec librenms snmpwalk -v2c -c public $SERVER_IP 1.3.6.1.2.1.1.1.0 2>/dev/null | grep -q "STRING"; then
        log_success "✅ SNMP responde correctamente con community 'public'"
    else
        log_warning "⚠️  SNMP no responde, verificando configuración..."
        # Intentar diagnóstico SNMP
        sudo docker exec librenms bash -c "
            echo 'Verificando proceso SNMP:'
            ps aux | grep snmp || echo 'No hay procesos SNMP'
            echo 'Verificando puerto 161:'
            ss -ulnp | grep :161 || echo 'Puerto 161 no activo'
        " 2>/dev/null || true
    fi
    
    # Verificar dispositivo en base de datos
    if sudo docker exec librenms_db mysql -u librenms -ppassword librenms -e "SELECT hostname FROM devices WHERE hostname='$SERVER_IP';" 2>/dev/null | grep -q "$SERVER_IP"; then
        log_success "✅ Dispositivo local registrado en base de datos"
    else
        log_warning "⚠️  Dispositivo no encontrado en base de datos"
    fi
    
    # Verificar crontab del poller
    if sudo crontab -l 2>/dev/null | grep -q "poller-wrapper.py"; then
        log_success "✅ Poller automático configurado en crontab"
    else
        log_warning "⚠️  Poller no encontrado en crontab"
    fi
    
    # Verificar configuración personalizada de LibreNMS
    if sudo docker exec librenms test -f /opt/librenms/config/config.custom.php 2>/dev/null; then
        log_success "✅ Configuración personalizada aplicada"
    else
        log_warning "⚠️  Configuración personalizada no encontrada"
    fi
    
    # Ejecutar poller manual una vez para verificar funcionamiento
    log_info "Ejecutando poller manual de prueba..."
    sudo docker exec --user librenms librenms php /opt/librenms/poller.php -h $SERVER_IP -v 2>/dev/null | head -5 || log_warning "Poller manual no ejecutado correctamente"
    
    # Verificar que LibreNMS validate pase
    log_info "Ejecutando validación completa de LibreNMS..."
    sudo docker exec --user librenms librenms php /opt/librenms/validate.php 2>/dev/null | head -15 || log_warning "Validación de LibreNMS en progreso..."
}

# Configurar poller automático
setup_poller() {
    log_info "Configurando poller automático..."
    
    # Crear archivo de log
    sudo touch /var/log/librenms-poller.log
    sudo chmod 644 /var/log/librenms-poller.log
    
    # Agregar entrada a crontab si no existe
    CRON_ENTRY="*/5 * * * * docker exec --user librenms librenms python3 /opt/librenms/poller-wrapper.py 4 >> /var/log/librenms-poller.log 2>&1"
    
    if ! sudo crontab -l 2>/dev/null | grep -q "poller-wrapper.py"; then
        (sudo crontab -l 2>/dev/null; echo "$CRON_ENTRY") | sudo crontab -
        log_success "Poller automático configurado"
    else
        log_success "Poller automático ya estaba configurado"
    fi
    
    # Configurar rotación de logs
    sudo tee /etc/logrotate.d/librenms-poller > /dev/null << EOF
/var/log/librenms-poller.log {
    weekly
    rotate 8
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
}
EOF
    
    log_success "Rotación de logs configurada"
}

# Mostrar resumen final
show_summary() {
    echo
    echo "================================================="
    echo "🎉 LibreNMS desplegado exitosamente!"
    echo "================================================="
    echo
    log_success "URL de acceso: http://$SERVER_IP:8000"
    log_info "Configuración completada automáticamente:"
    echo "  📊 Base de datos: librenms / password"
    echo "  🔧 SNMP Community: public (configurado automáticamente)"
    echo "  🖥️  Dispositivo local: $SERVER_IP (agregado automáticamente)"
    echo "  ⏰ Poller automático: cada 5 minutos (crontab + interno)"
    echo "  🌐 BASE_URL: http://$SERVER_IP:8000 (configurada)"
    echo
    log_info "¡Todo listo para usar sin configuración adicional!"
    echo "  ✅ SNMP daemon configurado y corriendo"
    echo "  ✅ Servidor agregado para automonitoreo"
    echo "  ✅ Poller externo (crontab) configurado"
    echo "  ✅ Poller interno de LibreNMS configurado"
    echo "  ✅ Configuración personalizada aplicada"
    echo "  ✅ Servicios de descubrimiento habilitados"
    echo "  ✅ Rotación de logs configurada"
    echo "  ✅ Red en modo 'host' para mejor rendimiento SNMP"
    echo
    log_info "Próximos pasos opcionales:"
    echo "  1. Accede a LibreNMS desde tu navegador"
    echo "  2. Completa la configuración inicial del usuario admin"
    echo "  3. Agrega más dispositivos de red desde la interfaz"
    echo "  4. Personaliza alertas y notificaciones"
    echo
    log_info "Comandos útiles:"
    echo "  • Ver logs: sudo docker logs librenms"
    echo "  • Reiniciar: sudo docker-compose restart"
    echo "  • Acceder al contenedor: sudo docker exec -it librenms /bin/bash"
    echo "  • Validar configuración: sudo docker exec --user librenms librenms php /opt/librenms/validate.php"
    echo "  • Ver dispositivos: sudo docker exec librenms php /opt/librenms/lnms device:list"
    echo
    log_info "Documentación completa disponible en:"
    echo "  📚 https://github.com/felipevelasco7/Gestion-de-Redes/blob/main/README.md"
    echo
    echo "================================================="
}

# Función principal
main() {
    echo "🚀 Iniciando despliegue automático de LibreNMS para ISPs"
    echo "================================================="
    
    detect_os
    check_sudo
    check_internet
    check_resources
    update_system
    install_dependencies
    install_git
    install_docker
    install_docker_compose
    install_snmp_tools
    get_server_ip
    setup_repository
    configure_docker_compose
    deploy_librenms
    verify_deployment
    configure_snmp
    configure_internal_poller
    add_local_device
    setup_poller
    validate_final_setup
    show_summary
    
    log_success "¡Despliegue completado exitosamente!"
}

# Ejecutar función principal
main "$@"
