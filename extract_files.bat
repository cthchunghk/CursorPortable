@echo off
if [%1]==[] goto usage
%1 /VERYSILENT /SUPPRESSMSGBOXES /DIR="%~dp0App\cursor" /TASKS=""
goto end


:usage
echo Please specify the Setup file need to extract.
echo %~nx0 [Cursor_UserSetup_path]
goto end

:end
pause