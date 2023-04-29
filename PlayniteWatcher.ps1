param($playNiteId)

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


    Start-Process "F:\\Software\\Playnite\\Playnite.DesktopApp.exe" -ArgumentList "--start $playNiteId"

    while ($true) {
        Start-Sleep -Seconds 1

        $playJob = Get-Job -Name "Playnite-WatcherJob"

        if ($playJob.State -eq "Completed") {
            Start-Sleep -Seconds 1
            $playJob | Receive-Job
            $playJob | Remove-Job
            break;
        }
    }
}
finally {
    Write-Host "Terminating..."
    Remove-Item "\\.\pipe\PlayniteWatcher" -ErrorAction Ignore
    Remove-Job -Name "Playnite-WatcherJob" -ErrorAction Ignore
}


