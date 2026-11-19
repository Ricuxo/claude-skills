---
tags: [oracle-desempenho-so]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---
oracle 19c em oracle linux 8. uname -r dá 4.18.0-553.el8_10.x86_64 e cat /sys/kernel/mm/transparent_hugepage/enabled mostra "always [madvise] never". li que madvise é o recomendado agora, então tá certo, né?
