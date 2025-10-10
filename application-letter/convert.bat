@echo off
setlocal enabledelayedexpansion

for %%f in (input\*.md) do (
    set "basename=%%~nf"
    set "outputfile=output\!basename!.pdf"
    
    if not exist "!outputfile!" (
        echo Converting %%f to !outputfile!...
        pandoc "%%f" -o "!outputfile!" --template="templates/letter-template.tex" --pdf-engine=xelatex
    ) else (
        echo Skipping !basename!.pdf because it already exists.
    )
)

echo.
echo Conversion process finished.
pause