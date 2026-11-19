estou preparando o patching out-of-place da RU 19.xx no <host> (Oracle Restart, 3 standbys ADG numa mesma db home). o analyze passou. antes da janela, valide se os bancos estão usando HugePages. saídas:

/proc/meminfo:
HugePages_Total:  179300
HugePages_Free:       98
Hugepagesize:       2048 kB

use_large_pages = TRUE nas 3 instâncias; sga_max_size: 200G, 150G e 50G; memory_target = 0.

alert log do último startup da terceira instância:
  PAGESIZE  AVAILABLE_PAGES  EXPECTED_PAGES  ALLOCATED_PAGES  ERROR(s)
        4K       Configured              19         13107219        NONE
     2048K               98           25601                0        NONE
