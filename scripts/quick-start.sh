#!/bin/bash

# Script de inicio rápido para FRED MCP Server con HTTPS
# Configura todo automáticamente para desarrollo local

set -e

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "🚀 FRED MCP Server - Configuración Rápida HTTPS"
echo "================================================="
echo -e "${NC}"

# Verificar que estamos en el directorio correcto
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}❌ Error: Este script debe ejecutarse desde el directorio raíz del proyecto${NC}"
    exit 1
fi

# Verificar que Docker está corriendo
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}❌ Error: Docker no está corriendo. Por favor inicia Docker primero.${NC}"
    exit 1
fi

# Paso 1: Configurar variables de entorno
echo -e "${YELLOW}📝 Paso 1: Configuración de variables de entorno${NC}"
if [ ! -f ".env" ]; then
    if [ ! -f ".env.example" ]; then
        echo "❌ Archivo .env.example no encontrado. Creando..."
        cat > .env.example << EOF
# FRED API Configuration
FRED_API_KEY=your_fred_api_key_here

# Server Configuration
PORT=3000
NODE_ENV=production

# SSL/Domain Configuration
DOMAIN=localhost
EMAIL=admin@localhost
EOF
    fi
    
    cp .env.example .env
    echo "✅ Archivo .env creado desde .env.example"
    echo ""
    echo -e "${YELLOW}⚠️  IMPORTANTE: Edita el archivo .env y configura tu FRED_API_KEY${NC}"
    echo "   Obtén tu API key en: https://fred.stlouisfed.org/docs/api/api_key.html"
    echo ""
    read -p "Presiona Enter cuando hayas configurado tu API key en .env..."
else
    echo "✅ Archivo .env ya existe"
fi

# Verificar que FRED_API_KEY está configurado
source .env
if [ -z "$FRED_API_KEY" ] || [ "$FRED_API_KEY" = "your_fred_api_key_here" ]; then
    echo -e "${YELLOW}⚠️  FRED_API_KEY no configurado. El servidor puede fallar.${NC}"
    echo "   Configúralo en el archivo .env antes de continuar."
fi

# Paso 2: Generar certificados SSL para desarrollo
echo -e "${YELLOW}🔐 Paso 2: Generando certificados SSL para desarrollo local${NC}"
if [ ! -d "nginx/ssl/live/localhost" ]; then
    ./scripts/setup-ssl.sh self-signed localhost
    echo "✅ Certificados SSL generados para localhost"
else
    echo "✅ Certificados SSL ya existen"
fi

# Paso 3: Construir e iniciar servicios
echo -e "${YELLOW}🐳 Paso 3: Construyendo e iniciando servicios Docker${NC}"
echo "Esto puede tomar unos minutos la primera vez..."

# Construir imagen
docker-compose build

# Iniciar servicios
docker-compose up -d

# Esperar que los servicios estén listos
echo -e "${YELLOW}⏳ Esperando que los servicios estén listos...${NC}"
sleep 10

# Verificar estado de los servicios
echo -e "${YELLOW}🔍 Verificando estado de los servicios${NC}"
docker-compose ps

# Probar conectividad
echo -e "${YELLOW}🧪 Probando conectividad...${NC}"
if curl -k -s https://localhost/health >/dev/null; then
    echo "✅ Servidor HTTPS funcionando correctamente"
else
    echo "❌ Error: No se puede conectar al servidor HTTPS"
    echo "Verificando logs..."
    docker-compose logs --tail=20
    exit 1
fi

# Mostrar información final
echo -e "${GREEN}"
echo "🎉 ¡FRED MCP Server configurado exitosamente!"
echo "=============================================="
echo -e "${NC}"
echo "Endpoints disponibles:"
echo "  🌐 API Info:        https://localhost/"
echo "  ❤️  Health Check:   https://localhost/health"
echo "  🔍 Buscar series:   POST https://localhost/api/search"
echo "  🗂️  Explorar datos:  POST https://localhost/api/browse"
echo "  📊 Obtener series:  GET https://localhost/api/series/{SERIES_ID}"
echo ""
echo "Ejemplos de uso:"
echo "  curl -k https://localhost/health"
echo "  curl -k -X POST https://localhost/api/search -H 'Content-Type: application/json' -d '{\"search_text\":\"unemployment\"}'"
echo "  curl -k 'https://localhost/api/series/UNRATE?limit=12'"
echo ""
echo "Comandos útiles:"
echo "  docker-compose logs     # Ver logs"
echo "  docker-compose stop     # Detener servicios"
echo "  docker-compose start    # Iniciar servicios"
echo "  docker-compose down     # Detener y eliminar contenedores"
echo ""
echo -e "${YELLOW}⚠️  Nota: Los certificados son autofirmados para desarrollo.${NC}"
echo "   Tu navegador mostrará una advertencia de seguridad (usa la flag -k con curl)."
echo ""
echo "📖 Para más información, consulta DEPLOYMENT.md"
