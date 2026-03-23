# --- Config Path Helpers ---

function Get-AiConfigPath([string]$filename) {
    if ($filename -eq "workspaces.json" -and $Global:AiWorkspacesConfig) { return $Global:AiWorkspacesConfig }
    if ($filename -eq "tools.json"      -and $Global:AiToolsConfig)      { return $Global:AiToolsConfig }
    return Join-Path $PSScriptRoot $filename
}

function Initialize-ConfigFiles {
    $wsPath = Get-AiConfigPath "workspaces.json"
    if (-not (Test-Path $wsPath)) {
        '[]' | Set-Content $wsPath -Encoding UTF8
        Write-Host "Created: $wsPath" -ForegroundColor DarkGray
    }

    $toolsPath = Get-AiConfigPath "tools.json"
    if (-not (Test-Path $toolsPath)) {
        '[]' | Set-Content $toolsPath -Encoding UTF8
        Write-Host "Created: $toolsPath" -ForegroundColor DarkGray
    }
}

Initialize-ConfigFiles

# --- Workspaces ---

function Get-Workspaces {
    $path = Get-AiConfigPath "workspaces.json"
    if (Test-Path $path) {
        try {
            $content = Get-Content $path -Raw -Encoding UTF8
            if ([string]::IsNullOrWhiteSpace($content)) { return @() }
            $parsed = $content | ConvertFrom-Json
            if ($null -eq $parsed) { return @() }
            return $parsed
        } catch { return @() }
    }
    return @()
}

function Save-Workspaces($list) {
    $list | ConvertTo-Json | Set-Content (Get-AiConfigPath "workspaces.json") -Encoding UTF8
}

# --- Tools ---

function Get-Tools {
    $path = Get-AiConfigPath "tools.json"
    if (Test-Path $path) {
        try {
            $content = Get-Content $path -Raw -Encoding UTF8
            if ([string]::IsNullOrWhiteSpace($content)) { return @() }
            $parsed = $content | ConvertFrom-Json
            if ($null -eq $parsed) { return @() }
            return $parsed
        } catch { return @() }
    }
    return @()
}

function Save-Tools($list) {
    $list | ConvertTo-Json | Set-Content (Get-AiConfigPath "tools.json") -Encoding UTF8
}

# --- Help ---

function Show-WsHelp {
    Write-Host "`n--- AI Workspace Selector - Help ---" -ForegroundColor Cyan
    Write-Host "Usage: ws <command> [parameters]`n"
    Write-Host "Workspace commands:"
    Write-Host "  add <path>       Add a workspace path (use '.' for current directory)"
    Write-Host "  remove           Select and remove a workspace"
    Write-Host "  list             Show all saved workspaces`n"
    Write-Host "Tool commands:"
    Write-Host "  tool add <name> <command>   Register a new AI tool"
    Write-Host "  tool remove                 Select and remove a tool"
    Write-Host "  tool list                   Show all registered tools`n"
    Write-Host "Launcher:"
    Write-Host "  ai               Select tool and workspace, then launch`n"
}

# --- ws: Workspace & Tool Manager ---

