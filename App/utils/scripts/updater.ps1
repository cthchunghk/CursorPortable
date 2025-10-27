# ==============================================
# Veriable Setup
# ==============================================
$TARGET_DIR=$args[0]
$RAW_CONTENT_URL=$args[1]
$SAVE_PATH=Join-Path $TARGET_DIR "tmp"
$CURSOR_EXE_NAME="Cursor"
$DestDirCode = "{code_GetDestDir}" 
$AppCursorDir = Join-Path $TARGET_DIR "App\cursor\"
$UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

#$pattern = 'win32-arm64-system</a><br><a href=\"(https://.*?win32/x64/user-setup/CursorUserSetup-x64-.*?.exe)\"';


$ErrorActionPreference = 'Stop';
$ProgressPreference = 'SilentlyContinue'

# =============
# Check if the version is provided
# =============
$versionArg = $args[2]
if ([string]::IsNullOrWhiteSpace($versionArg)) {
    $versionPattern = '.*?'; 
    $specifyingVersion = 'false';
} else {
    $versionPattern = [regex]::Escape($versionArg);
    $specifyingVersion = 'true';
}
$pattern = 'win32-arm64-system</a><br><a href=\"(https://.*?win32/x64/user-setup/CursorUserSetup-x64-' + $versionPattern + '.exe)\"';

# =============
# Check the readme file for the latest version
# =============

Write-Host "Getting latest 'user-setup' link in the provided URL..."

$raw = Invoke-WebRequest -Uri $RAW_CONTENT_URL -UseBasicParsing -UserAgent $UA;

$urlMatch = Select-String -InputObject $raw.Content -Pattern $pattern | 
            Select-Object -ExpandProperty Matches | 
            Select-Object -ExpandProperty Groups | 
            Where-Object { $_.Name -eq 1 } | 
            Select-Object -ExpandProperty Value -First 1;

if (-not $urlMatch) { 
    Write-Host 'ERROR! Cannot find the latest link of win32-x64-user! Please check the URL provided! ';
    Write-Host "URL using: "$RAW_CONTENT_URL
    exit 1; 
}

$pureUrl = $urlMatch; 
$filename = Split-Path $pureUrl -Leaf; 
$saveFile = Join-Path $SAVE_PATH $filename;

#Write-Host ('Found the latest URL: ' + $pureUrl);
#Write-Host ('Latest Filename: ' + $filename); 


# ====================
# Check if the latest
# ====================

$EscapedPath = $TARGET_DIR.Replace('\', '\\')
$ExeVersionRaw = (wmic datafile where "name='$EscapedPath\\App\\cursor\\cursor.exe'" get Version /value) | Select-String -Pattern "Version=" | ForEach-Object { $_ -replace "Version=","" } | Select-Object -Last 1 | ForEach-Object { $_.Trim() }

$ExeVersionTrimmed = ($ExeVersionRaw -split '\.')[0..2] -join '.'

if (-not $ExeVersionTrimmed){
    $ExeVersionTrimmed = 0
}


$Match = [regex]::Match($filename, '(?<Version>\d+\.\d+\.\d+)')
$FileVersion = $Match.Groups['Version'].Value

if ($ExeVersionTrimmed -gt 0){
	Write-Host "Your Version: $ExeVersionTrimmed"
}

if ($specifyingVersion -eq 'true'){
    Write-Host "Specifying version: $versionArg"    
} else {
    Write-Host "Latest version: $FileVersion"
}

If ($ExeVersionTrimmed -eq $FileVersion) {
    Write-Host "You have installed the latest version ($ExeVersionTrimmed)" -ForegroundColor Green
    exit 0
}

if ($specifyingVersion -eq 'true' -and $ExeVersionTrimmed -ge $versionArg){
    Write-Host "Your installed verion ($ExeVersionTrimmed) is newer than specified version ($versionArg). Please remove the existing one if you want to downgrade." -ForegroundColor Yellow
    Write-Host "DO NOT REMOVE /Data FOLDER TO PRESERVE THE SETTING!" -ForegroundColor Red
    exit 0
}

if ($specifyingVersion -eq 'true'){
    Write-Host "Specified version ($versionArg) found. Start process." -ForegroundColor Yellow
} else {
    Write-Host "Latest version ($FileVersion) found. Process update." -ForegroundColor Yellow
}

# =================
# Capture meta data for the size!
# =================
$contentLengthBytes = 0;
    try {        
        $headResponse = Invoke-WebRequest -Uri $pureUrl -Method Head -UseBasicParsing -UserAgent '%UA%';
        $contentLengthBytes = [int64]($headResponse.Headers.'Content-Length');        
        $contentLengthMB = [math]::Round($contentLengthBytes / 1MB, 2);
        Write-Host ('Expected file size: ' + $contentLengthMB + ' MB');
    } catch {
        Write-Host 'Cannot capture the file size.';
    }


# =================
# Start download latest version and extract it
# =================

New-Item -Path $SAVE_PATH -ItemType Directory -Force *>$null
$ProgressPreference = 'Continue' # Reset to default after execution

Write-Host 'Downloading the latest resources...'; 
#Invoke-WebRequest -Uri $pureUrl -OutFile $saveFile -UserAgent $UA; 

try {
	Start-BitsTransfer -Source $pureUrl -Destination $saveFile -TransferType Download -DisplayName 'Cursor Installer Download';
} catch {
    Write-Host $_.Exception.Message;
	Write-Host "Fallbacking to Invoke-WebRequest to download...";
	Invoke-WebRequest -Uri $pureUrl -OutFile $saveFile -UserAgent $UA;
}

# ===============
# Process checking
# ===============
$process = Get-Process -Name $CURSOR_EXE_NAME -ErrorAction SilentlyContinue;
if ($process){
	Write-Host "Please close all Cursor window to process update..." -ForegroundColor Red
	Write-Host "Cleaning up..."
	Remove-Item -Path $SAVE_PATH -Recurse -Force 1>$null
	exit 1;
	#taskkill /im $CURSOR_EXE_NAME /f /t 2>&1 | Out-Null;
} 


Write-Host "Extraction in progress..." -ForegroundColor Cyan

# Use innounp.exe to extract files
& ".\App\utils\innounp\innounp.exe" -q -x -d"$SAVE_PATH" $saveFile "$DestDirCode\*" 1>$null

# 2. XCOPY to copy the files
Write-Host "Moving the extracted files..."
$SourcePath = Join-Path -Path $SAVE_PATH -ChildPath "$DestDirCode\"
$RobocopyParameters = @(
    "/E", "/IS", "/IT", 
    "/R:3", "/W:1",
    "/NFL", "/NDL", "/NJH", "/NJS" 
)

$RobocopyResult = & robocopy $SourcePath $AppCursorDir $RobocopyParameters

$ExitCode = $LASTEXITCODE

if ($ExitCode -le 7) {
    Write-Host "✅ Robocopy operation completed (Exit Code: $ExitCode)。"
} else {
    Write-Warning "❌ Robocopy failed (Exit Code: $ExitCode). Please check the path or permissions."
}


# 3. Cleanup
Write-Host "Cleaning up..."
Remove-Item -Path $SAVE_PATH -Recurse -Force 1>$null

Write-Host "🌟 Updated 🌟" -ForegroundColor Green
