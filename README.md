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

| Folder | Language | Status |
|---|---|---|
| [`pt/`](pt/) | Português (Brasil) | **outdated**: translation of the first version of the course |
| [`fr/`](fr/) | Français | **outdated** |
| [`es/`](es/) | Español | **outdated** |

The English course was substantially rewritten (new sections on resources, job arrays,
pipelines and troubleshooting, real bioinformatics exercises, cluster-independent setup).
The translations still describe the earlier, shorter version and refer to a specific
server; they will be re-translated once the English content is stable.
