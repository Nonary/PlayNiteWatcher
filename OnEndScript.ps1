
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
    
