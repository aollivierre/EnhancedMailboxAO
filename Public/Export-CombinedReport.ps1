function Export-CombinedReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object[]]$Results,
        
        [Parameter(Mandatory)]
        [string]$OutputDir,
        
        [Parameter()]
        [hashtable]$Metadata,
        
        [Parameter()]
        [object[]]$TapResults
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $htmlPath = Join-Path $OutputDir "CombinedReport_$timestamp.html"
    $csvPath = Join-Path $OutputDir "CombinedReport_$timestamp.csv"
    
    # Export to CSV
    $Results | Export-Csv -Path $csvPath -NoTypeInformation
    
    $tapMetadata = @{
        TotalUsers   = $TapResults.Count
        SuccessCount = ($TapResults | Where-Object Status -eq "Success").Count
        FailureCount = ($TapResults | Where-Object Status -eq "Failed").Count
    }
    
    New-HTML -Title "Combined Mailbox and TAP Report" -FilePath $htmlPath -ShowHTML {
        New-HTMLSection -HeaderText "Request Summary" {
            New-HTMLPanel {
                New-HTMLText -Text @"
                <h3>Mailbox Creation Details</h3>
                <ul>
                    <li>Department: $($Metadata.Department)</li>
                    <li>Request Date: $($Metadata.RequestDate)</li>
                    <li>Created By: $($Metadata.CreatedBy)</li>
                    <li>Requested By: $($Metadata.RequestedBy)</li>
                    <li>Approved By: $($Metadata.ApprovedBy)</li>
                    <li>Ivanti Task: $($Metadata.IvantiTask)</li>
                    <li>Ivanti SR: $($Metadata.IvantiSR)</li>
                </ul>
                <h3>TAP Generation Summary</h3>
                <ul>
                    <li>Total Users Processed: $($tapMetadata.TotalUsers)</li>
                    <li>Successful TAP Generations: $($tapMetadata.SuccessCount)</li>
                    <li>Failed TAP Generations: $($tapMetadata.FailureCount)</li>
                </ul>
"@
            }
        }
        
        New-HTMLSection -HeaderText "Created Mailboxes" {
            New-HTMLTable -DataTable $Results -ScrollX -Buttons @('copyHtml5', 'excelHtml5', 'csvHtml5') {
                New-TableCondition -Name 'CreationStatus' -ComparisonType string -Operator contains -Value 'Failed' -BackgroundColor Salmon -Color Black
                New-TableCondition -Name 'Status' -ComparisonType string -Operator eq -Value 'Success' -BackgroundColor LightGreen -Color Black
            }
        }
        
        New-HTMLSection -HeaderText "TAP Generation Details" {
            New-HTMLTable -DataTable $TapResults -ScrollX -Buttons @('copyHtml5', 'excelHtml5', 'csvHtml5') {
                New-TableCondition -Name 'Status' -ComparisonType string -Operator eq -Value 'Failed' -BackgroundColor Salmon -Color Black
                New-TableCondition -Name 'Status' -ComparisonType string -Operator eq -Value 'Success' -BackgroundColor LightGreen -Color Black
            }
        }
    }


    # Export standard reports (HTML and CSV)
    Export-TapGenerationReport -Results $Results -OutputDir $OutputDir
    
    # Export Keeper-compatible CSV
    Export-KeeperCompatibleCSV -Results $Results -OutputDir $OutputDir -Metadata $Metadata
    
    return @{
        CSVPath  = $csvPath
        HTMLPath = $htmlPath
    }
}