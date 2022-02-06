#User Configurable paths
$VideoToolsDirectory = "c:\Video Tools"
$FinalOutputDirectory = "" #Blank for same folder as original file
#End Config area


$FilePath = Read-Host -Prompt 'Input your full mkv file path'
$Time = Read-Host -Prompt 'Enter sample time, zero for full movie'
$ConvertAudio = Read-Host -Prompt 'Would you like to convert audio to AC3? (Y/N)'
$ConvertVideo = Read-Host -Prompt 'Would you like to re-encode video (This could take a long time)? (Y/N)'
$AudioOffset = Read-Host -Prompt 'Audio offset (MS, 1100ms seems normal for DV rips)'

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
$combinedArgs = $AudioOffset + " -i ""$FilePath"" -ss 0  $Time -map 0:0 -c copy ""$DirectoryName\BL_EL_RPU.hevc"" -y"
RunProcess -file "$VideoToolsDirectory\ffmpeg.exe" -processArgs $combinedArgs



Write-Host 'Extracting audio stream...'
if ($ConvertAudio){ 
    RunProcess "$VideoToolsDirectory\ffmpeg.exe" " -i ""$FilePath"" $Time -acodec ac3 -b:a 640k ""$DirectoryName\audio.ac3"" -y"
}
else {
    RunProcess "$VideoToolsDirectory\ffmpeg.exe" " -i ""$FilePath"" -map 0:2 $Time -acodec copy ""$DirectoryName\audio.ac3"" -y"
}



Write-Host 'DEMUX & convert to mel...'
RunProcess "$VideoToolsDirectory\python-3.7.6.amd64\python.exe" """$VideoToolsDirectory\src\app.py"" -demux -fel_to_mel -if ""$DirectoryName\BL_EL_RPU.hevc"" -bl_out ""$DirectoryName\BL.hevc"" -el_out ""$DirectoryName\EL_RPU.hevc"""

if (Test-Path -Path "$DirectoryName\BL2.hevc") {
    Remove-Item "$DirectoryName\BL2.hevc"
}

if ($ConvertVideo){
    Write-Host 'Extracting HDR10+ Metadata...'
    RunProcess "$VideoToolsDirectory\hdr10plus_tool.exe" " extract ""$DirectoryName\BL.hevc"" -o ""$DirectoryName\metadata.json"""
    
    Write-Host 'Re-Encoding video file (this will take forever)...'
    RunProcess "$VideoToolsDirectory\ffmpeg.exe" " -i ""$DirectoryName\BL.hevc"" -c:v libx265 -pix_fmt yuv420p10le -x265-params ""level5.1:high-tier=1:uhd-bd=1:colorprim=bt2020:transfer=smpte2084:colormatrix=bt2020nc:master-display=G(13250,34500)B(7500,3000)R(34000,16000)WP(15635,16450)L(40000000,50):max-cll=1000,755:hdr10=1:dhdr10-info='$DirectoryName\metadata.json'"" -crf 21 -preset fast ""$DirectoryName\BL2.hevc"""


}
else {
    
    Write-Host 'Renaming BL.hevc to BL2.hevc...'
    Rename-Item -Path "$DirectoryName\BL.hevc" -NewName "BL2.hevc"

}

Write-Host 'Mux.bat to create BL_EL_RPU.hevc...'
RunProcess "$VideoToolsDirectory\python-3.7.6.amd64\python.exe" " ""$VideoToolsDirectory\src\app.py"" -mux -skip_hdr10plus -bl ""$DirectoryName\BL2.hevc"" -el ""$DirectoryName\EL_RPU.hevc"" -of ""$DirectoryName\BL_EL_RPU2.hevc"""


Write-Host 'Creating MP4...'
RunProcess "$VideoToolsDirectory\mp4muxer.exe" " -i ""$DirectoryName\BL_EL_RPU2.hevc"" -i ""$DirectoryName\audio.ac3"" --media-lang eng --dv-profile 5 -o ""$FinalOutputDirectory\$FileName.mp4""  --overwrite"


Write-Host $stopwatch.Elapsed

