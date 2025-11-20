# GUIA DE DESPLIEGUE DOCKER LIBRENMS

Created: September 1, 2025 3:10 PM
Class: PDG2
: No

### 1. Instala `git` (si no lo tienes en el servidor)

```bash
sudo apt update && sudo apt install -y git
```

### 2. Clonar el repositorio

```bash
docker ps

```

```bash
git clone https://github.com/AlexisJ16/Gestion-de-Redes.git
```

### Entra en la carpeta del proyecto

```bash
cd Gestion-de-Redes
```

### Levanta LibreNMS con Docker Compose

```bash
sudo docker compose up -d
# o si es una version mas antigua
sudo docker-compose up -d
```

### Verificar que todo está corriendo

```bash
sudo docker ps
```

### Verifica que **Docker** está instalado y corriendo

```bash
docker --version
systemctl status docker
```

Si no está corriendo, levántalo:

```bash
sudo systemctl start docker
sudo systemctl enable docker
```

Si no funciona Instala **docker-compose**:

```bash
sudo apt update
sudo apt install docker-compose -y
docker compose ps
```

**Abrir en el navegador http://<IP-del-servidor>:8000
(o el puerto especificado en el docker)
Para saber la IP del servidor host (máquina donde está Docker corriendo)**

```bash
hostname -I
```