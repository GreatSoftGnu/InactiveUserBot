Import-Module ActiveDirectory

########## Start Editable Variables ###########
# This variable sets the amount of days before an inactive user is disabled.
$inactiveDays = 30
# This variable sets the amount of inactive days before a ticket for the termination of the user is submitted.
$terminationDays = 90
$disableDaysInactive = (Get-Date).AddDays( - ($inactiveDays))
$terminationDaysInactive = (Get-Date).AddDays( - ($terminationDays))
# Create array of OU searchbases to search for users.
$OUs = get-content "C:\Temp\Locations.txt"
# Path to Log file
$scanLogDir = "C:\Temp\Logs"
# Removes logs older than x number of days 
# Path to csv for Helpdesk ticketLog
$ticketLog = "C:\Temp\Logs\UserTerminationLog.csv"
# Email address to send user terminiation tickets to
$email = "someEmailAddress@foobar.com"
# SMTP email server
$smtpServer = "someServer.foobar.com"
########## End Editable Variables ###########

Get-ChildItem "$scanLogDir\*" | Where-Object LastWriteTime -LT (Get-Date).AddDays(-90) | Remove-Item -Confirm:$false
# Creates new scan log 
$scanLogName = Join-Path -Path $scanLogDir -ChildPath "$($MyInvocation.MyCommand.Name)-$(Get-Date -Format 'MM-dd-yyyy').log"

# Checks if ticketLog CSV exists and if doesn't it creates one.
if (-not(Test-Path $ticketLog -PathType Leaf)) {
    try {
        $newcsv = {} | Select-Object "First Name", "Last Name", "samAccountName", "Position", "Department", "City", "Inactive/NeverLoggedIn" | Export-Csv $ticketLog -NoTypeInformation
    }
    catch {
        throw $_.Exception.Message
    }
} 

