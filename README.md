# b60-flash-attention

llama.cpp for the Intel Arc Pro B60 (and other Xe2 Arc cards) on Windows, with the Vulkan flash-attention kernel
fixed to run on Intel's 8-row matrix tile. Prompt processing at long context roughly doubles. Generation is unchanged.

| pp512 tok/s at existing context of | 0 | 8K | 16K | 32K |
|---|---|---|---|---|
| stock llama.cpp b11191, Vulkan, B60 | 1707 | 319 | 173 | 89 |
| this build | 1847 | 586 | 341 | 187 |

Qwen3-Coder-30B-A3B Q3_K_XL, driver 32.0.101.9033, Windows 10 (22H2, build 19045). Generation (tg32): 98 / 70 / 57 / 40 both ways.
Correctness: test-backend-ops FLASH_ATTN_EXT 5297 of 5297 against the CPU reference; perplexity within noise.

## Install

The binary release is being rebuilt from the clean patch on b11200. Until it is up, build it yourself (below);
once it is, one line in PowerShell:

```powershell
irm https://raw.githubusercontent.com/wcarsond/b60-flash-attention/main/install/install-b60.ps1 -OutFile install-b60.ps1; powershell -ExecutionPolicy Bypass -File install-b60.ps1
```

It downloads the latest release zip, unpacks to `%LOCALAPPDATA%\b60-llama`, and lists the Vulkan devices it can see.
Or download the zip from Releases yourself and unpack it anywhere; there is nothing to register.

Then serve any GGUF model:

```powershell
& "$env:LOCALAPPDATA\b60-llama\bin\llama-server.exe" -m <model.gguf> -ngl 99 -fa on -c 32768 --port 8080
```

Ollama's model store holds GGUF files under `blobs\`; llama-server loads them directly.

Requirements: Windows 10/11 x64, Intel Arc driver 32.0.101.9033 or newer, Resizable BAR enabled in the BIOS
(Arc crawls without it), the Microsoft VC++ 2015-2022 runtime (nearly every PC has it; `https://aka.ms/vs/17/release/vc_redist.x64.exe` if not).

## Measure your card

```powershell
powershell -File "$env:LOCALAPPDATA\b60-llama\bench-b60.ps1" -Model <model.gguf>
```

Three minutes. Prints your depth curve next to ours. A different model shifts the absolute numbers; the shape, how
far pp512 falls from depth 0 to 32K, is what the fix is about. If you post numbers, name the card, driver and model.
The Arc Pro B65 and B70 are expected to report the same 8x16x16 tile and take the same path; we have only a B60 to test
on, and a shape listing or bench from any other Intel GPU is the evidence we lack.

## What was wrong

llama.cpp's fast prompt-processing attention kernel (`flash_attn_cm1.comp`) uses the GPU's cooperative-matrix
instruction and hard-codes a 16x16x16 tile, which is what Nvidia offers. Intel Xe offers 8x16x16. The backend checks
for 16, does not find it, and silently runs the scalar fallback. Nobody noticed because the fallback is correct, only
slow, and only at depth. Details and the diff: `patches/`, `src/`, `docs/PR.md`.

## What changed

The tile height is now a specialization constant the backend sets per device (16 where 16 exists, 8 on Intel Xe).
The P*V product walks the 16 query rows as two 8-row tiles, two shared-memory sizes come from the query side, Intel
coopmat1 attention pipelines are pinned to the 16-wide subgroup (at 32 the results are wrong on this driver), and
the subgroup count is capped so no thread reads past its rows. Devices that report the 16-row tile keep their previous
configuration; they compile the edited shader, and we have not been able to test one. Devices with the 16x16x16 tile are untouched.

## Build it yourself

Apply `patches/intel-xe-coopmat1-flash-attn.clean.patch` to llama.cpp b11191 or b11200 and build with `-DGGML_VULKAN=ON`.
That is the submission patch: three files, product changes only, no environment reads. `src/clean/` has those three
files in full, `src/pristine-b11191/` the untouched originals, and `src/current/` the working tree with the tuning
rig and experiments in it. `patches/current-full.patch` is the whole working tree as a diff; the `with-tuning-hooks`
patch is the first version, kept for the record.

## Repository

- `install/` the install and bench scripts above
- `patches/` the upstream patch and the full working-tree diff
- `src/` the four touched files, current and pristine
- `testing/` every measurement, as produced, with a README naming each file
- `docs/` the PR draft and the sources it cites

## Status

The clean patch is being prepared as a pull request to llama.cpp; `testing/clean-verify.output.log` records its build,
CPU-reference gate (5297/5297) and depth curve on an untouched upstream b11200 checkout. The tuning hooks and the
KV-slice experiment are not part of it.

## License

MIT. The files under `src/` and `patches/` derive from [llama.cpp](https://github.com/ggml-org/llama.cpp), Copyright
(c) 2023-2026 The ggml authors, MIT License, in `LICENSE`. The rest is Carson Daniel's under the same terms.
