<#

.SYNOPSIS
    Performs controlled, automated, and logged Windows updates via WSUS.

.DESCRIPTION
    WSUS-AutoUpdate.ps1 executes a structured update workflow on Windows systems integrated
    with a WSUS infrastructure. The script scans for applicable updates, installs them without
    requiring user interaction, checks for reboot requirements, and logs each step to a syslog
    server using the PSWriteSyslog function.

    Designed for automated environments such as server maintenance windows, enterprise
    patching routines, and scheduled update rollouts. All actions are logged in JSON format
    for integration with SIEM systems or central log management.

.PARAMETER (none)
    The script accepts no parameters. All configuration is done in-code.

.DEPENDENCIES
    - PowerShell v3 or higher
    - PSWindowsUpdate module (Install-Module PSWindowsUpdate)
    - Reachable syslog server via TCP (default: 127.0.0.1:514)

.EXAMPLE
    .\WSUS-AutoUpdate.ps1

    Runs the full update and logging cycle on the local machine, logging to the default syslog destination.

.NOTES
    Authors: Odd-Arne Haraldsen / Erik Sahlberg
    Version: 1.6
    Creation Date: 2016-04-18
    Change Date: 2025-07-20

#>

 
# Function for JSON syslog logging over TCP

function PSWriteSyslog {

    param (

        [string]$ServerName = $env:COMPUTERNAME,

        [string]$Service = "WSUS-AutoUpdate",

        [string]$Process = "PSWindowsUpdate",

        [string]$Action = "unspecified",

        [string]$Result = "undefined",

        [string]$Message = "generic",

        [string]$SyslogHost = "127.0.0.1",

        [string]$KB = "undefined",

        [int]$SyslogPort = 514

    )

    $ScriptVersion = "1.6"
 
    $Timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
 
    $payload = @{

        timestamp  = $Timestamp

        service    = $Service

        process    = $Process

        server     = $ServerName

        action     = $Action

        result     = $Result

        kb         = $KB

        message    = $Message

        version    = $ScriptVersion

    } | ConvertTo-Json -Depth 2 -Compress
 
    try {

        $tcpClient = New-Object System.Net.Sockets.TcpClient

        $tcpClient.Connect($SyslogHost, $SyslogPort)
 
        $stream = $tcpClient.GetStream()

        $writer = New-Object System.IO.StreamWriter($stream)

        $writer.AutoFlush = $true

        $writer.WriteLine($payload)
 
        $writer.Close()

        $stream.Close()

        $tcpClient.Close()

    }

    catch {

        Write-Host "Log error: $_"

    }

}
 
# Main flow

try {

    Import-Module PSWindowsUpdate -Force
 
    PSWriteSyslog -Action "start" -Result "success" -Message "Update script started"

    Write-Host "Update script started"
 
    $updates = Get-WUList
 
    if ($updates.KBArticleIDs.Count -eq 0) {

        PSWriteSyslog -Action "scan" -Result "none" -Message "No updates found"

        Write-Host "No updates found"

    }

    else {

        PSWriteSyslog -Action "scan" -Result "found" -Message "$($updates.KBArticleIDs.Count) update(s) found"

        Write-Host "$($updates.KBArticleIDs.Count) update(s) found"
 
        foreach ($update in $updates) {

            $title = $update.Title

            $kb = $update.KBArticleIDs
 
            try {

                PSWriteSyslog -Action "installing" -Result "pending" -Message "Installing: $title" -KB "$kb"

                Write-Host "Installing: $title"
 
                Get-WUInstall -KBArticleID $kb -AcceptAll -AutoReboot:$false -IgnoreReboot -Confirm:$false -ErrorAction Stop
 
                PSWriteSyslog -Action "install" -Result "success" -Message "Installed: $title" -KB "$kb"

                Write-Host "Installed: $title"

            }

            catch {

                PSWriteSyslog -Action "install" -Result "failed" -Message "Installation failed: $title - $_" -KB "$kb"

                Write-Host "Installation failed: $title - $_"

            }

        }
 
        $needsReboot = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -ErrorAction SilentlyContinue) -ne $null
 
        if ($needsReboot) {

            PSWriteSyslog -Action "reboot" -Result "required" -Message "System reboot is required"

            Write-Host "System reboot is required"

            Restart-Computer -Force

        }

        else {

            PSWriteSyslog -Action "reboot" -Result "not-required" -Message "No reboot required"

            Write-Host "No reboot required"

        }

    }
 
    PSWriteSyslog -Action "complete" -Result "success" -Message "Update script completed"

    Write-Host "Update script completed"

}

catch {

    PSWriteSyslog -Action "error" -Result "exception" -Message "General error: $_"

    Write-Host "General error: $_"

}
