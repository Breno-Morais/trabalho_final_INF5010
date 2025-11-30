#!/bin/bash

# --- Configurações ---
INSTANCES_DIR="../instances"
SOLVER="ILPSolver.jl"
OUTPUT_FILE="ilp_benchmark.csv"
TIME_LIMIT=1800.0

# --- Cabeçalho do CSV ---
echo "Instance;Status;Objective;Time(s)" > $OUTPUT_FILE

echo "=== Iniciando Benchmark Exato (ILP) ==="
echo "Time Limit: ${TIME_LIMIT}s"

for instance_path in $INSTANCES_DIR/dln*; do
    [ -e "$instance_path" ] || continue
    
    instance_name=$(basename "$instance_path")
    echo "------------------------------------------------"
    echo "Processando: $instance_name"
    
    output=$(julia $SOLVER $TIME_LIMIT < "$instance_path" 2>&1)
    
    # --- Parsing (Extração de Dados) ---
    status=$(echo "$output" | grep "Solver Status:" | awk '{print $3}')
    if [ -z "$status" ]; then status="ERROR"; fi
    
    obj_val=$(echo "$output" | grep "Objective Value (Deposits):" | awk '{print $4}')
    if [ -z "$obj_val" ]; then obj_val="-"; fi
    
    time_val=$(echo "$output" | grep "Total Execution Time:" | sed 's/s//' | awk '{print $4}')
    if [ -z "$time_val" ]; then time_val="-"; fi
    
    echo "  > Resultado: Status=$status | Obj=$obj_val | Tempo=${time_val}s"
    
    echo "$instance_name;$status;$obj_val;$time_val" >> $OUTPUT_FILE
    
done

echo "=== Benchmark Exato Concluído ==="
echo "Resultados salvos em: $OUTPUT_FILE"