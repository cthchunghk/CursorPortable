@echo off
title Setup extractor
if [%1]==[] goto usage
set destDirCode={code_GetDestDir}
set cursorDir=%~dp0App\cursor
set tmpDir=%~dp0tmp
echo Extracting files from installer...
.\App\utils\innounp\innounp.exe -q -x -d%tmpDir% %1 %destDirCode%\* >nul 2>&1
rem move /y ".\App\{code_GetDestDir}" ".\App\cursor"
xcopy /S /Y /I %tmpDir%\%destDirCode%\ %cursorDir% >nul 2>&1
echo Cleanup...
rd /S /Q %tmpDir%
echo Files extracted
goto end


:usage
echo Please specify the Setup file need to extract.
echo %~nx0 [Cursor_UserSetup_path]
goto end

:end
pause
