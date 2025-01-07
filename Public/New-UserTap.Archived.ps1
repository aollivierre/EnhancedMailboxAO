# function New-UserTap {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory)]
#         [string]$UserPrincipalName,
#         [int]$LifetimeInMinutes = 43200
#     )
    
#     try {
#         $tapParams = @{
#             StartDateTime = Get-Date
#             LifetimeInMinutes = $LifetimeInMinutes
#             IsUsableOnce = $false
#         }

#         $mgUserParams = @{
#             UserId = $UserPrincipalName
#             ErrorAction = 'Stop'
#         }
#         $user = Get-MgUser @mgUserParams
        
#         $newTapParams = @{
#             UserId = $user.Id
#             BodyParameter = $tapParams
#             ErrorAction = 'Stop'
#         }
#         $tap = New-MgUserAuthenticationTemporaryAccessPassMethod @newTapParams

#         [PSCustomObject]@{
#             UserPrincipalName = $UserPrincipalName
#             TAPCode = $tap.TemporaryAccessPass
#             ExpirationTime = $tap.StartDateTime.AddMinutes($LifetimeInMinutes)
#             GeneratedTime = Get-Date
#             ValidityDays = [math]::Round($LifetimeInMinutes / 1440, 2)
#             MultiUse = -not $tapParams.IsUsableOnce
#             Status = "Success"
#             ErrorMessage = ""
#         }
#     }
#     catch {
#         [PSCustomObject]@{
#             UserPrincipalName = $UserPrincipalName
#             TAPCode = "Error"
#             ExpirationTime = $null
#             GeneratedTime = Get-Date
#             ValidityDays = [math]::Round($LifetimeInMinutes / 1440, 2)
#             MultiUse = -not $tapParams.IsUsableOnce
#             Status = "Failed"
#             ErrorMessage = $_.Exception.Message
#         }
#     }
# }