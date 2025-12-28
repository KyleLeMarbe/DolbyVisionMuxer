#User Configurable paths
$VideoToolsDirectory = "c:\Video Tools"
$InputDirectory = "" #Directory containing .mkv files to process
$FinalOutputDirectory = "" #Blank for same folder as original file
$Time = 0 #Sample time in seconds, zero for full movie
$AudioOffset = 0 #Audio offset in MS (0ms seems normal for DV rips)
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
        $combinedArgs = $AudioOffsetArg + " -i ""$FilePath"" $TimeArg -map 0:0 -c copy ""$DirectoryName\BL_EL_RPU.hevc"" -y"
        RunProcess -file "$VideoToolsDirectory\ffmpeg.exe" -processArgs $combinedArgs
        
        Write-Host 'DEMUX & convert to mel...'
        RunProcess "$VideoToolsDirectory\dovi_tool.exe" " --drop-hdr10plus -m 2 convert --discard  ""$DirectoryName\BL_EL_RPU.hevc"" -o ""$DirectoryName\BL_RPU.hevc"""
        
        Write-Host 'Creating MP4 Video...'
        RunProcess "$VideoToolsDirectory\mp4muxer.exe" " -i ""$DirectoryName\BL_RPU.hevc"" --media-lang eng --dv-profile 8 --dv-bl-compatible-id 1 -o ""$DirectoryName\video.mp4""  --overwrite"
        
        Write-Host 'Doing Final Mux...'
        RunProcess "$VideoToolsDirectory\ffmpeg.exe" " -i ""$DirectoryName\video.mp4"" -i ""$FilePath"" $TimeArg  -map 0:v -map 1:a  -c:v copy -c:a copy   -strict experimental  ""$OutputDirectory\$FileNameWithoutExt.mp4"" -y"
        
        # Cleanup intermediate files
        Write-Host 'Cleaning up intermediate files...'
        if (Test-Path "$DirectoryName\BL_EL_RPU.hevc") { Remove-Item "$DirectoryName\BL_EL_RPU.hevc" -Force }
        if (Test-Path "$DirectoryName\BL_RPU.hevc") { Remove-Item "$DirectoryName\BL_RPU.hevc" -Force }
        if (Test-Path "$DirectoryName\video.mp4") { Remove-Item "$DirectoryName\video.mp4" -Force }
        
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
