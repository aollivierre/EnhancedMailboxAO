function Enable-SharedMailboxArchive {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SharedMailboxEmail
    )
    try {
        $mailbox = Get-Mailbox -Identity $SharedMailboxEmail -ErrorAction Stop
        if ($mailbox.RecipientTypeDetails -ne "SharedMailbox") {
            Write-Error "The specified mailbox is not a shared mailbox"
            return
        }
        
        Enable-Mailbox $SharedMailboxEmail -Archive
        
        $updatedMailbox = Get-Mailbox -Identity $SharedMailboxEmail
        if ($updatedMailbox.ArchiveStatus -eq "Active") {
            Write-Host "Archive successfully enabled for $SharedMailboxEmail" -ForegroundColor Green
            return $true
        }
        else {
            Write-Warning "Archive enabling process completed but archive is not active. Current status: $($updatedMailbox.ArchiveStatus)"
            return $false
        }
    }
    catch {
        Write-Error "Error occurred: $_"
        return $false
    }
}