# Loops through array of OUs
foreach ($OU in $OUs) {
    # Identify and disable users who have not logged in in x days. 
    $disableUsers = Get-ADUser -SearchBase $OU -Filter { Enabled -eq $TRUE } -Properties * | Where-Object { ($_.lastLogonDate -lt $disableDaysInactive) -and ($_.lastLogonDate -ne $NULL) }
    # Loops through the users found that are inactive. If user is found to be inactive it disables the account.
    $disableUsers | ForEach-Object {
        Disable-ADAccount $_ 
        Write-Output "$(get-date) - $($_.Name) Disabled in Active Directory (Inactive User)" | Out-File -Append $scanLogName
        # Checks if users have been inactive for more than the amount set at $terminationDaysInactive. 
        # If yes it checks if that users DistinguishedName is in the $ticketLog. If it is in the ticket log it does nothing.
        # If that users DistinguishedName is not found it emails the helpdesk and then adds the users Distinguished name to the $ticketLog.
        if ($_.lastLogonDate -lt $terminationDaysInactive) {
            if (Get-Content $ticketLog | Select-String $_.SamAccountName) {
                Write-Output "$(get-date) - $($_.Name) found in Helpdesk ticketLog (Inactive User)" | Out-File -Append $scanLogName
            }
            else {
                $Subject = "Terminate inactive user $($_.SamAccountName)" 
                $Message = "Please begin termination process for user $($_.Name) ($($_.distinguishedName)) because the last login was more than $terminationDays days ago."
                Send-MailMessage -From $email -To $email -Subject $Subject -Body $Message -SmtpServer $smtpServer
                Write-Output "$(get-date) - Ticket created for termination for inactive user $($_.Name)" | Out-File -Append $scanLogName
                "$($_.givenName), $($_.surname), $($_.samAccountName), $($_.title), $($_.department), $($_.city), 'Inactive'" | add-content -path $ticketLog
            }
        }
    }

    # Checks if users have been inactive for more than the amount set at $terminationDaysInactive. 
    # If yes it checks if that users DistinguishedName is in the $ticketLog. If it is in the ticket log it does nothing.
    # If that users DistinguishedName is not found it emails the helpdesk and then adds the users Distinguished name to the $ticketLog.
    $terminateUsers = Get-ADUser -SearchBase $OU -Filter { Enabled -eq $FALSE } -Properties * | Where-Object { ($_.lastLogonDate -lt $terminationDaysInactive) -and ($_.lastLogonDate -ne $NULL) }
    $terminateUsers | ForEach-Object {
        if (Get-Content $ticketLog | Select-String $_.SamAccountName) {
            Write-Output "$(get-date) - $($_.Name) found in Helpdesk ticketLog (Inactive User)" | Out-File -Append $scanLogName
        } 
        else {
            $Subject = "Terminate inactive user $($_.SamAccountName)" 
            $Message = "Please begin termination process for user $($_.Name) ($($_.distinguishedName)) because the last login was more than $terminationDays days ago."
            Send-MailMessage -From $email -To $email -Subject $Subject -Body $Message -SmtpServer $smtpServer
            Write-Output "$(get-date) - Ticket created for termination for inactive user $($_.Name)" | Out-File -Append $scanLogName
            "$($_.givenName), $($_.surname), $($_.samAccountName), $($_.title), $($_.department), $($_.city), 'Inactive'" | add-content -path $ticketLog
        }
    }

    # Identify and disable users who were created x days ago and never logged in.
    $disableNeverLoggedInUsers = Get-ADUser -SearchBase $OU -Filter { Enabled -eq $TRUE } -Properties * | Where-Object { ($_.whenCreated -lt $disableDaysInactive) -and (-not ($_.lastLogonDate -ne $NULL)) }
    # Loops through the users found that are inactive. If user is found to be inactive it disables the account.
    $disableNeverLoggedInUsers | ForEach-Object {
        Disable-ADAccount $_
        Write-Output "$(get-date) - $($_.Name) Disabled in Active Directory (Never Logged In User)" | Out-File -Append $scanLogName
        # Checks if users have been inactive for more than the amount set at $terminationDaysInactive. 
        # If yes it checks if that users DistinguishedName is in the $ticketLog. If it is in the ticket log it does nothing.
        # If that users DistinguishedName is not found it emails the helpdesk and then adds the users Distinguished name to the $ticketLog.
        if ($_.lastLogonDate -lt $terminationDaysInactive) {
            if (Get-Content $ticketLog | Select-String $_.SamAccountName) {
                Write-Output "$(get-date) - $($_.Name) found in Helpdesk ticketLog (Never Logged in)"  | Out-File -Append $scanLogName
            }
            else {
                $Subject = "Terminate Never Logged in user $($_.SamAccountName)" 
                $Message = "Please begin termination process for user $($_.Name) ($($_.distinguishedName)) because they have never logged in and $terminationDays days have passed."
                Send-MailMessage -From $email -To $email -Subject $Subject -Body $Message -SmtpServer $smtpServer
                Write-Output "$(get-date) - Ticket created for never logged in user $($_.Name)" | Out-File -Append $scanLogName
                "$($_.givenName), $($_.surname), $($_.samAccountName), $($_.title), $($_.department), $($_.city), 'NeverLoggedIn'" | add-content -path $ticketLog
            }
        }
    }

    # Checks if users have been inactive for more than the amount set at $terminationDaysInactive. 
    # If yes it checks if that users DistinguishedName is in the $ticketLog. If it is in the ticket log it does nothing.
    # If that users DistinguishedName is not found it emails the helpdesk and then adds the users Distinguished name to the $ticketLog.
    $terminateNeverLoggedInUsers = Get-ADUser -SearchBase $OU -Filter { Enabled -eq $FALSE } -Properties * | Where-Object { ($_.whenCreated -lt $terminationDaysInactive) -and (-not ($_.lastLogonDate -ne $NULL)) }
    $terminateNeverLoggedInUsers | ForEach-Object {
        if (Get-Content $ticketLog | Select-String $_.SamAccountName) {
            Write-Output "$(get-date) - $($_.Name) found in Helpdesk ticketLog (Never Logged in)"  | Out-File -Append $scanLogName
        }
        else {
            $Subject = "Terminate Never Logged in user $($_.SamAccountName)" 
            $Message = "Please begin termination process for user $($_.Name) ($($_.distinguishedName)) because they have never logged in and $terminationDays days have passed."
            Send-MailMessage -From $email -To $email -Subject $Subject -Body $Message -SmtpServer $smtpServer
            Write-Output "$(get-date) - Ticket created for never logged in user $($_.Name)" | Out-File -Append $scanLogName
            "$($_.givenName), $($_.surname), $($_.samAccountName), $($_.title), $($_.department), $($_.city), 'NeverLoggedIn'" | add-content -path $ticketLog
        }
    }
}

