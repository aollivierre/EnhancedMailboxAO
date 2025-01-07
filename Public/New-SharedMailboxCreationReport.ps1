function New-SharedMailboxCreationReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Results,
        
        [Parameter(Mandatory)]
        [string]$OutputPath,
        
        [Parameter(Mandatory)]
        [hashtable]$Metadata
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $htmlPath = Join-Path $OutputPath "SharedMailbox_$timestamp.html"
    $csvPath = Join-Path $OutputPath "SharedMailbox_$timestamp.csv"
    
    # Export CSV
    $Results | Export-Csv -Path $csvPath -NoTypeInformation
    
    # Create HTML report
    New-HTML -FilePath $htmlPath -ShowHTML {
        New-HTMLSection -HeaderText "Mailbox Creation Summary" {
            New-HTMLPanel {
                New-HTMLText -Text @"
                <h3>Operation Details</h3>
                <ul>
                    <li>Department: $($Metadata.Department)</li>
                    <li>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</li>
                    <li>Task: $($Metadata.IvantiTask)</li>
                    <li>SR: $($Metadata.IvantiSR)</li>
                </ul>
"@
            }
        }
        
        New-HTMLSection -HeaderText "Results" {
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
