@echo off
pasmboot pasm.asm pasm2.com
if errorlevel 1 goto err
echo * Self-hosted assembler ready
pasm2 pasm.asm pasm.com
if errorlevel 1 goto err
echo * Full native assembler ready
fc /b pasm2.com pasm.com
if errorlevel 1 goto err
echo * Files are identical!
echo.
echo PASM.COM is ready
goto end
:err
echo There was an error bootstrapping the assembler
:end
