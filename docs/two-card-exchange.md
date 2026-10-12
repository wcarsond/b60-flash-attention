# Two-card exchange: tensor split across two Arc cards on Windows (Vulkan)

`--split-mode tensor` splits every layer across both cards, so both work on every token. Each layer needs two
exchanges where the cards add their partial results. llama.cpp's generic exchange on Vulkan stops both cards several
times per exchange (~190 us each, 128 per token on a 64-layer model), which made two cards slower than one.
`patches/two-card-exchange.patch` gives the Vulkan backend its own two-device exchange. Three modes are in the code:

| mode (env) | what | Granite 4.2 30B decode, vs one card |
|---|---|---:|
| generic (`GGML_VK_DISABLE_COMM=1`) | the meta backend's all-reduce | 17.2 (0.86x) |
| sync (`GGML_VK_COMM_SYNC=1`) | copy through shared host memory, one CPU stop per exchange | 22.5 (1.12x) |
| relay (`GGML_VK_COMM_RELAY=1`) | no stop: timeline semaphores, a relay thread host-signals mirrors | 24.9 (1.24x) |
| **events** (default) | no stop: host counters + VkEvents, the relay thread sets the events | **29.5 (1.47x)** |

One card: 20.1 tok/s. Measured on two Arc Pro B60s, Windows 11, driver 32.0.101.9033.

## What was learned about the Intel Windows driver

1. **External semaphores import between the two cards but share nothing.** The driver reports opaque Win32 handles
   exportable and importable for timeline semaphores and every call succeeds, yet neither host nor queue signals on
   one card are ever seen on the other. Hence the relay thread.
2. **A shader cannot poll memory the other card writes.** With volatile loads, with atomics, on the uncached memory
   type: the polls return a stale value for as long as the poll lasts. Hence VkEvents: `vkCmdWaitEvents` is polled by
   the command streamer, which is built for host-written values.
3. **A semaphore wait costs a scheduler round trip**: the OS holds the submission back until the signal, and the
   wake-up is tens of microseconds. That is the gap between relay and events.
4. **`vkCmdFillBuffer` into imported host memory lands reliably** and the CPU sees it at once. The counters are the
   one channel that never misbehaved.

## With the flash-attention fix

`patches/two-card-exchange-with-flash-attn.patch` is the exchange plus the coopmat1 flash-attention fix from this
repository, as one diff against b11200 (`2145525`). Built with it, `test-backend-ops -o FLASH_ATTN_EXT` passes
5297/5297 on the B60 (`testing/backend-race/exchange-with-flash-attn.gate.log`). Decode is unchanged by the fix;
time to the first token on long prompts roughly halves:

| two cards, first token for a 32K-token prompt | exchange | exchange + fix |
|---|---|---|
| Qwen2.5-Coder-7B Q8_0 | 48.2 s | 30.2 s |
| Qwen2.5-14B Q4_K_M | 130.9 s | 67.2 s |
| Granite 4.2 30B Q4_K_M | 152.2 s | 80.2 s |

## Limits

- Exactly two Vulkan devices, F32 contiguous tensors, `VK_EXT_external_memory_host` required; anything else falls
  back to the generic all-reduce.
- An MoE model (30B-A3B) is at 0.84x of one card: its token is ~10 ms and the CPU spends ~9 ms submitting three
  submissions per layer per card. Dense models are GPU-bound.
- Not yet built or tested on Linux; the events path has nothing Windows-specific in it.
- Not submitted upstream.
