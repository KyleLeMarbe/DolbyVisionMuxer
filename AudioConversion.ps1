#User Configurable paths
$VideoToolsDirectory = "c:\Video Tools"
$FinalOutputDirectory = "" #Blank for same folder as original file
#End Config area


Write-Host 'Audio Conversion (AC3):'
$FilePath = Read-Host -Prompt 'Input your full file path'
$Time = Read-Host -Prompt 'Enter sample time, zero for full movie'
#$AudioOffset = Read-Host -Prompt 'Audio offset (MS)'

$FilePath = $FilePath -replace """", ""

$DirectoryName = Split-Path -Path $FilePath
$FileName = Split-Path -leaf $FilePath
$a = $FileName.Split(".")
$FileName = $a.GetValue(0)
$FileExtension = $a.GetValue(1)

if ($FinalOutputDirectory -eq ""){
    $FinalOutputDirectory = $DirectoryName
}


if ($Time -gt 0){
    $Time = '-t ' + $Time
}
else {
    $Time = ''
}

#if ($AudioOffset -gt 0) {
#    $AudioOffset = '-itsoffset ' + $AudioOffset + 'ms'
#}
#else {
#    $AudioOffset = ''
#}


function RunProcess($file, $processArgs){
    $p = Start-Process $file $processArgs -PassThru -Wait
}

$stopwatch =  [system.diagnostics.stopwatch]::StartNew()



Write-Host 'Converting audio stream and muxing video...'

RunProcess "$VideoToolsDirectory\ffmpeg.exe" " -i ""$FilePath"" $Time -map 0 -vcodec copy -scodec copy -acodec ac3 -b:a 640k ""$FinalOutputDirectory\$FileName.$FileExtension"" -y"


Write-Host $stopwatch.Elapsed

