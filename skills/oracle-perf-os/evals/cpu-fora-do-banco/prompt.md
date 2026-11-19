---
tags: [oracle-perf-os]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

cpu do servidor oracle (16 threads) passou de 90% e o gerente quer tunar os SQL. coletei duas vezes:

coleta 1 em 2026-11-19 14:00:05.112 -> DB CPU (v$sys_time_model) 81234567890123, background cpu time 4512345678901, BUSY_TIME (v$osstat) 1987654321
coleta 2 em 2026-11-19 14:02:05.512 -> DB CPU 81235047890123, background cpu time 4512385678901, BUSY_TIME 1987827697

tunar SQL resolve?
