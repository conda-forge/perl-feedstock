REM This should be inherited from the conda build env
if not defined %CPU_COUNT% set CPU_COUNT=1

REM 'bin' needs to exist already
mkdir %PREFIX%\bin

REM This assumes a three-part version string, e.g. 5.32.1.
REM It will break things if fewer or more parts are used in the conda recipe
for %%f in (%PKG_VERSION%) do set MAJOR_MINOR=%%~nf

set PERL_LIB=%PREFIX%\lib\perl5
set ARCH_LIB=%PERL_LIB%\%MAJOR_MINOR%

REM specifying PLMAKE below doesn't seem to be sufficient -- gmake still called in places
copy %BUILD_PREFIX%\Library\bin\make.exe ^
 %BUILD_PREFIX%\Library\bin\gmake.exe

if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

cd win32

make -j%CPU_COUNT% ^
 INST_TOP=%PREFIX% ^
 CCHOME=%BUILD_PREFIX%\Library\mingw-w64 ^
 USE_64_BIT_INT=define ^
 PKG_VERS=%MAJOR_MINOR%

if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

make -j%CPU_COUNT% ^
 INST_TOP=%PREFIX% ^
 CCHOME=%BUILD_PREFIX%\Library\mingw-w64 ^
 PKG_VERS=%MAJOR_MINOR% ^
 install

if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

copy %RECIPE_DIR%\win_reloc_inc.pl %PERL_LIB%

if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

REM Same post-build patching as the *nix script
REM (not sure yet if this is needed/wanted on Windows or not)
REM Further: currently disabled because the patch enables interpolation of
REM the configuration string, which can have special characters and does on Windows
REM (apparently not on *nix but maybe this is luck?)
REM pushd %ARCH_LIB%\core_perl
REM patch -p1 -i %RECIPE_DIR%/dynamic_config.patch ^
REM  && sed -i "s|%BUILD_PREFIX:/=\%|\$compilerroot|g" Config_heavy.pl ^
REM  && sed -i "s|%BUILD_PREFIX:/=\%|\$compilerroot|g" Config.pm ^
REM  && sed -i "s|cc => '\(.*\)'|cc => \"\1\"|g" Config.pm ^
REM  && sed -i "s|libpth => '\(.*\)'|libpth => \"\1\"|g" Config.pm
REM if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%
REM popd

REM perl's hard-coded default relative search path is bin/../lib;
REM Copying these libs to this default location will allow us 
REM to use perl during post-link before @INC is patched;
REM then we will remove them during post-link to tidy things up
copy %ARCH_LIB%\core_perl\Config.pm %PREFIX%\lib
copy %ARCH_LIB%\core_perl\Config_heavy.pl %PREFIX%\lib
copy %PERL_LIB%\core_perl\strict.pm %PREFIX%\lib
copy %PERL_LIB%\core_perl\warnings.pm %PREFIX%\lib

if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

REM Currently this needs to be done *after* install because the
REM linker paths are set to the installed locations. Possibly there
REM is a better approach for this.
make ^
 INST_TOP=%PREFIX% ^
 CCHOME=%BUILD_PREFIX%\Library\mingw-w64 ^
 PKG_VERS=%MAJOR_MINOR% ^
 HARNESS_OPTIONS=j%CPU_COUNT% ^
 test

if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

REM See *nix build.sh; make sure these folders are included in the package
REM Nested loops didn't work as expected, so this is a little more verbose
for %%P in (%PERL_LIB% %ARCH_LIB%) do (
    if not exist %%P\site_perl mkdir %%P\site_perl
    type nul >> %%P\site_perl\.conda-build.keep
    if not exist %%P\vendor_perl mkdir %%P\vendor_perl
    type nul >> %%P\vendor_perl\.conda-build.keep
)

REM Again, see *nix build.sh; we'll just do what they do
type nul >> %ARCH_LIB%\core_perl\perllocal.pod
