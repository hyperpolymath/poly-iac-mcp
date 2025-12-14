// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
/**
 * poly-iac-mcp - Unified MCP Server for Infrastructure as Code
 *
 * Supported IaC Tools:
 * - Terraform (HashiCorp)
 * - OpenTofu (FOSS Terraform fork)
 * - Pulumi (Multi-language IaC)
 * - Crossplane (Kubernetes-native)
 * - AWS CDK / CDK for Terraform
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";

// Import adapters (to be implemented)
// import { terraformAdapter } from "./adapters/terraform.js";
// import { opentofuAdapter } from "./adapters/opentofu.js";
// import { pulumiAdapter } from "./adapters/pulumi.js";
// import { crossplaneAdapter } from "./adapters/crossplane.js";
// import { cdkAdapter } from "./adapters/cdk.js";

const adapters = [
  // terraformAdapter,
  // opentofuAdapter,
  // pulumiAdapter,
  // crossplaneAdapter,
  // cdkAdapter,
];

const server = new Server(
  {
    name: "poly-iac-mcp",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Collect all tools from adapters
const allTools = adapters.flatMap((adapter) => adapter.tools || []);

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: allTools.map((tool) => ({
    name: tool.name,
    description: tool.description,
    inputSchema: tool.inputSchema,
  })),
}));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  for (const adapter of adapters) {
    const tool = adapter.tools?.find((t) => t.name === name);
    if (tool) {
      try {
        const result = await tool.handler(args);
        return {
          content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
        };
      } catch (error) {
        return {
          content: [{ type: "text", text: `Error: ${error.message}` }],
          isError: true,
        };
      }
    }
  }

  return {
    content: [{ type: "text", text: `Unknown tool: ${name}` }],
    isError: true,
  };
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("poly-iac-mcp server started");
}

main().catch(console.error);
