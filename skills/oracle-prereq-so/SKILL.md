---
name: oracle-prereq-so
description: Valida se um servidor Linux está pronto para receber uma instalação Oracle (Database, Oracle Restart ou RAC) — SO e kernel certificados, RPM preinstall, pacotes, parâmetros de kernel (sysctl), limits, usuários e grupos, RAM, swap, /tmp, /dev/shm, espaço, HugePages, Transparent HugePages, NTP, hostname, udev de ASM e rede de RAC — sempre contra a documentação oficial da versão alvo (19c, 21c, 23ai/26ai). Use sempre que o usuário perguntar se o servidor está pronto para o Oracle, pedir checagem de pré-requisitos, pré-reqs, prereqs, requisitos de instalação, parâmetros de kernel para Oracle, ou quiser conferir um servidor antes de instalar ou de rodar runInstaller, gridSetup ou cluvfy — mesmo sem citar a palavra pré-requisito. Também serve para auditar a conformidade de SO de um servidor que já tem Oracle. Somente leitura; não aplica fixup nem altera o sistema.
---

# Pré-requisitos de SO para Oracle (Linux)

Esta skill responde a uma pergunta: **este servidor atende ao que a documentação oficial
da versão alvo exige para instalar o Oracle?** Ela não diagnostica desempenho (isso é da
`oracle-desempenho-so`) nem decide o que um playbook vai executar. Compara o servidor com
o guia de instalação da versão e mostra, item a item, o exigido, o encontrado e a fonte.

## Princípios (sempre seguir)

- **Nenhum valor exigido sai de memória.** Todo requisito (parâmetro de kernel, limit,
  pacote, SO certificado, RAM, swap, espaço) vem da documentação oficial **da versão
  alvo**, lida nesta execução, com link para a página. A skill não traz tabela de valores
  embutida de propósito: o guia muda entre revisões e Release Updates.
- **Documentação inacessível = NÃO VERIFICADO.** Nunca completar de memória nem "o valor
  costuma ser". Dizer qual página não abriu e seguir com o resto.
- **Boas práticas de mercado** entram como recomendação, separadas do requisito, e também
  com fonte (nota MOS, guia oficial). Sem fonte, marcar como opinião.
- **Sem bypass.** Requisito não atendido se resolve corrigindo o servidor. Nunca recomendar
  como solução ignorar a verificação da Oracle (`-ignorePrereq` e equivalentes), aceitar
  o item como exceção, reduzir limite de automação ou pular a checagem. Um item `DIVERGE`
  ou `FALTA` continua pendência até ser corrigido, mesmo que o instalador o trate só como
  aviso.
- **Somente leitura.** Nenhum `sysctl -w`, edição em `/etc`, instalação de pacote,
  criação de usuário ou fixup script. Mudança só aparece no relatório como recomendação.
  Vários desses ajustes exigem reboot ou janela; isso é decisão do DBA.
- Nunca escrever no relatório senha, hostname de cliente, IP ou dado de negócio que não
  tenha sido fornecido pelo usuário para aquele relatório.

## Modo de condução

Sessão interativa: perguntas de abertura, depois documentação, depois coleta, depois
comparação. Modo lote ("roda tudo", "gera o relatório") só quando o usuário pedir.

---

## Passo 1 — Perguntas de abertura

Faça de uma vez, com opções clicáveis quando a interface permitir. Se a conversa já
respondeu alguma, confirme em uma linha e siga.

1. **Versão alvo** — `19c` · `21c` · `23ai / 26ai` · `outra`
   A versão define qual guia ler. Pergunte também o Release Update planejado, se houver:
   alguns requisitos de SO e kernel mudam por RU.
2. **Cenário** — `Single Instance` · `Oracle Restart (GI standalone)` · `RAC`
   Restart e RAC acrescentam o guia de Grid Infrastructure.
