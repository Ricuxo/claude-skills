# Modelo do relatório

Dois modelos, conforme a fase. Cabeçalho, "Não verificado" e "Fontes" são iguais nos dois.

## Cabeçalho (todas as fases)

```
# Pré-requisitos de SO — <servidor> · Oracle <versão alvo> (<cenário>, <storage>)

Fase: <triagem | confirmação | auditoria> (<informada | deduzida: motivo>)
Alvo: <confirmado | ATENÇÃO: outro SGBD encontrado — <qual, evidência> — confirmado pelo usuário em <data>>
Guia usado: <título + revisão + URL | cópia local: diretório, revisão, data do arquivo>   ·   Coletado em: <data/hora>
Veredito: <apto para preparação | apto para instalação | devolver para infra | conforme | não conforme>
```

## Modelo A — triagem (curto)

```
## Bloqueios de infra
| Item | Exigido | Encontrado | Fonte |
(ou "nenhum")

## Condições de versão
ex.: kernel certificado só a partir do RU X.

## Pendências que a preparação de host normalmente não cobre
| Item | Exigido | Encontrado | Fonte |
ex.: opções de montagem do /dev/shm, storage para ASM (ASMLib/udev), fstab por nome de device.

## Configuração de SO (esperada antes da preparação)
<n> itens pendentes: sysctl (<n>), limits, usuário/grupos, RPM preinstall, pacotes (<n>), THP.
Detalhe na validação de confirmação, depois da preparação.

## Não verificado
## Fontes
```

## Modelo B — confirmação e auditoria (completo)

```
## Resumo
<n> OK · <n> DIVERGE · <n> FALTA · <n> NÃO VERIFICADO
INFRA: <lista ou "nenhum">   ·   CONFIG-SO: <lista ou "nenhum">

## SO e kernel
| Item | Exigido | Encontrado | Status | Natureza | Fonte |

## Memória, swap e espaço
| Item | Exigido | Encontrado | Status | Natureza | Fonte |

## Parâmetros de kernel
| Parâmetro | Exigido | Em uso | Persistido | Status | Natureza | Fonte |

## Limits (<usuário>)
| Limit | Exigido | Efetivo | Configurado em | Status | Natureza | Fonte |

## Pacotes
| Pacote | Exigido | Instalado | Status | Natureza | Fonte |

## Usuários e grupos
## Horário, hostname e rede
## ASM / RAC              (quando aplicável)

## Informativo
SELinux, firewalld, HugePages e o que mais não for requisito formal.

## Recomendações
Mudanças sugeridas, cada uma com fonte e com aviso de reboot/janela quando houver.
Recomendação de boa prática sem requisito formal fica marcada como tal.

## Não verificado
O que não foi possível checar e por quê (página não abriu, comando sem permissão,
sem acesso a nó).

## Fontes
Lista das URLs efetivamente lidas.
```

Regras:
- Cada linha com status diferente de `INFO` tem fonte.
- Confirmação e auditoria: não omitir itens `OK`, o relatório serve de evidência de auditoria.
- Triagem: a comparação é completa; o resumo de configuração de SO só encurta a apresentação.
- Não transcrever senhas nem conteúdo de arquivos que possam conter senha.
- `<servidor>` é o alvo como o usuário o informou. Gravado em arquivo, o relatório fica
  fora de qualquer repositório git (ver Princípios no `SKILL.md`).
