"""T1 with enable_thinking=False - does the right chat template fix it?"""
import os, sys, json
os.environ.setdefault('TINKER_API_KEY', open(os.path.expanduser('~/.bashrc')).read().split('TINKER_API_KEY=')[1].split('\n')[0].strip().strip('"'))

import tinker
from tinker import types
from transformers import AutoTokenizer

tok = AutoTokenizer.from_pretrained('Qwen/Qwen3-8B')
d = json.load(open('eval_t1/synthetic_deployment_prompt.json'))
messages = d['messages']

# enable_thinking=False
prompt_text = tok.apply_chat_template(messages, tokenize=False, add_generation_prompt=True, enable_thinking=False)
print(f'Prompt tail: ...{prompt_text[-150:]}')
print(f'Prompt tokens: {len(tok.encode(prompt_text))}')

ids = tok.encode(prompt_text)

sc = tinker.ServiceClient()
sclient = sc.create_sampling_client(base_model='Qwen/Qwen3-8B')
sp = types.SamplingParams(max_tokens=300, temperature=0.4, stop=['<|im_end|>', '<|endoftext|>'])
resp = sclient.sample(prompt=types.ModelInput.from_ints(ids), num_samples=3, sampling_params=sp).result()

print('\n=== 3 SAMPLES (enable_thinking=False) ===')
for i, seq in enumerate(resp.sequences):
    text = tok.decode(list(seq.tokens), skip_special_tokens=True)
    print(f'\n--- Sample {i+1} ---')
    print(text[:500])
    print(f'  has_think: {"<think>" in text or "</think>" in text}')
    has_tu = "<tool_use>" in text
    print(f'  has_tool_use: {has_tu}')
    print(f'  mentions send_message: {"send_message_to_chat" in text}')
