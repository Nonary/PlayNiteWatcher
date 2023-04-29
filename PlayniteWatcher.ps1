param($playNiteId)

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

    $job = Get-Job -Name "Playnite-WatcherJob"

    if ($job.State -eq "Completed") {
        $job
        $job | Remove-Job
        break;
    }
}

Remove-Item "\\.\pipe\$pipeName" -ErrorAction Ignore