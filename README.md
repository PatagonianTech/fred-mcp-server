# Federal Reserve Economic Data MCP Server

[![smithery badge](https://smithery.ai/badge/@stefanoamorelli/fred-mcp-server)](https://smithery.ai/server/@stefanoamorelli/fred-mcp-server)
[![npm version](https://img.shields.io/npm/v/fred-mcp-server.svg)](https://www.npmjs.com/package/fred-mcp-server)
[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Tests](https://github.com/stefanoamorelli/fred-mcp-server/actions/workflows/test.yml/badge.svg)](https://github.com/stefanoamorelli/fred-mcp-server/actions/workflows/test.yml)

> [!IMPORTANT]
> *Disclaimer*: This open-source project is not affiliated with, sponsored by, or endorsed by the *Federal Reserve* or the *Federal Reserve Bank of St. Louis*. "FRED" is a registered trademark of the *Federal Reserve Bank of St. Louis*, used here for descriptive purposes only.

A Model Context Protocol (`MCP`) server providing universal access to all 800,000+ Federal Reserve Economic Data ([FRED®](https://fred.stlouisfed.org/)) time series through three powerful tools.

https://github.com/user-attachments/assets/66c7f3ad-7b0e-4930-b1c5-a675a7eb1e09

> [!TIP]
> If you use this project in your research or work, please cite it using the [CITATION.cff](CITATION.cff) file, or the APA format below:

`Amorelli, S. (2025). Federal Reserve Economic Data MCP (Model Context Protocol) Server [Computer software]. GitHub. https://github.com/stefanoamorelli/fred-mcp-server`


## Installation

### Option 1: MCP Server (Original)

#### Installing via Smithery

To install Federal Reserve Economic Data Server for Claude Desktop automatically via [Smithery](https://smithery.ai/server/@stefanoamorelli/fred-mcp-server):

```bash
npx -y @smithery/cli install @stefanoamorelli/fred-mcp-server --client claude
```

#### Manual Installation

1.  Clone the repository:
    ```bash
    git clone https://github.com/stefanoamorelli/fred-mcp-server.git
    cd fred-mcp-server
    ```
2.  Install dependencies:
    ```bash
    pnpm install
    ```
3.  Build the project:
    ```bash
    pnpm build
    ```

### Option 2: MCP Server over HTTPS (New! 🚀)

Deploy the MCP server accessible over HTTPS with Docker and Nginx:

```bash
# Quick start for development
./scripts/quick-start.sh

# Or step by step:
cp .env.example .env
# Edit .env with your FRED API key
./scripts/setup-ssl.sh self-signed
docker-compose up -d
```

Access your MCP server at `https://localhost/mcp`

**Features:**
- 🔒 HTTPS with SSL certificates (Let's Encrypt or self-signed)
- 🐳 Docker containerized deployment
- 🔄 Nginx reverse proxy with rate limiting
- 🔌 MCP server accessible over HTTP transport (JSON-RPC)
- 🔍 Health checks and monitoring
- 🌐 Compatible with web-based MCP clients

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

#### Testing Locally with ngrok

To expose your local MCP server publicly for testing:

```bash
# 1. Build and start the local MCP server
npm run build
npm run start:http

# 2. In another terminal, expose it with ngrok
ngrok http 3000
```

Then test with the ngrok URL:
```bash
# List tools
curl -X POST https://YOUR-NGROK-URL.ngrok.io/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}'

# Get US GDP data
curl -X POST https://YOUR-NGROK-URL.ngrok.io/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"fred_get_series","arguments":{"series_id":"GDP","limit":20,"units":"pch"}},"id":2}'
```

**Popular GDP Series IDs:**
- `GDP` - Gross Domestic Product (levels)
- `GDPC1` - Real GDP (chained dollars)  
- `GDPPOT` - Real Potential GDP
- Use `"units":"pc1"` for percent change from year ago

For complete deployment instructions, see [DEPLOYMENT.md](DEPLOYMENT.md).

### Option 3: MCP Through HTTP for production

For production environments, deploy the FRED MCP server as a containerized HTTP service using cloud services that handle load balancing and HTTPS certificates automatically.

#### Prerequisites

- FRED API key from [FRED website](https://fred.stlouisfed.org/docs/api/api_key.html)
- Access to a container registry (Docker Hub, Azure Container Registry, etc.)

#### Build and Push Container

```bash
# Build the production container
docker build -f Dockerfile.http -t fred-mcp-server:latest .

# Tag for your registry (example with Azure Container Registry)
docker tag fred-mcp-server:latest yourregistry.azurecr.io/fred-mcp-server:latest

# Push to registry
docker push yourregistry.azurecr.io/fred-mcp-server:latest
```

#### Deploy on Azure Container Apps

**Using Azure CLI:**

```bash
# Create resource group (if needed)
az group create --name fred-mcp-rg --location eastus

# Create container app environment
az containerapp env create \
  --name fred-mcp-env \
  --resource-group fred-mcp-rg \
  --location eastus

# Deploy the container app
az containerapp create \
  --name fred-mcp-server \
  --resource-group fred-mcp-rg \
  --environment fred-mcp-env \
  --image yourregistry.azurecr.io/fred-mcp-server:latest \
  --target-port 3000 \
  --ingress external \
  --env-vars FRED_API_KEY=your_api_key_here \
  --min-replicas 1 \
  --max-replicas 10 \
  --cpu 0.5 \
  --memory 1Gi
```

**Using ARM Template or Bicep:**

```json
{
  "type": "Microsoft.App/containerApps",
  "apiVersion": "2022-03-01",
  "name": "fred-mcp-server",
  "location": "[parameters('location')]",
  "properties": {
    "configuration": {
      "ingress": {
        "external": true,
        "targetPort": 3000,
        "allowInsecure": false
      }
    },
    "template": {
      "containers": [
        {
          "name": "fred-mcp-server",
          "image": "yourregistry.azurecr.io/fred-mcp-server:latest",
          "env": [
            {
              "name": "FRED_API_KEY",
              "secretRef": "fred-api-key"
            }
          ],
          "resources": {
            "cpu": 0.5,
            "memory": "1Gi"
          }
        }
      ],
      "scale": {
        "minReplicas": 1,
        "maxReplicas": 10
      }
    }
  }
}
```

#### Deploy on AWS ECS/Fargate

**Using AWS CLI:**

```bash
# Create ECS cluster
aws ecs create-cluster --cluster-name fred-mcp-cluster

# Create task definition
aws ecs register-task-definition \
  --family fred-mcp-task \
  --network-mode awsvpc \
  --requires-compatibilities FARGATE \
  --cpu 512 \
  --memory 1024 \
  --execution-role-arn arn:aws:iam::ACCOUNT:role/ecsTaskExecutionRole \
  --container-definitions '[
    {
      "name": "fred-mcp-server",
      "image": "your-account.dkr.ecr.region.amazonaws.com/fred-mcp-server:latest",
      "portMappings": [{"containerPort": 3000}],
      "environment": [{"name": "FRED_API_KEY", "value": "your_api_key_here"}],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/fred-mcp-server",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]'

# Create ALB and target group (replace with your VPC/subnet IDs)
# Then create ECS service
aws ecs create-service \
  --cluster fred-mcp-cluster \
  --service-name fred-mcp-service \
  --task-definition fred-mcp-task \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx],assignPublicIp=ENABLED}"
```

#### Deploy on Google Cloud Run

```bash
# Build and push to Google Container Registry
docker tag fred-mcp-server:latest gcr.io/your-project-id/fred-mcp-server:latest
docker push gcr.io/your-project-id/fred-mcp-server:latest

# Deploy to Cloud Run
gcloud run deploy fred-mcp-server \
  --image gcr.io/your-project-id/fred-mcp-server:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 3000 \
  --set-env-vars FRED_API_KEY=your_api_key_here \
  --min-instances 1 \
  --max-instances 10 \
  --memory 1Gi \
  --cpu 1
```

#### Health Check Configuration

All deployments should configure health checks using the built-in endpoint:

- **Health Check Path**: `/health`
- **Port**: `3000`
- **Protocol**: `HTTP`
- **Timeout**: `10s`
- **Interval**: `30s`

#### Environment Variables

Required environment variable:

- `FRED_API_KEY`: Your FRED API key

Optional environment variables:

- `NODE_ENV`: Set to `production`
- `PORT`: Port number (default: 3000)

#### Testing the Deployed Service

Once deployed, test your service endpoints:

```bash
# Replace YOUR_DOMAIN with your actual domain
DOMAIN="https://your-service-domain.com"

# Health check
curl $DOMAIN/health

# List tools
curl -X POST $DOMAIN/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}'

# Get GDP data
curl -X POST $DOMAIN/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"fred_get_series","arguments":{"series_id":"GDP","limit":10}},"id":2}'
```

#### Security Considerations

- Store your FRED API key as a secret in your cloud provider's secret management service
- Enable HTTPS at the load balancer/ingress level (handled automatically by most cloud services)
- Configure appropriate CORS headers if needed for web clients
- Set up monitoring and logging for the container
- Consider implementing rate limiting at the load balancer level

#### Scaling

The service is stateless and can be scaled horizontally:

- **Azure Container Apps**: Auto-scales based on HTTP traffic
- **AWS ECS/Fargate**: Configure auto-scaling based on CPU/memory or custom metrics
- **Google Cloud Run**: Auto-scales to zero when not in use, scales up based on requests

#### Cost Optimization

- Use auto-scaling to scale down during low usage
- Consider using spot instances/preemptible VMs where available
- Monitor API usage to optimize FRED API calls

## Configuration

This server requires a FRED® API key. You can obtain one from the [FRED® website](https://fred.stlouisfed.org/docs/api/api_key.html).

Install the server, for example, on [Claude Desktop](https://claude.ai/download), modify the `claude_desktop_config.json` file and add the following configuration:

```json
{
  "mcpServers": {
    "FRED MCP Server": {
      "command": "/usr/bin/node",
      "args": [
        "<PATH_TO_YOUR_CLONED_REPO>/fred-mcp-server/build/index.js"
      ],
      "env": {
        "FRED_API_KEY": "<YOUR_API_KEY>"
      }
    }
  }
}
```

## Available Tools

This MCP server provides three comprehensive tools to access all 800,000+ FRED® economic data series:

### `fred_browse`

**Description**: Browse FRED's complete catalog through categories, releases, or sources.

**Parameters**:
* `browse_type` (required): Type of browsing - "categories", "releases", "sources", "category_series", "release_series"
* `category_id` (optional): Category ID for browsing subcategories or series within a category
* `release_id` (optional): Release ID for browsing series within a release
* `limit` (optional): Maximum number of results (default: 50)
* `offset` (optional): Number of results to skip for pagination
* `order_by` (optional): Field to order results by
* `sort_order` (optional): "asc" or "desc"

### `fred_search`

**Description**: Search for FRED economic data series by keywords, tags, or filters.

**Parameters**:
* `search_text` (optional): Text to search for in series titles and descriptions
* `search_type` (optional): "full_text" or "series_id"
* `tag_names` (optional): Comma-separated list of tag names to filter by
* `exclude_tag_names` (optional): Comma-separated list of tag names to exclude
* `limit` (optional): Maximum number of results (default: 25)
* `offset` (optional): Number of results to skip for pagination
* `order_by` (optional): Field to order by (e.g., "popularity", "last_updated")
* `sort_order` (optional): "asc" or "desc"
* `filter_variable` (optional): Filter by "frequency", "units", or "seasonal_adjustment"
* `filter_value` (optional): Value to filter the variable by

### `fred_get_series`

**Description**: Retrieve data for any FRED series by its ID with support for transformations and date ranges.

**Parameters**:
* `series_id` (required): The FRED series ID (e.g., "GDP", "UNRATE", "CPIAUCSL")
* `observation_start` (optional): Start date in YYYY-MM-DD format
* `observation_end` (optional): End date in YYYY-MM-DD format
* `limit` (optional): Maximum number of observations
* `offset` (optional): Number of observations to skip
* `sort_order` (optional): "asc" or "desc"
* `units` (optional): Data transformation:
  - "lin" (levels/no transformation)
  - "chg" (change from previous period)
  - "ch1" (change from year ago)
  - "pch" (percent change)
  - "pc1" (percent change from year ago)
  - "pca" (compounded annual rate of change)
  - "cch" (continuously compounded rate of change)
  - "log" (natural log)
* `frequency` (optional): Frequency aggregation ("d", "w", "m", "q", "a")
* `aggregation_method` (optional): "avg" (average), "sum", or "eop" (end of period)

## Example Usage

With these three tools, you can:
- Browse all economic categories and discover available data
- Search for specific indicators by keywords or tags
- Retrieve any of the 800,000+ series with custom transformations
- Access real-time economic data including GDP, unemployment, inflation, interest rates, and more

## Testing

See [TESTING.md](./TESTING.md) for more details.

```bash
# Run all tests
pnpm test

# Run specific tests
pnpm test:registry
```

## License ⚖️

This open-source project is licensed under the GNU Affero General Public License v3.0 (AGPL-3.0). This means:

- You can use, modify, and distribute this software
- If you modify and distribute it, you must release your changes under AGPL-3.0
- If you run a modified version on a server, you must provide the source code to users
- See the [LICENSE](LICENSE) file for full details

For commercial licensing options or other licensing inquiries, please contact [stefano@amorelli.tech](mailto:stefano@amorelli.tech).

© 2025 [Stefano Amorelli](https://amorelli.tech)
