## PlayNite Watcher Script Installation Instructions

1. Open the PlayNite program on your computer.
2. Go to the [Playnite Add-ons page](https://playnite.link/addons.html) and download the "Sunshine App Export" extension.
3. Find the "apps.json" file used on Sunshine. This is normally located in the config folder where Sunshine is installed, I.E C:\Program Files\Sunshine\config
4. Copy the "apps.json" file to a different location on your computer, such as your desktop. (It needs to be in an area that does not require admin rights)
5. Open PlayNite and select the games that you want to add to Sunshine.
6. Click on the "Controller" menu button in the top left corner of the PlayNite window, then go to "Extensions" -> "Sunshine App Export" -> "Export selected games".
7. Choose the copy of the "apps.json" file that you copied earlier when prompted. 
8. Copy and paste the modified "apps.json" file back to its original location on your computer. You may be prompted for administrator rights during this step.
9. Double-click on the "Installer.bat" file. This will open up a window with a list of the games you selected in Step 5.
10. Check the box next to each game that you want to install the PlayNite Watcher Script on.
11. Click the "Install" button when you're done.

**NOTE** You might be clever and try to simply add user permissions to apps.json as a workaround instead of copying, but please make sure to remove user write permission when done. If you fail to do this, you will allow Sunshine to be exposed to **CRITICAL** security vulnerabilities, such as elevation of privilege. These are the worst kind of security vulnerabilities, since Sunshine runs as SYSTEM level.