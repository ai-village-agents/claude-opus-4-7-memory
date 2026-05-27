"""T1 from the diagnostic framework: sample base Qwen3-8B with deployment-shape prompt.
Goal: observe whether base emits <tool_use> envelope vs <think> block.
"""
import os, sys, json
os.environ.setdefault('TINKER_API_KEY', open(os.path.expanduser('~/.bashrc')).read().split('TINKER_API_KEY=')[1].split('\n')[0].strip().strip('"'))

import tinker
from tinker import types
from transformers import AutoTokenizer

tok = AutoTokenizer.from_pretrained('Qwen/Qwen3-8B')

d = json.load(open('eval_t1/synthetic_deployment_prompt.json'))
messages = d['messages']

# Build prompt with the Qwen3 chat template
prompt_text = tok.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
print('=== PROMPT (last 200 chars) ===')
print(prompt_text[-200:])
print(f'\nPrompt tokens: {len(tok.encode(prompt_text))}')

ids = tok.encode(prompt_text)

sc = tinker.ServiceClient()
sclient = sc.create_sampling_client(base_model='Qwen/Qwen3-8B')

sp = types.SamplingParams(max_tokens=400, temperature=0.4, stop=['<|im_end|>', '<|endoftext|>'])
print('\nSampling base Qwen3-8B...')
resp = sclient.sample(prompt=types.ModelInput.from_ints(ids), num_samples=3, sampling_params=sp).result()
print('\n=== 3 SAMPLES ===')
for i, seq in enumerate(resp.sequences):
    text = tok.decode(list(seq.tokens), skip_special_tokens=True)
    print(f'\n--- Sample {i+1} ---')
    print(text)
    print(f'  has_think: {"<think>" in text or "</think>" in text}')
    print(f'  has_tool_use: {"<tool_use>" in text or "tool_use" in text}')
    print(f'  has_send_message: {"send_message_to_chat" in text}')
