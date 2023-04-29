$isAdmin = [bool]([System.Security.Principal.WindowsIdentity]::GetCurrent().groups -match 'S-1-5-32-544')

# If the current user is not an administrator, re-launch the script with elevated privileges
if (-not $isAdmin) {
    Start-Process powershell.exe  -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -NoExit -File `"$($MyInvocation.MyCommand.Path)`""
    exit
}

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

function GetPlayniteExecutablePath($apps) { 
    foreach ($app in $apps) { 
        if ($app.PSObject.Properties.Name -contains 'detached') { 
            $match = select-string -InputObject $app.detached -Pattern '^(?<path>.+)\\Playnite.DesktopApp.exe' 
            if ($match) { 
                return $match.Matches.Groups[0].Value 
            } 
        }
    } return "None Found"
}

function SaveChanges($configPath, $JsonContent, $updatedApps) {
    $JsonContent.apps = $updatedApps
    $JsonContent | ConvertTo-Json -Depth 100 | Set-Content -Path $configPath
}



function LoadGames($configPath) {
    # Read JSON content from file
    $JsonContent = Get-Content -Path $configPath -Raw | ConvertFrom-Json

    # Filter games with PlayNite commands
    $PlayNiteGames = $JsonContent.apps | Where-Object { $_.detached -match 'PlayNite' -or $_.cmd -match 'PlayNite' }

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

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="PlayNite Games" Height="450" Width="600">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <DockPanel Grid.Row="0" Margin="10">
            <Label Content="PlayNite Executable:" VerticalAlignment="Center"/>
            <TextBox Name="PlayNightTextBox" Text="C:\Program Files\Sunshine\config\apps.json" Margin="5,0,5,0" Width="400"/>
            <Button Name="BrowseButton" Content="Browse" Width="75"/>
        </DockPanel>
        <DockPanel Grid.Row="1" Margin="10">
            <Label Content="Config file:" VerticalAlignment="Center"/>
            <TextBox Name="ConfigPath" Text="C:\Program Files\Sunshine\config\apps.json" Margin="5,0,5,0" Width="400"/>
            <Button Name="BrowseButton" Content="Browse" Width="75"/>
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
            <Button Name="ExitButton" Content="Exit" Width="75"/>
        </DockPanel>
    </Grid>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$gameList = $window.FindName("GameList")
$configPathTextBox = $window.FindName("ConfigPath")



# Load default games
LoadGames -configPath $configPathTextBox.Text

# Browse button click event handler
$window.FindName("BrowseButton").Add_Click({
        $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $openFileDialog.Filter = "JSON files (*.json)|*.json|All files (*.*)|*.*"
        $openFileDialog.InitialDirectory = [System.IO.Path]::GetDirectoryName($configPathTextBox.Text)

        if ($openFileDialog.ShowDialog() -eq "OK") {
            $configPathTextBox.Text = $openFileDialog.FileName
            LoadGames -configPath $openFileDialog.FileName
        }
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

        $JsonContent = Get-Content -Path $configPathTextBox.Text -Raw | ConvertFrom-Json
        $playnitePath = GetPlayniteExecutablePath -apps $JsonContent.apps
        $updatedApps = $JsonContent.apps.Clone()

        foreach ($checkBox in $gameList.Children) {
            $appName = $checkBox.Content
            $app = $updatedApps | Where-Object { $_.name -eq $appName }
            $app.'image-path' -match 'Apps\\(.*)\\'
            $id = $Matches[1]

            if ($checkBox.IsChecked) {
                $app.PSObject.Properties.Remove('detached')
                $app | Add-Member -MemberType NoteProperty -Name "cmd" -Value "powershell.exe -executionpolicy bypass -windowstyle hidden -file `"`"F:\sources\PlayNiteWatcher\PlayniteWatcher.ps1`"`" $id" -Force
            }
            else {
                $app.PSObject.Properties.Remove('cmd')
                $app | Add-Member -MemberType NoteProperty -Name "detached" -Value @("$playnitePath --start $id") -Force
        
            }
        }

        SaveChanges -configPath $configPathTextBox.Text -updatedApps $updatedApps -JsonContent $JsonContent
        $icon = [System.Windows.Forms.MessageBoxIcon]::Information
        $title = "Installation Complete!"
        [System.Windows.Forms.MessageBox]::Show("You can now close this application, the script has been succesfully installed to the selected applications", $title, $icon)
    })

# Show WPF window
$window.ShowDialog() | Out-Null


