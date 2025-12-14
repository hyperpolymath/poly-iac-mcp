// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
/**
 * Terraform/OpenTofu Adapter
 *
 * Supports both Terraform and OpenTofu via command detection.
 * OpenTofu is preferred as the FOSS alternative.
 */

const name = "terraform";
const description = "Terraform/OpenTofu Infrastructure as Code";

let binaryPath = null;
let connected = false;

async function detectBinary() {
  // Prefer OpenTofu (FOSS) over Terraform
  for (const binary of ["tofu", "terraform"]) {
    try {
      const command = new Deno.Command(binary, { args: ["version"] });
      const { code } = await command.output();
      if (code === 0) {
        return binary;
      }
    } catch {
      // Binary not found, try next
    }
  }
  return null;
}

async function connect() {
  binaryPath = await detectBinary();
  if (binaryPath) {
    connected = true;
    return { success: true, binary: binaryPath };
  }
  return { success: false, error: "No Terraform/OpenTofu binary found" };
}

function disconnect() {
  connected = false;
  binaryPath = null;
}

function isConnected() {
  return connected;
}

async function runCommand(args) {
  if (!binaryPath) {
    throw new Error("Not connected to Terraform/OpenTofu");
  }

  const command = new Deno.Command(binaryPath, {
    args,
    stdout: "piped",
    stderr: "piped",
  });

  const { code, stdout, stderr } = await command.output();
  const output = new TextDecoder().decode(stdout);
  const error = new TextDecoder().decode(stderr);

  return {
    success: code === 0,
    output,
    error,
    code,
  };
}

const tools = [
  {
    name: "terraform_init",
    description: "Initialize a Terraform/OpenTofu working directory",
    inputSchema: {
      type: "object",
      properties: {
        path: {
          type: "string",
          description: "Path to the Terraform configuration directory",
        },
        backend: {
          type: "boolean",
          description: "Configure the backend for this configuration",
          default: true,
        },
        upgrade: {
          type: "boolean",
          description: "Upgrade modules and plugins",
          default: false,
        },
      },
      required: ["path"],
    },
    handler: async ({ path, backend = true, upgrade = false }) => {
      const args = ["init"];
      if (!backend) args.push("-backend=false");
      if (upgrade) args.push("-upgrade");
      args.push(path);
      return await runCommand(args);
    },
  },
  {
    name: "terraform_plan",
    description: "Generate and show an execution plan",
    inputSchema: {
      type: "object",
      properties: {
        path: {
          type: "string",
          description: "Path to the Terraform configuration directory",
        },
        out: {
          type: "string",
          description: "Write plan to a file",
        },
        vars: {
          type: "object",
          description: "Variable values",
        },
      },
      required: ["path"],
    },
    handler: async ({ path, out, vars }) => {
      const args = ["plan"];
      if (out) args.push(`-out=${out}`);
      if (vars) {
        for (const [key, value] of Object.entries(vars)) {
          args.push(`-var=${key}=${value}`);
        }
      }
      args.push(path);
      return await runCommand(args);
    },
  },
  {
    name: "terraform_apply",
    description: "Apply infrastructure changes",
    inputSchema: {
      type: "object",
      properties: {
        path: {
          type: "string",
          description: "Path to plan file or configuration directory",
        },
        autoApprove: {
          type: "boolean",
          description: "Skip interactive approval",
          default: false,
        },
      },
      required: ["path"],
    },
    handler: async ({ path, autoApprove = false }) => {
      const args = ["apply"];
      if (autoApprove) args.push("-auto-approve");
      args.push(path);
      return await runCommand(args);
    },
  },
  {
    name: "terraform_destroy",
    description: "Destroy infrastructure managed by Terraform",
    inputSchema: {
      type: "object",
      properties: {
        path: {
          type: "string",
          description: "Path to the Terraform configuration directory",
        },
        autoApprove: {
          type: "boolean",
          description: "Skip interactive approval",
          default: false,
        },
      },
      required: ["path"],
    },
    handler: async ({ path, autoApprove = false }) => {
      const args = ["destroy"];
      if (autoApprove) args.push("-auto-approve");
      args.push(path);
      return await runCommand(args);
    },
  },
  {
    name: "terraform_output",
    description: "Show output values from state",
    inputSchema: {
      type: "object",
      properties: {
        path: {
          type: "string",
          description: "Path to the Terraform configuration directory",
        },
        name: {
          type: "string",
          description: "Specific output to retrieve",
        },
        json: {
          type: "boolean",
          description: "Output in JSON format",
          default: true,
        },
      },
      required: ["path"],
    },
    handler: async ({ path, name, json = true }) => {
      const args = ["output"];
      if (json) args.push("-json");
      if (name) args.push(name);
      // Note: path handling for terraform output
      return await runCommand(args);
    },
  },
  {
    name: "terraform_state_list",
    description: "List resources in the state",
    inputSchema: {
      type: "object",
      properties: {
        path: {
          type: "string",
          description: "Path to the Terraform configuration directory",
        },
      },
      required: ["path"],
    },
    handler: async ({ path }) => {
      return await runCommand(["state", "list"]);
    },
  },
  {
    name: "terraform_validate",
    description: "Validate the configuration files",
    inputSchema: {
      type: "object",
      properties: {
        path: {
          type: "string",
          description: "Path to the Terraform configuration directory",
        },
      },
      required: ["path"],
    },
    handler: async ({ path }) => {
      return await runCommand(["validate", path]);
    },
  },
  {
    name: "terraform_fmt",
    description: "Format configuration files",
    inputSchema: {
      type: "object",
      properties: {
        path: {
          type: "string",
          description: "Path to the Terraform configuration directory",
        },
        check: {
          type: "boolean",
          description: "Check if files are formatted without modifying",
          default: false,
        },
      },
      required: ["path"],
    },
    handler: async ({ path, check = false }) => {
      const args = ["fmt"];
      if (check) args.push("-check");
      args.push(path);
      return await runCommand(args);
    },
  },
];

export { name, description, connect, disconnect, isConnected, tools };
