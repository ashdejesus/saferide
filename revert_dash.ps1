$content = Get-Content "lib\screens\dashboard_screen.dart" -Raw

$content = [System.Text.RegularExpressions.Regex]::Replace($content, 'SizedBox\(\s*height:\s*16\s*\)', 'SizedBox(height: 12)')
$content = [System.Text.RegularExpressions.Regex]::Replace($content, 'SizedBox\(\s*height:\s*24\s*\)', 'SizedBox(height: 20)')
$content = [System.Text.RegularExpressions.Regex]::Replace($content, 'SizedBox\(\s*width:\s*16\s*\)', 'SizedBox(width: 12)')
$content = [System.Text.RegularExpressions.Regex]::Replace($content, 'SizedBox\(\s*width:\s*24\s*\)', 'SizedBox(width: 20)')

$content = [System.Text.RegularExpressions.Regex]::Replace($content, 'EdgeInsets\.all\(\s*16\s*\)', 'EdgeInsets.all(12)')
$content = [System.Text.RegularExpressions.Regex]::Replace($content, 'EdgeInsets\.all\(\s*24\s*\)', 'EdgeInsets.all(20)')

$content = [System.Text.RegularExpressions.Regex]::Replace($content, 'EdgeInsets\.symmetric\(\s*horizontal:\s*24\s*,', 'EdgeInsets.symmetric(horizontal: 20,')
$content = [System.Text.RegularExpressions.Regex]::Replace($content, 'EdgeInsets\.symmetric\(\s*horizontal:\s*16\s*,', 'EdgeInsets.symmetric(horizontal: 12,')

Set-Content -Path "lib\screens\dashboard_screen.dart" -Value $content -NoNewline
Write-Host "Reverted dashboard spacing."
