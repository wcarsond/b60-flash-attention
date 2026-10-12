| model | backend | weights | cards | decode short | decode 16K | decode 32K | first token, 16K prompt (s) | first token, 32K prompt (s) |
|---|---|---|---|---|---|---|---|---|
| qwen2.5-coder-7b | vulkan-stock | Q8_0 | 1 | 44.4 | 38.5 | 34.0 | 26.4 | 90.8 |
| qwen2.5-coder-7b | vulkan-patched | Q8_0 | 1 | 44.5 | 38.4 | 34.0 | 15.1 | 47.3 |
| qwen2.5-coder-7b | sycl-stock | Q8_0 | 1 | 38.6 | 20.5 | 13.5 | 22.5 | 47.4 |
| qwen2.5-coder-7b | vllm | bf16 | 1 | 30.0 | 27.9 | 26.3 | 3.5 | 8.5 |
| qwen2.5-coder-7b | vulkan-stock | Q8_0 | 2 | 43.4 | 37.4 | 33.1 | 17.6 | 60.5 |
| qwen2.5-coder-7b | vulkan-patched | Q8_0 | 2 | 43.4 | 37.4 | 33.1 | 10.2 | 31.7 |
| qwen2.5-coder-7b | sycl-stock | Q8_0 | 2 | 37.4 | 20.2 | 13.4 | 22.6 | 47.6 |
| qwen2.5-coder-7b | vulkan-allreduce | Q8_0 | 2 | 66.9 | 55.7 | 48.3 | 14.6 | 48.2 |
| qwen2.5-coder-7b | vulkan-allreduce-fa | Q8_0 | 2 | 66.0 | 56.5 | 48.6 | 9.9 | 30.2 |
| qwen2.5-coder-7b | vllm | bf16 | 2 | 46.4 | 43.8 | 40.1 | 4.0 | 8.8 |
| qwen2.5-14b | vulkan-stock | Q4_K_M (coder) | 1 | 38.8 | 28.6 | 22.9 | 67.1 | 236.0 |
| qwen2.5-14b | vulkan-patched | Q4_K_M (coder) | 1 | 38.8 | 28.6 | 22.9 | 33.7 | 108.4 |
| qwen2.5-14b | sycl-stock | Q4_K_M (coder) | 1 | 34.8 | 10.1 | 6.0 | 46.2 | 98.1 |
| qwen2.5-14b | vllm | bf16 (instruct) | 1 | does not fit one card | | | | |
| qwen2.5-14b | vulkan-stock | Q4_K_M (coder) | 2 | 37.9 | 27.9 | 22.4 | 43.9 | 154.0 |
| qwen2.5-14b | vulkan-patched | Q4_K_M (coder) | 2 | 37.9 | 28.0 | 22.3 | 22.1 | 71.0 |
| qwen2.5-14b | sycl-stock | Q4_K_M (coder) | 2 | 33.8 | 10.0 | 5.9 | 46.3 | 98.3 |
| qwen2.5-14b | vulkan-allreduce | Q4_K_M (coder) | 2 | 50.2 | 38.3 | 31.3 | 38.5 | 130.9 |
| qwen2.5-14b | vulkan-allreduce-fa | Q4_K_M (coder) | 2 | 50.2 | 38.7 | 31.5 | 22.0 | 67.2 |
| qwen2.5-14b | vllm | bf16 (instruct) | 2 | 25.2 | 22.9 | 20.9 | 8.0 | 17.7 |
| granite-4.2-30b | vulkan-stock | Q4_K_M | 1 | 20.1 | 16.2 | 7.3 | 82.0 | 579.7 |
| granite-4.2-30b | vulkan-patched | Q4_K_M | 1 | 20.1 | 16.2 | 7.3 | 49.0 | 309.8 |
| granite-4.2-30b | sycl-stock | Q4_K_M | 1 | 17.2 | 14.0 | - | 94.1 | - |
| granite-4.2-30b | vllm | GPTQ int4 | 1 | failed; see logs\granite-4.2-30b_vllm_1.* | | | | |
| granite-4.2-30b | vulkan-stock | Q4_K_M | 2 | 19.8 | 16.0 | 13.6 | 53.2 | 176.1 |
| granite-4.2-30b | vulkan-patched | Q4_K_M | 2 | 19.8 | 16.0 | 13.6 | 31.8 | 93.7 |
| granite-4.2-30b | sycl-stock | Q4_K_M | 2 | 17.0 | 13.9 | 11.9 | 94.2 | 193.2 |
| granite-4.2-30b | vulkan-allreduce | Q4_K_M | 2 | 29.5 | 24.2 | 20.2 | 47.2 | 152.2 |
| granite-4.2-30b | vulkan-allreduce-fa | Q4_K_M | 2 | 29.3 | 23.9 | 20.3 | 28.4 | 80.2 |
| granite-4.2-30b | vllm | GPTQ int4 | 2 | 31.9 | 28.7 | 25.3 | 12.8 | 27.8 |

