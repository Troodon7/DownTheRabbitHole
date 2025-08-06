# Entra ID Free sucks but this will help

Okay so basically, I recently went through a little bit of a headache trying to get one of my customers on Entra ID because they were unable to get proper licensing, however, they had business Standard which comes with Entra ID for free. 
Slight rant, its cool and all, you can add devices to the cloud domain like you would expect... however it doesn't work like you'd expect with on prem... heres the issue, when you go to login for the first time as a user from that 
domain, it will ask you to create a pin... for EACH machine that SAME USER logs into, thats because you should buy the right license. However, fuck that. So heres what you need to know, a "how to" if you will:

1. Dump the No-Pin-Workaround-EntraID.ps1 ... somewhere idc
2. Step 2, you can do "1" of 2 things, either open a powershell prompt as admin and run 1... (see what I did there?) or modify the no-required-pin.bat to match where you put it then just right click, run as admin and it will do the same thing with the proper execution stuff. That was helpful because I had a few PC's to do.
3. Anyway step three is a sanity check, and can also be step one if you really wanna see the before and after, you just need to run the test-if-it-has-it.bat 1 = 1 and error message = 0 .... you want a 1.
4. Totally optional but something I learned along the way, you only get local admin rights if you were the one that added it to the cloud domain, so I was using one of the admin accounts from the portal to add all the PC's to the new domain, however this customer of mine needs some of their users to have local admin rights, that last script will fix that. Obviously you need to run it as admin, kinda goes without saying when adding users to local admin... anyway just login as them then run the add-current-user-to-local-admins.ps1 with the same arguments as the bat script that had it, unless you wanna permanently allow powershell scripts, if you do, go look that up. 
