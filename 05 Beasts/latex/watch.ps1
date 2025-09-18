# LaTeX Live Development Watcher
Write-Host "Starting LaTeX live development..." -ForegroundColor Green
Write-Host "Watching template.tex and markdown files for changes..." -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow

$watchPath = Get-Location
$templatePath = Join-Path $watchPath "template.tex"
$markdownPath = Join-Path (Split-Path $watchPath) "The Neutral, Inhuman and the Intimate.md"

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = (Split-Path $watchPath)
$watcher.Filter = "*.*"
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

$action = {
    $path = $Event.SourceEventArgs.FullPath
    $name = $Event.SourceEventArgs.Name
    $changeType = $Event.SourceEventArgs.ChangeType

    if ($name -eq "template.tex" -or $name -eq "The Neutral, Inhuman and the Intimate.md") {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Detected change in $name" -ForegroundColor Cyan

        try {
            Set-Location $using:watchPath
            $result = pandoc "..\The Neutral, Inhuman and the Intimate.md" --template="template.tex" --pdf-engine=xelatex -o "The_Neutral_Inhuman_and_Intimate.pdf" 2>&1

            if ($LASTEXITCODE -eq 0) {
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] ✓ PDF updated successfully" -ForegroundColor Green
            } else {
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] ✗ Compilation failed:" -ForegroundColor Red
                Write-Host $result -ForegroundColor Red
            }
        }
        catch {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Register-ObjectEvent -InputObject $watcher -EventName "Changed" -Action $action

try {
    while ($true) {
        Start-Sleep 1
    }
}
finally {
    $watcher.Dispose()
}