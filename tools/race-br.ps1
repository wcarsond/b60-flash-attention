# race-br.ps1 - query-block height (Br) for the 8-row coopmat1 kernel: 16 (current) vs 32 vs 64, 2 subgroups.
# Each Br walks the whole KV cache once per Br queries, so taller blocks mean less traffic; the question is whether
# registers and shared memory allow it. Gate first (test-backend-ops vs CPU), then the depth curve.
#   powershell -File race-br.ps1
$B = '<home>\llama.cpp-b60\build-vk\bin\Release'
$m = '<model.gguf>'
$log = '<home>\llama.cpp-b60\fa-tune\race-br.log'
"race-br $(Get-Date -Format s)" | Set-Content $log
foreach ($br in 16, 32, 64) {
    [Environment]::SetEnvironmentVariable('GGML_VK_FA_CM1_BR', "$br", 'Process')
    [Environment]::SetEnvironmentVariable('GGML_VK_FA_CM1_SUBGROUPS', '2', 'Process')
    $t0 = Get-Date
    $out = & "$B\test-backend-ops.exe" test -o FLASH_ATTN_EXT -b Vulkan0 2>&1 | ForEach-Object { "$_" -replace "`e\[[\d;]*m", '' }
    $sum = ($out | Where-Object { $_ -match 'tests passed' } | Select-Object -Last 1)
    $rej = @($out | Where-Object { $_ -match 'REJECTED' }).Count
    ("Br={0,-3} gate: {1}  rejected-msgs={2}  ({3}s)" -f $br, ("$sum").Trim(), $rej, [int]((Get-Date) - $t0).TotalSeconds) | Tee-Object -FilePath $log -Append
    $bench = & "$B\llama-bench.exe" -m $m -ngl 99 -fa 1 -p 512 -n 32 -d 0,8192,16384,32768 -r 1 2>$null | Select-String '^\| qwen' | ForEach-Object { $_.Line }
    $pp = @{}; $tg = @{}
    foreach ($l in $bench) { if ($l -match '(pp512|tg32)(?: @ d(\d+))? \|\s+([\d.]+)') { $d = if ($Matches[2]) { [int]$Matches[2] } else { 0 }; if ($Matches[1] -eq 'pp512') { $pp[$d] = [math]::Round([double]$Matches[3]) } else { $tg[$d] = [math]::Round([double]$Matches[3]) } } }
    ("Br={0,-3} pp: d0 {1,5}  8K {2,5}  16K {3,5}  32K {4,5}   tg: d0 {5,3}  8K {6,3}  16K {7,3}  32K {8,3}" -f $br, $pp[0], $pp[8192], $pp[16384], $pp[32768], $tg[0], $tg[8192], $tg[16384], $tg[32768]) | Tee-Object -FilePath $log -Append
    [Environment]::SetEnvironmentVariable('GGML_VK_FA_CM1_BR', $null, 'Process')
    [Environment]::SetEnvironmentVariable('GGML_VK_FA_CM1_SUBGROUPS', $null, 'Process')
}
"done $(Get-Date -Format s)" | Add-Content $log
