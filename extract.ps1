$content = Get-Content -Path "docx_clean.txt" -Raw
$index = $content.IndexOf("Statement of the Problem", [System.StringComparison]::InvariantCultureIgnoreCase)
if ($index -ge 0) {
    $length = [Math]::Min(3000, $content.Length - $index)
    $content.Substring($index, $length)
} else {
    Write-Host "Not found"
}
