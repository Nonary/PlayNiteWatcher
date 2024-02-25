# PlayNite Watcher Script Guide

Welcome to the PlayNite Watcher script for Sunshine and Moonlight! This powerful script enables the automated addition of multiple games to Sunshine and ensures that Moonlight shuts down when you exit those games. It emulates the behavior of GeForce Experience, providing you with game names, box art, and additional details right within Moonlight once installed.

This script is also perfect for users who prefer the "Big Picture Mode" or FullScreen mode in PlayNite. It conveniently closes games launched in FullScreen mode upon exit, maintaining the same streamlined experience.

## Why the script is necessary

Many games launch through unique launchers that initiate separate processes. As a result, these games are often added as "detached" commands, which Sunshine and Moonlight can't monitor to close the stream automatically. This script is designed to overcome that hurdle, enabling virtually any game to launch without sacrificing auto-close functionality.

Furthermore, the script is a great asset for those seeking to streamline their big picture mode experience.

In short, this script enhances PlayNite by running games as "commands," thus allowing Sunshine to recognize when a game is closed.

## Caveats:

 - If using Windows 11, you'll need to set the default terminal to Windows Console Host as there is currently a bug in Windows Terminal that prevents hidden consoles from working properly.
    * That can be changed at Settings > System > For Developers > Terminal [Let Windows decide] >> (change to) >> Terminal [Windows Console Host]
    * On older versions of Windows 11 it can be found at: Settings > Privacy & security > Security > For developers > Terminal [Let Windows decide] >> (change to) >> Terminal [Windows Console Host]
 - The script will stop working if you move the folder, simply reinstall it to resolve that issue.
 - Due to Windows API restrictions, this script does not work on cold reboots (hard crashes or shutdowns of your computer).
    * If you're cold booting, simply sign into the computer using the "Desktop" app on Moonlight, then end the stream, then start it again. 
    * Normal reboots issued from start menu will function as intended, no workarounds needed.

## Prerequisites

Before you begin, ensure:

- Your host computer is Windows-based.
- Sunshine is installed, version 0.20 or higher.

## Setup Instructions

Note: The script automatically adds Playnite's fullscreen mode to Sunshine, allowing you to skip manually adding every game—focus on your favorites.

1. Open the PlayNite application on your computer.
2. Navigate to the [Playnite Add-ons page](https://playnite.link/addons.html) and download the "Sunshine App Export" extension. When prompted, open it in PlayNite.
3. Restart PlayNite as instructed to move to the next steps.
4. Select the games you want to export to Sunshine within PlayNite.
5. Go to "Controller" in the top-left corner, then "Extensions" -> "Sunshine App Export" -> "Export selected games."
6. If Sunshine's installation path has changed, click "Browse" to find it; if not, click "Export Games." Confirm the admin rights UAC prompt that appears.
7. Run "Installer.bat" by double-clicking it, and accept the admin prompt. A list of your selected games will be displayed.
8. Follow any provided instructions if a configuration error occurs.
9. Click "Install" to finalize the setup

The script will automatically remove any duplicate applications during an export and will also remove all exports when uninstalling the script.

You will need to export and install the script again each time you wish to add more games to Sunshine. 

To remove applications, visit the Sunshine Web UI application tab and remove them there, or uninstall the script to automatically remove all exports.

## Troubleshooting

If you encounter issues with the PlayNite Watcher script, take the following steps:

1. Revisit the setup instructions to verify correct completion.
2. Check that all prerequisites are in place and configured correctly.
3. Ensure Sunshine is updated to at least version 0.20.

If problems persist, seek further support on the Sunshine or Moonlight Discord channels. The script's creator is DemonCat.