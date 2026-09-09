bash -xeu %RECIPE_DIR%\replace-strawberry-perl-paths.sh
if %ERRORLEVEL% NEQ 0 exit 1

robocopy %SRC_DIR%\perl\ %LIBRARY_PREFIX%\ *.* /E
if %ERRORLEVEL% GEQ 8 exit 1

REM There's a bat file in here that says it is better than exe.
REM Let's trust the strawberry perl folks.
del %LIBRARY_BIN%\perlglob.exe

copy %SRC_DIR%\licenses\perl %LIBRARY_PREFIX%\perl_licenses
