:: Blacklight OS build script
:: 2011 Troy Martin
:: Blacklight OS is licensed under the Simplified BSD License (see license.txt)
:: http://www.opensource.org/licenses/bsd-license.php

@echo off

:: Valid values for target:
::    3 = 386
::    4 = 486
::    5 = Pentium
::    6 = Pentium Pro and higher
set target=5

echo Blacklight OS build script

if "%1" == "" goto help

:optionsloop
shift

if "%0" == "/?"			goto help
if "%0" == "--help"		goto help
if "%0" == "-b12"		goto boot12
if "%0" == "--boot12"		goto boot12
if "%0" == "-b16"		goto boot16
if "%0" == "--boot16"		goto boot16
if "%0" == "-k"			goto kernel
if "%0" == "--kernel"		goto kernel
if "%0" == "-p"			goto programs
if "%0" == "--programs"		goto prorams

if "%0" == ""         goto done

echo Unrecognized option '%0', ignoring.
goto optionsloop

:boot12
echo Assembling FAT12 bootloader...
nasm -O0 -fbin Boot/boot12.asm -o Boot/boot12.bin
echo Done!
goto optionsloop

:kernel
echo Building kernel...
cd Kernel
nasm -O0 -fbin main.asm -Dtarget=%target% -o uvlight.krn
cd ..
echo Done!
goto optionsloop

:programs
echo Building programs...
cd Programs
for %%i in (*.asm) do nasm -O0 -fbin "%%i"
for %%i in (*.bin) do del "%%i"
for %%i in (*.) do ren "%%i" "%%i.bin"
del header.bin
cd ..
echo Done!
goto optionsloop

:help
echo.
echo Valid options:
echo.   /?, --help                      Displays help
echo.   -b12, --boot12                  Assembles FAT12 bootloader
echo.   -b16, --boot16                  Assembles FAT16 bootloader
echo.   -k, --kernel                    Builds kernel
echo.   -p, --programs                  Build programs
echo.

:done
echo Build complete!