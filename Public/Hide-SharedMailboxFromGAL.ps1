function Hide-SharedMailboxFromGAL {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SharedMailboxEmail
    )
    try {
        # Initial check
        $mailbox = Get-Mailbox -Identity $SharedMailboxEmail -ErrorAction Stop
        if ($mailbox.RecipientTypeDetails -ne "SharedMailbox") {
            Write-Error "The specified mailbox is not a shared mailbox"
            return $false
        }

        # Store ExchangeGuid for consistent lookup
        $mailboxGuid = $mailbox.ExchangeGuid

        Write-Host "Initial GAL Status: $($mailbox.HiddenFromAddressListsEnabled)" -ForegroundColor Yellow
        
        # Set GAL status
        Set-Mailbox -Identity $mailboxGuid -HiddenFromAddressListsEnabled $true
        
        # Verify change with GUID
        $updatedMailbox = Get-Mailbox -Identity $mailboxGuid
        if ($updatedMailbox.HiddenFromAddressListsEnabled) {
            Write-Host "Mailbox successfully hidden from GAL: $SharedMailboxEmail" -ForegroundColor Green
            Write-Host "Final GAL Status: $($updatedMailbox.HiddenFromAddressListsEnabled)" -ForegroundColor Green
            return $true
        }
        else {
            Write-Warning "Failed to hide mailbox from GAL. Current status: $($updatedMailbox.HiddenFromAddressListsEnabled)"
            return $false
        }
    }
    catch {
        Write-Error "Error occurred: $_"
        return $false
    }
}
