# Add these at the end of your script, just before the main execution block

function New-UserTap {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$UserPrincipalName,
        [int]$LifetimeInMinutes = 43200
    )
    
    try {
        $tapParams = @{
            StartDateTime = Get-Date
            LifetimeInMinutes = $LifetimeInMinutes
            IsUsableOnce = $false
        }

        $mgUserParams = @{
            UserId = $UserPrincipalName
            ErrorAction = 'Stop'
        }
        $user = Get-MgUser @mgUserParams
        
        $newTapParams = @{
            UserId = $user.Id
            BodyParameter = $tapParams
            ErrorAction = 'Stop'
        }
        $tap = New-MgUserAuthenticationTemporaryAccessPassMethod @newTapParams

        [PSCustomObject]@{
            UserPrincipalName = $UserPrincipalName
            TAPCode = $tap.TemporaryAccessPass
            ExpirationTime = $tap.StartDateTime.AddMinutes($LifetimeInMinutes)
            GeneratedTime = Get-Date
            ValidityDays = [math]::Round($LifetimeInMinutes / 1440, 2)
            MultiUse = -not $tapParams.IsUsableOnce
            Status = "Success"
            ErrorMessage = ""
        }
    }
    catch {
        [PSCustomObject]@{
            UserPrincipalName = $UserPrincipalName
            TAPCode = "Error"
            ExpirationTime = $null
            GeneratedTime = Get-Date
            ValidityDays = [math]::Round($LifetimeInMinutes / 1440, 2)
            MultiUse = -not $tapParams.IsUsableOnce
            Status = "Failed"
            ErrorMessage = $_.Exception.Message
        }
    }
}

function Export-CombinedReport {
    param (
        [Parameter(Mandatory)]
        $Results,
        [Parameter(Mandatory)]
        $OutputDir,
        [Parameter(Mandatory)]
        $Metadata,
        [Parameter(Mandatory)]
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
    
    $htmlParams = @{
        Title = "Combined Mailbox and TAP Report"
        FilePath = $htmlPath
        ShowHTML = $true
    }

    New-HTML @htmlParams {
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
        
        New-HTMLSection -HeaderText "Created Mailboxes and TAPs" {
            New-HTMLTable -DataTable $Results -ScrollX -Buttons @('copyHtml5', 'excelHtml5', 'csvHtml5') {
                New-TableCondition -Name 'CreationStatus' -ComparisonType string -Operator contains -Value 'Failed' -BackgroundColor Salmon -Color Black
                New-TableCondition -Name 'Status' -ComparisonType string -Operator eq -Value 'Success' -BackgroundColor LightGreen -Color Black
            }
        }
    }
    
    return @{
        CSVPath = $csvPath
        HTMLPath = $htmlPath
    }
}

# Modify your existing foreach loop with this addition:
[System.Collections.ArrayList]$tapResults = @()

foreach ($entry in $emails) {
    try {
        # Your existing mailbox creation code...

        # Add TAP generation after mailbox creation succeeds
        $tapResult = New-UserTap -UserPrincipalName $entry.email
        [void]$tapResults.Add($tapResult)

        # Update your results object to include TAP info
        [void]$results.Add([PSCustomObject]@{
            Email          = $entry.email
            DisplayName    = $mailboxName
            Department     = $metadata.Department
            Password      = $password
            TAPCode       = $tapResult.TAPCode
            TAPExpiration = $tapResult.ExpirationTime
            Comment       = $metadata.Comment
            RequestDate   = $metadata.RequestDate
            CreatedBy     = $metadata.CreatedBy
            RequestedBy   = $metadata.RequestedBy
            ApprovedBy    = $metadata.ApprovedBy
            IvantiTask    = $metadata.IvantiTask
            IvantiSR      = $metadata.IvantiSR
            CreationStatus = if ($null -eq $mailbox) { "Created" } else { "Updated" }
            ArchiveStatus = if ($archiveEnabled) { "Enabled" } else { "Not Modified" }
            GALStatus     = if ($hiddenFromGAL) { "Hidden from GAL" } else { "Not Modified" }
            CreationDate  = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Delegates     = $delegates -join "; "
            SecurityGroup = "Added"
            MFA          = "User must add TOTP code by scanning QR Code with Keeper Desktop"
        })
    }
    catch {
        # Your existing error handling...
    }
}

# Replace your existing export code with:
Export-CombinedReport -Results $results -OutputDir $outputDir -Metadata $metadata -TapResults $tapResults