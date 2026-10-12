# bench-b60.ps1 - run the depth curve we publish, on your card, and print it next to ours.
#
#   powershell -File bench-b60.ps1 -Model <model.gguf>            (binaries in .\bin next to this script, or -Bin <dir>)
#
# Runs llama-bench: 512-token prompt (pp512) and 32-token generation (tg32) at 0 / 8K / 16K / 32K tokens of existing
# context, flash attention on, all layers on the GPU. Takes about three minutes. Our reference line is an Arc Pro B60,
# Windows 10 (22H2, build 19045), driver 32.0.101.9033, Qwen3-Coder-30B-A3B Q3_K_XL (12.85 GiB). A different model changes the absolute
# numbers; the SHAPE (how much pp512 falls from depth 0 to 32K) is what the patch is about. Stock llama.cpp on this
# card fell from 1707 to 89. Patched: 1847 to 187.
param([Parameter(Mandatory = $true)][string]$Model, [string]$Bin = "$PSScriptRoot\bin", [string]$Device = '')

$bench = Join-Path $Bin 'llama-bench.exe'
if (-not (Test-Path $bench)) { throw "no llama-bench.exe in $Bin" }
if (-not (Test-Path $Model)) { throw "model not found: $Model" }
$depths = 0, 8192, 16384, 32768
$args = @('-m', $Model, '-ngl', '99', '-fa', '1', '-p', '512', '-n', '32', '-d', ($depths -join ','), '-r', '1')
if ($Device) { $args += @('--device', $Device) }

Write-Host "running llama-bench (about three minutes) ..."
$raw = & $bench @args 2>&1 | ForEach-Object { "$_" }
$pp = @{}; $tg = @{}
foreach ($l in $raw) {
    if ($l -match '(pp512|tg32)(?: @ d(\d+))? \|\s+([\d.]+)') {
        $d = if ($Matches[2]) { [int]$Matches[2] } else { 0 }
        if ($Matches[1] -eq 'pp512') { $pp[$d] = [math]::Round([double]$Matches[3]) } else { $tg[$d] = [math]::Round([double]$Matches[3]) }
    }
}
$dev = ($raw | Where-Object { $_ -match 'ggml_vulkan: \d+ = ' } | Select-Object -First 1)
Write-Host ""
if ($dev) { Write-Host $dev.Trim() }
Write-Host ("{0,-34} {1,7} {2,7} {3,7} {4,7}" -f 'pp512 tok/s at depth', '0', '8K', '16K', '32K')
Write-Host ("{0,-34} {1,7} {2,7} {3,7} {4,7}" -f 'yours', $pp[0], $pp[8192], $pp[16384], $pp[32768])
Write-Host ("{0,-34} {1,7} {2,7} {3,7} {4,7}" -f 'ours, B60 patched', 1847, 586, 341, 187)
Write-Host ("{0,-34} {1,7} {2,7} {3,7} {4,7}" -f 'ours, B60 stock llama.cpp', 1707, 319, 173, 89)
Write-Host ""
Write-Host ("{0,-34} {1,7} {2,7} {3,7} {4,7}" -f 'tg32 tok/s at depth', '0', '8K', '16K', '32K')
Write-Host ("{0,-34} {1,7} {2,7} {3,7} {4,7}" -f 'yours', $tg[0], $tg[8192], $tg[16384], $tg[32768])
Write-Host ("{0,-34} {1,7} {2,7} {3,7} {4,7}" -f 'ours, B60 patched', 98, 70, 57, 40)
Write-Host ""
$out = Join-Path $PSScriptRoot ("bench-b60.output.{0}.txt" -f (Get-Date -Format 'yyyyMMdd-HHmm'))
$raw | Set-Content $out -Encoding utf8
Write-Host "raw llama-bench output saved to $out. If you share your numbers, name the card, driver and model."
