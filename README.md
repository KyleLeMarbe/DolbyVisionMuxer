# DolbyVisionMuxer
Scripts and tools for Dolby Vision Muxing

This repo contains powershell files to automate conversion from .mkv (MakeMKV) files to compatible dolby vision .mp4.

To use these scripts:
1) Download yusesope's tools from here: https://mega.nz/file/mdU00TZR#bCiuGx6-7QaM2IeaIjNwdkmRWVA4hLti5rjLOOKESeE
2) Download mp4muxer from here: https://github.com/DolbyLaboratories/dlb_mp4base
3) Download ffmpeg from here: https://www.ffmpeg.org/download.html
4) Download powershell scripts from this repository
5) Place all files in "c:\Video Tools" or directory of your choice
6) Enjoy easy Dolby Vision conversions

# Notes
* I recommend setting your time to something around 300 seconds to start the encode.  This will allow you to view a sample and make sure things work on your TV.
* These scripts assume 1 video track and that the first audio track is the intended audio track to include in the final mux
* Re-Encoding video in the dolby vision 5 script still needs work
* This script will automatically exclude HDR10+.  I've seen incompatibilities with TVs that do not support HDR10+.

# Powershell Errors
* If you recieve a policy error when trying to run the powershell script, run this command:
* Set-ExecutionPolicy Unrestricted
