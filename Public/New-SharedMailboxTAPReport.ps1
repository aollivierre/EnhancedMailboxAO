function New-SharedMailboxTAPReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Results,
        
        [Parameter(Mandatory)]
        [string]$OutputPath
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $htmlPath = Join-Path $OutputPath "TAP_$timestamp.html"
    $csvPath = Join-Path $OutputPath "TAP_$timestamp.csv"
    
    # Export CSV with TAP prefix for Keeper compatibility
    $Results | Select-Object @{N='TAP_UserPrincipalName';E={$_.UserPrincipalName}},
                           @{N='TAP_Code';E={$_.TAPCode}},
                           @{N='TAP_ExpirationTime';E={$_.ExpirationTime}},
                           @{N='TAP_GeneratedTime';E={$_.GeneratedTime}},
                           @{N='TAP_ValidityDays';E={$_.ValidityDays}},
                           @{N='TAP_MultiUse';E={$_.MultiUse}},
                           @{N='TAP_Status';E={$_.Status}} |
    Export-Csv -Path $csvPath -NoTypeInformation
    
    New-HTML -FilePath $htmlPath -ShowHTML {
        New-HTMLSection -HeaderText "TAP Generation Results" {
            New-HTMLTable -DataTable $Results -ScrollX -SearchBuilder {
                New-TableCondition -Name 'Status' -ComparisonType string -Operator eq -Value 'Failed' -BackgroundColor Salmon -Color Black
                New-TableCondition -Name 'Status' -ComparisonType string -Operator eq -Value 'Success' -BackgroundColor LightGreen -Color Black
            }
        }
    }

    return @{
        CSVPath = $csvPath
        HTMLPath = $htmlPath
    }
}