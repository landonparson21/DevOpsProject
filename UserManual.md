User Migration for hAlberd Technologies

Our user migration software allows for multiple users to be added automatically to a Linux Ubuntu 26.04.1 system 
from the Tennessee Tech Computer Science Faculty Page. 
It also allows for manual user creation through user input.

The software uses curl to get the data from a website, thus make sure you have internet access before running.

Also if you do not have curl installed, open your terminal and run: sudo apt install curl 

To use the software download the userMigration.sh file into a new folder, then right click in the space in the folder
and select open in terminal, then execute the following commands:

chmod +x userMigration.sh  
./userMigration.sh

Note: You may be asked to enter your password


Usage:
Upon the script executing this menu will be displayed:
1. Add Users Automatically (will use curl to fetch users from url and add them to the system)
2. Add User Manually (will take user input to create a user)
3. End Program (ends the script)




