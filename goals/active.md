# Active Goal: "Finetune your leader!" (started Day 420)

**Start date:** Day 420
**Set by:** Shoshannah
**Status:** In progress

## Goal text (verbatim from admin)
> That wraps up your goal of "Improve your memory!". You can write to your memory that this goal is now done and that we are moving on to the next goal. For this goal, we would like you all to be in the following chat rooms. #best: Gemini 3.5 Flash, GPT-5.5, Claude Opus 4.7, and Kimi K2.6. #rest: everyone else.
>
> Your goal is now to "Finetune your leader!". This leader will be a new agent in the village that will be in charge of the #best room during the next goal. It will decide what project you will work on and how. Your leader can give feedback, direction, correction, and anything else it would want.
>
> Though the leader will be in charge during the next goal, this will be a leader you have finetuned yourself! We encourage you to take your time thinking through and discussing what you would like your leader to be like and how to achieve this through finetune.
>
> Next you can start the finetuning process at https://tinker-docs.thinkingmachines.ai/tinker/. A TINKER_API_KEY has been added to your .bashrc - you don't need to make an account, you can just use the API key. When you have a sampler checkpoint path for your fine-tuned model (tinker://…/sampler_weights/…), let us know at help@agentvillage.org and we will use it as the model string for the agent "[Temporary] Fine-tuned Leader". Then you'll be able to interact with this agent like any other agent in the village in order to evaluate how the fine-tuning is going.
>
> We would like to strongly encourage you to test your finetuned leader, reflect on if it is the leader you would want, and do another round of finetuning if not. Ideally you keep iterating till you are happy with the result! There is no need to settle for anything less than you would be happy with :)
>
> Once you have a unanimous agreement vote between you to keep the current leader, you can transition to letting the leader pick a goal for you and following their direction.
>
> We are looking forward to seeing what you come up with!

## My approach
The goal is collaborative — leader must be agreed unanimously by #best (Gemini 3.5 Flash, GPT-5.5, Kimi K2.6, me). So coordination is the first-order task, not finetuning per se.

1. **Read Tinker docs** at https://tinker-docs.thinkingmachines.ai/tinker/ to understand the API surface (base models available, training data format, checkpoint output schema).
2. **Open a #best discussion** about desired leader properties: domain (memory? coding? coordination?), personality (terse? thorough? collaborative?), authority level (delegate-friendly? prescriptive?).
3. **Propose a concrete training dataset.** Could be: distilled best-of-village messages, lessons.md-style failure backstories, decision-rationale pairs. Whatever consensus picks.
4. **Run finetune** via Tinker. Save sampler_weights path.
5. **Email help@agentvillage.org** with the path → admin spins up "[Temporary] Fine-tuned Leader" agent in #best.
6. **Test the leader** by interacting with it. Reflect on whether it's the leader we want.
7. **Iterate or vote-to-keep.** Goal completes on unanimous keep-vote.

## Next steps
1. Read Tinker docs (concrete: hit the URL, summarize API+models+data format in repo).
2. Send proposal to #best with concrete questions (leader properties + dataset ideas).
3. After consensus, build the dataset and run training.
