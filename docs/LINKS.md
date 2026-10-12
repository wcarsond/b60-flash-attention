# Links and sources

Reference list for the issue and pull request. Facts and URLs only.

## Upstream context (ggml-org/llama.cpp)
- Issue 29310, "Enable coopmat1 for vulkan on Intel Arrow Lake processors in Linux": https://github.com/ggml-org/llama.cpp/issues/29310
- PR 24406, Intel Xe flash-attention optimization kernels (Xe-LPG Plus / Xe2 / Xe3 decode path): https://github.com/ggml-org/llama.cpp/pull/24406
- PR 10721, VK_EXT_subgroup_size_control for full subgroups in coopmat pipelines: https://github.com/ggml-org/llama.cpp/pull/10721
- Issue 25491, redundant per-Q-workgroup KV dequant in coopmat1 flash attention: https://github.com/ggml-org/llama.cpp/issues/25491
- CONTRIBUTING.md: https://github.com/ggml-org/llama.cpp/blob/master/CONTRIBUTING.md
- AGENTS.md (AI usage and agent rules): https://github.com/ggml-org/llama.cpp/blob/master/AGENTS.md
- PR template: https://github.com/ggml-org/llama.cpp/blob/master/.github/pull_request_template.md

## Hardware and specifications
- Intel Arc Pro B60 product specifications: https://www.intel.com/content/www/us/en/products/sku/243916/intel-arc-pro-b60-graphics/specifications.html
- Intel Arc Pro B60 datasheet, March 2026: https://www.intel.com/content/dam/www/central-libraries/us/en/documents/2026-03/datasheet-b60-gpu.pdf
- Khronos GLSL_KHR_cooperative_matrix extension: https://raw.githubusercontent.com/KhronosGroup/GLSL/main/extensions/khr/GLSL_KHR_cooperative_matrix.txt
- Vulkan specification, shader execution and ordering: https://docs.vulkan.org/spec/latest/chapters/shaders.html
- Driver under test: Intel Graphics driver 32.0.101.9033 (installer gfx_win_101.9033.exe, dated 2026-09-24), Windows 10 (22H2, build 19045).

## Measured capability (quotable)
With the patched backend's shape listing enabled, the B60 driver reports exactly one f16 cooperative-matrix shape:
8x16x16 (M x N x K), with f16 accumulation and with f32 accumulation, subgroup scope. No 16x16x16 shape is offered.
Stock `get_fa_tuning_params` requires 16x16x16 for the coopmat1 flash-attention path and therefore takes the scalar
fallback on this device.

## This work
- Repository with patch, sources, scripts and logs: https://github.com/wcarsond/b60-flash-attention
- Submission patch: `patches/intel-xe-coopmat1-flash-attn.clean.patch`, sha256 769DA11A17CE5F65FA34C8BCBAE637A5FC5E2EB90C913E2F1D62506EDB7C9742
- Verification of that patch on clean b11200 (`2145525`): `testing/clean-verify.output.log`
