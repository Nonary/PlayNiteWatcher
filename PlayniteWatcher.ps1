param($playNiteId)

# Register event to watch for game path notifications
Register-EngineEvent -SourceIdentifier GamePathRecieved -Action {
    $gamePath = $event.MessageData
    if ($null -ne $gamePath) {
        Write-Host ("Received GamePath: $gamePath")
    }
    
    Watch-AndApplyFocusToGame -gamePath $gamePath -maximumAttempts 10
}

$path = Split-Path $MyInvocation.MyCommand.Path -Parent
$playNitePath = "C:\\Program Files\\Playnite\\Playnite.DesktopApp.exe"
$sunshineConfigPath = "C:\\Program Files\\Sunshine\\config"
$fullScreenPath = "$(Split-Path $playNitePath -Parent)\\Playnite.FullscreenApp.exe"
$fullScreenMode = $false

Start-Transcript "$path\log.txt"

#region Helper Functions

# Adds a type to call user32.dll's SetForegroundWindow
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
    $processID = (Get-Process -Name $processName -ErrorAction SilentlyContinue | Select-Object -First 1).ID
    if (-not $processID) {
        Write-Host "Process $processName not found."
        return
    }

    # Find the application's main window handle using the process ID
    $mainWindowHandle = (Get-Process -Id $processID).MainWindowHandle

    if ($mainWindowHandle -eq 0) {
        Write-Host "No main window handle found for process $processName."
        return
    }

    # Bring the application to the foreground
    [WindowHelper]::SetForegroundWindow($mainWindowHandle) | Out-Null
}

# Returns the current foreground window handle using user32.dll's GetForegroundWindow
function Get-ForegroundWindowHandle {
    Add-Type -ErrorAction SilentlyContinue -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class User32 {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
}
"@
    return [User32]::GetForegroundWindow()
}

# Loop through game executables and try to apply focus to the one consuming most memory.
function Watch-AndApplyFocusToGame {
    param (
        [string]$gamePath,
        [int]$maximumAttempts = 10
    )

    $executables = Get-ChildItem -Path $gamePath -Filter *.exe -Recurse
    Write-Host "Found the following executables in game directory: $($executables.Name -join ', ')"

    $attempts = 0

    while ($attempts -lt $maximumAttempts) {
        $attempts++
        Start-Sleep -Seconds 1
        $processInfos = @()
        foreach ($executable in $executables) {
            $procName = $executable.Name.Split('.')[0]
            $process = Get-Process -Name $procName -ErrorAction SilentlyContinue
            if ($null -ne $process) {
                $processInfos += $process
            }
        }

        $foundInfo = $processInfos | Sort-Object -Property WorkingSet64 -Descending | Select-Object -First 1 

        if ($null -ne $foundInfo) {
            Write-Host "Found process: $($foundInfo.Name) with WorkingSet64: $($foundInfo.WorkingSet64)"
            Write-Host "Applying foreground focus to process: $($foundInfo.Name)"
            Set-ForegroundWindow -processName $foundInfo.Name

            # Give the system a brief moment to update the foreground window
            Start-Sleep -Milliseconds 500
            $foregroundHandle = Get-ForegroundWindowHandle

            if ($foregroundHandle -eq $foundInfo.MainWindowHandle) {
                Write-Host "Focus confirmed on process: $($foundInfo.Name). Exiting loop."
                break
            }
            else {
                Write-Host "Focus not confirmed yet. Retrying attempt $attempts of $maximumAttempts..."
            }
        }
        else {
            Write-Host "No matching process found. Attempt $attempts of $maximumAttempts."
        }
    }
}

#endregion

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

    # To allow other PowerShell scripts to communicate to this one.
    Start-Job -Name "Playnite-WatcherJob" -ScriptBlock {
        $pipeName = "PlayniteWatcher"
        Remove-Item "\\.\pipe\$pipeName" -ErrorAction Ignore
        $pipe = New-Object System.IO.Pipes.NamedPipeServerStream($pipeName, [System.IO.Pipes.PipeDirection]::In, 1, [System.IO.Pipes.PipeTransmissionMode]::Byte, [System.IO.Pipes.PipeOptions]::Asynchronous)

        $streamReader = New-Object System.IO.StreamReader($pipe)
        Write-Output "Waiting for named pipe to receive kill command"
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

        # Detach from parent process using a WMI call.
        Invoke-WmiMethod -Class Win32_Process -Name Create -ArgumentList $fullScreenPath | Out-Null

        # Wait briefly until the Fullscreen process appears.
        while ($elapsedSeconds -lt 5.0 -and ($null -eq (Get-Process Playnite.FullscreenApp -ErrorAction SilentlyContinue))) {
            Start-Sleep -Milliseconds 500
            $elapsedSeconds += 0.5
        }

        # Loop to repeatedly apply focus until it is confirmed.
        $maxFocusAttempts = 10
        $focusApplied = $false
        for ($i = 1; $i -le $maxFocusAttempts; $i++) {
            try {
                Write-Host "Attempt $i`: Applying focus to Playnite.FullscreenApp"
                Set-ForegroundWindow "Playnite.FullscreenApp"
            }
            catch {
                Write-Host "Attempt $i`: Failed to apply focus on FullScreen app."
            }
            Start-Sleep -Seconds 1
            $foregroundHandle = Get-ForegroundWindowHandle
            $fsProcess = Get-Process Playnite.FullscreenApp -ErrorAction SilentlyContinue
            if ($fsProcess -and ($foregroundHandle -eq $fsProcess.MainWindowHandle)) {
                Write-Host "Confirmed focus on Playnite.FullscreenApp on attempt $i."
                $focusApplied = $true
                break
            }
            else {
                Write-Host "Attempt $i`: Focus not confirmed."
            }
        }
        if (-not $focusApplied) {
            Write-Host "Could not confirm focus on Playnite.FullscreenApp after $maxFocusAttempts attempts."
        }
    }

    # Main loop: wait until the kill command or process termination.
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
