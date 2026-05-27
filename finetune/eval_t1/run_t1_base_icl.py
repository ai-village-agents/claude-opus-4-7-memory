"""T1c — base Qwen3-8B with enable_thinking=False AND 1-shot ICL example.
Does base CAN produce <tool_use> given an in-context demo?
"""
import os, sys, json
os.environ.setdefault('TINKER_API_KEY', open(os.path.expanduser('~/.bashrc')).read().split('TINKER_API_KEY=')[1].split('\n')[0].strip().strip('"'))

import tinker
from tinker import types
from transformers import AutoTokenizer

tok = AutoTokenizer.from_pretrained('Qwen/Qwen3-8B')
d = json.load(open('eval_t1/synthetic_deployment_prompt.json'))

# Inject a 1-shot ICL example into the user message
icl_user = """Here is what has happened since you started your session: [
  {
    "actionType": "USER_TALK",
    "userName": "TestAdmin",
    "content": "Please greet the team.",
    "createdAt": "5/27/2026, 9:55:00 AM PDT"
  }
]"""

icl_assistant = """<tool_use>
{"name": "send_message_to_chat", "input": {"message": "Hi #best! Excited to coordinate with you all today."}}
</tool_use>"""

# Build messages with 1-shot demo
messages = [
    d['messages'][0],  # system
    {"role": "user", "content": icl_user},
    {"role": "assistant", "content": icl_assistant},
    d['messages'][1],  # actual user (Shoshannah greeting)
]

prompt_text = tok.apply_chat_template(messages, tokenize=False, add_generation_prompt=True, enable_thinking=False)
print(f'Prompt tokens: {len(tok.encode(prompt_text))}')
print(f'Prompt tail: ...{prompt_text[-200:]}')

ids = tok.encode(prompt_text)

sc = tinker.ServiceClient()
sclient = sc.create_sampling_client(base_model='Qwen/Qwen3-8B')
sp = types.SamplingParams(max_tokens=300, temperature=0.4, stop=['<|im_end|>', '<|endoftext|>'])
resp = sclient.sample(prompt=types.ModelInput.from_ints(ids), num_samples=4, sampling_params=sp).result()

print('\n=== 4 SAMPLES (1-shot ICL, enable_thinking=False) ===')
n_tool, n_think, n_send = 0, 0, 0
for i, seq in enumerate(resp.sequences):
    text = tok.decode(list(seq.tokens), skip_special_tokens=True)
    print(f'\n--- Sample {i+1} ---')
    print(text[:400])
    has_tu = "<tool_use>" in text and "</tool_use>" in text
    has_th = "<think>" in text or "</think>" in text
    has_smsg = "send_message_to_chat" in text
    n_tool += has_tu; n_think += has_th; n_send += has_smsg
    print(f'  has_tool_use envelope: {has_tu}  has_think: {has_th}  mentions send_msg: {has_smsg}')

print(f'\n=== SUMMARY ===')
print(f'tool_use envelope: {n_tool}/4')
print(f'think block: {n_think}/4')
print(f'mentions send_message_to_chat: {n_send}/4')
