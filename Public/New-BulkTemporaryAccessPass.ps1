function New-BulkTemporaryAccessPass {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName = 'Direct')]
        [string[]]$UserPrincipalNames,
        
        [Parameter(Mandatory, ParameterSetName = 'CSV')]
        [string]$CsvPath,
        
        [Parameter()]
        [ValidateRange(10, 43200)]
        [int]$LifetimeInMinutes = 43200, # 30 days default
        
        [Parameter()]
        [string]$ReportPath = ".\TAP_Report"
    )

    # Ensure output directory exists
    $null = New-Item -ItemType Directory -Force -Path $ReportPath

    # Process input method
    if ($PSCmdlet.ParameterSetName -eq 'CSV') {
        if (-not (Test-Path $CsvPath)) {
            Write-Error "CSV file not found: $CsvPath"
            return
        }
        $UserPrincipalNames = Import-Csv $CsvPath | Select-Object -ExpandProperty UserPrincipalName
    }

    # Initialize results array using ArrayList for better performance
    $results = [System.Collections.ArrayList]::new()

    # Ensure proper Graph authentication
    Connect-GraphWithScope

    # TAP configuration
    $tapParams = @{
        StartDateTime = Get-Date
        LifetimeInMinutes = $LifetimeInMinutes
        IsUsableOnce = $false  # Set to multi-use
    }

    foreach ($upn in $UserPrincipalNames) {
        try {
            # Get user ID first
            $mgUserParams = @{
                UserId = $upn
                ErrorAction = 'Stop'
            }
            $user = Get-MgUser @mgUserParams
            
            # Create TAP
            $newTapParams = @{
                UserId = $user.Id
                BodyParameter = $tapParams
                ErrorAction = 'Stop'
            }
            $tap = New-MgUserAuthenticationTemporaryAccessPassMethod @newTapParams

            $resultObject = [PSCustomObject]@{
                UserPrincipalName = $upn
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
            $resultObject = [PSCustomObject]@{
                UserPrincipalName = $upn
                TAPCode = "Error"
                ExpirationTime = $null
                GeneratedTime = Get-Date
                ValidityDays = [math]::Round($LifetimeInMinutes / 1440, 2)
                MultiUse = -not $tapParams.IsUsableOnce
                Status = "Failed"
                ErrorMessage = $_.Exception.Message
            }
        }

        $null = $results.Add($resultObject)
        
        # Display progress in console
        $statusParams = @{
            Object = "Processed $upn - Status: $($resultObject.Status)"
            ForegroundColor = if ($resultObject.Status -eq "Success") { "Green" } else { "Red" }
        }
        Write-Host @statusParams
    }

    # Generate reports using the new export function
    Export-TapGenerationReport -Results $results -OutputDir $ReportPath

    return $results
}