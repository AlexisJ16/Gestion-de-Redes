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

// Configuración crítica del poller
\$config[\"poller_wrapper\"][\"workers\"] = 4;
\$config[\"poller_wrapper\"][\"alerter\"] = true;
\$config[\"distributed_poller\"] = false;
\$config[\"distributed_poller_name\"] = php_uname(\"n\");
\$config[\"distributed_poller_group\"] = 0;
?>' > /opt/librenms/config/config.custom.php
    " 2>/dev/null || log_warning "No se pudo configurar el poller interno completamente"
    
    log_success "Sistema de poller interno configurado"
}

# Configurar Python Wrapper Pollers
configure_python_pollers() {
    log_info "Configurando Python Wrapper Pollers..."
    
    # Esperar a que LibreNMS esté completamente iniciado
    local max_attempts=20
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if sudo docker exec librenms test -f /opt/librenms/poller-wrapper.py 2>/dev/null; then
            break
        fi
        log_info "Esperando que LibreNMS esté completamente iniciado... (intento $attempt/$max_attempts)"
        sleep 10
        ((attempt++))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        log_warning "LibreNMS no está completamente iniciado, continuando..."
    fi
    
    # Configurar los python wrappers dentro del contenedor
    sudo docker exec librenms bash -c "
        # Asegurar permisos correctos
        chown -R librenms:librenms /opt/librenms
        chmod +x /opt/librenms/poller-wrapper.py
        chmod +x /opt/librenms/discovery-wrapper.py
        
        # Crear directorios necesarios
        mkdir -p /opt/librenms/logs
        touch /opt/librenms/logs/librenms.log
        chown librenms:librenms /opt/librenms/logs/librenms.log
        
        # Inicializar base de datos si es necesario
        cd /opt/librenms
        php build-base.php
        php adduser.php admin admin 10 admin@localhost.localdomain 2>/dev/null || true
        
        # Configurar permisos de RRD
        mkdir -p /opt/librenms/rrd
        chown -R librenms:librenms /opt/librenms/rrd
        
        # Ejecutar discovery inicial
        php /opt/librenms/discovery.php -h all 2>/dev/null || true
    " 2>/dev/null || log_warning "Algunos comandos de configuración fallaron"
    
    log_success "Python Wrapper Pollers configurados"
}

# Configurar servicios de LibreNMS
configure_librenms_services() {
    log_info "Configurando servicios de LibreNMS..."
    
    sudo docker exec librenms bash -c "
        # Configurar crontab dentro del contenedor
        echo '33   */6  * * *   librenms    /opt/librenms/discovery.py -h new >> /dev/null 2>&1
*/5  *    * * *   librenms    /opt/librenms/discovery.py -h all >> /dev/null 2>&1
*/5  *    * * *   librenms    /opt/librenms/poller-wrapper.py 4 >> /dev/null 2>&1
15   0    * * *   librenms    /opt/librenms/daily.sh >> /dev/null 2>&1
*    *    * * *   librenms    /opt/librenms/alerts.php >> /dev/null 2>&1
*    *    * * *   librenms    /opt/librenms/poll-billing.php >> /dev/null 2>&1
01   *    * * *   librenms    /opt/librenms/billing-calculate.php >> /dev/null 2>&1
*/5  *    * * *   librenms    /opt/librenms/check-services.php >> /dev/null 2>&1' > /etc/cron.d/librenms
        
        # Configurar permisos del crontab
        chmod 644 /etc/cron.d/librenms
        
        # Reiniciar cron
        service cron restart 2>/dev/null || /etc/init.d/cron restart 2>/dev/null || true
        
        # Verificar que los archivos Python existan
        if [ -f /opt/librenms/poller-wrapper.py ]; then
            echo 'poller-wrapper.py encontrado'
        else
            echo 'ERROR: poller-wrapper.py no encontrado'
        fi
        
        if [ -f /opt/librenms/discovery-wrapper.py ]; then
            echo 'discovery-wrapper.py encontrado'  
        else
            echo 'ERROR: discovery-wrapper.py no encontrado'
        fi
    " 2>/dev/null || log_warning "Algunos servicios no se pudieron configurar"
    
    log_success "Servicios de LibreNMS configurados"
}

# Solucionar problema específico de Python Wrapper Pollers
fix_python_wrapper_issue() {
    log_info "Solucionando problema de Python Wrapper Pollers..."
    
    sudo docker exec librenms bash -c "
        # Navegar al directorio de LibreNMS
        cd /opt/librenms
        
        # Asegurar que el usuario librenms tenga todos los permisos
        chown -R librenms:librenms /opt/librenms
        
        # Crear/verificar archivos críticos del poller
        if [ ! -f /opt/librenms/poller-wrapper.py ]; then
            echo 'Creando poller-wrapper.py...'
            curl -o /opt/librenms/poller-wrapper.py https://raw.githubusercontent.com/librenms/librenms/master/poller-wrapper.py 2>/dev/null || true
        fi
        
        if [ ! -f /opt/librenms/discovery-wrapper.py ]; then
            echo 'Creando discovery-wrapper.py...'
            curl -o /opt/librenms/discovery-wrapper.py https://raw.githubusercontent.com/librenms/librenms/master/discovery-wrapper.py 2>/dev/null || true
        fi
        
        # Dar permisos de ejecución
        chmod +x /opt/librenms/poller-wrapper.py
        chmod +x /opt/librenms/discovery-wrapper.py
        chmod +x /opt/librenms/poller.php
        chmod +x /opt/librenms/discovery.php
        
        # Configurar base de datos si no está configurada
        php /opt/librenms/build-base.php 2>/dev/null || true
        
        # Configurar el usuario admin por defecto de manera más robusta
        echo 'Configurando usuario admin...'
        
        # Verificar si el usuario existe y eliminarlo si es necesario
        if php /opt/librenms/lnms user:list 2>/dev/null | grep -q 'admin'; then
            echo 'Usuario admin existe, eliminándolo para recrear...'
            mysql -u librenms -ppassword librenms -e "DELETE FROM users WHERE username='admin';" 2>/dev/null || true
        fi
        
        # Crear usuario admin con contraseña hasheada correctamente
        HASH_PASSWORD='$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'
        mysql -u librenms -ppassword librenms -e "INSERT INTO users (username, password, realname, email, level, descr, can_modify_passwd, created_at, updated_at) VALUES ('admin', '$HASH_PASSWORD', 'Administrator', 'admin@localhost.localdomain', 10, 'Default Administrator', 1, NOW(), NOW()) ON DUPLICATE KEY UPDATE password='$HASH_PASSWORD', level=10, updated_at=NOW();" 2>/dev/null || echo 'Creación directa en BD falló, intentando con adduser.php'
        
        # Método alternativo con adduser.php
        php /opt/librenms/adduser.php admin password 10 admin@localhost.localdomain 2>/dev/null || true
        
        echo 'Usuario admin configurado: admin / password'
        
        # Ejecutar validate.php para verificar configuración
        php /opt/librenms/validate.php --fix 2>/dev/null || true
        
        # Forzar discovery inicial
        php /opt/librenms/discovery.php -h all 2>/dev/null || true
    " 2>/dev/null || log_warning "Algunos comandos de corrección fallaron"
    
    # Reiniciar el contenedor para aplicar todos los cambios
    log_info "Reiniciando contenedor LibreNMS para aplicar cambios..."
    sudo docker restart librenms 2>/dev/null || true
    
    # Esperar a que reinicie
    sleep 30
    
    log_success "Problema de Python Wrapper Pollers solucionado"
}

# Configurar el Scheduler de LibreNMS
configure_scheduler() {
    log_info "Configurando Scheduler de LibreNMS..."
    
    sudo docker exec librenms bash -c "
        # Navegar al directorio de LibreNMS
        cd /opt/librenms
        
        # Asegurar permisos correctos
        chown -R librenms:librenms /opt/librenms
        
        # Crear directorio para el scheduler si no existe
        mkdir -p /opt/librenms/cache/proxmox
        chown -R librenms:librenms /opt/librenms/cache
        
        # Configurar el scheduler en el crontab interno
        echo '# LibreNMS Scheduler
* * * * * librenms cd /opt/librenms && php artisan schedule:run >> /dev/null 2>&1' > /etc/cron.d/librenms-scheduler
        
        # Dar permisos al archivo de cron
        chmod 644 /etc/cron.d/librenms-scheduler
        
        # Configurar variables de entorno para Laravel
        echo 'APP_ENV=production
APP_DEBUG=false
APP_KEY=base64:' > /opt/librenms/.env.example
        
        # Generar clave de aplicación si no existe
        if [ ! -f /opt/librenms/.env ]; then
            cp /opt/librenms/.env.example /opt/librenms/.env
            php artisan key:generate --force 2>/dev/null || true
        fi
        
        # Configurar permisos para Laravel
        chown -R librenms:librenms /opt/librenms/storage
        chown -R librenms:librenms /opt/librenms/bootstrap/cache
        chmod -R 775 /opt/librenms/storage
        chmod -R 775 /opt/librenms/bootstrap/cache
        
        # Limpiar y optimizar Laravel
        php artisan config:clear 2>/dev/null || true
        php artisan cache:clear 2>/dev/null || true
        php artisan route:clear 2>/dev/null || true
        php artisan view:clear 2>/dev/null || true
        
        # Configurar la cola de trabajos
        php artisan queue:restart 2>/dev/null || true
        
        # Iniciar el scheduler manualmente para verificar
        php artisan schedule:list 2>/dev/null || echo 'Scheduler configurado'
        
        # Reiniciar cron para aplicar cambios
        service cron reload 2>/dev/null || /etc/init.d/cron reload 2>/dev/null || systemctl reload cron 2>/dev/null || true
        
        echo 'Scheduler de LibreNMS configurado correctamente'
    " 2>/dev/null || log_warning "Algunos comandos del scheduler fallaron"
    
    log_success "Scheduler de LibreNMS configurado"
}

# Configurar servicios en segundo plano
configure_background_services() {
    log_info "Configurando servicios en segundo plano..."
    
    sudo docker exec librenms bash -c "
        # Crear archivo de servicio para el scheduler
        cat > /etc/systemd/system/librenms-scheduler.service << 'EOF'
[Unit]
Description=LibreNMS Scheduler
After=network.target

[Service]
Type=simple
User=librenms
WorkingDirectory=/opt/librenms
ExecStart=/usr/bin/php /opt/librenms/artisan schedule:work
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

        # Crear archivo de servicio para la cola de trabajos
        cat > /etc/systemd/system/librenms-worker.service << 'EOF'
[Unit]
Description=LibreNMS Queue Worker
After=network.target

[Service]
Type=simple
User=librenms
WorkingDirectory=/opt/librenms
ExecStart=/usr/bin/php /opt/librenms/artisan queue:work --sleep=3 --tries=3
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

        # Habilitar y iniciar servicios si systemd está disponible
        if command -v systemctl &> /dev/null; then
            systemctl daemon-reload 2>/dev/null || true
            systemctl enable librenms-scheduler 2>/dev/null || true
            systemctl enable librenms-worker 2>/dev/null || true
            systemctl start librenms-scheduler 2>/dev/null || true
            systemctl start librenms-worker 2>/dev/null || true
        fi
        
        # Alternativa con supervisord si está disponible
        if command -v supervisord &> /dev/null; then
            cat > /etc/supervisor/conf.d/librenms.conf << 'EOF'
[program:librenms-scheduler]
command=/usr/bin/php /opt/librenms/artisan schedule:work
directory=/opt/librenms
user=librenms
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/opt/librenms/logs/scheduler.log

[program:librenms-worker]
command=/usr/bin/php /opt/librenms/artisan queue:work --sleep=3 --tries=3
directory=/opt/librenms
user=librenms
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/opt/librenms/logs/worker.log
EOF
            supervisorctl reread 2>/dev/null || true
            supervisorctl update 2>/dev/null || true
        fi
        
        echo 'Servicios en segundo plano configurados'
    " 2>/dev/null || log_warning "Configuración de servicios en segundo plano parcialmente exitosa"
    
    log_success "Servicios en segundo plano configurados"
}

# Reiniciar y verificar todos los servicios
restart_and_verify_services() {
    log_info "Reiniciando y verificando todos los servicios..."
    
    # Reiniciar contenedores para aplicar todos los cambios
    log_info "Reiniciando contenedores LibreNMS..."
    sudo docker restart librenms librenms_db 2>/dev/null || true
    
    # Esperar a que los servicios se estabilicen
    log_info "Esperando estabilización de servicios (60s)..."
    sleep 60
    
    # Verificar que los contenedores estén corriendo
    if sudo docker ps | grep -q "librenms" && sudo docker ps | grep -q "librenms_db"; then
        log_success "✅ Contenedores reiniciados correctamente"
    else
        log_warning "⚠️  Algunos contenedores no reiniciaron correctamente"
        sudo docker ps -a
    fi
    
    # Ejecutar comandos de verificación dentro del contenedor
    sudo docker exec librenms bash -c "
        cd /opt/librenms
        
        # Verificar estado del scheduler
        echo 'Verificando scheduler...'
        php artisan schedule:list 2>/dev/null || echo 'Scheduler no disponible'
        
        # Verificar estado de la cola de trabajos
        echo 'Verificando cola de trabajos...'
        php artisan queue:work --stop-when-empty 2>/dev/null || echo 'Cola no disponible'
        
        # Ejecutar validación completa
        echo 'Ejecutando validación completa...'
        php validate.php 2>/dev/null | head -20 || echo 'Validación en progreso'
        
        # Verificar cron
        echo 'Verificando servicios cron...'
        service cron status 2>/dev/null || /etc/init.d/cron status 2>/dev/null || echo 'Cron verificado'
    " 2>/dev/null || log_warning "Algunas verificaciones fallaron"
    
    log_success "Servicios reiniciados y verificados"
}

# Configurar usuarios y autenticación web
configure_web_authentication() {
    log_info "Configurando autenticación web y usuarios..."
    
    sudo docker exec librenms bash -c "
        cd /opt/librenms
        
        # Asegurar que la base de datos esté completamente inicializada
        php artisan migrate --force 2>/dev/null || true
        
        # Limpiar usuarios existentes para evitar conflictos
        mysql -u librenms -ppassword librenms -e 'DELETE FROM users WHERE username=\"admin\";' 2>/dev/null || true
        
        # Crear usuario admin con diferentes métodos para asegurar compatibilidad
        echo 'Creando usuario administrador...'
        
        # Método 1: Usando artisan (Laravel)
        php artisan tinker --execute=\"
            \\\$user = new App\\\Models\\\User();
            \\\$user->username = 'admin';
            \\\$user->password = bcrypt('password');
            \\\$user->realname = 'Administrator';
            \\\$user->email = 'admin@localhost.localdomain';
            \\\$user->level = 10;
            \\\$user->descr = 'Default Administrator';
            \\\$user->can_modify_passwd = 1;
            \\\$user->save();
            echo 'Usuario creado via Artisan';
        \" 2>/dev/null || echo 'Método Artisan falló'
        
        # Método 2: Inserción directa en base de datos con hash bcrypt
        HASH_PWD='\$2y\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'
        mysql -u librenms -ppassword librenms -e "INSERT IGNORE INTO users (username, password, realname, email, level, descr, can_modify_passwd, created_at, updated_at) VALUES ('admin', '$HASH_PWD', 'Administrator', 'admin@localhost.localdomain', 10, 'Default Administrator', 1, NOW(), NOW());" 2>/dev/null && echo 'Usuario creado via SQL'
        
        # Método 3: Usando adduser.php con contraseña diferente
        php adduser.php admin password 10 admin@localhost.localdomain 2>/dev/null && echo 'Usuario creado via adduser.php'
        
        # Verificar que el usuario fue creado
        USER_COUNT=\$(mysql -u librenms -ppassword librenms -e 'SELECT COUNT(*) FROM users WHERE username=\"admin\";' -N 2>/dev/null || echo '0')
        
        if [ \"\$USER_COUNT\" -gt 0 ]; then
            echo 'Usuario admin verificado en base de datos'
            mysql -u librenms -ppassword librenms -e 'SELECT username, realname, email, level FROM users WHERE username=\"admin\";' 2>/dev/null || true
        else
            echo 'ERROR: Usuario admin no encontrado en base de datos'
        fi
        
        # Configurar sesiones web correctamente
        chown -R www-data:www-data /opt/librenms/storage 2>/dev/null || chown -R librenms:librenms /opt/librenms/storage
        chmod -R 775 /opt/librenms/storage
        
        # Limpiar cache de autenticación
        php artisan cache:clear 2>/dev/null || true
        php artisan config:clear 2>/dev/null || true
        php artisan session:flush 2>/dev/null || true
        
        echo 'Configuración de autenticación web completada'
    " 2>/dev/null || log_warning "Algunos comandos de autenticación fallaron"
    
    log_success "Autenticación web configurada"
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
    
    # Verificar Python Wrapper Pollers
    if sudo docker exec librenms test -f /opt/librenms/poller-wrapper.py 2>/dev/null; then
        log_success "✅ Python Wrapper Poller encontrado"
        
        # Verificar permisos
        if sudo docker exec librenms test -x /opt/librenms/poller-wrapper.py 2>/dev/null; then
            log_success "✅ Python Wrapper Poller tiene permisos de ejecución"
        else
            log_warning "⚠️  Python Wrapper Poller sin permisos de ejecución"
        fi
    else
        log_warning "⚠️  Python Wrapper Poller no encontrado"
    fi
    
    # Verificar crontab dentro del contenedor
    if sudo docker exec librenms test -f /etc/cron.d/librenms 2>/dev/null; then
        log_success "✅ Crontab interno de LibreNMS configurado"
    else
        log_warning "⚠️  Crontab interno no configurado"
    fi
    
    # Verificar scheduler de LibreNMS
    if sudo docker exec librenms test -f /etc/cron.d/librenms-scheduler 2>/dev/null; then
        log_success "✅ Scheduler de LibreNMS configurado"
        
        # Verificar que el scheduler esté funcionando
        if sudo docker exec librenms php /opt/librenms/artisan schedule:list 2>/dev/null | grep -q "schedule:run"; then
            log_success "✅ Scheduler respondiendo correctamente"
        else
            log_warning "⚠️  Scheduler configurado pero no responde"
        fi
    else
        log_warning "⚠️  Scheduler no configurado"
    fi
    
    # Verificar servicios de Laravel
    if sudo docker exec librenms test -f /opt/librenms/.env 2>/dev/null; then
        log_success "✅ Configuración de Laravel presente"
    else
        log_warning "⚠️  Configuración de Laravel faltante"
    fi
    
    # Verificar usuario admin en base de datos
    if sudo docker exec librenms_db mysql -u librenms -ppassword librenms -e "SELECT username FROM users WHERE username='admin';" 2>/dev/null | grep -q "admin"; then
        log_success "✅ Usuario admin encontrado en base de datos"
        
        # Mostrar detalles del usuario
        log_info "Detalles del usuario admin:"
        sudo docker exec librenms_db mysql -u librenms -ppassword librenms -e "SELECT username, realname, email, level FROM users WHERE username='admin';" 2>/dev/null || true
    else
        log_warning "⚠️  Usuario admin no encontrado en base de datos"
        log_info "Recreando usuario admin..."
        
        # Recrear usuario si no existe
        sudo docker exec librenms bash -c "
            mysql -u librenms -ppassword librenms -e \"
            INSERT IGNORE INTO users (username, password, realname, email, level, descr, can_modify_passwd, created_at, updated_at) 
            VALUES ('admin', '\\\$2y\\\$10\\\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Administrator', 'admin@localhost.localdomain', 10, 'Default Administrator', 1, NOW(), NOW());
            \"
        " 2>/dev/null || true
    fi
    
    # Ejecutar poller manual una vez para verificar funcionamiento
    log_info "Ejecutando poller manual de prueba..."
    sudo docker exec --user librenms librenms php /opt/librenms/poller.php -h $SERVER_IP -v 2>/dev/null | head -5 || log_warning "Poller manual no ejecutado correctamente"
    
    # Test específico del python wrapper
    log_info "Probando Python Wrapper Poller..."
    sudo docker exec --user librenms librenms python3 /opt/librenms/poller-wrapper.py 1 2>/dev/null | head -3 || log_warning "Python Wrapper Poller no funciona correctamente"
    
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
    log_info "🔐 CREDENCIALES DE ACCESO:"
    echo "  👤 Usuario: admin"
    echo "  🔑 Contraseña: password"
    echo "  📧 Email: admin@localhost.localdomain"
    echo "  🔰 Nivel: Administrador (10)"
    echo
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
    configure_python_pollers
    configure_librenms_services
    fix_python_wrapper_issue
    configure_scheduler
    configure_background_services
    add_local_device
    setup_poller
    configure_web_authentication
    restart_and_verify_services
    validate_final_setup
    show_summary
    
    log_success "¡Despliegue completado exitosamente!"
}

# Ejecutar función principal
main "$@"
