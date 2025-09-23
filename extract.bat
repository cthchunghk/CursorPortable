@echo off
if [%1]==[] goto usage
echo Extracting files from installer...
.\App\utils\innounp\innounp.exe -q -x -dtemp %1 {code_GetDestDir}\* >nul 2>&1
rem move /y ".\App\{code_GetDestDir}" ".\App\cursor"
xcopy /S /Y /I ".\temp\{code_GetDestDir}" ".\App\cursor" >nul 2>&1
echo Cleanup...
rd /S /Q ".\temp"
goto end


:usage
echo Please specify the Setup file need to extract.
echo %~nx0 [Cursor_UserSetup_path]
goto end

:end
rem pause
