// scripts/GenerateShells.res
// RSR Compliance: Strict ReScript (No TS)

// Minimal bindings for Node.js File System
module Fs = {
  @module("fs") external writeFileSync: (string, string) => unit = "writeFileSync"
  @module("fs") external mkdirSync: (string, { "recursive": bool }) => unit = "mkdirSync"
}

module Path = {
  @module("path") external join: (string, string) => string = "join"
}

type shellDef = {
  ext: string,
  name: string,
  installCommand: string => string,
  scriptContent: option<string>,
}

let baseUrl = "https://install.indieweb2.net"
let outputDir = "./dist/installers"
let docsDir = "./scripts"
let docFile = "install_vectors.adoc"

// The Core Logic to replicate
let installLogic = `
echo ">>> [RSR] Initiating IndieWeb2 Bastion Install..."
curl -fsSL ${baseUrl}/bootstrap.tar.gz | tar -xz
./indieweb2-bastion/bin/init
`

// ---------------------------------------------------------
// SHELL DEFINITIONS
// ---------------------------------------------------------

let shells = [
  // Standard
  {
    ext: "sh",
    name: "Bash",
    installCommand: u => `bash -c "$(curl -fsSL ${u}/install.sh)"`,
    scriptContent: None
  },
  {
    ext: "zsh",
    name: "Zsh",
    installCommand: u => `zsh -c "$(curl -fsSL ${u}/install.zsh)"`,
    scriptContent: None
  },
  // Modern
  {
    ext: "oil",
    name: "Oil (Preferred)",
    installCommand: u => `curl -fsSL ${u}/install.oil | osh`,
    scriptContent: None
  },
  {
    ext: "nu",
    name: "Nushell",
    installCommand: u => `http get ${u}/install.nu | save -f install.nu; nu install.nu`,
    scriptContent: Some(`print ">>> [RSR] Nu Install"; http get ${baseUrl}/bootstrap.tar.gz | save bootstrap.tar.gz; ^tar -xzf bootstrap.tar.gz; ^./indieweb2-bastion/bin/init`)
  },
  // [Truncated for brevity - Imagine Murex, Elvish, etc here following same pattern]
  {
    ext: "ps1",
    name: "PowerShell Core",
    installCommand: u => `Invoke-RestMethod ${u}/install.ps1 | Invoke-Expression`,
    scriptContent: Some(`Write-Host ">>> [RSR] PowerShell Install"; Invoke-WebRequest -Uri "${baseUrl}/bootstrap.zip" -OutFile "bootstrap.zip"; Expand-Archive bootstrap.zip -DestinationPath .; .\\indieweb2-bastion\\bin\\init.ps1`)
  }
]

// ---------------------------------------------------------
// GENERATION LOGIC
// ---------------------------------------------------------

let generate = () => {
  Js.Console.log(">>> [ReScript] Generating Shell Vectors...")

  // Ensure directories exist
  Fs.mkdirSync(outputDir, {"recursive": true})
  Fs.mkdirSync(docsDir, {"recursive": true})

  let docHeader = "= Universal Installation Vectors\n:description: Auto-generated from ReScript source.\n\nNOTE: This file is auto-generated. Do not edit manually.\n\n"
  
  // Mutable accumulator for doc content
  let docContent = ref(docHeader)

  shells->Js.Array2.forEach(shell => {
    // 1. Write the script file
    let filename = `install.${shell.ext}`
    let filePath = Path.join(outputDir, filename)
    
    let content = switch shell.scriptContent {
    | Some(c) => c
    | None => installLogic
    }

    Fs.writeFileSync(filePath, content)
    Js.Console.log(`    Generated: ${filename}`)

    // 2. Append to docs
    docContent := docContent.contents ++ `== ${shell.name}\n[source,${shell.ext}]\n----\n${shell.installCommand(baseUrl)}\n----\n\n`
  })

  // Write documentation
  let docPath = Path.join(docsDir, docFile)
  Fs.writeFileSync(docPath, docContent.contents)
  Js.Console.log(`>>> Documentation updated: ${docPath}`)
}

generate()
