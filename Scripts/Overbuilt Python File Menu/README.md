# Me and my friend over-built this because we're lazy
So... the purpose of this was for an emulation project we did on the steamdeck, we had to keep manually doing this process and it was annoying. This is for Playstation 3 games. 

No special requirements need to be imported, we wanted it to be easily transferable. All you need to do is copy that .exe somewhere - might as well be the same root directory and run the .py from the command line. The rest is self explanitory in the menus but here is a quick explanation: 

⦁	    Prompts the user to select a PlayStation 3 .iso file and a .dkey decryption key
⦁	    Decrypts the ISO using PS3Dec.exe
⦁	    Mounts the decrypted ISO using PowerShell
⦁	    Copies its contents to a custom output folder using robocopy
⦁	    Optionally deletes the original, key, and decrypted ISO - we added this because there is really no need to have them afterwards unless you plan to share.
⦁	    Keeps running after the first one if you have multiple. 
