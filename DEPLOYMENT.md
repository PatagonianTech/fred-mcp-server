# Guía de Despliegue HTTPS para FRED MCP Server

Esta guía te ayuda a desplegar el servidor FRED MCP con HTTPS usando Docker, Nginx como proxy reverso y certificados SSL.

## Requisitos

- Docker y Docker Compose instalados
- Dominio configurado (para Let's Encrypt en producción)
- API key de FRED (obtener en https://fred.stlouisfed.org/docs/api/api_key.html)

## Configuración Rápida

### 1. Configurar Variables de Entorno

```bash
# Copiar archivo de ejemplo
cp .env.example .env

# Editar con tus valores
nano .env
```

### 2. Desarrollo Local (Certificados Autofirmados)

```bash
# Generar certificados autofirmados
./scripts/setup-ssl.sh self-signed

# Iniciar servicios
docker-compose up -d

# Verificar que funciona
curl -k https://localhost/health
```

### 3. Producción (Let's Encrypt)

```bash
# IMPORTANTE: Asegúrate de que tu dominio apunte a tu servidor

# Configurar Let's Encrypt
./scripts/setup-ssl.sh letsencrypt tu-dominio.com tu-email@ejemplo.com

# Los servicios se reinician automáticamente con SSL
```

## Endpoints de la API

Una vez desplegado, tu servidor expondrá estos endpoints:

### Información General
- `GET /` - Información de la API
- `GET /health` - Estado del servidor

### Explorar Datos de FRED
```bash
# Buscar series económicas
curl -X POST https://tu-dominio.com/api/search \\
  -H "Content-Type: application/json" \\
  -d '{"search_text": "unemployment rate"}'

# Navegar categorías
curl -X POST https://tu-dominio.com/api/browse \\
  -H "Content-Type: application/json" \\
  -d '{"browse_type": "categories"}'

# Obtener datos de una serie específica
curl "https://tu-dominio.com/api/series/UNRATE?limit=12"
```

### Ejemplos Completos

#### Buscar Series de Inflación
```bash
curl -X POST https://tu-dominio.com/api/search \\
  -H "Content-Type: application/json" \\
  -d '{
    "search_text": "inflation",
    "tag_names": "usa",
    "limit": 10
  }'
```

#### Obtener PIB de EE.UU. (últimos 5 años)
```bash
curl "https://tu-dominio.com/api/series/GDP?observation_start=2019-01-01&units=pc1"
```

#### Explorar Series en una Categoría
```bash
curl -X POST https://tu-dominio.com/api/browse \\
  -H "Content-Type: application/json" \\
  -d '{
    "browse_type": "category_series",
    "category_id": 32991,
    "limit": 20
  }'
```

## Arquitectura del Despliegue

```
Internet
    ↓
[Nginx (Puerto 80/443)]
    ↓ Proxy Reverso
[FRED HTTP Server (Puerto 3000)]
    ↓ API Calls
[FRED API (fred.stlouisfed.org)]
```

### Componentes

1. **Nginx**: Proxy reverso con SSL/TLS, rate limiting y compresión
2. **FRED Server**: API HTTP que expone las herramientas MCP como endpoints REST
3. **Certbot**: Generación automática de certificados Let's Encrypt

## Gestión de Certificados

### Renovación Automática (Let's Encrypt)

Los certificados se renuevan automáticamente cada 12 horas:

```bash
# Verificar estado de certificados
docker-compose exec certbot certbot certificates

# Renovar manualmente si es necesario
docker-compose exec certbot certbot renew
```

### Certificados Personalizados

Si tienes certificados propios:

```bash
# Copiar certificados al directorio correcto
cp tu-certificado.pem nginx/ssl/live/tu-dominio.com/fullchain.pem
cp tu-clave-privada.pem nginx/ssl/live/tu-dominio.com/privkey.pem

# Reiniciar nginx
docker-compose restart nginx
```

## Seguridad

### Rate Limiting

Configurado automáticamente en Nginx:
- Endpoints generales: 10 req/s por IP
- Endpoints de búsqueda: 5 req/s por IP

### Headers de Seguridad

- HSTS habilitado
- X-Frame-Options: DENY
- X-Content-Type-Options: nosniff
- XSS Protection habilitado

### Monitoreo

```bash
# Ver logs de nginx
docker-compose logs nginx

# Ver logs del servidor FRED
docker-compose logs fred-server

# Monitorear en tiempo real
docker-compose logs -f
```

## Resolución de Problemas

### El servidor no responde

```bash
# Verificar estado de contenedores
docker-compose ps

# Verificar logs
docker-compose logs

# Reiniciar servicios
docker-compose restart
```

### Error de certificados SSL

```bash
# Verificar certificados
ls -la nginx/ssl/live/

# Regenerar certificados autofirmados
./scripts/setup-ssl.sh self-signed

# Verificar configuración nginx
docker-compose exec nginx nginx -t
```

### Error "FRED_API_KEY not set"

```bash
# Verificar variables de entorno
cat .env

# Asegúrate de que FRED_API_KEY está configurado
echo "FRED_API_KEY=tu_api_key_aqui" >> .env

# Reiniciar servicios
docker-compose restart
```

## Escalabilidad

### Múltiples Instancias

Para mayor capacidad, modifica `docker-compose.yml`:

```yaml
fred-server:
  # ... configuración existente ...
  deploy:
    replicas: 3
```

### Balanceador de Carga

Para alta disponibilidad, agrega más instancias al upstream de nginx:

```nginx
upstream fred_backend {
    server fred-server-1:3000;
    server fred-server-2:3000;
    server fred-server-3:3000;
    keepalive 32;
}
```

## Respaldo

### Configuración

```bash
# Respaldar configuración
tar -czf fred-backup-$(date +%Y%m%d).tar.gz \\
  docker-compose.yml nginx/ .env scripts/
```

### Certificados SSL

```bash
# Respaldar certificados
tar -czf ssl-backup-$(date +%Y%m%d).tar.gz nginx/ssl/
```

## Soporte

Para problemas específicos:

1. Verificar logs: `docker-compose logs`
2. Revisar configuración: archivo `.env` y `nginx/nginx.conf`
3. Validar conectividad: `curl https://tu-dominio.com/health`
4. Consultar documentación de FRED API: https://fred.stlouisfed.org/docs/api/

---

¡Tu servidor FRED MCP ahora está disponible por HTTPS! 🚀
