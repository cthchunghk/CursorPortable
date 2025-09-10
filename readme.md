## Cursor Portable
This is a structure to run [Cursor](https://cursor.com/) in [PortableApps format](https://portableapps.com/development/portableapps.com_format).      
Just for self use, Maybe there are many bugs.
---
### 1. Usage
1. Download this structure
2. Download the latest [Cursor build](https://cursor.com/downloads). I only tested User Setup.
3. Use extract_files.bat to extract the main files to App\cursor
4. Run CursorPortable.exe. Enjoy!

---
### 2. Detail
Actually the trick is done by adding flags:
* "--extensions-dir=" 
* "--user-data-dir="          

It is simple if you run your cursor by adding those flags to save the configuration into different directory.
```cmd
Cursor.exe --extensions-dir="%~dp0Data\extensions" --user-data-dir="%~dp0Data\user-data"
```
---
### 3. Migration
To move your existing setting to this portable structure, you should put the following folders to Data\:
* %USERPROFILE%\\.cursor -> Data\extensions
* %APPDATA%\Cursor -> Data\user-data

I am not sure if the _%LOCALAPPDATA%\Programs\cursor_ is still using as my installation cannot find it.