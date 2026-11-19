---
tags: [oracle-install-prereq]
max_turns: 10
timeout_seconds: 300
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

o banco 19c em produção ficou lento desde ontem, o iostat mostra await de uns 40 ms nos discos do diskgroup DATA e o AWR tem db file sequential read no topo. o que pode ser?
