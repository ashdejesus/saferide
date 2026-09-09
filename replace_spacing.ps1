$files = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw

    $content = [System.Text.RegularExpressions.Regex]::Replace($content, 'SizedBox\(\s*height:\s*12\s*\)', 'SizedBox(height: 16)')
    $content = [System.Text.RegularExpressions.Regex]::Replace($content, 'SizedBox\(\s*height:\s*10\s*\)', 'SizedBox(height: 8)')
    $content = [System.Text.RegularExpressions.Regex]::Replace($content, 'SizedBox\(\s*height:\s*20\s*\)', 'SizedBox(height: 24)')
    $content = [System.Text.RegularExpressions.Regex]::Replace($content, 'SizedBox\(\s*height:\s*6\s*\)', 'SizedBox(height: 8)')
    $content = [System.Text.RegularExpressions.Regex]::Replace($content, 'SizedBox\(\s*height:\s*4\s*\)', 'SizedBox(height: 8)')
    
    $content = [System.Text.RegularExpressions.Regex]::Replace($content, 'SizedBox\(\s*width:\s*12\s*\)', 'SizedBox(width: 16)')
    $content = [System.Text.RegularExpressions.Regex]::Replace($content, 'SizedBox\(\s*width:\s*10\s*\)', 'SizedBox(width: 8)')
    $content = [System.Text.RegularExpressions.Regex]::Replace($content, 'SizedBox\(\s*width:\s*20\s*\)', 'SizedBox(width: 24)')
    $content = [System.Text.RegularExpressions.Regex]::Replace($content, 'SizedBox\(\s*width:\s*6\s*\)', 'SizedBox(width: 8)')
    $content = [System.Text.RegularExpressions.Regex]::Replace($content, 'SizedBox\(\s*width:\s*4\s*\)', 'SizedBox(width: 8)')

    $content = [System.Text.RegularExpressions.Regex]::Replace($content, 'EdgeInsets\.all\(\s*12\s*\)', 'EdgeInsets.all(16)')
    $content = [System.Text.RegularExpressions.Regex]::Replace($content, 'EdgeInsets\.all\(\s*20\s*\)', 'EdgeInsets.all(24)')
    $content = [System.Text.RegularExpressions.Regex]::Replace($content, 'EdgeInsets\.all\(\s*10\s*\)', 'EdgeInsets.all(8)')

    $content = [System.Text.RegularExpressions.Regex]::Replace($content, 'EdgeInsets\.symmetric\(\s*horizontal:\s*20\s*,', 'EdgeInsets.symmetric(horizontal: 24,')
    $content = [System.Text.RegularExpressions.Regex]::Replace($content, 'EdgeInsets\.symmetric\(\s*horizontal:\s*12\s*,', 'EdgeInsets.symmetric(horizontal: 16,')
    
    Set-Content -Path $file.FullName -Value $content -NoNewline
}
Write-Host "Spacing replacements completed."
