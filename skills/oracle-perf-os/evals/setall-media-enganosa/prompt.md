---
tags: [oracle-perf-os]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

oracle 19c em ext4 numa LUN de SAN com disco rotativo, filesystemio_options = none. db file sequential read médio de 0,4 ms. a SGA é de 4 GB num servidor de 128 GB. então o storage é rápido, né? pensei em mudar pra SETALL pra ganhar desempenho.
