# VideoFileResizer
Powershell Script to automate conversion of video files of a specified size or larger to smaller mkv or mp4 files using handbreakcli or ffmpeg.

# Pre Reqs
1. Must have HandBreakCLI or ffmpeg installed.  
  HandbreakCLI: <https://handbrake.fr/downloads2.php>
  ffmpeg: <https://ffmpeg.zeranoe.com/builds/>
2. Must have powershell 5.1 or higher installed.  You can install from here: https://www.microsoft.com/en-us/download/details.aspx?id=54616
3. Must have powershell setup to allow this script.  See [Powershell Setup](https://github.com/Rocketcandy/VideoFileResizer#powershell-setup)
4. Powershell is a requirement to run the script.  I have only tested it on Windows, but if you can get it to work on MacOS or Linux more power to you!
5. Edit the script and change the first section of the script to match your needs

A couple notes about editing the script

1. All paths can be either a network path.  Example: "\\\\my.server\share\files" or a local path.  Example: "C:\Users\Public\Videos"
2. All of the flags can be changed, and you can add new ones just copy the existing format.

Handbreak flags: https://handbrake.fr/docs/en/latest/cli/command-line-reference.html
ffmpeg flags: https://ffmpeg.org/ffmpeg.html#toc-Options
 
# What does the script actually do?

1. By default it will look for all files in defined $MovieDir over 2GB and all files in defined $TvShowdir over 1GB (it will look for all files recursivly inside of the defined $MovieDir or $TvShowdir so just specify the base directory that includes all files you want to convert.)
2. Once it has found them all it will start converting them from largest to smallest
3. It will create a brand new file named: OriginalFileName-New
4. Once the conversion is completed it will delete the OriginalFileName and rename the newly converted file to match the OriginalFileName
5. When a conversion is completed it will add the file name and path to the csv spreadsheet and not try to convert it again.
6. If a conversion fails it does not delete the original file
7. If you do have a failed conversion you might have to delete the OriginalFileName-New file that was created before it failed.
8. You should only have to delete the OriginalFileName-New file if you kill powershell to stop converting.

# Running the script
1. After you have modified the variables and changed the execution policy right click on the script
2. Select Run with Powershell
3. You should see a Powershell window apear and you should see this apear at the top of the window:

    Finding Movie Files over xGB in \\\\Path\To\Movies and Episodes ove xGB in \\\\Path\To\Shows be patient...

4. If you see that message the script is running and conversions should start

# Powershell Setup
Open powershell as the user that will be running the script and then run the following command:

    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser

Select Yes or Yes to all.  This will allow scripts to run as the current user.

for more information on Execution Policy view this page: <https://technet.microsoft.com/library/hh847748.aspx>

# Other Information

1. This takes a LONG time to run it all depends on how fast your computer is and how the original file was encoded
2. On average a 2GB file will take 2-3 hours to complete on an 8 core CPU clocked around 3.9GHz (Might be faster or slower depending on how new the CPU is)
