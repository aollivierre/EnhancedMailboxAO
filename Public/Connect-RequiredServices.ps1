
function Connect-RequiredServices {
    [CmdletBinding()]
    param()
    
    Write-SharedMailboxLog "=== Starting Service Connections ===" -Level Info
    
    try {
        Connect-GraphWithScope
        Connect-ExchangeOnlineWithCheck
        Write-SharedMailboxLog "=== All Service Connections Completed Successfully ===" -Level Info
    }
    catch {
        Write-SharedMailboxLog "=== Service Connection Process Failed ===" -Level Error
        throw "Failed to connect to required services: $_"
    }
}