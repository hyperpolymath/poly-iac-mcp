// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

/// Pulumi Adapter
/// Infrastructure as Code using real programming languages

open Adapter

let connected = ref(false)

let name = "pulumi"
let description = "Pulumi Infrastructure as Code"

let runPulumiCmd = async (args: array<string>): (int, string, string) => {
  await Deno.Command.run("pulumi", args)
}

let connect = async () => {
  let (code, _, _) = await runPulumiCmd(["version"])
  if code == 0 {
    connected := true
  } else {
    Exn.raiseError("Pulumi CLI not found")
  }
}

let disconnect = async () => {
  connected := false
}

let isConnected = async () => connected.contents

// Preview changes (like terraform plan)
let previewHandler = async (args: dict<JSON.t>): JSON.t => {
  let stack = switch Dict.get(args, "stack") {
  | Some(JSON.String(s)) => Some(s)
  | _ => None
  }
  let path = switch Dict.get(args, "path") {
  | Some(JSON.String(p)) => p
  | _ => "."
  }

  let cmdArgs = ["preview", "--cwd", path, "--json"]
  switch stack {
  | Some(s) => Array.push(cmdArgs, `--stack=${s}`)
  | None => ()
  }

  let (code, stdout, stderr) = await runPulumiCmd(cmdArgs)
  JSON.Encode.object(Dict.fromArray([
    ("success", JSON.Encode.bool(code == 0)),
    ("output", JSON.Encode.string(stdout)),
    ("error", JSON.Encode.string(stderr)),
  ]))
}

// Apply changes (pulumi up)
let upHandler = async (args: dict<JSON.t>): JSON.t => {
  let stack = switch Dict.get(args, "stack") {
  | Some(JSON.String(s)) => Some(s)
  | _ => None
  }
  let path = switch Dict.get(args, "path") {
  | Some(JSON.String(p)) => p
  | _ => "."
  }
  let yes = switch Dict.get(args, "yes") {
  | Some(JSON.Boolean(b)) => b
  | _ => false
  }

  let cmdArgs = ["up", "--cwd", path, "--json"]
  switch stack {
  | Some(s) => Array.push(cmdArgs, `--stack=${s}`)
  | None => ()
  }
  if yes {
    Array.push(cmdArgs, "--yes")
  }

  let (code, stdout, stderr) = await runPulumiCmd(cmdArgs)
  JSON.Encode.object(Dict.fromArray([
    ("success", JSON.Encode.bool(code == 0)),
    ("output", JSON.Encode.string(stdout)),
    ("error", JSON.Encode.string(stderr)),
  ]))
}

// Destroy infrastructure
let destroyHandler = async (args: dict<JSON.t>): JSON.t => {
  let stack = switch Dict.get(args, "stack") {
  | Some(JSON.String(s)) => Some(s)
  | _ => None
  }
  let path = switch Dict.get(args, "path") {
  | Some(JSON.String(p)) => p
  | _ => "."
  }
  let yes = switch Dict.get(args, "yes") {
  | Some(JSON.Boolean(b)) => b
  | _ => false
  }

  let cmdArgs = ["destroy", "--cwd", path, "--json"]
  switch stack {
  | Some(s) => Array.push(cmdArgs, `--stack=${s}`)
  | None => ()
  }
  if yes {
    Array.push(cmdArgs, "--yes")
  }

  let (code, stdout, stderr) = await runPulumiCmd(cmdArgs)
  JSON.Encode.object(Dict.fromArray([
    ("success", JSON.Encode.bool(code == 0)),
    ("output", JSON.Encode.string(stdout)),
    ("error", JSON.Encode.string(stderr)),
  ]))
}

// List stacks
let stackListHandler = async (args: dict<JSON.t>): JSON.t => {
  let path = switch Dict.get(args, "path") {
  | Some(JSON.String(p)) => p
  | _ => "."
  }

  let (code, stdout, stderr) = await runPulumiCmd(["stack", "ls", "--cwd", path, "--json"])
  if code == 0 {
    try {
      JSON.parseExn(stdout)
    } catch {
    | _ => JSON.Encode.object(Dict.fromArray([("stacks", JSON.Encode.string(stdout))]))
    }
  } else {
    JSON.Encode.object(Dict.fromArray([
      ("success", JSON.Encode.bool(false)),
      ("error", JSON.Encode.string(stderr)),
    ]))
  }
}

