@echo off
echo Starting LaTeX live development...
echo Watching for changes to template.tex and markdown files...
echo Press Ctrl+C to stop

:loop
pandoc "..\The Neutral, Inhuman and the Intimate.md" --template="template.tex" --pdf-engine=xelatex -o "The_Neutral_Inhuman_and_Intimate.pdf"
if %errorlevel% equ 0 (
    echo [%time%] PDF updated successfully
) else (
    echo [%time%] Compilation failed
)
timeout /t 2 /nobreak >nul
goto loop