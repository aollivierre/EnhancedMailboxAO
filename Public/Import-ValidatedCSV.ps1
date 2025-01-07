function Import-ValidatedCSV {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [string[]]$RequiredColumns = @('email')
    )

    try {
        if (-not (Test-Path -Path $Path)) {
            throw [System.IO.FileNotFoundException]::new("CSV file not found: $Path")
        }

        $content = Import-Csv -Path $Path -ErrorAction Stop
        
        if ($content.Count -eq 0) {
            throw [System.InvalidOperationException]::new("The CSV file contains no data")
        }

        # Header validation
        $headers = $content[0].PSObject.Properties.Name
        $missingColumns = $RequiredColumns | Where-Object { $_ -notin $headers }
        
        if ($missingColumns) {
            throw [System.FormatException]::new("Missing required columns: $($missingColumns -join ', ')")
        }

        # Email validation and uniqueness check
        $emailRegex = '^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$'
        $duplicates = $content | Group-Object email | Where-Object Count -gt 1
        $invalidEmails = $content | Where-Object { 
            [string]::IsNullOrWhiteSpace($_.email) -or
            $_.email -notmatch $emailRegex -or
            $_.email.Split('@').Count -ne 2 -or
            $_.email.Contains(',')
        }

        if ($duplicates) {
            throw [System.ArgumentException]::new("Duplicate emails found: $($duplicates.Name -join ', ')")
        }

        if ($invalidEmails) {
            throw [System.FormatException]::new("Invalid email format found: $($invalidEmails.email -join ', ')")
        }

        return $content
    }
    catch {
        Write-Error "CSV validation failed: $_"
        throw
    }
}