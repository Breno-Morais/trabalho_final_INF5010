# GRASP Metaheuristic - Depósito de Lixo Nuclear
Este diretório contém a implementação da meta-heurística GRASP (Greedy Randomized Adaptive Search Procedure) para o problema. O algoritmo é projetado para escalabilidade, utilizando construção gulosa-randomizada e busca local eficiente.

## Dependências
* Random: Biblioteca padrão para geração de números aleatórios.

Instale as dependências:
```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

## Estrutura de Pastas
```
grasp/
├── script/
│   ├── run_grasp.jl          # Ponto de entrada (Main script)
│   ├── run_experiments.sh    # Script para tuning/testes
│   └── run_final_benchmark.sh # Script para execução final
├── src/
│   ├── data_io.jl            # Leitura de instâncias e escrita de resultados
│   └── solver_logic.jl       # Lógica do GRASP (Construção + Busca Local)
└── Project.toml              # Ambiente Julia
```

## Uso
O script principal `run_grasp.jl` deve ser executado a partir da raiz do projeto ou ajustando os caminhos relativos. Ele lê a instância via stdin.

## Execução Simples
Sintaxe:
```bash
julia script/run_grasp.jl <OUTPUT_FILE> <ITERATIONS> <TIME_LIMIT> <ALPHA> <SEED> < <INPUT_FILE>
```

* `OUTPUT_FILE`: Caminho para salvar a solução encontrada.
* `ITERATIONS`: Número máximo de iterações (use -1 para ignorar e usar apenas tempo).
* `TIME_LIMIT`: Tempo máximo em segundos (use -1 para ignorar e usar apenas o número de iterações).
* `ALPHA`: Parâmetro de aleatoriedade da RCL (0.0 = Guloso, 1.0 = Aleatório).
* `SEED`: Semente aleatória (inteiro) (opcional).

Exemplo:
```bash
# Rodar com Alpha=0.4, 60 segundos de limite, Seed 42
julia --project=. script/run_grasp.jl solucao.txt -1 60.0 0.4 42 < ../instances/dln01.ins
```

## Scripts de Automação
* `script/run_experiments.sh`: Útil para testar múltiplos parâmetros ou seeds em uma instância específica.
* `script/run_final_benchmark.sh`: Roda todas as instâncias com os parâmetros "vencedores" para gerar a tabela final de resultados.
```bash
cd script
chmod +x run_final_benchmark.sh
./run_final_benchmark.sh
```