// Select stack
let stackSelectHandler = async (args: dict<JSON.t>): JSON.t => {
  let stack = switch Dict.get(args, "stack") {
  | Some(JSON.String(s)) => s
  | _ => Exn.raiseError("stack parameter is required")
  }
  let path = switch Dict.get(args, "path") {
  | Some(JSON.String(p)) => p
  | _ => "."
  }

  let (code, stdout, stderr) = await runPulumiCmd(["stack", "select", stack, "--cwd", path])
  JSON.Encode.object(Dict.fromArray([
    ("success", JSON.Encode.bool(code == 0)),
    ("stack", JSON.Encode.string(stack)),
    ("error", JSON.Encode.string(stderr)),
  ]))
}

// Create new stack
let stackInitHandler = async (args: dict<JSON.t>): JSON.t => {
  let stack = switch Dict.get(args, "stack") {
  | Some(JSON.String(s)) => s
  | _ => Exn.raiseError("stack parameter is required")
  }
  let path = switch Dict.get(args, "path") {
  | Some(JSON.String(p)) => p
  | _ => "."
  }

  let (code, stdout, stderr) = await runPulumiCmd(["stack", "init", stack, "--cwd", path])
  JSON.Encode.object(Dict.fromArray([
    ("success", JSON.Encode.bool(code == 0)),
    ("stack", JSON.Encode.string(stack)),
    ("output", JSON.Encode.string(stdout)),
    ("error", JSON.Encode.string(stderr)),
  ]))
}

// Get stack outputs
let stackOutputHandler = async (args: dict<JSON.t>): JSON.t => {
  let stack = switch Dict.get(args, "stack") {
  | Some(JSON.String(s)) => Some(s)
  | _ => None
  }
  let path = switch Dict.get(args, "path") {
  | Some(JSON.String(p)) => p
  | _ => "."
  }

  let cmdArgs = ["stack", "output", "--cwd", path, "--json"]
  switch stack {
  | Some(s) => Array.push(cmdArgs, `--stack=${s}`)
  | None => ()
  }

  let (code, stdout, stderr) = await runPulumiCmd(cmdArgs)
  if code == 0 {
    try {
      JSON.parseExn(stdout)
    } catch {
    | _ => JSON.Encode.object(Dict.fromArray([("outputs", JSON.Encode.string(stdout))]))
    }
  } else {
    JSON.Encode.object(Dict.fromArray([
      ("success", JSON.Encode.bool(false)),
      ("error", JSON.Encode.string(stderr)),
    ]))
  }
}

// Refresh state
let refreshHandler = async (args: dict<JSON.t>): JSON.t => {
  let stack = switch Dict.get(args, "stack") {
  | Some(JSON.String(s)) => Some(s)
  | _ => None
  }
  let path = switch Dict.get(args, "path") {
  | Some(JSON.String(p)) => p
  | _ => "."
  }
  let yes = switch Dict.get(args, "yes") {
  | Some(JSON.Boolean(b)) => b
  | _ => false
  }

  let cmdArgs = ["refresh", "--cwd", path, "--json"]
  switch stack {
  | Some(s) => Array.push(cmdArgs, `--stack=${s}`)
  | None => ()
  }
  if yes {
    Array.push(cmdArgs, "--yes")
  }

  let (code, stdout, stderr) = await runPulumiCmd(cmdArgs)
  JSON.Encode.object(Dict.fromArray([
    ("success", JSON.Encode.bool(code == 0)),
    ("output", JSON.Encode.string(stdout)),
    ("error", JSON.Encode.string(stderr)),
  ]))
}

// Set config value
let configSetHandler = async (args: dict<JSON.t>): JSON.t => {
  let key = switch Dict.get(args, "key") {
  | Some(JSON.String(k)) => k
  | _ => Exn.raiseError("key parameter is required")
  }
  let value = switch Dict.get(args, "value") {
  | Some(JSON.String(v)) => v
  | _ => Exn.raiseError("value parameter is required")
  }
  let secret = switch Dict.get(args, "secret") {
  | Some(JSON.Boolean(b)) => b
  | _ => false
  }
  let path = switch Dict.get(args, "path") {
  | Some(JSON.String(p)) => p
  | _ => "."
  }

  let cmdArgs = ["config", "set", key, value, "--cwd", path]
  if secret {
    Array.push(cmdArgs, "--secret")
  }

  let (code, _, stderr) = await runPulumiCmd(cmdArgs)
  JSON.Encode.object(Dict.fromArray([
    ("success", JSON.Encode.bool(code == 0)),
    ("key", JSON.Encode.string(key)),
    ("error", JSON.Encode.string(stderr)),
  ]))
}

