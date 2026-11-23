@echo on

:: Upstream only provides an autoconf/Makefile build, so compile the sources
:: directly with MSVC, mirroring the targets in gridutils/makefile.in.
:: Only the static gu.lib is built: the public headers declare data symbols
:: (gu_verbose, gu_version, gu_quit, nodetype2str) without __declspec(dllimport),
:: so they can not be used from a DLL.
:: The default static CRT (/MT) is kept to match nn.lib, which gridbathy links.
cd gridutils
if errorlevel 1 exit /b 1

:: rattler-build does not pre-create the Library install directories
for %%d in ("%LIBRARY_LIB%" "%LIBRARY_INC%" "%LIBRARY_BIN%") do (
    if not exist "%%~d" mkdir "%%~d"
    if errorlevel 1 exit /b 1
)

:: MSVC has no strcasecmp and only defines M_PI with _USE_MATH_DEFINES.
:: kdtree.c includes malloc.h (for alloca) only if WIN32 is defined, but cl
:: only defines _WIN32.
set CFLAGS_WIN=/nologo /O2 /I. /I"%LIBRARY_INC%" /DWIN32 /D_USE_MATH_DEFINES /Dstrcasecmp=_stricmp /D_CRT_SECURE_NO_WARNINGS /D_CRT_NONSTDC_NO_WARNINGS

cl %CFLAGS_WIN% /c gridmap.c gridnodes.c gucommon.c kdtree.c poly.c
if errorlevel 1 exit /b 1
lib /nologo /out:gu.lib gridmap.obj gridnodes.obj gucommon.obj kdtree.obj poly.obj
if errorlevel 1 exit /b 1

for %%p in (getbound getnodes insertgrid setbathy subgrid xy2ij) do (
    cl %CFLAGS_WIN% %%p.c gu.lib /Fe:"%LIBRARY_BIN%\%%p.exe"
    if errorlevel 1 exit /b 1
)
:: Link csa_static.lib, not the csa.dll import library: gridbathy reads
:: csa_version, which csa.h declares without __declspec(dllimport), so it can
:: not be resolved from the DLL (LNK2019). csa_static.lib also uses /MT.
cl %CFLAGS_WIN% gridaverager.c gridbathy.c gu.lib "%LIBRARY_LIB%\nn.lib" "%LIBRARY_LIB%\csa_static.lib" /Fe:"%LIBRARY_BIN%\gridbathy.exe"
if errorlevel 1 exit /b 1

copy gu.lib "%LIBRARY_LIB%\"
if errorlevel 1 exit /b 1
for %%h in (gridmap.h gucommon.h gridnodes.h guquit.h) do (
    copy %%h "%LIBRARY_INC%\"
    if errorlevel 1 exit /b 1
)
