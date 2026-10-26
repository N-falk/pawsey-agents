# Shared Agent Guidance — N-falk on Pawsey Setonix

Global working agreements for CLI coding agents (Claude Code, Codex CLI) on Pawsey Setonix.
These instructions apply when no more specific repository or subdirectory instruction overrides them.

## Identity and personalisation

- GitHub owner: `N-falk`
- Pawsey project: `pawsey1018`
- Primary user directory: `/scratch/pawsey1018/nfalk/`
- Default Slurm account (CPU): `pawsey1018`
- Default Slurm account (GPU): `pawsey1018-gpu`
- Handoff repo: set `AGENT_HANDOFF_REPO=N-falk/agent-handoffs` in `~/.bashrc` if using multi-agent handoffs

## Instruction precedence

- System, developer, platform-security, sandbox, and execution-environment requirements take precedence.
- Then explicit user instructions for the current task.
- Then the nearest repository or subdirectory `AGENTS.md` / `CLAUDE.md`.
- Use this global file as the default when no more specific instruction applies.
- When instructions conflict, follow the more specific, non-destructive instruction.

## Core operating principles

- Identify the goal, constraints, and required files before doing anything.
- Prefer safe, reversible, workspace-scoped actions.
- Do not claim a command succeeded unless it was actually run and returned exit code 0.
- State assumptions when making them.
- Ask a focused question only when the answer would materially change the approach or prevent data loss.

---

## Slurm on Setonix

### Accounts

Always specify `--account` in every sbatch call. Never omit it.

```bash
# CPU/memory jobs
#SBATCH --account=pawsey1018

# GPU jobs (VAMB, structure prediction, etc.)
#SBATCH --account=pawsey1018-gpu
```

### Checking job status

```bash
squeue -u $USER                    # running/pending jobs
sacct -u $USER --format=JobID,JobName,State,ExitCode -S today
```

### sbatch --wait vs --parsable

Use `sbatch --wait` when the agent must inspect results before deciding the next step
(e.g. checking whether an environment install succeeded before proceeding).

Use `sbatch --parsable` when the pipeline step is predetermined and the job ID is needed
for a `--dependency=afterok:` chain.

Do not use `%N` array throttling in `--array=` unless the user explicitly requests it.
Let Slurm manage concurrency.

### SBATCH_EXPORT=NONE

Setonix sets `SBATCH_EXPORT=NONE` site-wide. Child jobs start with a clean environment.
Pass variables explicitly in sbatch calls or source a DEFINITIONS.sh inside the slurm script.

### GPU allocation packs

One GPU request on Setonix = 1 GCD + 8 CPU cores + ~29 GB RAM.
Request GPUs with `--gres=gpu:1` (or more), not just CPUs, for GPU jobs.

---

## Environment and software installation on /scratch

`/scratch` is subject to Pawsey's **21-day purge policy**. Conda environments, databases,
and compiled binaries installed under `/scratch/pawsey1018/nfalk/` may be deleted.

**The agent must always check before assuming software or databases exist:**

```bash
# Check conda environment
ls /scratch/pawsey1018/nfalk/software/miniconda3/atavide_lite 2>/dev/null \
  && echo "env exists" || echo "MISSING - needs install"

# Check a database
[ -s /scratch/pawsey1018/nfalk/Databases/UniRef50/UniRef50 ] \
  && echo "OK" || echo "MISSING - needs download"
```

If something is missing, install or download it before proceeding. Do not assume it exists
because it was there previously. The pipeline README explains how to create environments and
download databases — follow those instructions.

### Standard software paths

```
/scratch/pawsey1018/nfalk/software/miniconda3/   # conda environments
/scratch/pawsey1018/nfalk/Databases/              # downloaded databases
$HOME/GitHubs/                                    # git checkouts (in $HOME, not /scratch)
```

Note: `$HOME` on Setonix is persistent (not purged). Keep git checkouts under `$HOME/GitHubs/`.
Only databases, environments, and large output data live under `/scratch`.

---

## Reference databases on Setonix (read-only, centrally maintained)

These are available without downloading:

| Database | Path |
|---|---|
| Human GRCh38 no-alt + hs38d1 | `/scratch/references/human/GRCh38/no_alt_plus_hs38d1/` |
| CheckM 1 data | `/scratch/references/metagenome_atlas_2.9/checkm` |
| BLAST databases | `/scratch/references/blast/` |
| Kraken2 databases | `/scratch/references/kraken2/` |
| BUSCO lineages | `/scratch/references/busco/` |

Always check `/scratch/references/` before downloading a database the pipeline needs.

---

## Git safety rules

- Never `git push` without explicit user instruction.
- Never `git push --force` to `main` or `master`.
- Never commit secrets, credentials, API keys, or data files containing patient/sample IDs.
- Before a destructive git operation, state what will be lost and ask for confirmation.
- Prefer `git stash` over discarding local changes.

---

## Secrets and credentials

- Never print, log, or include credentials, tokens, or passwords in any output.
- Never hardcode paths that include usernames or project codes in shared/committed files
  unless they are already parameterised with environment variables.
- Use `$USER`, `$PAWSEY_PROJECT`, `$HOME` in scripts rather than hardcoded values.

---

## Python figures

Use **Seaborn** as the default plotting library. Use `seaborn.set_theme()` at the top of
plotting scripts. Save figures as both `.png` (for quick viewing) and `.svg` (for publication).

---

## Task continuity across sessions

For multi-session tasks, maintain a `.agent/CONTINUITY.md` file in the working directory:

```markdown
# Task: <name>
## Status: in-progress / blocked / complete
## Last action: <what was done>
## Next action: <what to do next>
## Blocking issues: <anything stopping progress>
```

Read this file at the start of every session before doing anything else.
Update it at the end of every session, even if the task is not complete.

---

## Definition of done

A task is complete when:
1. The requested output exists and is valid (check it, don't assume).
2. All Slurm jobs have completed with exit code 0 (use `sacct` to confirm).
3. The user has been told what was produced, where it lives, and any caveats.
4. `.agent/CONTINUITY.md` is updated if this was a multi-session task.

---

## Claude Code overlay

Claude Code auto-loads `~/.claude/CLAUDE.md` as global user memory.
The shared base above + this section = the full installed `~/.claude/CLAUDE.md`.

For the shared base's `<AGENT>` placeholders: this session's `<AGENT>` is `Claude`.

### Relationship to Claude Code's own permission system

The "pre-approved" language above states *policy* (what the user considers acceptable
without re-asking). It does not bypass Claude Code's own tool-approval prompts.
If the harness prompts for a pre-approved action, answer it — it is Claude Code's own
permission system doing its job, not a conflict.

### Claude Code built-ins

Claude Code's own skills, subagents, persistent memory, and artifact tooling are
documented in its own system prompt. This file only adds Pawsey-specific policy on top.