function ws {
    param(
        [Parameter(Position=0)][string]$command,
        [Parameter(Position=1)][string]$arg1,
        [Parameter(Position=2)][string]$arg2
    )

    switch ($command) {

        # --- workspace management ---
        "add" {
            if (-not $arg1) { Write-Host "Error: Please provide a path!" -ForegroundColor Red; return }
            try {
                $fullPath = Resolve-Path $arg1 -ErrorAction Stop
                $list = @(Get-Workspaces)
                if ($list -notcontains $fullPath.Path) {
                    $list += $fullPath.Path
                    Save-Workspaces $list
                    Write-Host "Success: Added workspace: $($fullPath.Path)" -ForegroundColor Green
                } else {
                    Write-Host "Note: Path already exists in the list." -ForegroundColor Yellow
                }
            } catch { Write-Host "Error: Path does not exist!" -ForegroundColor Red }
        }
        "remove" {
            $list = @(Get-Workspaces)
            if ($list.Count -eq 0) { Write-Host "Note: Workspace list is empty." -ForegroundColor Gray; return }
            Write-Host "`n--- Select a Workspace to Remove ---" -ForegroundColor Yellow
            for ($i = 0; $i -lt $list.Count; $i++) { Write-Host "[$i] $($list[$i])" }
            Write-Host "[q] Cancel"
            $choice = Read-Host "`nEnter selection index to remove"
            if ($choice -eq 'q' -or [string]::IsNullOrWhiteSpace($choice)) { return }
            if ($choice -match '^\d+$' -and [int]$choice -lt $list.Count) {
                $removed = $list[[int]$choice]
                Save-Workspaces ($list | Where-Object { $_ -ne $removed })
                Write-Host "Success: Removed workspace: $removed" -ForegroundColor Green
            } else { Write-Host "Error: Invalid selection." -ForegroundColor Red }
        }
        "list" {
            $list = @(Get-Workspaces)
            if ($list.Count -gt 0) {
                Write-Host "`nWorkspaces:" -ForegroundColor Cyan
                $list | ForEach-Object { Write-Host "  - $_" }
                Write-Host ""
            } else { Write-Host "Note: Workspace list is empty." -ForegroundColor Gray }
        }

        # --- tool management ---
        "tool" {
            $tools = @(Get-Tools)
            switch ($arg1) {
                "add" {
                    if (-not $arg1 -or -not $arg2) {
                        # arg1 is "add", need name=arg2 and command from next...
                        # actually positional: ws tool add <name> <command>
                        # arg1="add", arg2=name, but command is Position=3 which we didn't capture
                        # Need to re-read from user
                        Write-Host "Error: Usage: ws tool add <name> <command>" -ForegroundColor Red; return
                    }
                    # arg2 = name, but we need the launch command too
                    # Let's prompt for the command if not provided
                    $toolName = $arg2
                    $toolCmd  = Read-Host "Enter the shell command to launch '$toolName'"
                    if ([string]::IsNullOrWhiteSpace($toolCmd)) { Write-Host "Error: Command cannot be empty." -ForegroundColor Red; return }
                    if ($tools | Where-Object { $_.command -eq $toolCmd }) {
                        Write-Host "Note: Tool with command '$toolCmd' already exists." -ForegroundColor Yellow; return
                    }
                    $tools += [PSCustomObject]@{ name = $toolName; command = $toolCmd }
                    Save-Tools $tools
                    Write-Host "Success: Registered tool '$toolName' (command: $toolCmd)" -ForegroundColor Green
                }
                "remove" {
                    if ($tools.Count -eq 0) { Write-Host "Note: Tool list is empty." -ForegroundColor Gray; return }
                    Write-Host "`n--- Select a Tool to Remove ---" -ForegroundColor Yellow
                    for ($i = 0; $i -lt $tools.Count; $i++) { Write-Host "[$i] $($tools[$i].name)  ($($tools[$i].command))" }
                    Write-Host "[q] Cancel"
                    $choice = Read-Host "`nEnter selection index to remove"
                    if ($choice -eq 'q' -or [string]::IsNullOrWhiteSpace($choice)) { return }
                    if ($choice -match '^\d+$' -and [int]$choice -lt $tools.Count) {
                        $removed = $tools[[int]$choice]
                        Save-Tools ($tools | Where-Object { $_.command -ne $removed.command })
                        Write-Host "Success: Removed tool '$($removed.name)'" -ForegroundColor Green
                    } else { Write-Host "Error: Invalid selection." -ForegroundColor Red }
                }
                "list" {
                    if ($tools.Count -gt 0) {
                        Write-Host "`nRegistered Tools:" -ForegroundColor Cyan
                        $tools | ForEach-Object { Write-Host "  - $($_.name)  (command: $($_.command))" }
                        Write-Host ""
                    } else { Write-Host "Note: Tool list is empty." -ForegroundColor Gray }
                }
                default { Show-WsHelp }
            }
        }

        "help"    { Show-WsHelp }
        default   { Show-WsHelp }
    }
}

