import express, { Request, Response } from "express";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { createServer } from "./index.js";

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3001;

/**
 * Create MCP server for HTTP transport
 */
function createHttpServer() {
  const server = createServer();
  
  app.post('/mcp', async (req: Request, res: Response) => {
    try {
      const transport = new StreamableHTTPServerTransport({
        sessionIdGenerator: undefined, // Stateless mode
      });
      
      res.on('close', () => {
        transport.close();
        server.close();
      });
      
      await server.connect(transport);
      await transport.handleRequest(req, res, req.body);
    } catch (error) {
      console.error('Error handling MCP request:', error);
      if (!res.headersSent) {
        res.status(500).json({
          jsonrpc: '2.0',
          error: {
            code: -32603,
            message: 'Internal server error',
          },
          id: null,
        });
      }
    }
  });

  app.get('/health', (_req: Request, res: Response) => {
    res.json({ status: 'healthy', timestamp: new Date().toISOString() });
  });

  return app;
}

/**
 * Start HTTP server
 */
async function startHttpServer() {
  const httpServer = createHttpServer();
  
  httpServer.listen(PORT, () => {
    console.log(`FRED MCP Server running on http://localhost:${PORT}`);
    console.log(`Health check: http://localhost:${PORT}/health`);
    console.log(`MCP endpoint: http://localhost:${PORT}/mcp`);
  });
}

// Start the server
startHttpServer().catch((error) => {
  console.error("Failed to start HTTP server:", error);
  process.exit(1);
});
