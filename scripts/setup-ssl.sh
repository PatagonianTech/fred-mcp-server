#!/bin/bash

# Script para configurar certificados SSL para FRED MCP Server
# Soporta tanto Let's Encrypt como certificados autofirmados

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funciones de utilidad
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar que estamos en el directorio correcto
if [ ! -f "docker-compose.yml" ]; then
    log_error "Este script debe ejecutarse desde el directorio raíz del proyecto"
    exit 1
fi

# Función para generar certificados autofirmados (desarrollo)
generate_self_signed() {
    local domain=${1:-localhost}
    
    log_info "Generando certificados autofirmados para $domain..."
    
    # Crear directorio para certificados
    mkdir -p nginx/ssl/live/$domain
    
    # Generar clave privada
    openssl genrsa -out nginx/ssl/live/$domain/privkey.pem 2048
    
    # Generar certificado autofirmado
    openssl req -new -x509 -key nginx/ssl/live/$domain/privkey.pem \
        -out nginx/ssl/live/$domain/fullchain.pem \
        -days 365 \
        -subj "/C=US/ST=Local/L=Local/O=FRED-MCP-Dev/CN=$domain"
    
    # Crear enlace simbólico para chain.pem
    ln -sf fullchain.pem nginx/ssl/live/$domain/chain.pem
    
    log_info "Certificados autofirmados generados exitosamente"
    log_warn "ADVERTENCIA: Estos certificados son solo para desarrollo"
    log_warn "Los navegadores mostrarán una advertencia de seguridad"
}

# Función para configurar Let's Encrypt
setup_letsencrypt() {
    local domain=$1
    local email=$2
    
    if [ -z "$domain" ] || [ -z "$email" ]; then
        log_error "Dominio y email son requeridos para Let's Encrypt"
        echo "Uso: $0 letsencrypt <dominio> <email>"
        exit 1
    fi
    
    log_info "Configurando Let's Encrypt para $domain..."
    
    # Crear directorio para certificados
    mkdir -p nginx/ssl/live/$domain
    mkdir -p nginx/www
    
    # Iniciar nginx temporal para validación
    log_info "Iniciando nginx temporal para validación..."
    docker-compose up -d nginx
    
    # Esperar que nginx esté listo
    sleep 10
    
    # Generar certificados con certbot
    log_info "Generando certificados con Let's Encrypt..."
    docker run --rm -v "$PWD/nginx/ssl:/etc/letsencrypt" \
        -v "$PWD/nginx/www:/var/www/certbot" \
        certbot/certbot certonly --webroot \
        --webroot-path=/var/www/certbot \
        --email $email \
        --agree-tos \
        --no-eff-email \
        -d $domain
    
    if [ $? -eq 0 ]; then
        log_info "Certificados Let's Encrypt generados exitosamente"
        log_info "Actualizando configuración de nginx..."
        
        # Actualizar nginx.conf para habilitar SSL
        sed -i.bak 's/# ssl_/ssl_/g' nginx/nginx.conf
        sed -i.bak "s/your-domain.com/$domain/g" nginx/nginx.conf
        sed -i.bak 's/# server {/server {/g' nginx/nginx.conf
        sed -i.bak 's/# }/}/g' nginx/nginx.conf
        sed -i.bak 's/# add_header/add_header/g' nginx/nginx.conf
        sed -i.bak 's/# location/location/g' nginx/nginx.conf
        sed -i.bak 's/# return 301/return 301/g' nginx/nginx.conf
        
        log_info "Reiniciando servicios con SSL habilitado..."
        docker-compose down
        docker-compose up -d
        
        log_info "¡SSL configurado exitosamente!"
        log_info "Tu sitio ahora está disponible en https://$domain"
    else
        log_error "Error al generar certificados Let's Encrypt"
        exit 1
    fi
}

# Función para mostrar ayuda
show_help() {
    echo "Script de configuración SSL para FRED MCP Server"
    echo ""
    echo "Uso:"
    echo "  $0 self-signed [dominio]     # Generar certificados autofirmados (desarrollo)"
    echo "  $0 letsencrypt <dominio> <email>  # Configurar Let's Encrypt (producción)"
    echo "  $0 help                      # Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0 self-signed                     # Certificados para localhost"
    echo "  $0 self-signed fred.local          # Certificados para fred.local"
    echo "  $0 letsencrypt fred.example.com admin@example.com"
    echo ""
    echo "Notas:"
    echo "  - Para desarrollo local usa 'self-signed'"
    echo "  - Para producción usa 'letsencrypt' con un dominio real"
    echo "  - Asegúrate de que el dominio apunte a tu servidor antes de usar Let's Encrypt"
}

# Main script
case "${1:-help}" in
    "self-signed")
        generate_self_signed "${2:-localhost}"
        ;;
    "letsencrypt")
        setup_letsencrypt "$2" "$3"
        ;;
    "help"|*)
        show_help
        ;;
esac