# --- ai: Unified Launcher ---

function ai {
    $tools = @(Get-Tools)
    $workspaces = @(Get-Workspaces)

    if ($tools.Count -eq 0) {
        Write-Host "`nNo AI tools registered yet." -ForegroundColor Yellow
        $confirm = Read-Host "Would you like to add one now? [Y/n]"
        if ($confirm -eq 'n') { return }
        $toolName = Read-Host "Enter tool name (e.g. Claude Code)"
        if ([string]::IsNullOrWhiteSpace($toolName)) { Write-Host "Error: Name cannot be empty." -ForegroundColor Red; return }
        $toolCmd = Read-Host "Enter shell command to launch '$toolName' (e.g. claude)"
        if ([string]::IsNullOrWhiteSpace($toolCmd)) { Write-Host "Error: Command cannot be empty." -ForegroundColor Red; return }
        $tools += [PSCustomObject]@{ name = $toolName; command = $toolCmd }
        Save-Tools $tools
        Write-Host "Success: Registered '$toolName'" -ForegroundColor Green
    }

    if ($workspaces.Count -eq 0) {
        Write-Host "`nNo workspaces added yet." -ForegroundColor Yellow
        $confirm = Read-Host "Would you like to add one now? [Y/n]"
        if ($confirm -eq 'n') { return }
        $wsPath = Read-Host "Enter workspace path ('.' for current directory)"
        if ([string]::IsNullOrWhiteSpace($wsPath)) { Write-Host "Error: Path cannot be empty." -ForegroundColor Red; return }
        try {
            $fullPath = Resolve-Path $wsPath -ErrorAction Stop
            $workspaces += $fullPath.Path
            Save-Workspaces $workspaces
            Write-Host "Success: Added workspace: $($fullPath.Path)" -ForegroundColor Green
        } catch { Write-Host "Error: Path does not exist!" -ForegroundColor Red; return }
    }

    # Step 1: Select tool
    Write-Host "`n--- Select AI Tool ---" -ForegroundColor Cyan
    for ($i = 0; $i -lt $tools.Count; $i++) { Write-Host "[$i] $($tools[$i].name)" }
    Write-Host "[q] Quit"
    $toolChoice = Read-Host "`nEnter selection index"
    if ($toolChoice -eq 'q' -or [string]::IsNullOrWhiteSpace($toolChoice)) { return }
    if (-not ($toolChoice -match '^\d+$') -or [int]$toolChoice -ge $tools.Count) {
        Write-Host "Error: Invalid selection." -ForegroundColor Red; return
    }
    $selectedTool = $tools[[int]$toolChoice]

    # Step 2: Select workspace
    Write-Host "`n--- Select Workspace ---" -ForegroundColor Cyan
    for ($i = 0; $i -lt $workspaces.Count; $i++) { Write-Host "[$i] $($workspaces[$i])" }
    Write-Host "[q] Quit"
    $wsChoice = Read-Host "`nEnter selection index"
    if ($wsChoice -eq 'q' -or [string]::IsNullOrWhiteSpace($wsChoice)) { return }
    if (-not ($wsChoice -match '^\d+$') -or [int]$wsChoice -ge $workspaces.Count) {
        Write-Host "Error: Invalid selection." -ForegroundColor Red; return
    }
    $selectedWs = $workspaces[[int]$wsChoice]

    # Step 3: Launch
    Set-Location -Path $selectedWs
    Write-Host "Switched to: $selectedWs" -ForegroundColor Green
    Write-Host "Launching: $($selectedTool.name)...`n" -ForegroundColor Cyan
    & $selectedTool.command
}

Export-ModuleMember -Function ai, ws
