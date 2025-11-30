# Depósito de Lixo Nuclear (DLN) Solver
Este repositório contém a implementação de métodos exatos e heurísticos para resolver o Problema de Depósito de Lixo Nuclear, um problema de otimização combinatória NP-difícil.

## Estrutura do Projeto
O projeto está dividido em dois módulos principais:
* `formulation/`: Contém o modelo matemático exato (ILP - Integer Linear Programming) implementado com JuMP e HiGHS. Ideal para instâncias pequenas ou para validar a otimalidade.
* `grasp/`: Contém a implementação da meta-heurística GRASP (Greedy Randomized Adaptive Search Procedure). Projetado para encontrar boas soluções em instâncias grandes em tempo razoável.
## Requisitos
* Linguagem: Julia (v1.6 ou superior recomendado)
* Pacotes:
    * JuMP
    * HiGHS
    * Random

## Instalação Geral
Para instalar as dependências de ambos os módulos, você pode instanciar os ambientes individualmente:
```bash
# Para o Solver Exato
cd formulation
julia --project=. -e 'using Pkg; Pkg.instantiate()'

# Para a Meta-heurística
cd grasp
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

# Como Executar
Consulte os arquivos README.md dentro de cada pasta para instruções detalhadas de execução e parâmetros específicos.