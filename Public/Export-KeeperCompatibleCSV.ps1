function Export-KeeperCompatibleCSV {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object[]]$Results,
        
        [Parameter(Mandatory)]
        [string]$OutputDir,
        
        [Parameter()]
        [hashtable]$Metadata
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $keeperCsvPath = Join-Path $OutputDir "keeper_format_$timestamp.csv"
    $keeperHeaderlessPath = Join-Path $OutputDir "keeper_import_$timestamp.csv"
    
    # Transform results to Keeper format
    $keeperData = $Results | ForEach-Object {
        [PSCustomObject]@{
            # 'Please ignore this column when importing in Keeper' = 'Please ignore this column when importing in Keeper'
            Folder                  = "Please ignore this column when importing in Keeper"  # You can customize this
            Title                   = $_.DisplayName
            Login                   = $_.Email
            Password                = $_.Password
            URL                     = "https://outlook.office.com/mail"  # Default URL for mailboxes
            Notes                   = $_.Comment
            "Shared Folder"         = "ICTC-Apollo-Lemlist-Service Accounts"  # You can customize this
            "Custom Field Name 1"   = "RequestDate"
            "Custom Field Value 1"  = $_.RequestDate
            "Custom Field Name 2"   = "CreatedBy"
            "Custom Field Value 2"  = $_.CreatedBy
            "Custom Field Name 3"   = "ApprovedBy"
            "Custom Field Value 3"  = $_.ApprovedBy
            "Custom Field Name 4"   = "IvantiTask"
            "Custom Field Value 4"  = $_.IvantiTask
            "Custom Field Name 5"   = "IvantiSR"
            "Custom Field Value 5"  = $_.IvantiSR
            "Custom Field Name 6"   = "CreationStatus"
            "Custom Field Value 6"  = $_.CreationStatus
            "Custom Field Name 7"   = "ArchiveStatus"
            "Custom Field Value 7"  = $_.ArchiveStatus
            "Custom Field Name 8"   = "GALStatus"
            "Custom Field Value 8"  = $_.GALStatus
            "Custom Field Name 9"   = "CreationDate"
            "Custom Field Value 9"  = $_.CreationDate
            "Custom Field Name 10"  = "Delegates"
            "Custom Field Value 10" = $_.Delegates
            "Custom Field Name 11"  = "SecurityGroup"
            "Custom Field Value 11" = $_.SecurityGroup
            "Custom Field Name 12"  = "MFA"
            "Custom Field Value 12" = $_.MFA
            "Custom Field Name 13"  = "TAPCode"
            "Custom Field Value 13" = $_.TAPCode
            "Custom Field Name 14"  = "TAP ExpirationTime"
            "Custom Field Value 14" = $_.TAPExpiration
            "Custom Field Name 15"  = "TAP GeneratedTime"
            "Custom Field Value 15" = $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            "Custom Field Name 16"  = "TAP ValidityDays"
            "Custom Field Value 16" = "30"  # Assuming 30 days validity
            "Custom Field Name 17"  = "TAP MultiUse"
            "Custom Field Value 17" = "True"  # Assuming multi-use TAPs
        }
    }
    
    # Export to CSV with headers (for reference)
    $keeperData | Export-Csv -Path $keeperCsvPath -NoTypeInformation
    
    # Create headerless version for Keeper import
    $keeperData | ConvertTo-Csv -NoTypeInformation | Select-Object -Skip 1 | Set-Content -Path $keeperHeaderlessPath
    
    Write-Host "Keeper-compatible CSV files exported:" -ForegroundColor Green
    Write-Host "Reference copy (with headers): $keeperCsvPath" -ForegroundColor Green
    Write-Host "Keeper import copy (no headers): $keeperHeaderlessPath" -ForegroundColor Green
    
    return @{
        ReferenceCSV = $keeperCsvPath
        ImportCSV    = $keeperHeaderlessPath
    }
}