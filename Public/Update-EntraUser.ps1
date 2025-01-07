
function Update-EntraUser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$MailboxName,
        [Parameter(Mandatory)]
        [string]$TargetEmail,
        [Parameter(Mandatory)]
        [hashtable]$Metadata,
        [Parameter(Mandatory)]
        [string]$SecurityGroupId
    )

    $logParams = @{
        Message = "Starting Entra user update process for $TargetEmail"
        Level   = "Info"
    }
    Write-SharedMailboxLog @logParams
    
    # Initialize retry parameters
    $maxAttempts = 5
    $attempt = 1
    $baseDelay = 10
    $success = $false
    
    do {
        try {
            $logParams = @{
                Message = "Attempt $attempt Retrieving ExternalDirectoryObjectId"
                Level   = "Info"
            }
            Write-SharedMailboxLog @logParams

            # Get user ID with retry
            $mailbox = $null
            $retryCount = 0

            $mailboxParams = @{
                Identity    = $MailboxName
                ErrorAction = "Stop"
            }

            while ($null -eq $mailbox -and $retryCount -lt 3) {
                $mailbox = Get-Mailbox @mailboxParams
                if ($null -eq $mailbox) {
                    $retryCount++
                    Start-Sleep -Seconds 5
                }
            }

            if ($null -eq $mailbox) {
                throw "Failed to retrieve mailbox after multiple attempts"
            }

            $userId = $mailbox.ExternalDirectoryObjectId
            if ([string]::IsNullOrEmpty($userId)) {
                throw "ExternalDirectoryObjectId is null or empty"
            }

            $logParams = @{
                Message = "Retrieved UserId: $userId"
                Level   = "Info"
            }
            Write-SharedMailboxLog @logParams

            # # Update user properties
            # $userParams = @{
            #     UserId            = $userId
            #     AccountEnabled    = $true
            #     UserPrincipalName = $TargetEmail
            #     Department        = $Metadata.Department
            #     JobTitle          = "Shared Mailbox - Apollo/Lemlist Integration"
            #     CompanyName       = "ICTC"
            # }


            # Update the userParams in Update-EntraUser function to include password
            $userParams = @{
                UserId            = $userId
                AccountEnabled    = $true
                UserPrincipalName = $TargetEmail
                Department        = $Metadata.Department
                JobTitle          = "Shared Mailbox - Apollo/Lemlist Integration"
                CompanyName       = "ICTC"
                PasswordProfile   = @{
                    Password                      = $password
                    ForceChangePasswordNextSignIn = $false
                }
            }


            $logParams = @{
                Message = "Updating user properties in Entra"
                Level   = "Info"
            }
            Write-SharedMailboxLog @logParams

            Update-MgUser @userParams

            # Verify the update
            $mgUserParams = @{
                UserId = $userId
            }
            $updatedUser = Get-MgUser @mgUserParams

            if ($updatedUser.UserPrincipalName -ne $TargetEmail) {
                throw "UPN verification failed. Expected: $TargetEmail, Got: $($updatedUser.UserPrincipalName)"
            }

            # Add to security group
            $logParams = @{
                Message = "Adding user to security group"
                Level   = "Info"
            }
            Write-SharedMailboxLog @logParams

            $groupParams = @{
                GroupId           = $SecurityGroupId
                DirectoryObjectId = $userId
            }
            New-MgGroupMember @groupParams

            $success = $true
            
            $logParams = @{
                Message = "Successfully updated Entra user and added to security group"
                Level   = "Info"
            }
            Write-SharedMailboxLog @logParams

            return @{
                Success = $true
                UserId  = $userId
                Message = "Update completed successfully"
            }
        }
        catch {
            $delay = $baseDelay * [Math]::Pow(2, ($attempt - 1))
            
            $logParams = @{
                Message = "Attempt $attempt failed: $_"
                Level   = "Warning"
            }
            Write-SharedMailboxLog @logParams
            
            if ($attempt -lt $maxAttempts) {
                $logParams = @{
                    Message = "Waiting $delay seconds before retry..."
                    Level   = "Warning"
                }
                Write-SharedMailboxLog @logParams
                Start-Sleep -Seconds $delay
            }
            $attempt++
            
            if ($attempt -gt $maxAttempts) {
                $logParams = @{
                    Message = "All attempts exhausted. Final error: $_"
                    Level   = "Error"
                }
                Write-SharedMailboxLog @logParams

                return @{
                    Success = $false
                    Error   = $_
                    Message = "Failed after $maxAttempts attempts"
                }
            }
        }
    } while (-not $success -and $attempt -le $maxAttempts)
}
