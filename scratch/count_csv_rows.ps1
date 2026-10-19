$file = 'saferide_passenger_reports.csv'
$lines = Get-Content $file -Encoding UTF8
Write-Host "Total lines (incl. header): $($lines.Count)"
$dataRows = 0
$shortRows = @()
$outOfPh = @()
$badTs = @()

for ($i = 1; $i -lt $lines.Count; $i++) {
    $line = $lines[$i].Trim()
    if ($line.Length -eq 0) { continue }
    $dataRows++
    $cols = $line -split ','
    if ($cols.Count -lt 14) {
        $shortRows += "Row $($i+1): $($cols.Count) cols"
        continue
    }
    $lat = [double]::Parse($cols[5].Trim())
    $lon = [double]::Parse($cols[6].Trim())
    if ($lat -lt 4.0 -or $lat -gt 21.0 -or $lon -lt 116.0 -or $lon -gt 128.0) {
        $outOfPh += "Row $($i+1): lat=$lat lon=$lon id=$($cols[0].Trim())"
    }
}
Write-Host "Data rows: $dataRows"
Write-Host "Short-column rows (< 14 cols): $($shortRows.Count)"
$shortRows | ForEach-Object { Write-Host "  $_" }
Write-Host "Out-of-Philippines GPS rows: $($outOfPh.Count)"
$outOfPh | ForEach-Object { Write-Host "  $_" }
Write-Host "Total excluded by build script: $($shortRows.Count + $outOfPh.Count)"
