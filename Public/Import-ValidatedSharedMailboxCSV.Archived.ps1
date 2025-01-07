# function Import-ValidatedSharedMailboxCSV {
#     [CmdletBinding()]
#     param(
#         [Parameter(Mandatory)]
#         [string]$Path
#     )

#     try {
#         $content = Import-Csv -Path $Path -ErrorAction Stop
        
#         # Validate structure
#         $requiredColumns = @('email')
#         $headers = $content | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
#         $missingColumns = $requiredColumns | Where-Object { $_ -notin $headers }
        
#         if ($missingColumns) {
#             throw "Missing required columns: $($missingColumns -join ', ')"
#         }

#         # Validate email format and uniqueness
#         $emailRegex = '^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$'
#         $duplicates = $content | Group-Object email | Where-Object Count -gt 1
#         $invalidEmails = $content | Where-Object { 
#             $_.email -notmatch $emailRegex -or 
#             $_.email.Split('@').Count -ne 2 -or
#             $_.email.Contains(',')
#         }

#         if ($duplicates) {
#             throw "Duplicate emails found: $($duplicates.Name -join ', ')"
#         }

#         if ($invalidEmails) {
#             throw "Invalid email format found: $($invalidEmails.email -join ', ')"
#         }

#         return $content
#     }
#     catch {
#         Write-Error "CSV validation failed: $_"
#         throw
#     }
# }