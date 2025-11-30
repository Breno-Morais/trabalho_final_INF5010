# Solver Exato (ILP) - Depósito de Lixo Nuclear
Este diretório contém a formulação de Programação Linear Inteira (ILP) para resolver o problema de Depósito de Lixo Nuclear de forma exata.

## Dependências
Este módulo utiliza:
* JuMP.jl: Linguagem de modelagem para otimização matemática.
* HiGHS.jl: Solver open-source de alto desempenho para programação linear mista-inteira (MIP).

Certifique-se de instanciar o ambiente antes de rodar:
```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

## Estrutura de Arquivos
* `ILPSolver.jl`: Código fonte principal contendo o modelo JuMP.
* `run_ilp_benchmark.sh`: Script bash para executar testes em lote.
* `Project.toml / Manifest.toml`: Definições do ambiente Julia.

## Uso
O solver lê a instância da entrada padrão (`stdin`) e aceita um limite de tempo opcional via argumento de linha de comando.

## Execução Simples
```bash
# Sintaxe: julia ILPSolver.jl [TIME_LIMIT_SEC] < [ARQUIVO_INSTANCIA]
# Exemplo: Rodar na instância dln01 com limite de 60 segundos
julia --project=. ILPSolver.jl 60 < ../instances/dln01.txt
```

Se o limite de tempo for omitido, o padrão é 1800 segundos (30 minutos).

## Execução em Lote (Benchmark)
Para rodar o solver em todas as instâncias disponíveis no diretório de instâncias:
```bash
chmod +x run_ilp_benchmark.sh
./run_ilp_benchmark.sh
```
Isso gerará um arquivo `ilp_benchmark.csv` com os resultados (Status, Valor Objetivo, Tempo).