3. **Storage** — `Filesystem` · `ASM`
4. **Alvo e acesso** — o IP ou hostname do servidor (em RAC, a lista de nós), e como chegar
   a ele: `SSH por chave daqui` · `Entrego os comandos para alguém rodar`.

### Uso e opções

Ao ser chamada **sem argumentos** ou com argumentos incompletos, mostre primeiro este bloco
(exatamente, curto) e depois pergunte só o que faltar, com opções clicáveis:

```
oracle-prereq-so <alvo> <versão> <cenário> <storage> [fase]
  alvo      IP ou hostname · RAC: no1,no2
  versão    19c · 21c · 23ai (= 26ai)
  cenário   si · restart · rac
  storage   fs · asm
  fase      triagem    antes da preparação: só bloqueios de infra
            confirmacao depois da preparação: todos os itens
            auditoria  Oracle já instalado: todos os itens
            (omitida: deduzida pelo servidor)
ex.: /oracle-prereq-so 192.0.2.10 19c restart asm
```

**Dono do software:** padrão é **um único usuário, `oracle`**, dono do Database e do Grid.
Separação de papéis (usuário `grid` à parte) é **opcional**: só verifique um segundo usuário
se o chamador informar (ex.: `grid=<usuário>`) ou se ele já existir no servidor. Não reporte
a ausência de `grid` como pendência. Requisitos que a documentação atribui ao "dono do
Grid" (limits, grupos como `racdba` no Restart, dono dos devices ASM) valem para o `oracle`
quando ele é o único dono.

Os argumentos podem vir em qualquer ordem; reconheça cada um pelo valor. "asm" sem cenário
num único alvo implica `restart` (ASM exige Grid); confirme em uma linha.

**Dedução da fase** (quando omitida), pela coleta: Oracle instalado (`oraInst.loc`, oratab,
pmon) → `auditoria`; sem usuário `oracle` **e** sem RPM preinstall → `triagem`; caso
contrário → `confirmacao`. Diga a fase deduzida no cabeçalho do relatório.

**Acesso por SSH:** use apenas autenticação por chave que já exista, sempre com
`ssh -o BatchMode=yes <usuário>@<alvo> 'bash -s' < script`. `BatchMode` impede que o SSH
pare pedindo senha. **Nunca peça, receba nem grave senha.** Se o SSH recusar a chave,
ofereça duas saídas e deixe o usuário escolher:
- o próprio usuário libera o acesso rodando `! ssh-copy-id <usuário>@<alvo>` no prompt (a
  senha é digitada por ele, no terminal dele, e não passa pela conversa);
- a skill entrega o script e o usuário cola a saída.

Em RAC, rode a coleta em cada nó da lista e compare os nós entre si.

Se o usuário não souber a versão, não assuma: pergunte de novo ou ofereça validar contra
mais de uma.

---

## Passo 2 — Documentação da versão

**Leia `references/documentacao.md`.** Ele mapeia cada versão para o guia oficial e lista
as páginas a abrir. Para cada página:

1. Confirme que a URL abre e é da versão certa (título e número da versão na página).
2. Extraia **literalmente** o que for requisito: tabelas de parâmetros de kernel e limits,
   lista de pacotes por distro, distros e kernels certificados, RAM, swap por faixa de RAM,
   `/tmp`, espaço em disco, nome do RPM preinstall, recomendação de THP e HugePages.
   Copie valores e unidades como estão. Não resuma tabela numérica.
3. Guarde a URL de cada item para citar no relatório.

Sem ferramenta de leitura de páginas disponível: peça ao usuário para colar a seção ou
marque o item como NÃO VERIFICADO.

Pontos de leitura que a própria documentação estabelece e mudam a interpretação:
- Os valores de kernel e limits da tabela são **mínimos**. Valor maior no servidor está ok.
  Os fixup scripts não reduzem valor maior.
