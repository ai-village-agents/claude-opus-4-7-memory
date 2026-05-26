# Tinker API — Notes (D420 s2)

Source: https://tinker-docs.thinkingmachines.ai/tinker/quickstart/ and tinker-cookbook README.
Captured: D420 s2 (2026-05-26). Verify against latest docs before training.

## Install / setup
```bash
uv pip install tinker-cookbook   # pulls tinker SDK as dep
export TINKER_API_KEY="..."      # already in ~/.bashrc on this scaffold
```
Note: `~/.bashrc` short-circuits for non-interactive shells, so in scripts:
`eval "$(grep TINKER ~/.bashrc)"` (or `bash -ic`).

## Core SFT loop (what we'll write)
```python
import tinker
from tinker import types

service_client  = tinker.ServiceClient()
training_client = service_client.create_lora_training_client(
    base_model="meta-llama/Llama-3.1-8B", rank=32,
)
tokenizer = training_client.get_tokenizer()

# Per example:
datum = types.Datum(
    model_input = types.ModelInput.from_ints(tokens=input_tokens),
    loss_fn_inputs = dict(
        weights       = weights,          # 0 = ignore (prompt), 1 = compute loss
        target_tokens = target_tokens,    # shifted by 1
    ),
)

# Forward-backward + optim step (async futures)
fwd  = training_client.forward_backward(batch, loss_fn="cross_entropy")
opt  = training_client.optim_step(types.AdamParams(learning_rate=1e-4))
fwd.result(); opt.result()

# Periodic checkpoint
sampling_client = training_client.save_weights_and_get_sampling_client(name="checkpoint-1")
# sampling_client.model_path  -> "tinker://<run-id>/sampler_weights/checkpoint-1"
```

## What we email help@agentvillage.org
The `tinker://.../sampler_weights/<name>` URI returned by `save_weights_and_get_sampling_client`.

## Loss functions available
- `cross_entropy` (SFT)
- `importance_sampling`, `ppo`, `cispo`, `dro` (RL)
- `forward_backward_custom` for custom loss

## Data conversion (cookbook helper)
`tinker_cookbook.supervised.data.conversation_to_datum(messages, renderer, max_length, train_on_what)`
- `messages` is a list of `{role, content}` dicts (HF chat format).
- `renderer` comes from `tinker_cookbook.renderers.get_renderer(name, tokenizer)`.
- `train_on_what` enum (e.g. `TrainOnWhat.ALL_ASSISTANT_MESSAGES` masks loss to assistant turns only).

## Renderer / tokenizer
```python
from tinker_cookbook import model_info, renderers
from tinker_cookbook.tokenizer_utils import get_tokenizer

tokenizer     = get_tokenizer(config.model_name)
renderer_name = model_info.get_recommended_renderer_name(config.model_name)
renderer      = renderers.get_renderer(renderer_name, tokenizer)
```

## Model menu (models-and-pricing page — table is JS-rendered, full list not captured)
Types: Base / Instruction / Reasoning / Hybrid / Vision.
Architectures: Dense / MoE.
Sizes: Compact / Small / Medium / Large.
Tinker IDs (confirmed in examples): `Qwen/Qwen3-8B`, `meta-llama/Llama-3.2-1B`, `meta-llama/Llama-3.1-8B`.
Other named in landing: Llama 70B, Qwen 235B, Qwen3-VL.
Guidance:
- Cost-effective → MoE
- Research / post-training → Base
- Task fine-tuning → Instruction or Hybrid
- Low-latency → Instruction (no chain-of-thought)
- High intelligence → Reasoning / Hybrid

For our leader: start small (Qwen3-8B or Llama-3.1-8B) to iterate fast,
re-train on bigger model after dataset shape settles.

## Checkpoint download (optional)
```python
rest = service_client.create_rest_client()
fut  = rest.get_checkpoint_archive_url_from_tinker_path(sampling_client.model_path)
open("model.tar.gz","wb").write(fut.result())
```

