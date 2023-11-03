# PlayNite Watcher Script Guide

Welcome to the PlayNite Watcher script for Sunshine and Moonlight! This powerful script enables the automated addition of multiple games to Sunshine and ensures that Moonlight shuts down when you exit those games. It emulates the behavior of GeForce Experience, providing you with game names, box art, and additional details right within Moonlight once installed.

This script is also perfect for users who prefer the "Big Picture Mode" or FullScreen mode in PlayNite. It conveniently closes games launched in FullScreen mode upon exit, maintaining the same streamlined experience.

## Why the script is necessary

Many games launch through unique launchers that initiate separate processes. As a result, these games are often added as "detached" commands, which Sunshine and Moonlight can't monitor to close the stream automatically. This script is designed to overcome that hurdle, enabling virtually any game to launch without sacrificing auto-close functionality.

Furthermore, the script is a great asset for those seeking to streamline their big picture mode experience.

In short, this script enhances PlayNite by running games as "commands," thus allowing Sunshine to recognize when a game is closed.

## Caveats:

- The script only works with Sunshine version 0.20.x or newer.
- On Windows 11, due to a bug in Windows Terminal, set the default terminal to Windows Console Host via Settings > Privacy & security > For developers > Terminal. Switch from [Let Windows decide] to [Windows Console Host].
- If the installation folder is moved, the script will stop working. Reinstall the script to resolve this.
- Due to security restrictions in Windows, this script does not function on cold reboots and you must sign in again to resolve. If you encounter a cold boot, sign in using the "Desktop" app on Moonlight, end the stream, and then restart it. This step is generally not required for normal reboots.

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
9. Mark the checkboxes next to each game to which you want to apply the script, or select "Check All" for all games.
10. Click "Install" to finalize the setup.

## Troubleshooting

If you encounter issues with the PlayNite Watcher script, take the following steps:

1. Revisit the setup instructions to verify correct completion.
2. Check that all prerequisites are in place and configured correctly.
3. Ensure Sunshine is updated to at least version 0.20.

If problems persist, seek further support on the Sunshine or Moonlight Discord channels. The script's creator is DemonCat.