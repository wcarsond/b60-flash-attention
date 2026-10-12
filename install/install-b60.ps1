# install-b60.ps1 - get the patched llama.cpp Vulkan build for Intel Arc Pro B60 onto this machine and prove it runs.
#
#   powershell -ExecutionPolicy Bypass -File install-b60.ps1                 -> installs to %LOCALAPPDATA%\b60-llama
#   powershell -ExecutionPolicy Bypass -File install-b60.ps1 -Dir D:\b60     -> somewhere else
#   powershell -ExecutionPolicy Bypass -File install-b60.ps1 -Zip .\b60-llama-vulkan-win-x64.zip   -> from a zip you already have
#
# What it does: downloads the latest release zip from github.com/wcarsond/b60-flash-attention (or uses -Zip), unpacks it,
# runs llama-bench --list-devices and shows the Vulkan devices it found. Then tells you the one command to serve a model.
# Needs: Windows 10/11 x64, an Intel Arc driver (32.0.101.9033 or newer is what was tested), the Microsoft VC++ 2015-2022
# runtime (almost every PC has it; https://aka.ms/vs/17/release/vc_redist.x64.exe if not), Resizable BAR on in the BIOS.
param([string]$Dir = "$env:LOCALAPPDATA\b60-llama", [string]$Zip = '')

$repo = 'wcarsond/b60-flash-attention'
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force $Dir | Out-Null

if (-not $Zip) {
    $api = "https://api.github.com/repos/$repo/releases/latest"
    Write-Host "fetching latest release from $repo ..."
    $rel = Invoke-RestMethod $api -Headers @{ 'User-Agent' = 'b60-install' }
    $asset = $rel.assets | Where-Object { $_.name -like '*.zip' } | Select-Object -First 1
    if (-not $asset) { throw "no zip asset on release $($rel.tag_name)" }
    $Zip = Join-Path $env:TEMP $asset.name
    Write-Host "downloading $($asset.name) ($([math]::Round($asset.size / 1MB)) MB) ..."
    Invoke-WebRequest $asset.browser_download_url -OutFile $Zip -UseBasicParsing
    "release: $($rel.tag_name)  $($rel.html_url)" | Set-Content (Join-Path $Dir 'INSTALLED-FROM.txt')
}

Write-Host "unpacking to $Dir ..."
Expand-Archive -Path $Zip -DestinationPath $Dir -Force

$bench = Join-Path $Dir 'bin\llama-bench.exe'
if (-not (Test-Path $bench)) { throw "unpack did not produce bin\llama-bench.exe under $Dir" }

Write-Host ""
Write-Host "Vulkan devices this build can see:"
& $bench --list-devices 2>&1 | Where-Object { $_ -match 'Vulkan|Arc|Intel|NVIDIA|AMD|Radeon|GeForce' } | ForEach-Object { "  $_" }
Write-Host ""
Write-Host "Installed. To serve a model (any GGUF):"
Write-Host "  `"$Dir\bin\llama-server.exe`" -m <model.gguf> -ngl 99 -fa on -c 32768 --port 8080"
Write-Host "To measure this card against ours:"
Write-Host "  powershell -File `"$Dir\bench-b60.ps1`" -Model <model.gguf>"