// Get config value
let configGetHandler = async (args: dict<JSON.t>): JSON.t => {
  let key = switch Dict.get(args, "key") {
  | Some(JSON.String(k)) => k
  | _ => Exn.raiseError("key parameter is required")
  }
  let path = switch Dict.get(args, "path") {
  | Some(JSON.String(p)) => p
  | _ => "."
  }

  let (code, stdout, stderr) = await runPulumiCmd(["config", "get", key, "--cwd", path])
  JSON.Encode.object(Dict.fromArray([
    ("success", JSON.Encode.bool(code == 0)),
    ("key", JSON.Encode.string(key)),
    ("value", JSON.Encode.string(String.trim(stdout))),
    ("error", JSON.Encode.string(stderr)),
  ]))
}

// Version
let versionHandler = async (_args: dict<JSON.t>): JSON.t => {
  let (code, stdout, stderr) = await runPulumiCmd(["version"])
  JSON.Encode.object(Dict.fromArray([
    ("success", JSON.Encode.bool(code == 0)),
    ("version", JSON.Encode.string(String.trim(stdout))),
    ("error", JSON.Encode.string(stderr)),
  ]))
}

let tools: dict<toolDef> = Dict.fromArray([
  ("pulumi_preview", {
    description: "Preview changes to infrastructure",
    params: Dict.fromArray([
      ("path", stringParam(~description="Path to Pulumi project")),
      ("stack", stringParam(~description="Stack name to preview")),
    ]),
    handler: previewHandler,
  }),
  ("pulumi_up", {
    description: "Deploy infrastructure changes",
    params: Dict.fromArray([
      ("path", stringParam(~description="Path to Pulumi project")),
      ("stack", stringParam(~description="Stack name to deploy")),
      ("yes", boolParam(~description="Skip confirmation prompt")),
    ]),
    handler: upHandler,
  }),
  ("pulumi_destroy", {
    description: "Destroy infrastructure",
    params: Dict.fromArray([
      ("path", stringParam(~description="Path to Pulumi project")),
      ("stack", stringParam(~description="Stack name to destroy")),
      ("yes", boolParam(~description="Skip confirmation prompt")),
    ]),
    handler: destroyHandler,
  }),
  ("pulumi_stack_list", {
    description: "List all stacks",
    params: Dict.fromArray([
      ("path", stringParam(~description="Path to Pulumi project")),
    ]),
    handler: stackListHandler,
  }),
  ("pulumi_stack_select", {
    description: "Select a stack",
    params: Dict.fromArray([
      ("stack", stringParam(~description="Stack name to select")),
      ("path", stringParam(~description="Path to Pulumi project")),
    ]),
    handler: stackSelectHandler,
  }),
  ("pulumi_stack_init", {
    description: "Create a new stack",
    params: Dict.fromArray([
      ("stack", stringParam(~description="Stack name to create")),
      ("path", stringParam(~description="Path to Pulumi project")),
    ]),
    handler: stackInitHandler,
  }),
  ("pulumi_stack_output", {
    description: "Get stack outputs",
    params: Dict.fromArray([
      ("stack", stringParam(~description="Stack name")),
      ("path", stringParam(~description="Path to Pulumi project")),
    ]),
    handler: stackOutputHandler,
  }),
  ("pulumi_refresh", {
    description: "Refresh state from cloud",
    params: Dict.fromArray([
      ("path", stringParam(~description="Path to Pulumi project")),
      ("stack", stringParam(~description="Stack name")),
      ("yes", boolParam(~description="Skip confirmation prompt")),
    ]),
    handler: refreshHandler,
  }),
  ("pulumi_config_set", {
    description: "Set a configuration value",
    params: Dict.fromArray([
      ("key", stringParam(~description="Configuration key")),
      ("value", stringParam(~description="Configuration value")),
      ("secret", boolParam(~description="Encrypt the value")),
      ("path", stringParam(~description="Path to Pulumi project")),
    ]),
    handler: configSetHandler,
  }),
  ("pulumi_config_get", {
    description: "Get a configuration value",
    params: Dict.fromArray([
      ("key", stringParam(~description="Configuration key")),
      ("path", stringParam(~description="Path to Pulumi project")),
    ]),
    handler: configGetHandler,
  }),
  ("pulumi_version", {
    description: "Show Pulumi version",
    params: Dict.make(),
    handler: versionHandler,
  }),
])
