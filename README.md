# AI Workspace Selector

A unified PowerShell module to manage workspaces and launch any AI CLI tool — all from a single entry point.

Instead of maintaining separate scripts for each AI tool, this module lets you register any AI CLI tool once and reuse the same workspace list across all of them. Adding a new tool requires no code changes.

> Built and tested on Windows 11 with PowerShell 7.

---

## How It Works

```
ai
 ├─ [0] Gemini CLI
 ├─ [1] Claude Code
 └─ [q] Quit
       ↓ pick a tool
 ├─ [0] D:\GitHub\ProjectA
 ├─ [1] D:\GitHub\ProjectB
 └─ [q] Quit
       ↓ pick a workspace
  auto cd → launch tool
```

---

## Prerequisites

- **PowerShell** 5.1 or later (PowerShell 7 recommended)
- At least one AI CLI tool installed and accessible from your terminal, e.g.:
  - [Gemini CLI](https://github.com/google-gemini/gemini-cli) — command: `gemini`
  - [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — command: `claude`
  - Any other AI CLI tool of your choice

---

## Installation

### 1. Clone the repository

```powershell
git clone https://github.com/your-username/ai-workspace-selector.git
```

Place the folder anywhere you like. The module uses `$PSScriptRoot` for portable paths, so the location doesn't matter.

### 2. Add to your PowerShell Profile

Open your profile file:

```powershell
notepad $PROFILE
```

Add the following lines (update the path to match where you cloned the repo):

```powershell
# --- AI Workspace Selector ---
$AiSelectorRoot = "C:\path\to\ai-workspace-selector"
Import-Module (Join-Path $AiSelectorRoot "ai-workspace-selector.psm1") -Force
```

### 3. Reload your profile

```powershell
. $PROFILE
```

That's it. The `ai` and `ws` commands are now available in every terminal session.

### Optional: Custom config file locations

If you'd like to sync your config files via OneDrive or keep them outside the module folder:

```powershell
$Global:AiWorkspacesConfig = "C:\Users\YourName\OneDrive\ai-workspaces.json"
$Global:AiToolsConfig      = "C:\Users\YourName\OneDrive\ai-tools.json"
```

---

## Getting Started

### Step 1 — Register your AI tools

```powershell
ws tool add "Gemini CLI"
# Prompts: Enter the shell command to launch 'Gemini CLI': gemini

ws tool add "Claude Code"
# Prompts: Enter the shell command to launch 'Claude Code': claude
```

### Step 2 — Add your workspaces

```powershell
ws add D:\GitHub\MyProject   # Add a specific path
ws add .                     # Add current directory
```

### Step 3 — Launch

```powershell
ai
```

---

## Commands

### `ai` — Launch

Select a tool and workspace interactively, then launch.

```
--- Select AI Tool ---
[0] Gemini CLI
[1] Claude Code
[q] Quit

Enter selection index: 1

--- Select Workspace ---
[0] D:\GitHub\ProjectA
[1] D:\GitHub\ProjectB
[q] Quit

Enter selection index: 0
Switched to: D:\GitHub\ProjectA
Launching: Claude Code...
```

---

### `ws` — Workspace & Tool Manager

#### Workspaces

```powershell
ws add <path>    # Add a workspace ('.' for current directory)
ws remove        # Remove a workspace via interactive menu
ws list          # List all saved workspaces
```

#### AI Tools

```powershell
ws tool add <name>    # Register a new AI tool (prompts for launch command)
ws tool remove        # Remove a tool via interactive menu
ws tool list          # List all registered tools
```

---

## Quick Reference

| Command | Description |
|---------|-------------|
| `ai` | Select tool & workspace, then launch |
| `ws add <path>` | Add a workspace |
| `ws remove` | Remove a workspace |
| `ws list` | List all workspaces |
| `ws tool add <name>` | Register an AI tool |
| `ws tool remove` | Remove an AI tool |
| `ws tool list` | List all AI tools |
| `ws help` | Show help |

---

## Config Files

Both files are auto-created on first use if they don't exist.

### tools.json

Stores registered AI tools. The `command` field is the shell command used to launch the tool.

```json
[
  { "name": "Gemini CLI",  "command": "gemini" },
  { "name": "Claude Code", "command": "claude" }
]
```

### workspaces.json

Stores your workspace paths. This file is personal and excluded from the repository via `.gitignore`.

```json
[
  "C:\\Users\\YourName\\Projects\\ProjectA",
  "C:\\Users\\YourName\\Projects\\ProjectB"
]
```

Both files can be edited manually or managed entirely through `ws` commands.

---

## License

MIT License
