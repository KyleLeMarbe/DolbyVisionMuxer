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

# Notes
* I recommend using the time setting to test and using around 300 seconds to start.  This will allow you to view a sample and make sure things work on your TV.
* These scripts assume 1 video track and all audio tracks are included in the final mux
* Re-Encoding video in the dolby vision 5 script still needs work (This will likely be decomissioned.  DV 7 from disks convert well to DV8 but not to DV 5.)
* This script will automatically exclude HDR10+.  HDR10+ and Dolby Vision together can cause incompatibilities with certain TVs.

# Powershell Errors
* If you recieve a policy error when trying to run the powershell script, run this command:
* Set-ExecutionPolicy Unrestricted
