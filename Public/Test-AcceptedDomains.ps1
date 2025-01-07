function Test-AcceptedDomains {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string[]]$EmailAddresses,
        [switch]$Detailed
    )
 
    Write-Host "Starting domain validation for $($EmailAddresses.Count) email addresses" -ForegroundColor Green
    
    try {
        $acceptedDomains = Get-AcceptedDomain
        Write-Host "Retrieved $($acceptedDomains.Count) accepted domains from Exchange" -ForegroundColor Green
        
        # First validate all domains before processing any
        foreach ($email in $EmailAddresses) {
            $domain = ($email -split '@')[1]
            if (-not ($acceptedDomains.DomainName -contains $domain)) {
                Write-Error "Domain validation failed. Invalid domain found: $domain"
                return $false
            }
        }
        
        # If we get here, all domains are valid - proceed with detailed results
        $results = [System.Collections.ArrayList]::new()
        foreach ($email in $EmailAddresses) {
            $domain = ($email -split '@')[1]
            Write-Verbose "Domain $domain is valid"
            
            $null = $results.Add([PSCustomObject]@{
                Email = $email
                Domain = $domain
                IsAccepted = $true
                Status = "Valid"
            })
        }
 
        Write-Host "All domains validated successfully" -ForegroundColor Green
        
        if ($Detailed) {
            return $results
        }
        return $true
    }
    catch {
        Write-Error "Domain validation failed: $_"
        return $false
    }
 }