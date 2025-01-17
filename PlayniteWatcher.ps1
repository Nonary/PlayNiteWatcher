param($playNiteId)

Register-EngineEvent -SourceIdentifier GamePathRecieved -Action {
    $gamePath = $event.MessageData
    if ($null -ne $gamePath) {
        Write-Host ("Received GamePath: $gamePath")
    }
    
    Watch-AndApplyFocusToGame -gamePath $gamePath -maximumAttempts 10
}

$path = Split-Path $MyInvocation.MyCommand.Path -Parent
$playNitePath = "C:\\Program Files\\Playnite\\Playnite.DesktopApp.exe"
$sunshineConfigPath = "C:\\Program Files\\Sunshine\\config\\apps.json"
$fullScreenPath = "$(Split-Path $playNitePath -Parent)\\Playnite.FullscreenApp.exe"
$fullScreenMode = $false


Start-Transcript $path\log.txt


function Set-ForegroundWindow {
    param (
        [string]$processName
    )

    Add-Type -ErrorAction SilentlyContinue -TypeDefinition  @"
    using System;
    using System.Runtime.InteropServices;

    public class WindowHelper
    {
        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
    }
"@

    # Get the process ID (PID) of the application you want to bring to the foreground
    $processID = Get-Process -Name $processName | Select-Object -ExpandProperty ID

    # Find the application's main window handle using the process ID
    $mainWindowHandle = (Get-Process -id $processID).MainWindowHandle

    # Bring the application to the foreground
    [WindowHelper]::SetForegroundWindow($mainWindowHandle) | Out-Null
}

function Watch-AndApplyFocusToGame {
    param (
        [string]$gamePath,
        [int]$maximumAttempts = 10
    )

    $executables = Get-ChildItem -Path $gamePath -Filter *.exe -Recurse
    Write-Host "Found the following executables in game directory: $executables"

    $attempts = 0

    while ($attempts -lt $maximumAttempts) {
        $attempts++
        Start-Sleep -Seconds 1
        $processInfos = @()
        foreach ($executable in $executables) {
            $process = Get-Process -Name $executable.Name.Split('.')[0] -ErrorAction SilentlyContinue
            if ($null -ne $process) {
                $processInfos += $process
            }
        }

        $foundInfo = $processInfos | Sort-Object -Property WorkingSet64 -Descending | Select-Object -First 1 

        if ($null -ne $foundInfo) {
            Write-Host "Found the following process: $($foundInfo.Name) with WorkingSet64: $($foundInfo.WorkingSet64)"
            Write-Host "Applying foreground focus to process: $($foundInfo.Name)"
            Set-ForegroundWindow -processName $foundInfo.Name
        }
    }
}

try {

    Start-Job -Name "PlayniteWatcher-OnStreamStart" -ScriptBlock {
        $pipeName = "PlayniteWatcher-OnStreamStart"
        Remove-Item "\\.\pipe\$pipeName" -ErrorAction Ignore
        $pipe = New-Object System.IO.Pipes.NamedPipeServerStream($pipeName, [System.IO.Pipes.PipeDirection]::In, 1, [System.IO.Pipes.PipeTransmissionMode]::Byte, [System.IO.Pipes.PipeOptions]::Asynchronous)
        $streamReader = New-Object System.IO.StreamReader($pipe)

        Register-EngineEvent -SourceIdentifier GamePathRecieved -Forward

        while ($true) {
            Write-Host "Waiting for named pipe to receive game information"
            $pipe.WaitForConnection()
    
            $message = $streamReader.ReadLine()

            if ($message -eq "Terminate") {
                break;
                return;
            }
    
            New-Event -SourceIdentifier GamePathRecieved -MessageData $message | Out-Null
    
            # Disconnect and wait for the next connection
            $pipe.Disconnect()
        }
    }

    # To allow other powershell scripts to communicate to this one.
    Start-Job -Name "Playnite-WatcherJob" -ScriptBlock {
        $pipeName = "PlayniteWatcher"
        Remove-Item "\\.\pipe\$pipeName" -ErrorAction Ignore
        $pipe = New-Object System.IO.Pipes.NamedPipeServerStream($pipeName, [System.IO.Pipes.PipeDirection]::In, 1, [System.IO.Pipes.PipeTransmissionMode]::Byte, [System.IO.Pipes.PipeOptions]::Asynchronous)

        $streamReader = New-Object System.IO.StreamReader($pipe)
        Write-Output "Waiting for named pipe to recieve kill command"
        $pipe.WaitForConnection()

        $message = $streamReader.ReadLine()
        if ($message -eq "Terminate") {
            Write-Output "Terminating pipe..."
            $pipe.Dispose()
            $streamReader.Dispose()
        }
    }



    if ($playNiteId -ne "FullScreen") {
        Start-Process -FilePath $playNitePath  -ArgumentList "--start $playNiteId"
    }
    else {
        $elapsedSeconds = 0
        Write-Host "Launching PlayNite Fullscreen: $fullScreenPath"
        $fullScreenMode = $true
        # Because Sunshine terminates the process forcefully, it will kill children processes from this script.
        # As a workaround, by using a WMI Process call, we can be safely detached from the parent process.
        Invoke-WmiMethod -Class Win32_Process -Name Create -ArgumentList $fullScreenPath | Out-Null
        while ($elapsedSeconds -lt 5.0 -and ($null -eq (Get-Process Playnite.FullscreenApp -ErrorAction SilentlyContinue))) {
            Start-Sleep -Milliseconds 500
            $elapsedSeconds += .5
        }

        try {
            # Give Playnite Desktop enough time to be focusable.
            Start-Sleep -Seconds 1
            Set-ForegroundWindow "Playnite.FullscreenApp"
        }
        catch {
            Write-Host "Failed to apply focus on FullScreen app, application such as DS4Tool may not properly activate controller profiles."
            Write-Host "This is not a serious error, and does not prevent the overall functionality of the script"
        }

    }



    while ($true) {
        Start-Sleep -Seconds 1

        $playJob = Get-Job -Name "Playnite-WatcherJob"

        if ($playJob.State -eq "Completed") {
            Start-Sleep -Seconds 1
            $playJob | Receive-Job
            $playJob | Remove-Job
            break;
        }

        if ($fullScreenMode) {
            if ($null -eq (Get-Process Playnite.FullscreenApp -ErrorAction SilentlyContinue)) {
                Write-Host "Playnite Fullscreen ended, terminating script."
                break;
            }
        }
    }
}
finally {
    Write-Host "Terminating..."
    # This makes sure that the end script is executed and closes out the pipes.
    # PowerShell will stall for up to 2 minutes when forcefully stopping a job.
    . $path\PlayniteWatcher-EndScript.ps1
    TerminatePipes
    Remove-Item "\\.\pipe\PlayniteWatcher" -Force -ErrorAction Ignore
    Remove-Item "\\.\pipe\PlayniteWatcher-OnStreamStart" -Force -ErrorAction Ignore
    Remove-Job -Name "Playnite-WatcherJob" -Force -ErrorAction Ignore
    Remove-Job -Name "PlayniteWatcher-OnStreamStart" -Force -ErrorAction Ignore
    Stop-Transcript
}


