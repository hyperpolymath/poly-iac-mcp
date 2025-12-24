// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
// main.js - Entry shim for poly-iac-mcp (ReScript compiled)

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.res.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.res.js";

// Import ReScript compiled modules
import * as Terraform from "./lib/es6/src/adapters/Terraform.res.res.js";
import * as Pulumi from "./lib/es6/src/adapters/Pulumi.res.res.js";

const VERSION = "1.2.0";
const adapters = [Terraform, Pulumi];

async function main() {
  const server = new McpServer({
    name: "poly-iac-mcp",
    version: VERSION,
  });

  // Connect all adapters and collect tools
  const connectedAdapters = [];
  const allTools = {};

  for (const adapter of adapters) {
    try {
      await adapter.connect();
      connectedAdapters.push(adapter);

      // Register tools from this adapter
      const tools = adapter.tools;
      for (const [name, def] of Object.entries(tools)) {
        allTools[name] = def;
      }
    } catch (err) {
      console.error(`Failed to connect ${adapter.name}: ${err.message}`);
    }
  }

  // Register tools with MCP server
  for (const [name, tool] of Object.entries(allTools)) {
    const inputSchema = {
      type: "object",
      properties: {},
    };

    for (const [paramName, paramDef] of Object.entries(tool.params)) {
      inputSchema.properties[paramName] = {
        type: paramDef.type_,
        description: paramDef.description,
      };
    }

    server.tool(name, tool.description, inputSchema, async (args) => {
      try {
        const result = await tool.handler(args);
        return { content: [{ type: "text", text: JSON.stringify(result, null, 2) }] };
      } catch (err) {
        return { content: [{ type: "text", text: `Error: ${err.message}` }], isError: true };
      }
    });
  }

  // Start server
  const transport = new StdioServerTransport();
  await server.connect(transport);

  console.error(`poly-iac-mcp v${VERSION} (STDIO mode)`);
  console.error(`${connectedAdapters.length} adapter(s) connected`);
  console.error(`${Object.keys(allTools).length} tools registered`);
  console.error("Feedback: https://github.com/hyperpolymath/poly-iac-mcp/issues");
}

main().catch(console.error);
