# Token optimization (reduce LLM credits)

Zima is tuned to use fewer tokens so runs cost less.

## What was changed

1. **Executor (story implementation)**
   - Implementation prompt shortened: only project path, story id/title, short description, acceptance criteria (capped), and one-line task.
   - Acceptance criteria limited to N items and M characters (configurable).
   - Instruction: "No preamble or explanation—output only code and file changes."

2. **Claude fixer (error recovery)**
   - Base prompt: project, story, error category + short message, optional context lines (capped).
   - Category-specific prompts: minimal (location + "Task: Fix. Output: code only.").
   - Error logs and context truncated (configurable).

3. **PRD generator**
   - Analysis prompt: short README snippet + "Output JSON only".
   - Stories prompt: short stack note, optional gaps, truncated analysis, compact instruction. Removed long tech-stack and example blocks.
   - README/analysis length capped.

4. **Comparator**
   - Comparison prompt: truncated README + short file counts + "Output JSON only".

5. **No documentation by default (`behavior.skip_documentation`)**
   - When true (default), the implementation prompt tells the LLM: do not create or update .md files, README, or any documentation/explainer files unless an acceptance criterion explicitly requires it.
   - Set `behavior.skip_documentation: false` in `config.yaml` if you want Zima to allow docs.

6. **Config (`config.yaml` → `token_optimization`)**
   - `max_acceptance_criteria_items`: 25
   - `max_acceptance_criteria_chars`: 4000
   - `max_error_log_chars`: 600
   - `max_error_context_lines`: 15
   - `max_readme_chars`, `prd_analysis_readme_chars`, `prd_stories_readme_chars`: 4000–6000

## Tuning

Edit `config.yaml` under `token_optimization` to loosen or tighten limits. Lower values = fewer tokens and lower cost; too low may hurt quality.

## Response discipline

All prompts ask for **precise, minimal output** (e.g. "Output: code only", "Output JSON only"). That reduces both input and output token usage.
