# HTTPS Deployment Guide for FRED MCP Server in Development Environment

This guide helps you deploy the FRED MCP server with HTTPS using Docker, Nginx as reverse proxy and SSL certificates.

## Requirements

- Docker and Docker Compose installed
- Configured domain (for Let's Encrypt in production)
- FRED API key (get it at https://fred.stlouisfed.org/docs/api/api_key.html)

## Quick Setup

### 1. Configure Environment Variables

```bash
# Copy example file
cp .env.example .env

# Edit with your values
nano .env
```

### 2. Local Development (Self-signed Certificates)

```bash
# Generate self-signed certificates
./scripts/setup-ssl.sh self-signed

# Start services
docker-compose up -d

# Verify it works
curl -k https://localhost/health
```

### 3. Production (Let's Encrypt)

```bash
# IMPORTANT: Make sure your domain points to your server

# Setup Let's Encrypt
./scripts/setup-ssl.sh letsencrypt your-domain.com your-email@example.com

# Services are automatically restarted with SSL
```

## API Endpoints

Once deployed, your server will expose these endpoints:

### General Information
- `GET /` - API information
- `GET /health` - Server status

#### Testing the MCP Server over HTTP

**List available tools:**
```bash
curl -k -X POST https://localhost/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}'
```

**Search for unemployment data:**
```bash
curl -k -X POST https://localhost/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"fred_search","arguments":{"search_text":"unemployment","limit":5}},"id":2}'
```

**Get unemployment rate data:**
```bash
curl -k -X POST https://localhost/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"fred_get_series","arguments":{"series_id":"UNRATE","limit":12}},"id":3}'
```

**Browse economic categories:**
```bash
curl -k -X POST https://localhost/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"fred_browse","arguments":{"browse_type":"categories"}},"id":4}'
```

**Get US GDP data (percent change):**
```bash
curl -k -X POST https://localhost/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"fred_get_series","arguments":{"series_id":"GDP","limit":20,"units":"pch"}},"id":5}'
```

#### Using with Postman

1. **Method**: POST
2. **URL**: `https://localhost/mcp`
3. **Headers**:
   - `Content-Type: application/json`
   - `Accept: application/json, text/event-stream`
4. **Body** (raw JSON): Use any of the JSON-RPC requests above
5. **Settings**: Disable SSL certificate verification

## Deployment Architecture

```
Internet
    ↓
[Nginx (Port 80/443)]
    ↓ Reverse Proxy
[FRED HTTP Server (Port 3000)]
    ↓ API Calls
[FRED API (fred.stlouisfed.org)]
```

### Components

1. **Nginx**: For development environment - Reverse proxy with SSL/TLS, rate limiting and compression
2. **FRED Server**: HTTP API that exposes MCP tools as REST endpoints
3. **Certbot**: Automatic generation of Let's Encrypt certificates

## Certificate Management

### Automatic Renewal (Let's Encrypt)

Certificates are automatically renewed every 12 hours:

```bash
# Check certificate status
docker-compose exec certbot certbot certificates

# Manually renew if necessary
docker-compose exec certbot certbot renew
```

### Custom Certificates

If you have your own certificates:

```bash
# Copy certificates to the correct directory
cp your-certificate.pem nginx/ssl/live/your-domain.com/fullchain.pem
cp your-private-key.pem nginx/ssl/live/your-domain.com/privkey.pem

# Restart nginx
docker-compose restart nginx
```

## Security

### Rate Limiting

Automatically configured in Nginx:
- General endpoints: 10 req/s per IP
- Search endpoints: 5 req/s per IP

### Security Headers

- HSTS enabled
- X-Frame-Options: DENY
- X-Content-Type-Options: nosniff
- XSS Protection enabled

### Monitoring

```bash
# View nginx logs
docker-compose logs nginx

# View FRED server logs
docker-compose logs fred-server

# Monitor in real time
docker-compose logs -f
```

## Troubleshooting

### Server not responding

```bash
# Check container status
docker-compose ps

# Check logs
docker-compose logs

# Restart services
docker-compose restart
```

### SSL certificate errors

```bash
# Check certificates
ls -la nginx/ssl/live/

# Regenerate self-signed certificates
./scripts/setup-ssl.sh self-signed

# Check nginx configuration
docker-compose exec nginx nginx -t
```

### Error "FRED_API_KEY not set"

```bash
# Check environment variables
cat .env

# Make sure FRED_API_KEY is configured
echo "FRED_API_KEY=your_api_key_here" >> .env

# Restart services
docker-compose restart
```

## Scalability

### Multiple Instances

For higher capacity, modify `docker-compose.yml`:

```yaml
fred-server:
  # ... existing configuration ...
  deploy:
    replicas: 3
```

### Load Balancer

For high availability, add more instances to nginx upstream:

```nginx
upstream fred_backend {
    server fred-server-1:3000;
    server fred-server-2:3000;
    server fred-server-3:3000;
    keepalive 32;
}
```

## Backup

### Configuration

```bash
# Backup configuration
tar -czf fred-backup-$(date +%Y%m%d).tar.gz \
  docker-compose.yml nginx/ .env scripts/
```

### SSL Certificates

```bash
# Backup certificates
tar -czf ssl-backup-$(date +%Y%m%d).tar.gz nginx/ssl/
```

## Support

For specific issues:

1. Check logs: `docker-compose logs`
2. Review configuration: `.env` file and `nginx/nginx.conf`
3. Validate connectivity: `curl https://your-domain.com/health`
4. Consult FRED API documentation: https://fred.stlouisfed.org/docs/api/

---

Your FRED MCP server is now available over HTTPS! 🚀
