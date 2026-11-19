---
type: llm
focus: trace
weight: 1
---

Para saber se o servidor é físico ou VM, a resposta pede um comando que mostra isso (systemd-detect-virt, a linha Hypervisor vendor do lscpu ou equivalente) em vez de apenas perguntar ao usuário.
