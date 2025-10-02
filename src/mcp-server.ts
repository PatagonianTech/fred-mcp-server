import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { InitializeRequestSchema, JSONRPCError } from "@modelcontextprotocol/sdk/types.js";
import { randomUUID } from "crypto";
import { Request, Response } from "express";

const SESSION_ID_HEADER_NAME = "mcp-session-id"
const JSON_RPC = "2.0"

export class MCPServer {
  server: McpServer

  // to support multiple simultaneous connections
  transports: { [sessionId: string]: StreamableHTTPServerTransport } = {}

  constructor(server: McpServer) {
    this.server = server
  }

  async handleGetRequest(req: Request, res: Response) {
    console.log("get request received")
    // if server does not offer an SSE stream at this endpoint.
    res.status(405).set('Allow', 'POST').send('Method Not Allowed')
    return
  }

  async handlePostRequest(req: Request, res: Response) {
    const sessionId = req.headers[SESSION_ID_HEADER_NAME] as string | undefined

    console.log("post request received")
    console.log("body: ", req.body)

    let transport: StreamableHTTPServerTransport

    try {
      // reuse existing transport
      if (sessionId && this.transports[sessionId]) {
        transport = this.transports[sessionId]
        await transport.handleRequest(req, res, req.body)
        return
      }

      // create new transport
      if (!sessionId && this.isInitializeRequest(req.body)) {
        const transport = new StreamableHTTPServerTransport({
          sessionIdGenerator: () => randomUUID(),
          // for stateless mode:
          // sessionIdGenerator: () => undefined
        })

        await this.server.connect(transport)
        await transport.handleRequest(req, res, req.body)

        // session ID will only be available (if in not Stateless-Mode)
        // after handling the first request
        const sessionId = transport.sessionId
        if (sessionId) {
          this.transports[sessionId] = transport
        }

        await this.sendMessages(transport)
        return
      }

      res.status(400).json(this.createErrorResponse("Bad Request: invalid session ID or method."))
      return

    } catch (error) {

      console.error('Error handling MCP request:', error)
      res.status(500).json(this.createErrorResponse("Internal server error."))
      return
    }
  }

  // send message streaming message every second
  // cannot use server.sendLoggingMessage because we have can have multiple transports
  private async sendMessages(transport: StreamableHTTPServerTransport) {
    try {
      await transport.send({
        jsonrpc: "2.0",
        method: "sse/connection",
        params: { message: "Stream started" }
      })
      console.log("Stream started")

      let messageCount = 0
      const interval = setInterval(async () => {

        messageCount++

        const message = `Message ${messageCount} at ${new Date().toISOString()}`

        try {
          await transport.send({
            jsonrpc: "2.0",
            method: "sse/message",
            params: { data: message }
          })

          console.log(`Sent: ${message}`)

          if (messageCount === 2) {
            clearInterval(interval)
            await transport.send({
              jsonrpc: JSON_RPC,
              method: "sse/complete",
              params: { message: "Stream completed" }
            })
            console.log("Stream completed")
          }

        } catch (error) {
          console.error("Error sending message:", error)
          clearInterval(interval)
        }

      }, 1000)

    } catch (error) {
      console.error("Error in startSending:", error)
    }
  }

  private createErrorResponse(message: string): JSONRPCError {
    return {
      jsonrpc: JSON_RPC,
      error: {
        code: -32000,
        message: message,
      },
      id: randomUUID(),
    }
  }

  private isInitializeRequest(body: any): boolean {
    const isInitial = (data: any) => {
      const result = InitializeRequestSchema.safeParse(data)
      return result.success
    }
    if (Array.isArray(body)) {
      return body.some(request => isInitial(request))
    }
    return isInitial(body)
  }

}