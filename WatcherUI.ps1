$isAdmin = [bool]([System.Security.Principal.WindowsIdentity]::GetCurrent().groups -match 'S-1-5-32-544')
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

$OutputEncoding = [Console]::OutputEncoding = New-Object System.Text.Utf8Encoding
[Console]::InputEncoding = New-Object System.Text.Utf8Encoding

# If the current user is not an administrator, re-launch the script with elevated privileges
if (-not $isAdmin) {
    $result = [System.Windows.Forms.MessageBox]::Show("You will be prompted for administrator rights, as Sunshine requires admin in order to modify the apps.json file.", "Administrator Required", [System.Windows.Forms.MessageBoxButtons]::OKCancel, [System.Windows.Forms.MessageBoxIcon]::Information)
    if ($result -eq [System.Windows.Forms.DialogResult]::Cancel) {
        exit
    }
    else {
        Start-Process powershell.exe  -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`"" -WindowStyle Hidden
        exit
    }
}

$scriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent
Set-Location $scriptPath
$sunshineApps = $null
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms


function LoadConfigFilePath() { 
    # Retrieve the path utilizing regex from the primary script.
    $scriptContents = Get-Content "./PlayniteWatcher.ps1"
    $ma = $scriptContents | select-string  '(\$sunshineConfigPath)\s=\s"(.*)"'
    $foundPath = $ma.Matches.Groups[2].Value
    $configPathTextBox.Text = $foundPath.Replace('\\', '\')
}

function LoadPlayniteExecutablePath() { 
    # Retrieve the path utilizing regex from the primary script.
    $scriptContents = Get-Content "./PlayniteWatcher.ps1"
    $ma = $scriptContents | select-string  '(\$playnitepath)\s=\s"(.*)"'
    $foundPath = $ma.Matches.Groups[2].Value
    $playNitePathTextBox.Text = $foundPath.Replace('\\', '\')
}

function SaveChanges($configPath, $JsonContent, $updatedApps) {
    $JsonContent.apps = $updatedApps
    $JsonContent | ConvertTo-Json -Depth 100 | Set-Content -Path $configPath -Encoding utf8
}

function LoadGames($configPath) {

    if (-not (Test-Path $configPath)) {
        throw "Unable to locate configuration"
    }

    # Read JSON content from file
    $JsonContent = Get-Content -Encoding utf8 -Path $configPath -Raw | ConvertFrom-Json

    # Filter games with PlayNite commands
    $PlayNiteGames = $JsonContent.apps | Where-Object { ($_.detached -match 'PlayNite' -or $_.cmd -match 'PlayNite') -and ($_.name -ne "PlayNite FullScreen App") }
    $script:sunshineApps = $PlayNiteGames

    # Clear the current list
    $gameList.Children.Clear()

    # Add games to the UI
    foreach ($game in $PlayNiteGames) {
        $isChecked = $game.cmd -match 'PlayNiteWatcher'
        $checkBox = New-Object System.Windows.Controls.CheckBox
        $checkBox.Content = $game.name
        $checkBox.IsChecked = $isChecked
        $gameList.Children.Add($checkBox)
    }

    
}

# OpenFileDialog Function
function ShowOpenFileDialog($filter, $initialDirectory, $textBox) {
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Filter = $filter
    $openFileDialog.InitialDirectory = $initialDirectory

    if ($openFileDialog.ShowDialog() -eq "OK") {
        $textBox.Text = $openFileDialog.FileName
    }
}

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Playnite Watcher Installer" Height="450" Width="635">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <DockPanel Grid.Row="0" Margin="10">
            <Label Content="Sunshine Config Location:" VerticalAlignment="Center" Width="165"/>
            <TextBox Name="ConfigPath" Text="C:\Program Files\Sunshine\config\apps.json" Margin="5,0,5,0" Width="325" Height="25"/>
            <Button Name="BrowseButton" Content="Browse" Width="75" HorizontalAlignment="Left" Margin="5,0,5,0" Height="25"/>
        </DockPanel>
        <DockPanel Grid.Row="1" Margin="10">
            <Label Content="Playnite Executable Location:" VerticalAlignment="Center" Width="165"/>
            <TextBox Name="PlaynitePath" Text="C:\Program Files\Playnite\Playnite.DesktopApp.exe" Margin="5,0,5,0" Width="325" Height="25"/>
            <Button Name="PlayniteBrowseButton" Content="Browse" Width="75" HorizontalAlignment="Left" Margin="5,0,5,0" Height="25"/>
        </DockPanel>
        <GroupBox Grid.Row="2" Header="PlayNite Games" Margin="10">
            <ScrollViewer VerticalScrollBarVisibility="Auto">
                <StackPanel Name="GameList"/>
            </ScrollViewer>
        </GroupBox>
        <DockPanel Grid.Row="3" Margin="10">
            <TextBlock TextWrapping="Wrap" Width="400">Check the games you wish to have Sunshine end the stream when the game closes.</TextBlock>
            <Button Name="CheckAllButton" Content="Check All" Width="75" Margin="5,0,5,0"/>
        </DockPanel>
        <DockPanel Grid.Row="4" Margin="10">
            <Button Name="InstallButton" Content="Install" Width="75" Margin="5,0,5,0"/>
            <Button Name="UninstallButton" Content="Uninstall" Width="75" Margin="5,0,5,0"/>
            <Button Name="ExitButton" Content="Exit" Width="75"/>
        </DockPanel>
    </Grid>
</Window>

"@

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$gameList = $window.FindName("GameList")
$configPathTextBox = $window.FindName("ConfigPath")
$playNitePathTextBox = $window.FindName("PlaynitePath")

# Browse button click event handler
$window.FindName("BrowseButton").Add_Click({
        ShowOpenFileDialog -filter "JSON files (*.json)|*.json|All files (*.*)|*.*" -initialDirectory ([System.IO.Path]::GetDirectoryName($configPathTextBox.Text)) -textBox $configPathTextBox
        LoadGames -configPath $configPathTextBox.Text
    })

$window.FindName("PlayniteBrowseButton").Add_Click({
        ShowOpenFileDialog -filter "Exe files (*.exe)|*.exe|All files (*.*)|*.*" -initialDirectory ([System.IO.Path]::GetDirectoryName($playNitePathTextBox.Text)) -textBox $playNitePathTextBox
    })

# Check all button click event handler
$window.FindName("CheckAllButton").Add_Click({
        foreach ($checkBox in $gameList.Children) {
            $checkBox.IsChecked = $true
        }
    })

# Exit button click event handler
$window.FindName("ExitButton").Add_Click({
        $window.Close()
    })

$window.FindName("InstallButton").Add_Click({


        ## Replace the $playNitePath with the users selection
        $playnitePath = $playNitePathTextBox.Text
        $playniteRoot = Split-Path $playnitePath -Parent

        $filePath = ".\PlayniteWatcher.ps1" 
    
        $content = Get-Content -Encoding utf8 -Path $filePath
    
        $playNitePattern = '(\$playNitePath\s*=\s*")[^"]*(")'
        $configPattern = '(\$sunshineConfigPath\s*=\s*")[^"]*(")'
    
        $updatedContent = $content -replace $playNitePattern, "`$1$($playnitePath.Replace('\', '\\'))`$2"
        $updatedContent = $updatedContent -replace $configPattern, "`$1$($configPathTextBox.Text.Replace('\', '\\'))`$2"
    
        Set-Content -Path $filePath -Value $updatedContent
        ######
    


        $JsonContent = Get-Content -Encoding utf8 -Path $configPathTextBox.Text -Raw | ConvertFrom-Json

        $updatedApps = $JsonContent.apps.Clone()

        ## add FullScreen applet
        if ($null -eq ($updatedApps | Where-Object { $_.name -eq "PlayNite FullScreen App" })) {
            $updatedApps += [PSCustomObject]@{
                name         = "PlayNite FullScreen App"
                'image-path' = "$scriptPath\playnite-boxart.png"
                cmd          = "powershell.exe -executionpolicy bypass -windowstyle hidden -file `"$scriptPath\PlayniteWatcher.ps1`" FullScreen"
            }
        }

        foreach ($checkBox in $gameList.Children) {
            
            $appName = $checkBox.Content
            $app = $updatedApps | Where-Object { $_.name -eq $appName }
            $app.'image-path' -match 'Apps\\(.*)\\'
            $id = $Matches[1]

            if ($checkBox.IsChecked) {

                $app.PSObject.Properties.Remove('detached')
                $app | Add-Member -MemberType NoteProperty -Name "cmd" -Value "powershell.exe -executionpolicy bypass -windowstyle hidden -file `"$scriptPath\PlayniteWatcher.ps1`" $id" -Force
            }
            else {
                $app.PSObject.Properties.Remove('cmd')
                $app | Add-Member -MemberType NoteProperty -Name "detached" -Value @("$playnitePath --start $id") -Force
            }
        }
        Remove-Item -Path "$playniteRoot\Extensions\PlayniteWatcherExt" -Recurse -Force -ErrorAction SilentlyContinue
        Copy-Item -Path "./PlayNiteWatcherExt"  -Destination "$playniteRoot\Extensions\PlayNiteWatcherExt" -Force  -Recurse
        SaveChanges -configPath $configPathTextBox.Text -updatedApps $updatedApps -JsonContent $JsonContent

        $scopedInstall = {
            . $scriptPath\PrepCommandInstaller.ps1 $true
        }
    
        & $scopedInstall
        [System.Windows.Forms.MessageBox]::Show("You can now close this application, the script has been successfully installed to the selected applications", "Installation Complete!", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)

    })
    
$window.FindName("UninstallButton").Add_Click({

        $msgBoxTitle = "Uninstall script"
        $msgBoxText = "Are you sure you want to remove this script?"
        $msgBoxButtons = [System.Windows.Forms.MessageBoxButtons]::YesNo
        $msgBoxIcon = [System.Windows.Forms.MessageBoxIcon]::Warning
        $msgBoxResult = [System.Windows.Forms.MessageBox]::Show($msgBoxText, $msgBoxTitle, $msgBoxButtons, $msgBoxIcon)
    
        if ($msgBoxResult -eq [System.Windows.Forms.DialogResult]::Yes) {
            $JsonContent = Get-Content -Encoding utf8 -Path $configPathTextBox.Text -Raw | ConvertFrom-Json
            $playnitePath = $playNitePathTextBox.Text
            $playniteRoot = Split-Path $playnitePath -Parent
            $updatedApps = $JsonContent.apps.Clone() | Where-Object { $_.name -ne "PlayNite FullScreen App" }
    
            foreach ($checkBox in $gameList.Children) {
                $appName = $checkBox.Content
                $app = $updatedApps | Where-Object { $_.name -eq $appName }
                $app.'image-path' -match 'Apps\\(.*)\\'
                $id = $Matches[1]
    
    
                $app.PSObject.Properties.Remove('cmd')
                $app | Add-Member -MemberType NoteProperty -Name "detached" -Value @("`"$playnitePath`" --start $id") -Force
                
            }

            # Remove FullScreen Applet
            $updatedApps = $updatedApps | Where-Object { $_.name -ne 'PlayNite FullScreen App' }
    
            SaveChanges -configPath $configPathTextBox.Text -updatedApps $updatedApps -JsonContent $JsonContent
    
            $scopedInstall = {
                . $scriptPath\PrepCommandInstaller.ps1 $false
            }

            Remove-Item "$playniteRoot\Extensions\PlayNiteWatcherExt" -Force  -Recurse
        
            & $scopedInstall
            [System.Windows.Forms.MessageBox]::Show("You can now close this application, the script has been successfully uninstalled", "Uninstall Complete!", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
    })
    

$window.Add_Loaded({
        try {
            LoadConfigFilePath
            LoadGames -configPath $configPathTextBox.Text
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("An issue was encountered while attempting to retrieve your Sunshine application list. Once you dismiss this message, a window will open, prompting you to locate the Sunshine config folder. Please ensure that navigate to your Sunshine config folder and select the `"apps.json`" file within it.", "Error: Could not find apps.json file", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            ShowOpenFileDialog -filter "JSON files (*.json)|*.json|All files (*.*)|*.*" -initialDirectory $env:ProgramFiles -textBox $configPathTextBox
            LoadGames -configPath $configPathTextBox.Text
        }

        try {
            LoadPlayniteExecutablePath 
            if (-not (Test-Path $playNitePathTextBox.Text)) {
                throw "Could not locate PlayNite"
            }
            
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("An issue was encountered while attempting to retrieve the PlayNite executable path. Once you dismiss this message, a window will open, prompting you to locate the PlayNite folder. Please ensure that you choose the PlayNite folder and select the `"PlayNiteDesktop.exe`" file within it.", "Error: Could not find PlayNite Executable", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            ShowOpenFileDialog -filter "Playnite Exe|Playnite.DesktopApp.exe|All files (*.*)|*.*" -textBox $playNitePathTextBox
        }
    })

# Show WPF window
$window.ShowDialog() | Out-Null