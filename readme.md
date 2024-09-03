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

**Note:** This script automatically adds Playnite's fullscreen mode to Sunshine, so you don't need to manually add every game—just focus on your favorites.

1. **Open PlayNite**: Launch the PlayNite application on your computer.
2. **Download the Extension**: Visit the [Playnite Add-ons page](https://playnite.link/addons.html) and download the "Sunshine App Export" extension. When prompted, open the extension in PlayNite.
3. **Restart PlayNite**: Follow the on-screen instructions to restart PlayNite and proceed to the next steps.
4. **Select Games to Export**: In PlayNite, select the games you want to export to Sunshine.
5. **Export Games**:
   - Click on "Controller" in the top-left corner.
   - Navigate to "Extensions" -> "Sunshine App Export" -> "Export selected games."
6. **Specify Sunshine Path**: If the installation path for Sunshine has changed, click "Browse" to locate it. If the path is correct, click "Export Games." Confirm the User Account Control (UAC) prompt that appears.
7. **Run the Installer**: Double-click "Installer.bat" and accept the UAC prompt to continue. 
8. **Handle Configuration Errors**: If a configuration error occurs, follow any additional instructions provided.
9. **Finalize Setup**: Click "Install" to complete the setup process. This will terminate any existing Moonlight sessions and restart PlayNite.

### Important Notes:
- **Automatic Duplicate Removal**: The script automatically removes duplicate exports when installing, so you don't have to worry about accidentally adding the same game more than once.
- **Re-exporting Games**: You need to re-export and reinstall the script each time you want to add more games to Sunshine.
- **Removing Applications**: To remove exported applications, either:
  - Visit the Sunshine Web UI application tab and remove them manually, or
  - Uninstall the script, which will remove remove **all** exported games.


## Troubleshooting

If you encounter any issues with the PlayNite Watcher script, follow these steps:

1. **Review Setup Instructions**: Double-check the setup instructions to ensure all steps were completed correctly.
2. **Verify Prerequisites**: Confirm that all required prerequisites are installed and properly configured.
3. **Update Sunshine**: Ensure that Sunshine is updated to at least version 0.20.

### Export Issues: Not All Games Are Exported
The export feature only works for games with downloaded metadata. If you have added games manually (e.g., via scanning or manual entry), ensure that you download all necessary metadata for those games. To download metadata in Playnite:

1. Right-click the game in Playnite.
2. Select "Edit."
3. Click the "Download Metadata" button.
4. Choose "IGDB," select the correct game name, and follow the on-screen instructions to import all available data.

**Tip:** You can automate metadata downloads for all games by clicking the Playnite menu button and selecting "Download Metadata" (or press Control + D).

### Session Not Terminating When Closing a Game
If the script doesn’t terminate the session when you close a game, it may be due to the script being saved in a location that requires administrator rights. This script does not run in administrator mode. To resolve this:

- Adjust the folder's file permissions to allow write access for users.
- Alternatively, move the folder to your user profile (e.g., Documents, Desktop) and reinstall the script.

If these steps don’t resolve your issues, seek further support on the Sunshine or Moonlight Discord channels. You can also contact the script creator, demon.cat, for additional help.