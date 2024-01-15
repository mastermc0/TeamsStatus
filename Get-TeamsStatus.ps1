<#
.NOTES
    Name: Get-TeamsStatus.ps1
    Author: Danny de Vries
    Requires: PowerShell v2 or higher
    Version History: https://github.com/EBOOZ/TeamsStatus/commits/main
.SYNOPSIS
    Sets the status of the Microsoft Teams client to Home Assistant.
.DESCRIPTION
    This script is monitoring the Teams client logfile for certain changes. It
    makes use of two sensors that are created in Home Assistant up front.
    The status entity (sensor.teams_status by default) displays that availability 
    status of your Teams client based on the icon overlay in the taskbar on Windows. 
    The activity entity (sensor.teams_activity by default) shows if you
    are in a call or not based on the App updates deamon, which is paused as soon as 
    you join a call.
.PARAMETER SetStatus
    Run the script with the SetStatus-parameter to set the status of Microsoft Teams
    directly from the commandline.
.EXAMPLE
    .\Get-TeamsStatus.ps1 -SetStatus "Offline"
#>
# Configuring parameter for interactive run
Param($SetStatus)

# Import Settings PowerShell script
. ($PSScriptRoot + "\Settings.ps1")

$headers = @{"Authorization"="Bearer $HAToken";}
$Enable = 1

# Run the script when a parameter is used and stop when done
If($null -ne $SetStatus){
    Write-Host ("Setting Microsoft Teams status to "+$SetStatus+":")
    $params = @{
     "state"="$SetStatus";
     "attributes"= @{
        "friendly_name"="$entityStatusName";
        "icon"="mdi:microsoft-teams";
        }
     }
	 
    $params = $params | ConvertTo-Json
    Invoke-RestMethod -Uri "$HAUrl/api/states/$entityStatus" -Method POST -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($params)) -ContentType "application/json"
    break
}

# Start monitoring the Teams logfile when no parameter is used to run the script
DO {
# Get Teams Logfile and last icon overlay status

$Directory = "C:\Users\gwhite\AppData\Local\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams\Logs"

$TeamsLogFile = Get-ChildItem -Attributes !Directory "$Directory\MSTEAMS_*.log" | Sort-Object -Descending -Property LastWriteTime | select -First 1

Write-Host $Directory
Write-Host $TeamsLogFile

$TeamsStatus = Get-Content -Path $TeamsLogFile -Tail 1000 | Select-String -Pattern `
  'Received Action: UserPresenceAction:' | Select-Object -Last 1

# Get Teams Logfile and last app update deamon status
$TeamsActivity = Get-Content -Path $TeamsLogFile -Tail 1000 | Select-String -Pattern `
  'Resuming daemon App updates',`
  'Pausing daemon App updates',`
  'SfB:TeamsNoCall',`
  'SfB:TeamsPendingCall',`
  'SfB:TeamsActiveCall',`
  'name: desktop_call_state_change_send, isOngoing' | Select-Object -Last 1

# Get Teams application process
$TeamsProcess = Get-Process -Name ms-teams -ErrorAction SilentlyContinue

# Check if Teams is running and start monitoring the log if it is
If ($null -ne $TeamsProcess) {
    If($TeamsStatus -eq $null){ }
    ElseIf ($TeamsStatus -like "*availability: $lgAvailable*") {
        $Status = $lgAvailable
        Write-Host $Status
    }
    ElseIf ($TeamsStatus -like "*availability: $lgBusy*") {
        $Status = $lgBusy
        Write-Host $Status
    }
    ElseIf ($TeamsStatus -like "*availability: $lgAway*") {
        $Status = $lgAway
        Write-Host $Status
    }
    ElseIf ($TeamsStatus -like "*availability: $lgBeRightBack*") {
        $Status = $lgBeRightBack
        Write-Host $Status
    }
    ElseIf ($TeamsStatus -like "*availability: $lgDoNotDisturb*") {
        $Status = $lgDoNotDisturb
        Write-Host $Status
    }
    ElseIf ($TeamsStatus -like "*availability: $lgFocusing*") {
        $Status = $lgFocusing
        Write-Host $Status
    }
    ElseIf ($TeamsStatus -like "*availability: $lgPresenting*") {
        $Status = $lgPresenting
        Write-Host $Status
    }
    ElseIf ($TeamsStatus -like "*availability: $lgInAMeeting*") {
        $Status = $lgInAMeeting
        Write-Host $Status
    }
    ElseIf ($TeamsStatus -like "*availability: $lgOffline*") {
        $Status = $lgOffline
        Write-Host $Status
    }

    If($TeamsActivity -eq $null){ }
    ElseIf ($TeamsActivity -like "*Resuming daemon App updates*" -or `
        $TeamsActivity -like "*SfB:TeamsNoCall*" -or `
        $TeamsActivity -like "*name: desktop_call_state_change_send, isOngoing: false*") {
        $Activity = $lgNotInACall
        $ActivityIcon = $iconNotInACall
        Write-Host $Activity
    }
    ElseIf ($TeamsActivity -like "*Pausing daemon App updates*" -or `
        $TeamsActivity -like "*SfB:TeamsActiveCall*" -or `
        $TeamsActivity -like "*name: desktop_call_state_change_send, isOngoing: true*") {
        $Activity = $lgInACall
        $ActivityIcon = $iconInACall
        Write-Host $Activity
    }
}
# Set status to Offline when the Teams application is not running
Else {
        $Status = $lgOffline
        $Activity = $lgNotInACall
        $ActivityIcon = $iconNotInACall
        Write-Host $Status
        Write-Host $Activity
}

# Call Home Assistant API to set the status and activity sensors
If ($CurrentStatus -ne $Status -and $Status -ne $null) {
    $CurrentStatus = $Status

    $params = @{
     "state"="$CurrentStatus";
     "attributes"= @{
        "friendly_name"="$entityStatusName";
        "icon"="mdi:microsoft-teams";
        }
     }
	 
    $params = $params | ConvertTo-Json
    Invoke-RestMethod -Uri "$HAUrl/api/states/$entityStatus" -Method POST -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($params)) -ContentType "application/json" 
}

If ($CurrentActivity -ne $Activity) {
    $CurrentActivity = $Activity

    $params = @{
     "state"="$Activity";
     "attributes"= @{
        "friendly_name"="$entityActivityName";
        "icon"="$ActivityIcon";
        }
     }
    $params = $params | ConvertTo-Json
    Invoke-RestMethod -Uri "$HAUrl/api/states/$entityActivity" -Method POST -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($params)) -ContentType "application/json" 
}
    Start-Sleep 1
} Until ($Enable -eq 0)
