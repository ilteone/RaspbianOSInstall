Script bash for download Raspbian OS and flash it into SD. (For lazy people like me)

This script run just on linux systems.

This script:
- Let you choose wich version of Raspbian OS you want install.
- It download automatically the selected image from the official site into a fixed folder (/home/<user>/Downloads). If the folder doesn't exist, will be created automatically.
- It ask if you want set some parameters, like enabling SSH or the WiFi connection
- It extract the img file in a temp folder
- It copy the img to selected SD
- At the end of all operation the script delete all the file and folder that it create during the operation except the downloaded zip.
- Every time that is run the script, it check if the zip file already exist in the indicated folder and ask if you want use this or download a new again.
# Operation
- Download or clone the project
- Open the folder with the script
- Open terminal in the same folder and make script esecutable whit:
```
chmod +x raspbianinst.sh
```
- Run the script whit:
```
./raspbianinst.sh
```
Following the instruction.
Remember to plug USB drive or SD card before start.

# Important
This script is just an automation of the operations I make usually for install Raspbian OS. My job hasn't any relation with Raspberry PI Foundation.
Be carefull, choose the right disk, EVERYTHING ON THE DISK WILL BE ERASED.