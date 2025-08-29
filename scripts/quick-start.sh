#!/bin/bash

# Quick start script for FRED MCP Server with HTTPS
# Automatically configures everything for local development

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "🚀 FRED MCP Server - Quick HTTPS Setup"
echo "======================================="
echo -e "${NC}"

# Verify we are in the correct directory
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}❌ Error: This script must be run from the project root directory${NC}"
    exit 1
fi

# Verify Docker is running
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}❌ Error: Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

# Step 1: Configure environment variables
echo -e "${YELLOW}📝 Step 1: Environment variables configuration${NC}"
if [ ! -f ".env" ]; then
    if [ ! -f ".env.example" ]; then
        echo "❌ .env.example file not found. Creating..."
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
    echo "✅ .env file created from .env.example"
    echo ""
    echo -e "${YELLOW}⚠️  IMPORTANT: Edit the .env file and configure your FRED_API_KEY${NC}"
    echo "   Get your API key at: https://fred.stlouisfed.org/docs/api/api_key.html"
    echo ""
    read -p "Press Enter when you have configured your API key in .env..."
else
    echo "✅ .env file already exists"
fi

# Verify FRED_API_KEY is configured
source .env
if [ -z "$FRED_API_KEY" ] || [ "$FRED_API_KEY" = "your_fred_api_key_here" ]; then
    echo -e "${YELLOW}⚠️  FRED_API_KEY not configured. Server may fail.${NC}"
    echo "   Configure it in the .env file before continuing."
fi

# Step 2: Generate SSL certificates for development
echo -e "${YELLOW}🔐 Step 2: Generating SSL certificates for local development${NC}"
if [ ! -d "nginx/ssl/live/localhost" ]; then
    ./scripts/setup-ssl.sh self-signed localhost
    echo "✅ SSL certificates generated for localhost"
else
    echo "✅ SSL certificates already exist"
fi

# Step 3: Build and start services
echo -e "${YELLOW}🐳 Step 3: Building and starting Docker services${NC}"
echo "This may take a few minutes the first time..."

# Build shared network
NETWORK_NAME="amar-network"

### Check if the network exists
if [ -z "$(docker network ls --filter name=^${NETWORK_NAME}$ --format="{{ .Name }}")" ]; then
    echo "Network '${NETWORK_NAME}' does not exist; creating it."
    docker network create "${NETWORK_NAME}"
else
    echo "Network '${NETWORK_NAME}' already exists."
fi

# Build image
docker-compose build

# Start services
docker-compose up -d

# Wait for services to be ready
echo -e "${YELLOW}⏳ Waiting for services to be ready...${NC}"
sleep 10

# Check services status
echo -e "${YELLOW}🔍 Checking services status${NC}"
docker-compose ps

# Test connectivity
echo -e "${YELLOW}🧪 Testing connectivity...${NC}"
if curl -k -s https://localhost/health >/dev/null; then
    echo "✅ HTTPS server working correctly"
else
    echo "❌ Error: Cannot connect to HTTPS server"
    echo "Checking logs..."
    docker-compose logs --tail=20
    exit 1
fi

# Show final information
echo -e "${GREEN}"
echo "🎉 FRED MCP Server configured successfully!"
echo "========================================="
echo -e "${NC}"
echo "Available endpoints:"
echo "  🌐 API Info:        https://localhost/"
echo "  ❤️  Health Check:   https://localhost/health"
echo "  🔍 Search series:   POST https://localhost/api/search"
echo "  🗂️  Browse data:     POST https://localhost/api/browse"
echo "  📊 Get series:      GET https://localhost/api/series/{SERIES_ID}"
echo ""
echo "Usage examples:"
echo "  curl -k https://localhost/health"
echo "  curl -k -X POST https://localhost/api/search -H 'Content-Type: application/json' -d '{\"search_text\":\"unemployment\"}'"
echo "  curl -k 'https://localhost/api/series/UNRATE?limit=12'"
echo ""
echo "Useful commands:"
echo "  docker-compose logs     # View logs"
echo "  docker-compose stop     # Stop services"
echo "  docker-compose start    # Start services"
echo "  docker-compose down     # Stop and remove containers"
echo ""
echo -e "${YELLOW}⚠️  Note: Certificates are self-signed for development.${NC}"
echo "   Your browser will show a security warning (use -k flag with curl)."
echo ""
echo "📖 For more information, check DEPLOYMENT.md"
