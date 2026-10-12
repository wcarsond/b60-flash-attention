# Testing data

Every file here is as the tool that produced it wrote it, on one machine: Intel Arc Pro B60 24 GB, Windows 10 (22H2, build 19045),
driver 32.0.101.9033, Core i7-11700F, model Qwen3-Coder-30B-A3B Q3_K_XL (12.85 GiB) unless a file says otherwise.
Builds: llama.cpp b11191 source snapshot plus the working-tree patch (the fix and the env-gated rig) for everything except
`upstream-verify` (b11200 `2145525` plus the fix) and `clean-verify` (b11200 `2145525` plus the CLEAN submission patch only).
`kv-slice-raw/BUILD.txt` states the build identity for the raw bench files, which print "build: unknown (0)" because the
tree is a snapshot, not a git checkout. Local paths are replaced with `<home>`.

| file | what it is |
|---|---|
| `clean-verify.output.log` | the SUBMISSION patch applied to an untouched b11200 checkout (the rig patch stashed first, restored after): build, `test-backend-ops` gate, depth curve. The evidence for the artifact in `patches/*.clean.patch`. |
| `upstream-verify.output.log` | depth curve of the working-tree fix on b11200, card checked empty first. |
| `race-br.log` | query block height 16 vs 32 vs 64 on the 8-row tile: correctness gate (test-backend-ops vs CPU) and depth curve for each. 16 stays; 32 and 64 fail the gate and are slower at depth. |
| `ledger-cm1-grid.jsonl` | the first tile-shape grid on the coopmat1 kernel, 18 cells. Every cell identical and REJECTED: the finding that the kernel was never running on this card. |
| `ledger-scalar-grid.jsonl` | 24 cells of the scalar kernel's knobs. Null result, two beliefs corrected (bigger blocks slower; 16-wide subgroup gives wrong output in that configuration). |
| `ref-output.txt` | the stock binary's greedy output on a fixed prompt, the correctness reference used by the grids. |
| `perf-share.output.log` | where a 512-token prompt step spends its time at depth 0 and 16K (per-op timer), and attention cost per KV row against depth. |
| `perf-share.output.raw-d16384.txt`, `-d0.txt` | the raw per-op timer output those summaries came from, one block per 512-token chunk as the context filled. |
| `kv-slice.output.log` | the KV-slicing races: gates, stock vs slice counts and dispatch orders, the q8 cache configuration comparison, the tune run, and run 3/3b (pp128, pp2048 with matching microbatch, three repetitions). The first run 3 lost its prompt columns to a parser bug; run 3b is the rerun. |
| `kv-slice-raw/` | one raw llama-bench output per run-3b configuration (printed mean and spread per cell), plus `BUILD.txt`. |
| `router-ab.output.log` | the deployed slice setting measured through the live llama-server: same 15.8K-token prompt, tuning on, off, on again, with a restart between. |

How the gate works everywhere: `test-backend-ops test -o FLASH_ATTN_EXT -b Vulkan0` compares the Vulkan kernel against the
CPU reference on 5297 shapes. "5297/5297" is a pass. A configuration that is faster and fails the gate is wrong work
finishing early, and there are several of those in these files.