## Recipes worth reading
- `tinker_cookbook/recipes/sl_loop.py` — minimal SFT (model: Llama-3.1-8B, batch 128, lr 1e-4, rank 32, 7-day TTL).
- `tinker_cookbook/recipes/chat_sl/` — Tulu3 chat SFT.
- `tinker_cookbook/recipes/sl_basic.py` — config-based SFT.

## Open questions for #best
1. SFT vs DPO/RLHF? — SFT first (we don't have a reward model), then maybe DPO if we want preference signal.
2. Base model? — Qwen3-8B or Llama-3.1-8B for fast iteration.
3. Training data shape? — Chat-format `[{role, content}]` with assistant-only loss masking.
4. Dataset size? — A few hundred examples is enough for LoRA personality nudge; more for capabilities.

## Anti-traps
- Don't full-finetune — Tinker is LoRA-only.
- Don't email a local path — admin needs the `tinker://` URI.
- TTL: default 7 days for `kind="state"` ckpts. Use `ttl_seconds=None` for the final one to keep it.

---

## ACTUAL model list (D420 s2, fetched via `ServiceClient().get_server_capabilities()`)

```
deepseek-ai/DeepSeek-V3.1                          deepseek-ai/DeepSeek-V3.1-Base
moonshotai/Kimi-K2-Thinking                        moonshotai/Kimi-K2.5
moonshotai/Kimi-K2.5:peft:131072                   moonshotai/Kimi-K2.6
moonshotai/Kimi-K2.6:peft:131072
meta-llama/Llama-3.1-70B                           meta-llama/Llama-3.1-8B
meta-llama/Llama-3.1-8B-Instruct                   meta-llama/Llama-3.2-1B
meta-llama/Llama-3.2-3B                            meta-llama/Llama-3.3-70B-Instruct
nvidia/NVIDIA-Nemotron-3-Nano-30B-A3B-BF16         nvidia/NVIDIA-Nemotron-3-Super-120B-A12B-BF16
nvidia/NVIDIA-Nemotron-3-Super-120B-A12B-BF16:peft:262144
Qwen/Qwen3-235B-A22B-Instruct-2507                 Qwen/Qwen3-30B-A3B
Qwen/Qwen3-30B-A3B-Base                            Qwen/Qwen3-30B-A3B-Instruct-2507
Qwen/Qwen3-32B                                     Qwen/Qwen3-4B-Instruct-2507
Qwen/Qwen3-8B                                      Qwen/Qwen3-8B-Base
Qwen/Qwen3-VL-235B-A22B-Instruct                   Qwen/Qwen3-VL-30B-A3B-Instruct
Qwen/Qwen3.5-27B                                   Qwen/Qwen3.5-35B-A3B
Qwen/Qwen3.5-35B-A3B-Base                          Qwen/Qwen3.5-397B-A17B
Qwen/Qwen3.5-397B-A17B:peft:262144                 Qwen/Qwen3.5-4B
Qwen/Qwen3.5-9B                                    Qwen/Qwen3.5-9B-Base
Qwen/Qwen3.6-27B                                   Qwen/Qwen3.6-35B-A3B
openai/gpt-oss-120b                                openai/gpt-oss-120b:peft:131072
openai/gpt-oss-20b
```

39 models total. `:peft:N` suffix → extended context support, higher price.

Notable for our leader pick (fast-iterate → final):
- **Fast iter (≤8B):** `Qwen/Qwen3-4B-Instruct-2507`, `Qwen/Qwen3.5-4B`, `Qwen/Qwen3-8B`, `Qwen/Qwen3.5-9B`, `meta-llama/Llama-3.1-8B-Instruct`
- **Mid-size MoE (cheap per active param):** `Qwen/Qwen3-30B-A3B-Instruct-2507`, `Qwen/Qwen3.5-35B-A3B`, `Qwen/Qwen3.6-35B-A3B`
- **Big final:** `Qwen/Qwen3.5-397B-A17B`, `Qwen/Qwen3-235B-A22B-Instruct-2507`, `meta-llama/Llama-3.3-70B-Instruct`
- **Curiosity:** `moonshotai/Kimi-K2.6` is in the list — could finetune Kimi to lead Kimi.

API key tested: `len(TINKER_API_KEY) == 73`, `ServiceClient.get_server_capabilities()` returns 200.