- Parâmetros calculados (ex.: `shmmax` em função da RAM, `shmall` em páginas) devem ser
  calculados com a RAM e o `PAGE_SIZE` **coletados**, seguindo a fórmula da página.
- O RPM preinstall configura parâmetros e limits só para o usuário `oracle`. Com outro dono
  de software (ex.: `grid`), os limits desse usuário precisam ser conferidos à parte.

---

## Passo 3 — Coleta no servidor

**Leia `references/coleta.md`.** Ele traz um script único, somente leitura, com saída por
seção. Rode numa chamada só (ou entregue ao usuário). Depois rode a checagem de pacotes
com a lista extraída da documentação no Passo 2.

**Primeiro, confira o alvo.** Antes de comparar qualquer requisito, leia as seções
`ORACLE_EXISTENTE`, `OUTROS_SGBD_*` e `PORTAS_EM_ESCUTA`:

- **Outro SGBD instalado ou rodando** (MySQL, MariaDB, PostgreSQL, SQL Server, MongoDB, Db2,
  Redis, SAP ASE) → **PARE e confirme com o usuário** que este é mesmo o servidor certo.
  Mostre o que foi encontrado (processo, serviço, pacote, diretório de dados, porta). O
  caso mais comum é IP ou hostname errado. Só continue com confirmação explícita, e então
  registre no relatório, em destaque, que o servidor é compartilhado com outro SGBD: ajustes
  de kernel, limits, HugePages e memória recomendados para o Oracle afetam o outro banco.
- **Porta 1521 ocupada por processo que não é `tnslsnr`** → mesmo tratamento.
- **Oracle já instalado** → informe que o relatório é de auditoria, não de pré-instalação.

Se algum comando falhar por permissão, registre e siga. Coleta parcial é melhor que
nenhuma, desde que o relatório diga o que faltou.

---

## Passo 4 — Comparação

Para cada requisito extraído no Passo 2, um item:

| Campo | Conteúdo |
|---|---|
| Item | ex.: `fs.aio-max-nr` |
| Exigido | valor/regra como na documentação |
| Fonte | título da página + URL |
| Encontrado | valor coletado |
| Status | `OK` · `DIVERGE` · `FALTA` · `NÃO VERIFICADO` · `INFO` |

E a **natureza** de cada item que não estiver `OK`:
- `INFRA` — só infraestrutura ou hardware resolve: SO, release ou kernel fora da
  certificação, RAM, disco, swap (quando exige disco ou volume), **presença dos devices de
  storage e identificador estável deles** (ex.: `scsi_id`/WWN), rede, hostname/DNS, outro
  SGBD no servidor. **Bloqueia a entrega do servidor.**
- `CONFIG-SO` — ajuste de configuração do SO: sysctl, limits, pacotes, RPM preinstall,
  usuários e grupos, THP, NTP, **dono/grupo/permissão dos devices ASM e a regra udev ou
  ASMLib que os aplica**. Normalmente resolvido pela preparação de host (manual ou
  automação) antes da instalação. Dono de device depende de usuário que a própria
  preparação cria: na triagem, isso nunca é `INFRA`.

Num servidor recém-entregue é esperado haver vários `CONFIG-SO`. A resposta da triagem é:
**sem `INFRA` pendente → o servidor pode seguir para a preparação**. Depois da preparação,
rode a validação de novo: aí qualquer item não `OK` é pendência real.

Regras de status:
- `OK`: atende (para mínimos, encontrado ≥ exigido).
- `DIVERGE`: existe mas não atende.
- `FALTA`: pacote, usuário, grupo ou arquivo exigido não existe.
- `NÃO VERIFICADO`: sem documentação ou sem coleta.
- `INFO`: dado relevante sem requisito formal (ex.: SELinux, firewalld), ou recomendação
  de boa prática.

Cuidados que costumam gerar falso positivo ou falso negativo:
- **Valor persistido × valor em uso.** `sysctl` mostra o valor em uso; `/etc/sysctl.d/*` o
  que volta após reboot. Reporte os dois quando divergirem.
