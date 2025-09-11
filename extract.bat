@echo off
if [%1]==[] goto usage
.\App\utils\innounp\innounp.exe -q -x -dApp %1 {code_GetDestDir}\*
RENAME ".\App\{code_GetDestDir}" "cursor"
goto end


:usage
echo Please specify the Setup file need to extract.
echo %~nx0 [Cursor_UserSetup_path]
goto end

:end
rem pause
