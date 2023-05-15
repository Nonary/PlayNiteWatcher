param($playNiteId)

$gamePath = $null
$path = Split-Path $MyInvocation.MyCommand.Path -Parent
$playNitePath = "F:\\Software\\Playnite\\Playnite.DesktopApp.exe"

Start-Transcript $path\log.txt


try {
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

    Start-Job -Name "PlayniteWatcher-OnStreamStart" -ScriptBlock {
        $pipeName = "PlayniteWatcher-OnStreamStart"
        Remove-Item "\\.\pipe\$pipeName" -ErrorAction Ignore
        $pipe = New-Object System.IO.Pipes.NamedPipeServerStream($pipeName, [System.IO.Pipes.PipeDirection]::In, 1, [System.IO.Pipes.PipeTransmissionMode]::Byte, [System.IO.Pipes.PipeOptions]::Asynchronous)

        $streamReader = New-Object System.IO.StreamReader($pipe)
        Write-Host "Waiting for named pipe to recieve game information"
        $pipe.WaitForConnection()

        $message = $streamReader.ReadLine()
    
        Write-Output $message
        $pipe.Dispose()
        $streamReader.Dispose()
    }


    Start-Process -FilePath $playNitePath  -ArgumentList "--start $playNiteId"

    while ($true) {
        Start-Sleep -Seconds 1

        $playJob = Get-Job -Name "Playnite-WatcherJob"
        $streamStartJob = Get-Job -Name "PlayniteWatcher-OnStreamStart" -ErrorAction SilentlyContinue

        if ($playJob.State -eq "Completed") {
            Start-Sleep -Seconds 1
            $playJob | Receive-Job
            $playJob | Remove-Job
            break;
        }

        if ($null -eq $gamePath -and $streamStartJob.State -eq "Completed") {
            [string]$gamePath = $streamStartJob | Receive-Job
            Write-Host "Received GamePath: $gamePath"
            $streamStartJob | Remove-Job
        }
    }
}
finally {
    Write-Host "Terminating..."
    Remove-Item "\\.\pipe\PlayniteWatcher" -ErrorAction Ignore
    Remove-Item "\\.\pipe\PlayniteWatcher-OnStreamStart" -ErrorAction Ignore
    Remove-Job -Name "Playnite-WatcherJob" -ErrorAction Ignore
    Remove-Job -Name "PlayniteWatcher-OnStreamStart" -ErrorAction Ignore
    Stop-Transcript
}


