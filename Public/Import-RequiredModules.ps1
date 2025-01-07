function Import-RequiredModules {
    [CmdletBinding()]
    param()
    
    $logParams = @{
        Message = "Importing required Microsoft Graph modules"
        Level   = "Info"
    }
    Write-SharedMailboxLog @logParams

    try {
        # Remove existing modules first to avoid assembly conflicts
        $modulesToRemove = @(
            'Microsoft.Graph.Users'
            'Microsoft.Graph.Groups'
            'Microsoft.Graph.Authentication'
        )

        foreach ($module in $modulesToRemove) {
            if (Get-Module $module) {
                $removeParams = @{
                    Name        = $module
                    Force       = $true
                    ErrorAction = "SilentlyContinue"
                }
                Remove-Module @removeParams
            }
        }

        # Import required modules
        $modulesToImport = @(
            'Microsoft.Graph.Users'
            'Microsoft.Graph.Groups'
            'Microsoft.Graph.Authentication'
        )

        foreach ($module in $modulesToImport) {
            $importParams = @{
                Name        = $module
                Force       = $true
                ErrorAction = "Stop"
            }
            Import-Module @importParams
            
            $logParams = @{
                Message = "Successfully imported module: $module"
                Level   = "Info"
            }
            Write-SharedMailboxLog @logParams
        }

        return $true
    }
    catch {
        $logParams = @{
            Message = "Failed to import required modules: $_"
            Level   = "Error"
        }
        Write-SharedMailboxLog @logParams
        throw
    }
}