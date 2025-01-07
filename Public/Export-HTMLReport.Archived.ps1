# function Export-HTMLReport {
#     param (
#         $Results,
#         $OutputDir,
#         $Metadata
#     )    
#     $htmlParams = @{
#         Title    = "Shared Mailbox Creation Report"
#         FilePath = (Join-Path $OutputDir "MailboxCreationReport.html")
#         ShowHTML = $true
#     }
    
#     New-HTML @htmlParams {
#         New-HTMLSection -HeaderText "Creation Summary" {
#             New-HTMLPanel {
#                 New-HTMLText -Text @"
#                 <h3>Request Details</h3>
#                 <ul>
#                     <li>Department: $($Metadata.Department)</li>
#                     <li>Request Date: $($Metadata.RequestDate)</li>
#                     <li>Created By: $($Metadata.CreatedBy)</li>
#                     <li>Requested By: $($Metadata.RequestedBy)</li>
#                     <li>Approved By: $($Metadata.ApprovedBy)</li>
#                     <li>Ivanti Task: $($Metadata.IvantiTask)</li>
#                     <li>Ivanti SR: $($Metadata.IvantiSR)</li>
#                 </ul>
#                 <h4>Purpose</h4>
#                 <p>$($Metadata.Comment)</p>
# "@
#             }
#         }
        
#         $tableParams = @{
#             DataTable = $Results
#             ScrollX   = $true
#             Buttons   = @('copyHtml5', 'excelHtml5', 'csvHtml5')
#         }
        
#         New-HTMLSection -HeaderText "Created Mailboxes" {
#             New-HTMLTable @tableParams {
#                 New-TableCondition -Name 'CreationStatus' -ComparisonType 'string' -Operator 'contains' -Value 'Failed' -BackgroundColor '#ffcdd2' -Color '#000000'
#             }
#         }
#     }
# }