function New-UserTap {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$UserPrincipalName,
        [int]$LifetimeInMinutes = 43200,
        [int]$MaxRetries = 3,
        [int]$RetryDelay = 5
    )
    
    $attempt = 0
    do {
        $attempt++
        try {
            Write-Verbose "Attempt $attempt to create TAP for $UserPrincipalName"
            
            $tapParams = @{
                StartDateTime = Get-Date
                LifetimeInMinutes = $LifetimeInMinutes
                IsUsableOnce = $false
            }

            $mgUserParams = @{
                UserId = $UserPrincipalName 
                ErrorAction = 'Stop'
            }
            
            Start-Sleep -Seconds ($attempt * $RetryDelay)
            $user = Get-MgUser @mgUserParams
            
            $newTapParams = @{
                UserId = $user.Id
                BodyParameter = $tapParams
                ErrorAction = 'Stop'
            }
            $tap = New-MgUserAuthenticationTemporaryAccessPassMethod @newTapParams

            Write-Host "Successfully created TAP for $UserPrincipalName" -ForegroundColor Green
            return [PSCustomObject]@{
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
            Write-Warning "Attempt $attempt failed for $UserPrincipalName : $_"
            if ($attempt -ge $MaxRetries) {
                Write-Error "Failed to create TAP after $MaxRetries attempts"
                return [PSCustomObject]@{
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
    } while ($attempt -lt $MaxRetries)
}