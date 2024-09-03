$isAdmin = [bool]([System.Security.Principal.WindowsIdentity]::GetCurrent().groups -match 'S-1-5-32-544')
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

$OutputEncoding = [Console]::OutputEncoding = New-Object System.Text.Utf8Encoding
[Console]::InputEncoding = New-Object System.Text.Utf8Encoding

$flagFilePath = "$env:APPDATA\PlayniteWatcher\PlayniteWatcherAdminFlag"

class ApplicationInfo {
    [string]$applicationName
    [string]$uniqueId
    [string]$cmd
    [string]$detached
    [string]$imagePath
}

# To minimize prompts, we will only warn the user once about admin rights.
if (-not $isAdmin) {
    if (-not (Test-Path $flagFilePath)) {
        $result = [System.Windows.Forms.MessageBox]::Show("You will be prompted for administrator rights, as Sunshine requires admin in order to modify the apps.json file.", "Administrator Required", [System.Windows.Forms.MessageBoxButtons]::OKCancel, [System.Windows.Forms.MessageBoxIcon]::Information)
        New-Item -ItemType File -Path $flagFilePath -Force
        if ($result -eq [System.Windows.Forms.DialogResult]::Cancel) {
            exit
        }
    }

    else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`"" -WindowStyle Hidden
        exit
    }
}



$scriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent
Set-Location $scriptPath
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

    return $foundPath.Replace("\\", "\")
}

function SaveChanges($configPath, $updatedApps) {

    $appConfiguration = Get-Content -Encoding utf8 -Path $configPath -Raw | ConvertFrom-Json
    [object[]]$filteredApps = FilterPlayniteApps -configPath $configPath

    foreach ($app in $updatedApps) {
        if ($app.uniqueId -eq "") {
            continue;
        }
        
        $jsonApp = [PSCustomObject]@{
            'image-path' = $app.imagePath
            name         = $app.applicationName
        }
        if ($app.cmd -ne "") {
            $jsonApp | Add-Member -MemberType NoteProperty  -Name "cmd" -Value $app.cmd -Force
        }
        if ($app.detached -ne "") {
            $jsonApp | Add-Member -MemberType NoteProperty -Name "detached" -Value $app.detached -Force
        }
        

        $filteredApps += $jsonApp
    }
    $appConfiguration.apps = $filteredApps
    $appConfiguration | ConvertTo-Json -Depth 100 | Set-Content -Path $configPath -Encoding utf8
}


function ParseGames($configPath) {
    $apps = @()
    $JsonContent = Get-Content -Encoding utf8 -Path $configPath -Raw | ConvertFrom-Json
    $JsonContent.apps | ForEach-Object {
        $app = [ApplicationInfo]::new()
        $_.'image-path' -match 'Apps\\(.*)\\' | Out-Null
        if ($Matches) {
            $id = $Matches[1]

            $app.applicationName = $_.name
            $app.uniqueId = $id
            $app.imagePath = $_.'image-path'
            $app.cmd = $_.cmd
            $app.detached = $_.detached

            $apps += $app
        }
    }

    return $apps
}

function FilterPlayniteApps($configPath) {
    $JsonContent = Get-Content -Encoding utf8 -Path $configPath -Raw | ConvertFrom-Json
    return $JsonContent.apps | Where-Object { $_.cmd -notlike '*playnite*' -and $_.detached -notlike '*playnite*' }
}

function RemoveDuplicates($apps) {
    $dict = [System.Collections.Generic.Dictionary[string, ApplicationInfo]]::new()
    foreach ($app in $apps) {
        if ($dict.ContainsKey($app.uniqueId)) {
            continue
        }
        else {
            $dict.Add($app.uniqueId, $app);
        }
    }

    return $dict.Values
}

function SaveSettings() {
    ## Replace the $playNitePath with the users selection
    $playnitePath = $playNitePathTextBox.Text
       
        
    $filePath = ".\PlayniteWatcher.ps1"
            
    $content = Get-Content -Encoding utf8 -Path $filePath
            
    $playNitePattern = '(\$playNitePath\s*=\s*")[^"]*(")'
    $configPattern = '(\$sunshineConfigPath\s*=\s*")[^"]*(")'
            
    $updatedContent = $content -replace $playNitePattern, "`$1$($playnitePath.Replace('\', '\\'))`$2"
    $updatedContent = $updatedContent -replace $configPattern, "`$1$($configPathTextBox.Text.Replace('\', '\\'))`$2"
            
    Set-Content -Path $filePath -Value $updatedContent
    ######
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
        Title="Playnite Watcher Installer" Height="230" Width="720">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <DockPanel Grid.Row="0" Margin="10">
            <Label Content="Sunshine Apps.json Path:" VerticalAlignment="Center" Width="165"/>
            <TextBox Name="ConfigPath" Text="C:\Program Files\Sunshine\config\apps.json" Margin="5,0,5,0" Width="325" Height="25" IsReadOnly="true"/>
            <Button Name="BrowseButton" Content="Browse" Width="75" HorizontalAlignment="Left" Margin="5,0,5,0" Height="25"/>
        </DockPanel>
        <DockPanel Grid.Row="1" Margin="10">
            <Label Content="Playnite Executable Path:" VerticalAlignment="Center" Width="165"/>
            <TextBox Name="PlaynitePath" Text="C:\Program Files\Playnite\Playnite.DesktopApp.exe" Margin="5,0,5,0" Width="325" Height="25" IsReadOnly="true"/>
            <Button Name="PlayniteBrowseButton" Content="Browse" Width="75" HorizontalAlignment="Left" Margin="5,0,5,0" Height="25"/>
        </DockPanel>


        <DockPanel Grid.Row="2" Margin="10" VerticalAlignment="Top">
            <Button Name="InstallButton" Content="Install" Width="75" Height="25" Margin="2,0,2,0"/>
            <Button Name="UninstallButton" Content="Uninstall" Width="75" Height="25" Margin="2,0,2,0"/>
        </DockPanel>

        <TextBlock Grid.Row="3" Margin="0" TextWrapping="Wrap" HorizontalAlignment="Center" FontWeight="Bold">
        NOTICE: Clicking install or uninstall will terminate existing Moonlight sessions and restart Playnite to finish the installation.
    </TextBlock>
    </Grid>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$configPathTextBox = $window.FindName("ConfigPath")
$playNitePathTextBox = $window.FindName("PlaynitePath")

# Browse button click event handler
$window.FindName("BrowseButton").Add_Click({
        ShowOpenFileDialog -filter "JSON files (*.json)|*.json|All files (*.*)|*.*" -initialDirectory ([System.IO.Path]::GetDirectoryName($configPathTextBox.Text)) -textBox $configPathTextBox
        LoadGames -configPath $configPathTextBox.Text
        SaveSettings
    })

$window.FindName("PlayniteBrowseButton").Add_Click({
        ShowOpenFileDialog -filter "Playnite Executable|Playnite.DesktopApp.exe" -initialDirectory ([System.IO.Path]::GetDirectoryName($playNitePathTextBox.Text)) -textBox $playNitePathTextBox
        SaveSettings
    })

$window.FindName("InstallButton").Add_Click({
        $installCount = 0
        $playniteRoot = Split-Path $playNitePathTextBox.Text -Parent

        $updatedApps = ParseGames -configPath $configPathTextBox.Text
        $updatedApps = RemoveDuplicates -apps $updatedApps




        foreach ($playniteApp in $updatedApps) {
            $installCount += 1
            $playniteApp.detached = ""
            $playniteApp.cmd = "powershell.exe -executionpolicy bypass -windowstyle hidden -file `"$scriptPath\PlayniteWatcher.ps1`" $($playniteApp.uniqueId)"
        }

        ## add FullScreen applet
        if ($null -eq ($updatedApps | Where-Object { $_.name -eq "PlayNite FullScreen App" })) {
            $updatedApps = , [PSCustomObject]@{
                applicationName = "PlayNite FullScreen App"
                imagePath       = "$scriptPath\playnite-boxart.png"
                cmd             = "powershell.exe -executionpolicy bypass -windowstyle hidden -file `"$scriptPath\PlayniteWatcher.ps1`" FullScreen"
                detached        = ""
            } + $updatedApps

            
        }

            

        Remove-Item -Path "$playniteRoot\Extensions\PlayniteWatcherExt" -Recurse -Force -ErrorAction SilentlyContinue
        Copy-Item -Path "./PlayNiteWatcherExt"  -Destination "$playniteRoot\Extensions\PlayNiteWatcherExt" -Force  -Recurse
        SaveChanges -configPath $configPathTextBox.Text -updatedApps $updatedApps

        $scopedInstall = {
            . $scriptPath\PrepCommandInstaller.ps1 $true
        }

        & $scopedInstall

 

        ## Open it in a background thread, that way if user disconnected from a moonlight session it will still restart playnite.
        Start-Job -ArgumentList $playNitePathTextBox.Text {
            param($path)
            Start-Sleep -Seconds 5
            Get-Process Playnite.DesktopApp -ErrorAction SilentlyContinue | Stop-Process -ErrorAction SilentlyContinue
            Start-Process -FilePath explorer.exe -ArgumentList $path
        }
        
        [System.Windows.Forms.MessageBox]::Show("The script has been successfully installed to $installCount application(s)!", "Installation Complete!", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        

    })

$window.FindName("UninstallButton").Add_Click({

        $msgBoxTitle = "Uninstall script"
        $msgBoxText = "Are you sure you want to remove this script? This will remove all exported games from Playnite"
        $msgBoxButtons = [System.Windows.Forms.MessageBoxButtons]::YesNo
        $msgBoxIcon = [System.Windows.Forms.MessageBoxIcon]::Warning
        $msgBoxResult = [System.Windows.Forms.MessageBox]::Show($msgBoxText, $msgBoxTitle, $msgBoxButtons, $msgBoxIcon)

        if ($msgBoxResult -eq [System.Windows.Forms.DialogResult]::Yes) {
            $playnitePath = $playNitePathTextBox.Text
            $playniteRoot = Split-Path $playnitePath -Parent
            $parsedApps = ParseGames -configPath $configPathTextBox.Text | ForEach-Object { $_.uniqueId = "" | Out-Null; $_ }

            SaveChanges -configPath $configPathTextBox.Text -updatedApps $parsedApps

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
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("An issue was encountered while attempting to retrieve your Sunshine application list. Once you dismiss this message, a window will open, prompting you to locate the Sunshine config folder. Please ensure that navigate to your Sunshine config folder and select the `"apps.json`" file within it.", "Error: Could not find apps.json file", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            ShowOpenFileDialog -filter "JSON files (*.json)|*.json|All files (*.*)|*.*" -initialDirectory $env:ProgramFiles -textBox $configPathTextBox
        }

        try {
            $path = LoadPlayniteExecutablePath
            if (-not (Test-Path $path)) {
                throw "Could not locate PlayNite"
            }

        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("An issue was encountered while attempting to retrieve the PlayNite executable path. Once you dismiss this message, a window will open, prompting you to locate the PlayNite folder. Please ensure that you choose the PlayNite folder and select the `"PlayNiteDesktop.exe`" file within it.", "Error: Could not find PlayNite Executable", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            ShowOpenFileDialog -filter "Playnite Exe|Playnite.DesktopApp.exe|All files (*.*)|*.*" -textBox $playNitePathTextBox
        }

        SaveSettings
    })

# Show WPF window
$window.ShowDialog() | Out-Null
