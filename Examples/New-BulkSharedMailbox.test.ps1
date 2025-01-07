#Requires -Modules Microsoft.Graph.Identity.SignIns, Microsoft.Graph.Users, Microsoft.Graph.Groups, Microsoft.Graph.Authentication, PSWriteHTML, ExchangeOnlineManagement


[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$InputCsvPath,
    
    [Parameter(Mandatory)]
    [string]$OutputPath,
    
    [Parameter()]
    [hashtable]$DomainPrefixes = @{
        
        
        'ictc-ctic.org'                    = 'ORG'
        'e-talent.ca'                      = 'TAL'
        'canadaupskill.ca'                 = 'UP'
        'thinktanknumeriquectic.com'       = 'TTN'
        'e-enterprise.ca'                  = 'ENT'
        'digitalthinktankictc.com'         = 'DTT'
        'etalentcanada.ca'                 = 'TALCA'
        'ictc-ctic.net'                    = 'NET'
        'ictc-ctic.ca'                     = 'CTIC'
        'ictc-ctic.com'                    = 'COM'
        'e-enterprisecanada.ca'            = 'ENTCA'
        'genai.ictc-ctic.org'              = 'GENAI-ORG'
        'genai.e-talent.ca'                = 'GENAI-TAL'
        'genai.canadaupskill.ca'           = 'GENAI-UP'
        'genai.thinktanknumeriquectic.com' = 'GENAI-TTN'
        'genai.e-enterprise.ca'            = 'GENAI-ENT'
        'genai.digitalthinktankictc.com'   = 'GENAI-DTT'
        'genai.etalentcanada.ca'           = 'GENAI-TALCA'
        'genai.ictc-ctic.net'              = 'GENAI-NET'
        'genai.ictc-ctic.ca'               = 'GENAI-CTIC'
        'genai.ictc-ctic.com'              = 'GENAI-COM'
        'genai.e-enterprisecanada.ca'      = 'GENAI-ENTCA'

        # Add other domains as needed
    },
    
    [Parameter()]
    [string[]]$Delegates = @(
        "s.sood@ictc-ctic.ca",
        "a.agzamov@ictc-ctic.ca",
        "o.sanya@ictc-ctic.ca"
    ),
    
    [Parameter()]
    [string]$SecurityGroupId = "68cbfcbb-9f6f-4cdb-af04-595143c2d028",
    
    [Parameter()]
    [hashtable]$Metadata = @{
        Department  = "Product Team"
        Comment     = "Apollo/Lemlist Integration"
        RequestDate = (Get-Date -Format "yyyy-MM-dd")
        CreatedBy   = $env:USERNAME
        RequestedBy = "Default Requestor"
        ApprovedBy  = "Default Approver"
        IvantiTask  = ""
        IvantiSR    = ""
    }
)

Import-Module 'C:\code\Modulesv2\EnhancedMailboxAO\SharedMailboxManagement.psm1'

# Ensure output directory exists
$null = New-Item -Type Directory -Force -Path $OutputPath

# Import validated CSV
$mailboxes = Import-ValidatedSharedMailboxCSV -Path $InputCsvPath

# Initialize results collection
$results = [System.Collections.ArrayList]::new()

foreach ($mailbox in $mailboxes) {
    try {
        $domain = $mailbox.email.Split('@')[1]
        $prefix = $DomainPrefixes[$domain]
        if (-not $prefix) {
            throw "Domain prefix not found for $domain"
        }

        $mailboxName = "AL-$prefix-" + ($mailbox.email.Split('@')[0])
        $password = New-RandomPassword -IncludeSpecialChars
        
        # Create mailbox with splatting
        $mailboxParams = @{
            Shared             = $true
            Name               = $mailboxName
            DisplayName        = $mailboxName
            Alias              = ("al-" + $prefix + "-" + $mailbox.email.Split('@')[0]).Replace(".", "-").ToLower()
            PrimarySmtpAddress = $mailbox.email
            Password           = (ConvertTo-SecureString -String $password -AsPlainText -Force)
        }
        
        $newMailbox = New-Mailbox @mailboxParams
        
        # Configure mailbox properties
        $null = Set-Mailbox -Identity $newMailbox.Alias -EmailAddresses @{Add = "smtp:$($mailbox.email)" }
        $null = Enable-MailboxArchive -Identity $mailbox.email
        $null = Set-Mailbox -Identity $mailbox.email -HiddenFromAddressListsEnabled $true
        
        # Set permissions for delegates
        foreach ($delegate in $Delegates) {
            $null = Add-RecipientPermission -Identity $mailbox.email -Trustee $delegate -AccessRights SendAs -Confirm:$false
            $null = Add-MailboxPermission -Identity $mailbox.email -User $delegate -AccessRights FullAccess -AutoMapping $false -Confirm:$false
        }

        # Generate TAP
        $tapParams = @{
            StartDateTime     = Get-Date
            LifetimeInMinutes = 43200 # 30 days
            IsUsableOnce      = $false
        }
        
        $tap = New-MgUserAuthenticationTemporaryAccessPassMethod -UserId $newMailbox.ExternalDirectoryObjectId -BodyParameter $tapParams

        # Add to results
        $null = $results.Add([PSCustomObject]@{
                Email          = $mailbox.email
                DisplayName    = $mailboxName
                Password       = $password
                Department     = $Metadata.Department
                TAPCode        = $tap.TemporaryAccessPass
                ExpirationTime = $tap.StartDateTime.AddMinutes($tapParams.LifetimeInMinutes)
                Status         = 'Success'
                Delegates      = $Delegates -join "; "
            })
    }
    catch {
        $null = $results.Add([PSCustomObject]@{
                Email  = $mailbox.email
                Status = "Failed: $_"
            })
        Write-Error "Failed to process $($mailbox.email): $_"
        continue
    }
}

# Generate reports
$mailboxReport = New-SharedMailboxCreationReport -Results $results -OutputPath $OutputPath -Metadata $Metadata
$tapReport = New-SharedMailboxTAPReport -Results $results -OutputPath $OutputPath

Write-Host "Operation completed. Reports generated at:"
Write-Host "Mailbox Report: $($mailboxReport.HTMLPath)"
Write-Host "TAP Report: $($tapReport.HTMLPath)"