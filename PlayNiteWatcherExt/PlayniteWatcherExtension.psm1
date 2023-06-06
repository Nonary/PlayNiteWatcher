function Send-PipeMessage($pipeName, $message) {
    $pipeExists = Get-ChildItem -Path "\\.\pipe\" | Where-Object { $_.Name -eq $pipeName } 
    if ($pipeExists.Length -gt 0) {
        $__logger.Info("Named pipe currently exists, attempting to send communication")
        $pipe = New-Object System.IO.Pipes.NamedPipeClientStream(".", $pipeName, [System.IO.Pipes.PipeDirection]::Out)
        $__logger.Info("Connecting to pipe...")

        $pipe.Connect(5)
        $streamWriter = New-Object System.IO.StreamWriter($pipe)
        $__logger.Info("Sending message to pipe: $message...")

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
        $__logger.Info("Communication completed!")
    }
}
function OnApplicationStarted() {
    $__logger.Info("OnApplicationStarted")
}

function OnApplicationStopped() {
    $__logger.Info("OnApplicationStopped")
}

function OnLibraryUpdated() {
    $__logger.Info("OnLibraryUpdated")
}

function OnGameStarting() {
    param($evnArgs)
    $__logger.Info("OnGameStarting $($evnArgs.Game)")
}

function OnGameStarted() {
    param($evnArgs)
    $game = $evnArgs.Game
    $gamePath = $game.InstallDirectory

    # Check to see if the game is emulated.
    if ($null -ne $game.GameActions) {
        $emulatorAction = $game.GameActions | Where-Object { $_.Type -eq "Emulator" } | Select-Object -First 1 -ErrorAction SilentlyContinue
        if ($null -ne $emulatorAction) {
            $emulatorId = $emulatorAction.EmulatorId.Guid
            $emulator = $PlayniteAPI.Database.Emulators | Where-Object { $_.Id -eq $emulatorId }
            $gamePath = $emulator.InstallDir
        }
    }

    Send-PipeMessage -pipeName "PlayniteWatcher-OnStreamStart" -message $gamePath
}

function OnGameStopped() {
    param($evnArgs)
    $__logger.Info("OnGameStopping $($evnArgs.Game)")

    $mode = $PlayniteApi.ApplicationInfo.Mode
    $isFullscreen = $mode -eq [Playnite.SDK.ApplicationMode]::Fullscreen
    

    if (-not $isFullscreen) {
        $__logger.Info("Application is not in fullscreen, stopping playnite watcher!")
        Send-PipeMessage -pipeName "PlayniteWatcher" -message "Terminate"
        Send-PipeMessage -pipeName "PlayniteWatcher-OnStreamStart" -message "Terminate"
    }
}

function OnGameInstalled() {
    param($evnArgs)
    $__logger.Info("OnGameInstalled $($evnArgs.Game)")
}

function OnGameUninstalled() {
    param($evnArgs)
    $__logger.Info("OnGameUninstalled $($evnArgs.Game)")
}

function OnGameSelected() {
    param($gameSelectionEventArgs)
    $__logger.Info("OnGameSelected $($gameSelectionEventArgs.OldValue) -> $($gameSelectionEventArgs.NewValue)")
}
