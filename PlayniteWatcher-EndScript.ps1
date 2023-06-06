$path = Split-Path -Path $MyInvocation.MyCommand.Path -Parent

function Send-PipeMessage($pipeName, $message) {
    $pipeExists = Get-ChildItem -Path "\\.\pipe\" | Where-Object { $_.Name -eq $pipeName } 
    if ($pipeExists.Length -gt 0) {
        $pipe = New-Object System.IO.Pipes.NamedPipeClientStream(".", $pipeName, [System.IO.Pipes.PipeDirection]::Out)

        # Give up after 5 seconds, if we can't connect by then it's probably stalled.
        $pipe.Connect(5)
        $streamWriter = New-Object System.IO.StreamWriter($pipe)

        $streamWriter.WriteLine($message)
        try {
            $streamWriter.Flush()
            $streamWriter.Dispose()
            $pipe.Dispose()
        }
        catch {
            # We don't care if the disposal fails, this is common with async pipes.
            # Also, this powershell script will terminate anyway.
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
            $process = Get-Process -Name $executable.Name.Split('.')[0] -ErrorAction SilentlyContinue
            if ($null -ne $process) {
                Write-Host "Stopping the following processes, since it is still open and Sunshine stream has ended: $($process.Name)"
                $process | Stop-Process
            }
        }
    }
}

function CloseDesktopGracefully() {
    # Give Playnite enough time to save playtime statistics
    Start-Sleep -Seconds 3 
    $matchesFound = Get-Content -Path "$path\log.txt" | Select-String "(?<=Launching PlayNite Fullscreen:\s)(?<path>.*)"
    if ($null -ne $matchesFound) {
        $desktopPath = $matchesFound.Matches[0].Value
        Start-Process $desktopPath -ArgumentList "--shutdown"
    }
}

TerminatePipes
CloseLaunchedGame
CloseDesktopGracefully