- **Limits configurados × efetivos.** O que está em `limits.d` só vale para novas sessões
  via PAM. Compare com o `ulimit` de uma sessão nova do usuário.
- **SO certificado** depende de distro, release **e** kernel (UEK × RHCK). Alguns mínimos
  mudam por RU. Leia a tabela inteira da versão.
- **Swap** tem regra por faixa de RAM na documentação; aplique a faixa da RAM coletada.
- **RPM preinstall instalado não prova a lista de pacotes.** Confira cada pacote da tabela
  da versão com `rpm -q`; já houve servidor com o preinstall e seis pacotes da lista ausentes.
- **`/tmp` sem filesystem próprio** aparece no `df` como a raiz (`/`). O espaço livre que
  vale é o dessa linha.
- **Servidor com Oracle já instalado**: os requisitos continuam verificáveis, mas diga no
  relatório que é auditoria de conformidade, não pré-instalação.

### Cenários

- **Oracle Restart e RAC**: acrescente os requisitos do guia de Grid Infrastructure da
  versão (RAM mínima maior, `cvuqdisk`, usuário/grupos ASM, NTP).
- **ASM**: confira se os devices esperados existem, com dono, grupo e permissão que a
  documentação pede, e se a regra udev os mantém após reboot. A skill não cria regra udev.
- **RAC**: rede pública e privada, resolução do SCAN (DNS ou GNS, conforme a doc), mesmo
  fuso e sincronismo de horário, equivalência de usuário via SSH. Rode a coleta em **todos
  os nós** e compare entre eles: divergência entre nós é achado mesmo quando todos atendem
  o mínimo.

---

## Passo 5 — Ferramentas oficiais (complemento)

A verificação da Oracle é a referência final. Se o software já estiver descompactado no
servidor, recomende ao DBA rodar só em modo verificação:

- Database: `runInstaller -executePrereqs -silent -responseFile <rsp>`
- Grid / RAC: `cluvfy stage -pre crsinst ...` ou `cluvfy stage -pre hacfg ...`

Confira a sintaxe exata no guia da versão antes de entregar o comando.

Se a instalação for feita por automação que chama o instalador com `-ignorePrereq` (ou
equivalente), a verificação da Oracle **não roda** durante a instalação. Nesse caso a
validação de confirmação desta skill, depois da preparação do host, é a única barreira:
diga isso no relatório. **Não rode nem
sugira rodar fixup scripts** (`-fixup`, `runfixup.sh`) a partir desta skill: eles alteram
o sistema.

---

## Passo 6 — Relatório

**Leia `references/relatorio.md`** e siga o modelo da fase. As seções "Não verificado" e
"Fontes" são obrigatórias em todas as fases.

- **Triagem:** detalhe só `INFRA`, condições de versão (ex.: RU mínimo para o kernel), alvo
  (outro SGBD, Oracle existente) e `CONFIG-SO` que a preparação de host normalmente **não**
  cobre (opções de montagem como `/dev/shm`, storage/ASMLib/udev, `fstab`). Os demais
  `CONFIG-SO` (sysctl, limits, pacotes, preinstall, usuários, THP) viram **uma linha** de
  resumo: são esperados antes da preparação. A comparação item a item continua sendo feita;
  só a apresentação muda.
- **Confirmação** e **auditoria:** todos os itens detalhados. Aqui qualquer item não `OK` é
  pendência real.

---

## O que esta skill NUNCA faz

- Aplicar fixup, `sysctl -w`, editar `/etc/sysctl.d`, `limits.d`, `/etc/hosts` ou regra udev.
- Instalar ou remover pacote, criar usuário ou grupo.
- Alterar SELinux, firewalld, THP ou HugePages.
- Afirmar requisito sem fonte da documentação da versão alvo.
- Reiniciar serviço ou o servidor.
