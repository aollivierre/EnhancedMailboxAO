# function Connect-GraphWithScope {
#     [CmdletBinding()]
#     param()
    
#     $requiredScopes = @(
#         "UserAuthenticationMethod.ReadWrite.All"
#         "User.Read.All"
#     )
    
#     $currentContext = Get-MgContext
    
#     if ($null -eq $currentContext) {
#         Write-Host "No existing Graph connection found. Connecting..." -ForegroundColor Yellow
#         Connect-MgGraph -Scopes $requiredScopes
#         return
#     }
    
#     $missingScopes = $requiredScopes | Where-Object { $_ -notin $currentContext.Scopes }
    
#     if ($missingScopes) {
#         Write-Host "Missing required scopes. Reconnecting with all required scopes..." -ForegroundColor Yellow
#         Disconnect-MgGraph
#         Connect-MgGraph -Scopes $requiredScopes
#     }
# }





function Connect-GraphWithScope {
    [CmdletBinding()]
    param()
    
    $requiredScopes = @(
        "UserAuthenticationMethod.ReadWrite.All"
        "User.Read.All"
        "Group.ReadWrite.All"
        "Directory.ReadWrite.All"
        "User.ReadWrite.All"
    )
    
    Write-SharedMailboxLog "Checking Microsoft Graph connection..."
    $currentContext = Get-MgContext
    
    if ($null -eq $currentContext) {
        Write-SharedMailboxLog "No existing Graph connection found. Connecting..." -Level Warning
        Connect-MgGraph -Scopes $requiredScopes
        $newContext = Get-MgContext
        Write-SharedMailboxLog "Connected to Microsoft Graph as: $($newContext.Account)" -Level Info
        return
    }
    
    $missingScopes = $requiredScopes | Where-Object { $_ -notin $currentContext.Scopes }
    
    if ($missingScopes) {
        Write-SharedMailboxLog "Missing required scopes: $($missingScopes -join ', ')" -Level Warning
        Write-SharedMailboxLog "Reconnecting with all required scopes..." -Level Warning
        Disconnect-MgGraph
        Connect-MgGraph -Scopes $requiredScopes
        $newContext = Get-MgContext
        Write-SharedMailboxLog "Reconnected to Microsoft Graph as: $($newContext.Account)" -Level Info
    }
    else {
        Write-SharedMailboxLog "Already connected to Microsoft Graph with required scopes as: $($currentContext.Account)" -Level Info
    }
}