Prefill tok/s for a whole prompt of this many tokens (higher is better):

| model | backend | weights | cards | 512 | 4K | 8K | 16K | 32K |
|---|---|---|---|---|---|---|---|---|
| qwen2.5-coder-7b | vulkan-stock | Q8_0 | 1 | 2,544 | 1,568 | 1,036 | 621 | 352 |
| qwen2.5-coder-7b | vulkan-patched | Q8_0 | 1 | 2,704 | 2,068 | 1,598 | 1,088 | 676 |
| qwen2.5-coder-7b | sycl-stock | Q8_0 | 1 | 784 | 775 | 762 | 728 | 676 |
| qwen2.5-coder-7b | vllm | bf16 | 1 | - | 5,772 | 5,261 | 4,674 | 3,763 |
| qwen2.5-coder-7b | vulkan-stock | Q8_0 | 2 | 2,527 | 2,257 | 1,530 | 929 | 529 |
| qwen2.5-coder-7b | vulkan-patched | Q8_0 | 2 | 2,678 | 2,988 | 2,342 | 1,614 | 1,010 |
| qwen2.5-coder-7b | sycl-stock | Q8_0 | 2 | 780 | 771 | 758 | 725 | 673 |
| qwen2.5-coder-7b | vulkan-allreduce | Q8_0 | 2 | 3,421 | 2,388 | 1,747 | 1,120 | 663 |
| qwen2.5-coder-7b | vulkan-allreduce-fa | Q8_0 | 2 | 3,531 | 2,833 | 2,300 | 1,656 | 1,060 |
| qwen2.5-coder-7b | vllm | bf16 | 2 | - | 4,504 | 4,358 | 4,087 | 3,629 |
| qwen2.5-14b | vulkan-stock | Q4_K_M (coder) | 1 | 1,289 | 667 | 422 | 244 | 136 |
| qwen2.5-14b | vulkan-patched | Q4_K_M (coder) | 1 | 1,400 | 996 | 737 | 486 | 295 |
| qwen2.5-14b | sycl-stock | Q4_K_M (coder) | 1 | 387 | 381 | 374 | 355 | 326 |
| qwen2.5-14b | vulkan-stock | Q4_K_M (coder) | 2 | 1,275 | 983 | 634 | 373 | 208 |
| qwen2.5-14b | vulkan-patched | Q4_K_M (coder) | 2 | 1,381 | 1,482 | 1,110 | 742 | 451 |
| qwen2.5-14b | sycl-stock | Q4_K_M (coder) | 2 | 386 | 380 | 373 | 354 | 325 |
| qwen2.5-14b | vulkan-allreduce | Q4_K_M (coder) | 2 | 1,644 | 1,039 | 702 | 426 | 244 |
| qwen2.5-14b | vulkan-allreduce-fa | Q4_K_M (coder) | 2 | 1,731 | 1,341 | 1,067 | 746 | 476 |
| qwen2.5-14b | vllm | bf16 (instruct) | 2 | - | 2,267 | 2,191 | 2,043 | 1,812 |
| granite-4.2-30b | vulkan-stock | Q4_K_M | 1 | 658 | 439 | 313 | 200 | 55 |
| granite-4.2-30b | vulkan-patched | Q4_K_M | 1 | 686 | 559 | 456 | 334 | 103 |
| granite-4.2-30b | sycl-stock | Q4_K_M | 1 | 183 | 181 | 179 | 174 | - |
| granite-4.2-30b | vulkan-stock | Q4_K_M | 2 | 652 | 661 | 476 | 308 | 182 |
| granite-4.2-30b | vulkan-patched | Q4_K_M | 2 | 685 | 851 | 698 | 515 | 341 |
| granite-4.2-30b | sycl-stock | Q4_K_M | 2 | 183 | 181 | 179 | 174 | 166 |
| granite-4.2-30b | vulkan-allreduce | Q4_K_M | 2 | 989 | 717 | 530 | 347 | 210 |
| granite-4.2-30b | vulkan-allreduce-fa | Q4_K_M | 2 | 1,025 | 876 | 748 | 576 | 399 |
| granite-4.2-30b | vllm | GPTQ int4 | 2 | - | 1,398 | 1,359 | 1,284 | 1,151 |
