# ==============================================
# Veriable Setup
# ==============================================
$TARGET_DIR=$args[0]
$RAW_CONTENT_URL=$args[1]
$SAVE_PATH=Join-Path $TARGET_DIR "tmp"
$CURSOR_EXE_NAME="Cursor.exe"
$DestDirCode = "{code_GetDestDir}" 
$AppCursorDir = Join-Path $TARGET_DIR "App\cursor"
$UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

$pattern = 'win32-arm64-system</a><br><a href=\"(https://.*?win32/x64/user-setup/CursorUserSetup-x64-.*?.exe)\"';


$ErrorActionPreference = 'Stop';

# =============
# Check the readme file for the latest version
# =============

Write-Host "1. Getting latest 'user-setup' link in the provided URL..."

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

Write-Host ('Found the latest URL: ' + $pureUrl);
Write-Host ('Latest Filename: ' + $filename); 


# ====================
# Check if the latest
# ====================

$EscapedPath = $TARGET_DIR.Replace('\', '\\')
$ExeVersionRaw = (wmic datafile where "name='$EscapedPath\\App\\cursor\\cursor.exe'" get Version /value) | Select-String -Pattern "Version=" | ForEach-Object { $_ -replace "Version=","" } | Select-Object -Last 1 | ForEach-Object { $_.Trim() }

$ExeVersionTrimmed = ($ExeVersionRaw -split '\.')[0..2] -join '.'


$Match = [regex]::Match($filename, '(?<Version>\d+\.\d+\.\d+)')
$FileVersion = $Match.Groups['Version'].Value


Write-Host "Your Version: $ExeVersionTrimmed"
Write-Host "Latest version: $FileVersion"

If ($ExeVersionTrimmed -eq $FileVersion) {
    Write-Host "You have installed the latest version ($FileVersion)" -ForegroundColor Green
    exit 0
}

Write-Host "Latest version found. Process update." -ForegroundColor Yellow

# =================
# Start download latest version and extract it
# =================

New-Item -Path $SAVE_PATH -ItemType Directory -Force *>$null

Write-Host '2. Downloading the latest resources...'; 
Invoke-WebRequest -Uri $pureUrl -OutFile $saveFile -UserAgent $UA; 


Write-Host "Extraction in progress..." -ForegroundColor Cyan

# Use innounp.exe to extract files
& ".\App\utils\innounp\innounp.exe" -q -x -d"$SAVE_PATH" $saveFile "$DestDirCode\*" 1>$null

# 2. XCOPY to copy the files
Write-Host "Moving the extracted files..."
$SourcePath = Join-Path -Path $SAVE_PATH -ChildPath "$DestDirCode\*"
Copy-Item -Path $SourcePath -Destination $AppCursorDir -Recurse -Force 1>$null

# 3. Cleanup
Write-Host "Cleaning up..."
Remove-Item -Path $SAVE_PATH -Recurse -Force 1>$null

Write-Host "🌟 Updated 🌟" -ForegroundColor Green
