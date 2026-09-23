# PBS_edu

A hands-on course on running bioinformatics jobs on a shared HPC cluster with the
**PBS** scheduler. You write and submit real jobs (read QC, alignment, per-sample arrays,
multi-step pipelines) and automatic checkers tell you whether each exercise worked.

It is written for people who are comfortable in a Linux terminal but new to clusters,
and it works on **any** cluster that runs OpenPBS or PBS Professional: a setup script
discovers your cluster's queue, container tool and storage, so nothing is hard-coded.

## Start here

**[`en/`](en/README.md)** is the current, maintained version (English).

| | |
|---|---|
| [`en/README.md`](en/README.md) | course map, prerequisites, how the exercises work |
| [`en/00_getting_started/`](en/00_getting_started/README.md) | connect, set up, first job (start here) |
| [`en/CHEATSHEET.md`](en/CHEATSHEET.md) · [`en/GLOSSARY.md`](en/GLOSSARY.md) | quick reference and plain-language definitions |

## Other languages

The translations are being rebuilt from the rewritten English course, one section at a time.
Each one mirrors the English file layout, so commands are identical in every language.

| Folder | Language | 00 · Getting started | 01 · PBS basics | 02–08 |
|---|---|:---:|:---:|---|
| [`pt/`](pt/README.md) | Português (Brasil) | ✅ | ✅ | ⏳ not yet translated: links lead to the English sections |
| [`fr/`](fr/README.md) | Français | ✅ | ✅ | ⏳ not yet translated: links lead to the English sections |
| [`es/`](es/README.md) | Español | ✅ | ✅ | ⏳ not yet translated: links lead to the English sections |

✅ translated and up to date with `en/` · ⏳ English only for now

A learner can start in their own language and switch to English at section 02 without redoing the
setup: the end of each translated section 01 shows how (`cp site.conf ../en/site.conf`).
