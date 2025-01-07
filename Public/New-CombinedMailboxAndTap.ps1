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