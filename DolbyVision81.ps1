#User Configurable paths
$VideoToolsDirectory = "c:\Video Tools"
$FinalOutputDirectory = "" #Blank for same folder as original file
#End Config area


$FilePath = Read-Host -Prompt 'Input your full mkv file path'
$Time = Read-Host -Prompt 'Enter sample time, zero for full movie'
#$ConvertAudio = Read-Host -Prompt 'Would you like to convert audio to EAC3? (Y/N)'
#$ConvertVideo = Read-Host -Prompt 'Would you like to re-encode video (This could take a long time)? (Y/N)'
$AudioOffset = Read-Host -Prompt 'Audio offset (MS, 0ms seems normal for DV rips)'

$FilePath = $FilePath -replace """", ""

$DirectoryName = Split-Path -Path $FilePath
$FileName = Split-Path -leaf $FilePath
$a = $FileName.Split(".")
$FileName = $a.GetValue(0)

if ($FinalOutputDirectory -eq ""){
    $FinalOutputDirectory = $DirectoryName
}


if ($ConvertAudio -eq 'y'){
    $ConvertAudio = $true
}
else {
    $ConvertAudio = $false
}

if ($ConvertVideo -eq 'y'){
    $ConvertVideo = $true
}
else {
    $ConvertVideo = $false
}

if ($Time -gt 0){
    $Time = '-t ' + $Time
}
else {
    $Time = ''
}

if ($AudioOffset -gt 0) {
    $AudioOffset = '-itsoffset ' + $AudioOffset + 'ms'
}
else {
    $AudioOffset = ''
}


function RunProcess($file, $processArgs){
    $p = Start-Process $file $processArgs -PassThru -Wait
}

$stopwatch =  [system.diagnostics.stopwatch]::StartNew()

Write-Host "Converting dolby vision file..." 


Write-Host 'Extracting hevc stream...'
$combinedArgs = $AudioOffset + " -i ""$FilePath"" $Time -map 0:0 -c copy ""$DirectoryName\BL_EL_RPU.hevc"" -y"
RunProcess -file "$VideoToolsDirectory\ffmpeg.exe" -processArgs $combinedArgs


Write-Host 'DEMUX & convert to mel...'
RunProcess "$VideoToolsDirectory\dovi_tool.exe" " --drop-hdr10plus -m 2 convert --discard  ""$DirectoryName\BL_EL_RPU.hevc"" -o ""$DirectoryName\BL_RPU.hevc"""


Write-Host 'Creating MP4 Video...'
RunProcess "$VideoToolsDirectory\mp4muxer.exe" " -i ""$DirectoryName\BL_RPU.hevc"" --media-lang eng --dv-profile 8 --dv-bl-compatible-id 1 -o ""$FinalOutputDirectory\video.mp4""  --overwrite"


Write-Host 'Doing Final Mux...'
RunProcess "$VideoToolsDirectory\ffmpeg.exe" " -i ""$DirectoryName\video.mp4"" -i ""$FilePath"" $Time  -map 0:v -map 1:a  -c:v copy -c:a copy   -strict experimental  ""$DirectoryName\$FileName.mp4"" -y"
#RunProcess "$VideoToolsDirectory\ffmpeg.exe" " -i ""$DirectoryName\video.mp4"" -i ""$FilePath"" $Time  -map 0:v -map 1:a -map 1:s? -c:v copy -c:a copy -c:s mov_text -strict experimental  ""$DirectoryName\$FileName DV.mp4"" -y"
#Error trying to convert PGS subtitles to mov_text for mp4


Write-Host $stopwatch.Elapsed

