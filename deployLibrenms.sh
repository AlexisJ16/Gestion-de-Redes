#!/bin/bash
set -e

echo "=== 🔍 Verificando dependencias ==="
sudo apt update -y

# Instalar Git si no está
if ! command -v git &> /dev/null; then
  echo "➡️ Instalando git..."
  sudo apt install -y git
else
  echo "✅ Git ya está instalado."
fi

# Instalar Docker si no está
if ! command -v docker &> /dev/null; then
  echo "➡️ Instalando Docker..."
  sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt update -y
  sudo apt install -y docker-ce docker-ce-cli containerd.io
  sudo systemctl enable docker
  sudo systemctl start docker
else
  echo "✅ Docker ya está instalado."
fi

# Instalar Docker Compose si no está
if ! command -v docker-compose &> /dev/null; then
  echo "➡️ Instalando docker-compose..."
  sudo apt install -y docker-compose
else
  echo "✅ docker-compose ya está instalado."
fi

echo "=== 📥 Clonando repositorio ==="
if [ ! -d "Gestion-de-Redes" ]; then
  git clone https://github.com/AlexisJ16/Gestion-de-Redes.git
fi

cd Gestion-de-Redes

echo "=== 🚀 Levantando LibreNMS con Docker Compose ==="
if command -v docker compose &> /dev/null; then
  sudo docker compose up -d
else
  sudo docker-compose up -d
fi

echo "=== ✅ Verificando contenedores corriendo ==="
sudo docker ps

echo "=== 🌐 Verificando red ==="
hostname -I

echo "================================================="
echo " LibreNMS ya está en ejecución 🎉"
echo " Accede desde tu navegador en: http://<IP-del-servidor>:8000"
echo "================================================="
