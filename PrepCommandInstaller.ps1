param($install)
$filePath = $($MyInvocation.MyCommand.Path)
$scriptRoot = Split-Path $filePath -Parent
$scriptPath = "$scriptRoot\OnScriptEnd.ps1"


# Define the path to the Sunshine configuration file
$confPath = "C:\Program Files\Sunshine\config\sunshine.conf"
$scriptRoot = Split-Path $scriptPath -Parent



# Get the current value of global_prep_cmd from the configuration file
function Get-GlobalPrepCommand {

    # Read the contents of the configuration file into an array of strings
    $config = Get-Content -Path $confPath

    # Find the line that contains the global_prep_cmd setting
    $globalPrepCmdLine = $config | Where-Object { $_ -match '^global_prep_cmd\s*=' }

    # Extract the current value of global_prep_cmd
    if ($globalPrepCmdLine -match '=\s*(.+)$') {
        return $matches[1]
    }
    else {
        Write-Information "Unable to extract current value of global_prep_cmd, this probably means user has not setup prep commands yet."
        return [object[]]@()
    }
}

# Remove any existing commands that contain PlayNiteWatcher from the global_prep_cmd value
function Remove-PlayNiteWatcherCommand {

    # Get the current value of global_prep_cmd as a JSON string
    $globalPrepCmdJson = Get-GlobalPrepCommand -ConfigPath $confPath

    # Convert the JSON string to an array of objects
    $globalPrepCmdArray = $globalPrepCmdJson | ConvertFrom-Json
    $filteredCommands = @()

    # Remove any PlayNiteWatcher Commands
    for ($i = 0; $i -lt $globalPrepCmdArray.Count; $i++) {
        if (-not ($globalPrepCmdArray[$i].undo -like "*PlayNiteWatcher*")) {
            $filteredCommands += $globalPrepCmdArray[$i]
        }
    }

    return [object[]]$filteredCommands
}

# Set a new value for global_prep_cmd in the configuration file
function Set-GlobalPrepCommand {
    param (

        # The new value for global_prep_cmd as an array of objects
        [object[]]$Value
    )

    if ($null -eq $Value) {
        $Value = [object[]]@()
    }


    # Read the contents of the configuration file into an array of strings
    $config = Get-Content -Path $confPath

    # Get the current value of global_prep_cmd as a JSON string
    $currentValueJson = Get-GlobalPrepCommand -ConfigPath $confPath

    # Convert the new value to a JSON string
    $newValueJson = ConvertTo-Json -InputObject $Value -Compress

    # Replace the current value with the new value in the config array
    try {
        $config = $config -replace [regex]::Escape($currentValueJson), $newValueJson
    }
    catch {
        # If it failed, it probably does not exist yet.
        # In the event the config only has one line, we will cast this to an object array so it appends a new line automatically.

        if ($Value.Length -eq 0) {
            [object[]]$config += "global_prep_cmd = []"
        }
        else {
            [object[]]$config += "global_prep_cmd = $($newValueJson)"
        }
    }



    # Write the modified config array back to the file
    $config | Set-Content -Path $confPath -Force
}

# Add a new command to run PlayNiteWatcher.ps1 to the global_prep_cmd value
function Add-PlayNiteWatcherCommand {

    # Remove any existing commands that contain PlayNiteWatcher from the global_prep_cmd value
    $globalPrepCmdArray = Remove-PlayNiteWatcherCommand -ConfigPath $confPath

    # Create a new object with the command to run PlayNiteWatcher.ps1
    $PlayNiteWatcherCommand = [PSCustomObject]@{
        do       = ""
        elevated = "false"
        undo     = "powershell.exe -executionpolicy bypass -file `"$($scriptRoot)\PlayNiteWatcher-EndScript.ps1`""
    }

    # Add the new object to the global_prep_cmd array
    [object[]]$globalPrepCmdArray += $PlayNiteWatcherCommand

    return [object[]]$globalPrepCmdArray
}
$commands = @()
if ($install -eq "True") {
    $commands = Add-PlayNiteWatcherCommand
}
else {
    $commands = Remove-PlayNiteWatcherCommand 
}

Set-GlobalPrepCommand $commands

$sunshineService = Get-Service -ErrorAction Ignore | Where-Object {$_.Name -eq 'sunshinesvc' -or $_.Name -eq 'SunshineService'}
# In order for the commands to apply we have to restart the service
$sunshineService | Restart-Service  -WarningAction SilentlyContinue
Write-Host "If you didn't see any errors, that means the script installed without issues! You can close this window."

