$path = Split-Path -Path $MyInvocation.MyCommand.Path -Parent

function TerminatePipe {
    $pipeExists = Get-ChildItem -Path "\\.\pipe\" | Where-Object { $_.Name -eq "PlayniteWatcher" } 
    if ($pipeExists.Length -gt 0) {
        $pipeName = "PlayniteWatcher"
        $pipe = New-Object System.IO.Pipes.NamedPipeClientStream(".", $pipeName, [System.IO.Pipes.PipeDirection]::Out)
        $pipe.Connect()
        $streamWriter = New-Object System.IO.StreamWriter($pipe)
        $streamWriter.WriteLine("Terminate")
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


function CloseLaunchedGame() {
    [string](Get-Content -Path "$path\log.txt") -match "(?<=Received GamePath:\s)(?<path>.*)"
    [string]$gamePath = $matches['path']
    Write-Host $gamePath
    $executables = Get-ChildItem -Path $gamePath -Filter *.exe -Recurse
    Write-Host $executables

    foreach ($executable in $executables) {
        $process = Get-Process -Name $executable.Name.Split('.')[0] -ErrorAction SilentlyContinue
        if ($null -ne $process) {
            Write-Host "Stopping the following processes, since it is still open and Sunshine stream has ended: $($process.Name)"
            $process | Stop-Process
        }
    }
}

TerminatePipe
CloseLaunchedGame
