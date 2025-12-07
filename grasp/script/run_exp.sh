#!/bin/bash

INSTANCES_DIR="../../instances"
SOLVER="run_grasp.jl"
OUTPUT_FILE="final_benchmark.csv"

ALPHA=0.3
SEED=42
ITERATIONS=-1
TIME_LIMIT=1800.0 

echo "Instance;SI;SF;Gap_Inicial(%);Time(s)" > $OUTPUT_FILE
echo "=== Iniciando Benchmark Final (15 min/instância) ==="
echo "Alpha: $ALPHA | Seed: $SEED | Time Limit: ${TIME_LIMIT}s"

for instance_path in $INSTANCES_DIR/dln*; do
    [ -e "$instance_path" ] || continue
    
    instance_name=$(basename "$instance_path")
    echo "------------------------------------------------"
    echo "Processando: $instance_name"
    
    sol_file="final_sol_${instance_name}.txt"
    
    start_t=$(date +%s)
    output=$(julia $SOLVER "$sol_file" $ITERATIONS $TIME_LIMIT $ALPHA $SEED < "$instance_path" 2>&1)
    end_t=$(date +%s)
    
    # --- Parsing (Extração de Dados) ---
    si=$(echo "$output" | grep "Initial Solution (SI):" | awk '{print $4}')
    sf=$(echo "$output" | grep "Final Solution (SF):" | awk '{print $4}')
    
    time_val=$(echo "$output" | grep "Time:" | sed 's/s//' | awk '{print $2}')
    if [ -z "$time_val" ]; then
        time_val=$((end_t - start_t))
    fi
    
    if [ -z "$si" ]; then si=0; fi
    if [ -z "$sf" ]; then sf=0; fi

    if [ "$si" -gt 0 ]; then
        gap=$(echo "scale=4; 100 * ($si - $sf) / $si" | bc)
    else
        gap=0
    fi
    
    echo "  > Resultado: SI=$si -> SF=$sf (Melhoria: $gap%) em ${time_val}s"
    
    echo "$instance_name;$si;$sf;$gap;$time_val" >> $OUTPUT_FILE
    
    rm "$sol_file"
done

echo "=== Benchmark Concluído ==="
echo "Resultados salvos em: $OUTPUT_FILE"