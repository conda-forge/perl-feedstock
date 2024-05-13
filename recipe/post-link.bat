for %%f in (%PKG_VERSION%) do set MAJOR_MINOR=%%~nf

set DLLNAME="%PREFIX%\bin\perl%MAJOR_MINOR:.=%.dll"

%PREFIX%\bin\perl.exe ^
 "%PREFIX%\lib\perl5\win_reloc_inc.pl" ^
 %DLLNAME% ^
 "%PREFIX%\bin\perldll.tmp" ^
 && move /Y ^
 "%PREFIX%\bin\perldll.tmp" ^
 %DLLNAME%

REM We only copied these during build so the above command would work;
REM now is the time to clean them up
del %PREFIX%\lib\Config.pm
del %PREFIX%\lib\Config_heavy.pl
del %PREFIX%\lib\strict.pm
del %PREFIX%\lib\warnings.pm
del %PREFIX%\lib\perl5\win_reloc_inc.pl
