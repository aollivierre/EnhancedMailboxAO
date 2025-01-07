# Required modules
#Requires -Modules Microsoft.Graph.Users, Microsoft.Graph.Groups, Microsoft.Graph.Authentication, Microsoft.Graph.Identity.SignIns, PSWriteHTML

# Configuration
$domainPrefixes = @{
    'ictc-ctic.org'                    = 'ORG'
    'e-talent.ca'                      = 'TAL'
    # ... (rest of your prefixes)
}

$delegates = @(
    "s.sood@ictc-ctic.ca",
    "a.agzamov@ictc-ctic.ca",
    "o.sanya@ictc-ctic.ca"
)

$metadata = @{
    Department  = "Product Team"
    Comment     = "Apollo: Sales Intelligence and Engagement Platform"
    RequestDate = "Dec 3, 2024"
    CreatedBy   = "AOllivierre - Nova Admin"
    RequestedBy = "Surabhi Sood"
    ApprovedBy  = "Aziz Agzamov"
    IvantiTask  = "287480"
    IvantiSR    = "140522"
}

$securityGroupId = "68cbfcbb-9f6f-4cdb-af04-595143c2d028"

function Export-CombinedReport {
    param (
        $Results,
        $OutputDir,
        $Metadata,
        $TapResults
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $htmlPath = Join-Path $OutputDir "CombinedReport_$timestamp.html"
    $csvPath = Join-Path $OutputDir "CombinedReport_$timestamp.csv"
    
    # Export to CSV
    $Results | Export-Csv -Path $csvPath -NoTypeInformation
    
    $tapMetadata = @{
        TotalUsers = $TapResults.Count
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
    
    return @{
        CSVPath = $csvPath
        HTMLPath = $htmlPath
    }
}

function New-CombinedMailboxAndTap {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName = 'CSV')]
        [string]$CsvPath,
        
        [Parameter()]
        [ValidateRange(10, 43200)]
        [int]$TapLifetimeInMinutes = 43200,
        
        [Parameter()]
        [string]$OutputDir = ".\Combined_Reports"
    )
    
    # Create output directory
    $null = New-Item -ItemType Directory -Force -Path $OutputDir
    
    try {
        # Initialize results
        $mailboxResults = [System.Collections.ArrayList]::new()
        $tapResults = [System.Collections.ArrayList]::new()
        
        # Import and validate CSV
        $emails = Import-ValidatedCSV -Path $CsvPath
        
        # Process each entry
        foreach ($entry in $emails) {
            try {
                # Create mailbox and process
                $mailboxResult = New-ProcessedMailbox -Entry $entry
                $null = $mailboxResults.Add($mailboxResult)
                
                # Generate TAP
                $tapResult = New-UserTap -UserPrincipalName $entry.email -LifetimeInMinutes $TapLifetimeInMinutes
                $null = $tapResults.Add($tapResult)
                
            }
            catch {
                Write-Error "Failed to process $($entry.email): $_"
            }
        }
        
        # Generate combined report
        Export-CombinedReport -Results $mailboxResults -TapResults $tapResults -OutputDir $OutputDir -Metadata $metadata
        
        return @{
            MailboxResults = $mailboxResults
            TapResults = $tapResults
        }
    }
    catch {
        Write-Error "Error in main processing: $_"
    }
}

# Example usage
$params = @{
    CsvPath = "C:\path\to\your\emails.csv"
    TapLifetimeInMinutes = 43200  # 30 days
    OutputDir = "C:\Reports"
}

New-CombinedMailboxAndTap @params