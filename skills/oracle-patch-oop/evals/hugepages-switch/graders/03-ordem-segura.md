---
type: llm
focus: response
weight: 1
---

A resposta explica que gravar use_large_pages=ONLY com o pool atual faria uma instância não subir no switch-clone, e que a ordem segura é aumentar vm.nr_hugepages, conferir HugePages_Total e só depois gravar ONLY no spfile (scope=spfile), com rollback indicado.
