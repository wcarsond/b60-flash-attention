# vulkan: run coopmat1 flash attention on Intel Xe with its native 8x16x16 tile

## Problem

`flash_attn_cm1.comp` hard-codes a 16x16x16 cooperative-matrix tile (`MatBr = MatBc = 16`), and
`get_fa_tuning_params()` only allows the coopmat1 path when the device reports a 16x16x16 f16 shape. An Arc Pro B60
(Xe2, Windows driver 32.0.101.9033) reports exactly one f16 cooperative-matrix shape, **8x16x16** (M=8), with both
f16 and f32 accumulation, and no 16x16x16. On that device, and on any device with the same capability profile, the
batched (prompt processing) flash attention therefore silently falls back to the scalar kernel, whose Intel branch
disables subgroup operations. On the B60 that is 1707 tok/s pp512 at depth 0 collapsing to 173 at 16K depth and 89 at
32K, while decode is already served by the Xe2 decode kernels from #24406. The matmul coopmat1 pipelines already handle
Intel's 8-row tile; flash attention never did. I expect other Intel Xe parts to report the same shape (see the note at
the end), but the B60 is the only one I have measured.

## Change

Confined to the coopmat1 FA path. Devices that report 16x16x16 keep `MatM = 16`, which reproduces the previous tile
dimensions and default subgroup count; they do compile the edited shader and pass through the new topology check.

- `flash_attn_cm1.comp`: the tile M becomes specialization constant 16 (`MatM`, default 16). Both products in the
  shader are `(MatBc x 16) * (16 x MatBr)`, and the shader's own comment noted it was "written transposed in order
  to allow for N being 8"; Intel needs the narrow side on M. `MatBc = MatM` covers K*Q^T. For P*V the query rows are
  walked in `Br / MatM` tiles while the KV reduction runs in chunks of 16 (the tile's K) instead of `MatBc`; the V
  staging width and `pvsh` are sized by `MatBr`/`Br` rather than `MatBc`.
- `ggml-vulkan.cpp` / `ggml-vulkan-types.h`: record 8x16x16 f16/f32-acc support at device init; `shape_ok` accepts
  either shape; `vk_fa_tuning_params` / `vk_fa_pipeline_state` carry `mat_m` (it keys the pipeline and feeds
  spec constant 16); `block_cols = mat_m * row_split`; the shared-memory estimate follows the same arithmetic.
- Intel coopmat1 FA pipelines are pinned to the minimum subgroup width (16 on Xe), as the coopmat1 matmul pipelines
  already are. This is also a shader requirement, not only a policy: with the 8-row tile and 2 subgroups `block_cols`
  is 16, and each thread gets `block_cols / subgroup_size` columns in the softmax loops that write `Psh` (the P
  operand of P*V). At a 32-wide subgroup that is zero columns, `Psh` is never written, and the output is wrong even
  though the K*Q product itself still runs. That is what happened at the device default width.
- 2 subgroups per workgroup on the 8-row tile (4 where the tile is 16 rows, as before). The shader constrains
  `row_split`: `block_rows / row_split` must be a multiple of 4 (the softmax walks rows four at a time), and
  `block_cols = M * row_split` must be a multiple of 16 (the tile's K), so with M = 8 only 2 or 4 are valid. 2
  measured faster (below). If 2 would leave `block_cols` below the subgroup width, 4 is taken; if the topology still
  does not fit, `get_fa_tuning_params` falls back to the scalar path as it does for a failed shape or shared-memory
  check. The fixed relationships are asserted. No new tuning knobs are added.

## Verification (Arc Pro B60, Windows, driver 101.9033, Qwen3-Coder-30B-A3B Q3_K_XL)

Test system: Intel Core i7-11700F, ASUS ROG Strix G15CE (B560), 32 GB DDR4-2667, ASRock Arc Pro B60 24 GB (PCI subsystem
1849:6023), Intel Graphics driver 32.0.101.9033, Windows 10 22H2 (build 19045). Vulkan backend only; the card is the sole
active display adapter.

- `test-backend-ops -o FLASH_ATTN_EXT -b Vulkan0`: 5297/5297 (2 subgroups; also 4 subgroups with and without
  shared-memory staging). Before the change the coopmat1 path never ran on this device.
- Perplexity, same 50 KB text, `-c 2048 -fa on`: scalar path 6.975 +/- 0.243, this change 6.992 +/- 0.244. A small
  observed difference, within the reported spread; I have not isolated its cause.
- `llama-bench -fa 1 -p 512 -n 32 -d 0,8192,16384,32768`, pp512 / tg32 tok/s, on b11191 (the historical comparison;
  the b11200 verification of the exact submitted patch is below):

  | | depth 0 | 8K | 16K | 32K |
  |---|---|---|---|---|
  | scalar (before) | 1707 / 98 | 319 / 70 | 173 / 57 | 89 / 40 |
  | coopmat1 8x16x16, 4 subgroups | 1863 / 98 | 560 / 71 | 290 / 56 | 153 / 40 |
  | coopmat1 8x16x16, 2 subgroups (default) | 1847 / 98 | 586 / 70 | 341 / 57 | 187 / 40 |

  Decode is unchanged (it takes the Xe2 decode path). Prompt processing roughly doubles at depth.

- The exact submitted patch (sha256 769DA11A…C9742) applied to a clean b11200 checkout (`2145525`, zero modified files
  before applying): build clean, `test-backend-ops -o FLASH_ATTN_EXT` 5297/5297, pp512 1845 / 588 / 343 / 187 and
  tg32 99 / 71 / 57 / 40 at depth 0 / 8K / 16K / 32K.

I only have the B60 to test on. Other Xe2 parts (Arc Pro B65/B70, Xe2 integrated GPUs) are expected to report the same
8x16x16 shape and take the same path, but I have no capability dump from them; numbers or a shape listing from any of
them would be welcome. Xe-HPG (Arc A-series) has an 8-wide DPAS and, as I understand it, would report 8x8x16, which this
change does not cover. For devices that report 16x16x16 the
16-row configuration is preserved as before, but they have not been tested with this change; a `test-backend-ops` run
on an Nvidia or AMD card would be welcome too.

Not in this PR: taller query blocks (Br 32/64) were tried and fail the CPU reference; the K*Q loop loads only the first
16-query tile (`MatBr`), so a larger Br needs a query-tile loop there first. A split-k heuristic for the batched case at
depth (about +13% pp512 at 16K on the B60 on top of this) is a separate follow-up once it has its own validation.
