// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

/// Terraform/OpenTofu Adapter
/// Supports both Terraform and OpenTofu via command detection.
/// OpenTofu is preferred as the FOSS alternative.

open Adapter

let binaryPath: ref<option<string>> = ref(None)
let connected: ref<bool> = ref(false)

let detectBinary = async (): option<string> => {
  // Prefer OpenTofu (FOSS) over Terraform
  let binaries = ["tofu", "terraform"]
  let result = ref(None)

  for i in 0 to Array.length(binaries) - 1 {
    if Option.isNone(result.contents) {
      let binary = binaries->Array.getUnsafe(i)
      try {
        let (code, _, _) = await Deno.Command.run(binary, ["version"])
        if code === 0 {
          result := Some(binary)
        }
      } catch {
      | _ => ()
      }
    }
  }
  result.contents
}

let runCommand = async (args: array<string>): JSON.t => {
  switch binaryPath.contents {
  | None => Obj.magic({"success": false, "error": "Not connected to Terraform/OpenTofu"})
  | Some(binary) =>
    let (code, stdout, stderr) = await Deno.Command.run(binary, args)
    Obj.magic({
      "success": code === 0,
      "output": stdout,
      "error": stderr,
      "code": code,
    })
  }
}

let name = "terraform"
let description = "Terraform/OpenTofu Infrastructure as Code"

let connect = async () => {
  let binary = await detectBinary()
  switch binary {
  | Some(b) =>
    binaryPath := Some(b)
    connected := true
  | None => Js.Exn.raiseError("No Terraform/OpenTofu binary found")
  }
}

let disconnect = async () => {
  connected := false
  binaryPath := None
}

let isConnected = async () => connected.contents

// Tool handlers
let initHandler = async (args: dict<JSON.t>): JSON.t => {
  let path = args->Dict.get("path")->Option.flatMap(JSON.Decode.string)->Option.getOr(".")
  let backend = args->Dict.get("backend")->Option.flatMap(JSON.Decode.bool)->Option.getOr(true)
  let upgrade = args->Dict.get("upgrade")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)

  let cmdArgs = ["init"]
  if !backend { cmdArgs->Array.push("-backend=false")->ignore }
  if upgrade { cmdArgs->Array.push("-upgrade")->ignore }
  cmdArgs->Array.push(path)->ignore

  await runCommand(cmdArgs)
}

let planHandler = async (args: dict<JSON.t>): JSON.t => {
  let path = args->Dict.get("path")->Option.flatMap(JSON.Decode.string)->Option.getOr(".")
  let out = args->Dict.get("out")->Option.flatMap(JSON.Decode.string)

  let cmdArgs = ["plan"]
  out->Option.forEach(o => cmdArgs->Array.push(`-out=${o}`)->ignore)
  cmdArgs->Array.push(path)->ignore

  await runCommand(cmdArgs)
}

let applyHandler = async (args: dict<JSON.t>): JSON.t => {
  let path = args->Dict.get("path")->Option.flatMap(JSON.Decode.string)->Option.getOr(".")
  let autoApprove = args->Dict.get("autoApprove")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)

  let cmdArgs = ["apply"]
  if autoApprove { cmdArgs->Array.push("-auto-approve")->ignore }
  cmdArgs->Array.push(path)->ignore

  await runCommand(cmdArgs)
}

let destroyHandler = async (args: dict<JSON.t>): JSON.t => {
  let path = args->Dict.get("path")->Option.flatMap(JSON.Decode.string)->Option.getOr(".")
  let autoApprove = args->Dict.get("autoApprove")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)

  let cmdArgs = ["destroy"]
  if autoApprove { cmdArgs->Array.push("-auto-approve")->ignore }
  cmdArgs->Array.push(path)->ignore

  await runCommand(cmdArgs)
}

let outputHandler = async (args: dict<JSON.t>): JSON.t => {
  let outputName = args->Dict.get("name")->Option.flatMap(JSON.Decode.string)
  let json = args->Dict.get("json")->Option.flatMap(JSON.Decode.bool)->Option.getOr(true)

  let cmdArgs = ["output"]
  if json { cmdArgs->Array.push("-json")->ignore }
  outputName->Option.forEach(n => cmdArgs->Array.push(n)->ignore)

  await runCommand(cmdArgs)
}

let stateListHandler = async (_args: dict<JSON.t>): JSON.t => {
  await runCommand(["state", "list"])
}

let validateHandler = async (args: dict<JSON.t>): JSON.t => {
  let path = args->Dict.get("path")->Option.flatMap(JSON.Decode.string)->Option.getOr(".")
  await runCommand(["validate", path])
}

let fmtHandler = async (args: dict<JSON.t>): JSON.t => {
  let path = args->Dict.get("path")->Option.flatMap(JSON.Decode.string)->Option.getOr(".")
  let check = args->Dict.get("check")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)

  let cmdArgs = ["fmt"]
  if check { cmdArgs->Array.push("-check")->ignore }
  cmdArgs->Array.push(path)->ignore

  await runCommand(cmdArgs)
}

let versionHandler = async (_args: dict<JSON.t>): JSON.t => {
  await runCommand(["version"])
}

// Tools dictionary
let tools: dict<toolDef> = {
  let dict = Dict.make()

  dict->Dict.set("terraform_init", {
    description: "Initialize a Terraform/OpenTofu working directory",
    params: Dict.fromArray([
      ("path", stringParam(~description="Path to configuration directory")),
      ("backend", boolParam(~description="Configure the backend")),
      ("upgrade", boolParam(~description="Upgrade modules and plugins")),
    ]),
    handler: initHandler,
  })

  dict->Dict.set("terraform_plan", {
    description: "Generate and show an execution plan",
    params: Dict.fromArray([
      ("path", stringParam(~description="Path to configuration directory")),
      ("out", stringParam(~description="Write plan to a file")),
    ]),
    handler: planHandler,
  })

  dict->Dict.set("terraform_apply", {
    description: "Apply infrastructure changes",
    params: Dict.fromArray([
      ("path", stringParam(~description="Path to plan file or configuration")),
      ("autoApprove", boolParam(~description="Skip interactive approval")),
    ]),
    handler: applyHandler,
  })

  dict->Dict.set("terraform_destroy", {
    description: "Destroy infrastructure managed by Terraform",
    params: Dict.fromArray([
      ("path", stringParam(~description="Path to configuration directory")),
      ("autoApprove", boolParam(~description="Skip interactive approval")),
    ]),
    handler: destroyHandler,
  })

  dict->Dict.set("terraform_output", {
    description: "Show output values from state",
    params: Dict.fromArray([
      ("name", stringParam(~description="Specific output to retrieve")),
      ("json", boolParam(~description="Output in JSON format")),
    ]),
    handler: outputHandler,
  })

  dict->Dict.set("terraform_state_list", {
    description: "List resources in the state",
    params: Dict.make(),
    handler: stateListHandler,
  })

  dict->Dict.set("terraform_validate", {
    description: "Validate the configuration files",
    params: Dict.fromArray([
      ("path", stringParam(~description="Path to configuration directory")),
    ]),
    handler: validateHandler,
  })

  dict->Dict.set("terraform_fmt", {
    description: "Format configuration files",
    params: Dict.fromArray([
      ("path", stringParam(~description="Path to configuration directory")),
      ("check", boolParam(~description="Check without modifying")),
    ]),
    handler: fmtHandler,
  })

  dict->Dict.set("terraform_version", {
    description: "Show Terraform/OpenTofu version",
    params: Dict.make(),
    handler: versionHandler,
  })

  dict
}
