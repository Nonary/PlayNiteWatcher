param(
    [switch]$Detached
)


# If not already running detached, re-launch self via WMI and exit.
if (-not $Detached) {
    # Get the full path of this script.
    $scriptPath = $MyInvocation.MyCommand.Definition
    # Build the command line; note that we add the -Detached switch.
    $command = "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`" -Detached"
    Write-Host "Launching detached instance via WMI: $command"
    # Launch using WMI Create process.
    ([wmiclass]"\\.\root\cimv2:Win32_Process").Create($command) | Out-Null
    exit
}
$path = (Split-Path $MyInvocation.MyCommand.Path -Parent)
Set-Location $path



function Send-PipeMessage($pipeName, $message) {
    $pipeExists = Get-ChildItem -Path "\\.\pipe\" | Where-Object { $_.Name -eq $pipeName }
    if ($pipeExists.Length -gt 0) {
        $pipe = New-Object System.IO.Pipes.NamedPipeClientStream(".", $pipeName, [System.IO.Pipes.PipeDirection]::Out)

        # Give up after 5 seconds; if we can't connect by then it's probably stalled.
        $pipe.Connect(5)
        $streamWriter = New-Object System.IO.StreamWriter($pipe)

        $streamWriter.WriteLine($message)
        try {
            $streamWriter.Flush()
            $streamWriter.Dispose()
            $pipe.Dispose()
        }
        catch {
            # We don't care if disposal fails; this is common with async pipes.
            # Also, this PowerShell script will terminate anyway.
        }
    }
}

function TerminatePipes {
    Send-PipeMessage -pipeName "PlayniteWatcher-OnStreamStart" -message "Terminate"
    Send-PipeMessage -pipeName "PlayniteWatcher" -message "Terminate"
}

function CloseLaunchedGame() {
    $matchesFound = Get-Content -Path "$path\log.txt" | Select-String "(?<=Received GamePath:\s)(?<path>.*)"
    if ($null -ne $matchesFound) {
        [string]$gamePath = ($matchesFound.Matches | Select-Object -Last 1).Value
        $executables = Get-ChildItem -Path $gamePath -Filter *.exe -Recurse
        Write-Host "Found the following executables in game directory: $executables"

        foreach ($executable in $executables) {
            $process = Get-Process -Name ($executable.Name.Split('.')[0]) -ErrorAction SilentlyContinue
            if ($null -ne $process) {
                Write-Host "Stopping the following processes, since it is still open and Sunshine stream has ended: $($process.Name)"
                $process | Stop-Process
            }
        }
    }
}

function CloseDesktopGracefully() {
    # Give Playnite enough time to save playtime statistics.
    Start-Sleep -Seconds 6 
    $matchesFound = Get-Content -Path "$path\log.txt" | Select-String "(?<=Launching PlayNite Fullscreen:\s)(?<path>.*)"
    if ($null -ne $matchesFound) {
        $desktopPath = $matchesFound.Matches[0].Value
        Start-Process $desktopPath -ArgumentList "--shutdown"
    }
}


TerminatePipes
CloseLaunchedGame
CloseDesktopGracefully

