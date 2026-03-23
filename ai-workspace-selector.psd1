@{
    ModuleVersion     = '2.0.0'
    GUID              = 'b7e3d924-1f5a-4c8b-a2e6-3d9f0c1b2a4e'
    Author            = 'hereisaa'
    Description       = 'A unified PowerShell module to manage workspaces and launch any registered AI CLI tool.'
    PowerShellVersion = '5.1'
    RootModule        = 'ai-workspace-selector.psm1'
    FunctionsToExport = @('ai', 'ws')
    PrivateData       = @{
        PSData = @{
            Tags       = @('ai', 'workspace', 'selector', 'cli', 'gemini', 'claude')
            LicenseUri = 'https://opensource.org/licenses/MIT'
        }
    }
}
