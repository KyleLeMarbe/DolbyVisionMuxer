#User Configurable paths
$VideoToolsDirectory = "c:\Video Tools"
$InputDirectory = "" #Directory containing .mkv files to process
$FinalOutputDirectory = "" #Blank for same folder as original file
$Time = 0 #Sample time in seconds, zero for full movie
$ConvertAudio = $false #Set to $true to convert audio to AC3
$ConvertVideo = $false #Set to $true to re-encode video (This could take a long time)
$AudioOffset = 1100 #Audio offset in MS (1100ms seems normal for DV rips)
#End Config area

# Prompt for input directory if not set
if ($InputDirectory -eq ""){
    $InputDirectory = Read-Host -Prompt 'Input directory containing .mkv files to process'
}

# Remove quotes if present
$InputDirectory = $InputDirectory -replace """", ""

# Validate input directory
if (-not (Test-Path -Path $InputDirectory -PathType Container)) {
    Write-Host "Error: Input directory does not exist: $InputDirectory"
    exit 1
}

# Get all .mkv files in the input directory
$MkvFiles = Get-ChildItem -Path $InputDirectory -Filter "*.mkv"

if ($MkvFiles.Count -eq 0) {
    Write-Host "No .mkv files found in directory: $InputDirectory"
    exit 0
}

Write-Host "Found $($MkvFiles.Count) .mkv file(s) to process"
Write-Host "Convert Audio: $ConvertAudio"
Write-Host "Convert Video: $ConvertVideo"
Write-Host ""

# Process time parameter
if ($Time -gt 0){
    $TimeArg = '-t ' + $Time
}
else {
    $TimeArg = ''
}

# Process audio offset parameter
if ($AudioOffset -gt 0) {
    $AudioOffsetArg = '-itsoffset ' + $AudioOffset + 'ms'
}
else {
    $AudioOffsetArg = ''
}

function RunProcess($file, $processArgs){
    $p = Start-Process $file $processArgs -PassThru -Wait
}

$totalStopwatch = [system.diagnostics.stopwatch]::StartNew()
$fileCount = 0
$successCount = 0
$failCount = 0

# Process each file
foreach ($MkvFile in $MkvFiles) {
    $fileCount++
    $FilePath = $MkvFile.FullName
    $DirectoryName = $MkvFile.DirectoryName
    $FileNameWithoutExt = $MkvFile.BaseName
    
    Write-Host "========================================="
    Write-Host "Processing file $fileCount of $($MkvFiles.Count): $($MkvFile.Name)"
    Write-Host "========================================="
    
    # Set output directory
    if ($FinalOutputDirectory -eq ""){
        $OutputDirectory = $DirectoryName
    } else {
        $OutputDirectory = $FinalOutputDirectory
    }
    
    $fileStopwatch = [system.diagnostics.stopwatch]::StartNew()
    
    try {
        Write-Host "Converting dolby vision file..." 
        
        Write-Host 'Extracting hevc stream...'
        $combinedArgs = $AudioOffsetArg + " -i ""$FilePath"" -ss 0  $TimeArg -map 0:0 -c copy ""$DirectoryName\BL_EL_RPU.hevc"" -y"
        RunProcess -file "$VideoToolsDirectory\ffmpeg.exe" -processArgs $combinedArgs
        
        Write-Host 'Extracting audio stream...'
        if ($ConvertAudio){ 
            RunProcess "$VideoToolsDirectory\ffmpeg.exe" " -i ""$FilePath"" $TimeArg -acodec ac3 -b:a 640k ""$DirectoryName\audio.ac3"" -y"
        }
        else {
            RunProcess "$VideoToolsDirectory\ffmpeg.exe" " -i ""$FilePath"" $TimeArg -acodec copy ""$DirectoryName\audio.ac3"" -y"
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
        RunProcess "$VideoToolsDirectory\mp4muxer.exe" " -i ""$DirectoryName\BL_EL_RPU2.hevc"" -i ""$DirectoryName\audio.ac3"" --media-lang eng --dv-profile 5 -o ""$OutputDirectory\$FileNameWithoutExt.mp4""  --overwrite"
        
        # Cleanup intermediate files
        Write-Host 'Cleaning up intermediate files...'
        if (Test-Path "$DirectoryName\BL_EL_RPU.hevc") { Remove-Item "$DirectoryName\BL_EL_RPU.hevc" -Force }
        if (Test-Path "$DirectoryName\audio.ac3") { Remove-Item "$DirectoryName\audio.ac3" -Force }
        if (Test-Path "$DirectoryName\BL.hevc") { Remove-Item "$DirectoryName\BL.hevc" -Force }
        if (Test-Path "$DirectoryName\BL2.hevc") { Remove-Item "$DirectoryName\BL2.hevc" -Force }
        if (Test-Path "$DirectoryName\EL_RPU.hevc") { Remove-Item "$DirectoryName\EL_RPU.hevc" -Force }
        if (Test-Path "$DirectoryName\BL_EL_RPU2.hevc") { Remove-Item "$DirectoryName\BL_EL_RPU2.hevc" -Force }
        if (Test-Path "$DirectoryName\metadata.json") { Remove-Item "$DirectoryName\metadata.json" -Force }
        
        $fileStopwatch.Stop()
        Write-Host "Successfully processed: $($MkvFile.Name) in $($fileStopwatch.Elapsed)"
        Write-Host ""
        $successCount++
        
    } catch {
        $fileStopwatch.Stop()
        Write-Host "Error processing file: $($MkvFile.Name)"
        Write-Host "Error: $_"
        Write-Host ""
        $failCount++
    }
}

$totalStopwatch.Stop()

Write-Host "========================================="
Write-Host "Batch Processing Complete"
Write-Host "========================================="
Write-Host "Total files processed: $fileCount"
Write-Host "Successful: $successCount"
Write-Host "Failed: $failCount"
Write-Host "Total time: $($totalStopwatch.Elapsed)"
Write-Host ""
