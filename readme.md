# PlayNite Watcher Script

Welcome to the PlayNite Watcher script for Sunshine and Moonlight! This script helps you add multiple games to Sunshine, and automatically closes Moonlight when the games are closed. It also allows you to end the stream and have it close automatically on your computer. This script creates an experience similar to GeForce Experience with its limited 300 supported games. Once the installation is done, you'll see game names, box art, and other details in Moonlight.

# Why a script is needed
A lot of games launch with their own launchers, and do not work without being added as a "detached" command. Unfortunately, when doing this... it prevents Sunshine and Moonlight from being able to tell if the game has closed to end the stream automatically.

The purpose of this script is to use PlayNite to allow most games to work in the way you'd expect them to work by converting them into "commands" which can be watched by Sunshine.

## Caveats

## This script only works on Sunshine 0.20.x and above.

1. If you're using Windows 11, make sure your Default Terminal setting is set to Windows Console Host. Windows Terminal has a bug that prevents hidden windows in PowerShell.
2. Installing this script will temporarily close Sunshine to apply changes, so be prepared for a disconnect if you're using Moonlight during the script installation.

## Prerequisites

Before starting, make sure you meet these requirements:

- Your host computer must be running on Windows.
- Sunshine must be installed as a service (the zip version of Sunshine won't work with this script).
- Set Sunshine's logging level to Debug.
- Users must have read permissions to `%WINDIR%/Temp/Sunshine.log` (do not change other permissions, just ensure Users have at least read permissions).
- Sunshine is at least 0.20 or higher.

## Setup

Follow these steps to set up the PlayNite Watcher script:

1. Open the PlayNite program on your computer.
2. Visit the [Playnite Add-ons page](https://playnite.link/addons.html) and download the "Sunshine App Export" extension.
3. Locate the "apps.json" file used by Sunshine. It's usually found in the config folder where Sunshine is installed, like C:\Program Files\Sunshine\config
4. Make a copy of the "apps.json" file and place it in a different location on your computer, such as your desktop. (Choose an area that does not require admin rights)
5. Open PlayNite and select the games you want to add to Sunshine.
6. Click the "Controller" menu button in the top left corner of the PlayNite window, then go to "Extensions" -> "Sunshine App Export" -> "Export selected games".
7. When prompted, select the copy of the "apps.json" file you made in step 4. 
8. Move the modified "apps.json" file back to its original location on your computer. You may be prompted for administrator rights during this step.
9. Double-click on the "Installer.bat" file. Click OK on the administrator prompt dialog. A window will open, showing the list of games you selected in step 5.
10. If you see an error message about the program being unable to retrieve configuration, follow the instructions in the error message to fix the issue.
11. Check the box next to each game you want to install the PlayNite Watcher Script on. Alternatively, click the Check All button to select all PlayNite games added to Sunshine.
12. Click the "Install" button when you're ready.

## Troubleshooting

If you encounter any issues while using the PlayNite Watcher script, try these steps to resolve them:

1. Make sure you've followed all the setup steps correctly.
2. Verify you have the proper prerequisites installed and configured.
3. Ensure you have read permissions for `%WINDIR%/Temp/Sunshine.log`.
4. Verify Sunshine is at 0.20 or higher.

If you still experience issues after following these troubleshooting steps, please consider posting your issue on either the Sunshine or Moonlight discord. The author of this script is DemonCat.