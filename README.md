# DolbyVisionMuxer
Scripts and tools for Dolby Vision Muxing

This repo contains powershell files to automate conversion from .mkv (MakeMKV) files to compatible dolby vision .mp4.

To use these scripts:
1) Download yusesope's tools from here (Replaced by dovi_tool for DV 8): https://mega.nz/file/mdU00TZR#bCiuGx6-7QaM2IeaIjNwdkmRWVA4hLti5rjLOOKESeE
2) Download mp4muxer from here: https://github.com/DolbyLaboratories/dlb_mp4base
3) Download ffmpeg from here: https://www.ffmpeg.org/download.html
4) Download dovi_tool from here: https://github.com/quietvoid/dovi_tool
5) Download powershell scripts from this repository
6) Place all files in "c:\Video Tools" or directory of your choice
7) Enjoy easy Dolby Vision conversions

## Available Scripts

### Single File Processing (Interactive)
* **DolbyVision5.ps1** - Process a single file with Dolby Vision Profile 5 (interactive prompts)
* **DolbyVision81.ps1** - Process a single file with Dolby Vision Profile 8.1 (interactive prompts)
* **AudioConversion.ps1** - Convert audio in a single file to AC3 (interactive prompts)

### Batch Processing (Automated)
* **DolbyVision5_Batch.ps1** - Process all .mkv files in a directory with Dolby Vision Profile 5
* **DolbyVision81_Batch.ps1** - Process all .mkv files in a directory with Dolby Vision Profile 8.1
* **AudioConversion_Batch.ps1** - Convert audio to AC3 for all video files in a directory

## Using Batch Scripts

The batch scripts allow you to process multiple files automatically without manual prompts for each file.

### Configuration
Edit the batch script file before running to configure these settings:
* **$VideoToolsDirectory** - Path to your video tools (default: "c:\Video Tools")
* **$InputDirectory** - Directory containing files to process (leave blank to be prompted)
* **$FinalOutputDirectory** - Where to save output files (blank = same as input directory)
* **$Time** - Sample time in seconds (0 = process full file)
* **$AudioOffset** - Audio offset in milliseconds (varies by script)
* **$ConvertAudio** - Convert audio to AC3 (DolbyVision5_Batch.ps1 only)
* **$ConvertVideo** - Re-encode video (DolbyVision5_Batch.ps1 only)

### Running Batch Scripts
1. Edit the batch script to set your preferences
2. Run the script: `.\DolbyVision81_Batch.ps1` (or whichever script you want)
3. If you didn't set $InputDirectory, you'll be prompted to enter the folder path
4. The script will process all applicable files in the directory
5. Progress and results will be displayed for each file

### Batch Script Behavior Notes
* **DolbyVision5_Batch.ps1** and **DolbyVision81_Batch.ps1** will create output .mp4 files with the same base name as the input .mkv files
* **AudioConversion_Batch.ps1** will append "_AC3" to the filename when the output directory is the same as the input directory (to avoid overwriting the original file). If you specify a different output directory, it will use the original filename.
* All batch scripts will automatically skip files if the output file already exists
* Intermediate/temporary files are automatically cleaned up after each file is processed

# Notes
* I recommend using the time setting to test and using around 300 seconds to start.  This will allow you to view a sample and make sure things work on your TV.
* These scripts assume 1 video track and all audio tracks are included in the final mux
* Re-Encoding video in the dolby vision 5 script still needs work (This will likely be decomissioned.  DV 7 from disks convert well to DV8 but not to DV 5.)
* This script will automatically exclude HDR10+.  HDR10+ and Dolby Vision together can cause incompatibilities with certain TVs.

# Powershell Errors
* If you recieve a policy error when trying to run the powershell script, run this command:
* Set-ExecutionPolicy Unrestricted
