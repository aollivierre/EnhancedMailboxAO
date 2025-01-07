
function Connect-ExchangeOnlineWithCheck {
    [CmdletBinding()]
    param()
    
    Write-SharedMailboxLog "Checking Exchange Online connection..."
    try {
        $exchangeConnection = Get-PSSession | Where-Object { 
            $_.ConfigurationName -eq 'Microsoft.Exchange' -and $_.State -eq 'Opened' 
        }
        
        if ($null -eq $exchangeConnection) {
            Write-SharedMailboxLog "No active Exchange Online session found. Connecting..." -Level Warning
            Connect-ExchangeOnline
            Write-SharedMailboxLog "Successfully connected to Exchange Online" -Level Info
        }
        else {
            Write-SharedMailboxLog "Active Exchange Online session found" -Level Info
        }
    }
    catch {
        Write-SharedMailboxLog "Error checking Exchange Online connection: $_" -Level Error
        throw
    }
}