# PlayNite Watcher Script

Welcome to the PlayNite Watcher script for Sunshine and Moonlight! This script helps you add multiple games to Sunshine, and automatically closes Moonlight when the games are closed. It also allows you to end the stream and have it close automatically on your computer. This script creates an experience similar to GeForce Experience with its limited 300 supported games. Once the installation is done, you'll see game names, box art, and other details in Moonlight. 

If you prefer having a "Big Picture Mode" experience, or want to utilize the FullScreen mode of PlayNite this script also offers that capability as well, and will support terminating games and ending sunshine in the exact same manner as an individual application being added.

# Why a script is needed
A lot of games launch with their own launchers, and do not work without being added as a "detached" command. Unfortunately, when doing this... it prevents Sunshine and Moonlight from being able to tell if the game has closed to end the stream automatically.

In addition, those that prefer to add a single app for a big picture mode experience, can also benefit from this script as it will close out games and end sunshine automatically once finished. This is useful for setting up a "kiosk" PC, or handling out closing out frozen emulators using just Moonlight itself.

Essentially, the purpose of this script is to use PlayNite to allow most games to work in the way you'd expect them to work by converting them into "commands" which can be watched by Sunshine.

## Caveats:
 - This script only works with Sunshine 0.20.x or above.
 - If using Windows 11, you'll need to set the default terminal to Windows Console Host as there is currently a bug in Windows Terminal that prevents hidden consoles from working properly.
    * That can be changed at Settings > Privacy & security > Security > For developers > Terminal [Let Windows decide] >> (change to) >> Terminal [Windows Console Host]
 - Prepcommands do not work from cold reboots, and will prevent Sunshine from working until you logon locally.
   * You should add a new application (with any name you'd like) in the WebUI and leave **both** the command and detached command empty.
   * When adding this new application, make sure global prep command option is disabled.
   * That will serve as a fallback option when you have to remote into your computer from a cold start.
   * Normal reboots issued from start menu, will still work without the workaround above as long as Settings > Accounts > Sign-in options and "Use my sign-in info to automatically finish setting up after an update" is enabled which is default in Windows 10 & 11.
 - The script will stop working if you move the folder, simply reinstall it to resolve that issue.

## Prerequisites

Before starting, make sure you meet these requirements:

- Your host computer must be running on Windows.
- Sunshine must be installed as a service (the zip version of Sunshine won't work with this script).
- Set Sunshine's logging level to Debug.
- Users must have read permissions to `%WINDIR%/Temp/Sunshine.log` (do not change other permissions, just ensure Users have at least read permissions).
- Sunshine is at least 0.20 or higher.

## Setup
You can use the FullScreen view of PlayNite and also add the applications individually. These are not mutally exclusive, and it is suggested to do both. You can prioritize adding your favorite games to Sunshine directly, and use the fullscreen option as a fallback for the less popular games.


### If you prefer to add applications individually to Moonlight:

1. Open the PlayNite program on your computer.
2. Visit the [Playnite Add-ons page](https://playnite.link/addons.html) and download the "Sunshine App Export" extension, when prompted by the browser to open it in PlayNite, click Open.
3. After it is installed, you will be prompted to reboot PlayNite, please do so to proceed to the next steps.
4. In PlayNite, select the games you want to expoty to Sunshine.
5. Click the "Controller" menu button in the top left corner of the PlayNite window, then go to "Extensions" -> "Sunshine App Export" -> "Export selected games".
6. If you've changed the install path of Sunshine, click the browse button to select the correct path, otherwise just click "Export Games" to finalize the export. You will be prompted for administrator rights, confirm the prompt and approve the UAC prompt (it will show up as Windows Powershell is requesting changes to your computer.)
7. Double-click on the "Installer.bat" file. Click OK on the administrator prompt dialog. A window will open, showing the list of games you selected in step 5.
8. If you see an error message about the program being unable to retrieve configuration, follow the instructions in the error message to fix the issue.
9. Check the box next to each game you want to install the PlayNite Watcher Script on. Alternatively, click the Check All button to select all PlayNite games added to Sunshine.
    - If you want to include the FullScreen app for PlayNite for a big picture mode experience, you can optionally choose to enable it here as well.
10. Click the "Install" button when you're ready.

### To add a "Big Picture Mode" or utilize the Full Screen view of PlayNite:

1. Double-click on the "Installer.bat" file. Click OK on the administrator prompt dialog. A UI interface will open showing your PlayNite games that you have exported (if applicable).
2. If you see an error message about the program being unable to retrieve configuration, follow the instructions in the error message to fix the issue.
3. Enable the "PlayNite FullScreen App" under the "PlayNite Games" section.
4. Click the "Install" button when you're ready.



## Troubleshooting

If you encounter any issues while using the PlayNite Watcher script, try these steps to resolve them:

1. Make sure you've followed all the setup steps correctly.
2. Verify you have the proper prerequisites installed and configured.
3. Ensure you have read permissions for `%WINDIR%/Temp/Sunshine.log`.
4. Verify Sunshine is at 0.20 or higher.

If you still experience issues after following these troubleshooting steps, please consider posting your issue on either the Sunshine or Moonlight discord. The author of this script is DemonCat.