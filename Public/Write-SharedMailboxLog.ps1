function Write-SharedMailboxLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Level = 'Info',

        [string]$LogPath = "$PSScriptRoot\..\..\logs\SharedMailbox.log"
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Ensure log directory exists
    $logDir = Split-Path $LogPath -Parent
    if (-not (Test-Path $logDir)) {
        $null = New-Item -ItemType Directory -Force -Path $logDir
    }

    # Write to file
    Add-Content -Path $LogPath -Value $logMessage

    # Write to console with color
    switch ($Level) {
        'Info'    { Write-Host $logMessage -ForegroundColor Green }
        'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
        'Error'   { Write-Host $logMessage -ForegroundColor Red }
    }
}