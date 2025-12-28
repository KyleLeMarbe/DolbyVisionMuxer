#User Configurable paths
$VideoToolsDirectory = "c:\Video Tools"
$InputDirectory = "" #Directory containing video files to process
$FinalOutputDirectory = "" #Blank for same folder as original file
$Time = 0 #Sample time in seconds, zero for full movie
$FilePattern = "*.*" #File pattern to match (e.g., "*.mkv", "*.mp4", or "*.*" for all video files)
#End Config area

# Prompt for input directory if not set
if ($InputDirectory -eq ""){
    $InputDirectory = Read-Host -Prompt 'Input directory containing video files to process'
}

# Remove quotes if present
$InputDirectory = $InputDirectory -replace """", ""

# Validate input directory
if (-not (Test-Path -Path $InputDirectory -PathType Container)) {
    Write-Host "Error: Input directory does not exist: $InputDirectory"
    exit 1
}

# Get all video files matching the pattern in the input directory
$VideoFiles = Get-ChildItem -Path $InputDirectory -Filter $FilePattern | Where-Object { 
    $_.Extension -match '\.(mkv|mp4|avi|mov|m4v)$' 
}

if ($VideoFiles.Count -eq 0) {
    Write-Host "No video files found in directory: $InputDirectory"
    exit 0
}

Write-Host "Found $($VideoFiles.Count) video file(s) to process"
Write-Host ""

# Process time parameter
if ($Time -gt 0){
    $TimeArg = '-t ' + $Time
}
else {
    $TimeArg = ''
}

function RunProcess($file, $processArgs){
    $p = Start-Process $file $processArgs -PassThru -Wait
}

$totalStopwatch = [system.diagnostics.stopwatch]::StartNew()
$fileCount = 0
$successCount = 0
$failCount = 0

# Process each file
foreach ($VideoFile in $VideoFiles) {
    $fileCount++
    $FilePath = $VideoFile.FullName
    $DirectoryName = $VideoFile.DirectoryName
    $FileNameWithoutExt = $VideoFile.BaseName
    $FileExtension = $VideoFile.Extension.TrimStart('.')
    
    Write-Host "========================================="
    Write-Host "Processing file $fileCount of $($VideoFiles.Count): $($VideoFile.Name)"
    Write-Host "========================================="
    
    # Set output directory
    if ($FinalOutputDirectory -eq ""){
        $OutputDirectory = $DirectoryName
    } else {
        $OutputDirectory = $FinalOutputDirectory
    }
    
    # Skip if output file already exists
    $OutputPath = "$OutputDirectory\$FileNameWithoutExt.$FileExtension"
    if (Test-Path $OutputPath) {
        Write-Host "Output file already exists, skipping: $OutputPath"
        Write-Host ""
        continue
    }
    
    $fileStopwatch = [system.diagnostics.stopwatch]::StartNew()
    
    try {
        Write-Host 'Converting audio stream and muxing video...'
        
        RunProcess "$VideoToolsDirectory\ffmpeg.exe" " -i ""$FilePath"" $TimeArg -map 0 -vcodec copy -scodec copy -acodec ac3 -b:a 640k ""$OutputPath"" -y"
        
        $fileStopwatch.Stop()
        Write-Host "Successfully processed: $($VideoFile.Name) in $($fileStopwatch.Elapsed)"
        Write-Host ""
        $successCount++
        
    } catch {
        $fileStopwatch.Stop()
        Write-Host "Error processing file: $($VideoFile.Name)"
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
