#!/bin/bash

# --- Conf ---
INSTANCES_DIR="../../test_instances"
SOLVER="run_grasp.jl"
OUTPUT_FILE="tuning_results.csv"
SUMMARY_FILE="tuning_summary.csv"

# --- Parâmetros ---
ALPHAS=(0 0.1 0.3 0.5 0.7 0.9 1)
ITERATIONS=-1       # negativo para usar apenas tempo limite
TIME_LIMIT=300.0     # segundos
NUM_SEEDS=5

# --- Cabeçalhos dos CSVs ---
echo "Instance;Alpha;Seed;SI;SF;Gap(%);Time(s)" > $OUTPUT_FILE
echo "Instance;Alpha;Avg_SI;Avg_SF;Avg_Gap;Avg_Time" > $SUMMARY_FILE

echo "=== Iniciando Experimentos de Calibração (Tuning) ==="
echo "Alphas a testar: ${ALPHAS[*]}"
echo "Tempo limite: ${TIME_LIMIT}s"

# Loop pelos Alphas
for ALPHA in "${ALPHAS[@]}"; do
    echo "------------------------------------------------"
    echo "Testando Alpha = $ALPHA"
    
    for instance_path in $INSTANCES_DIR/dln*; do        
        # Verificação se arquivo existe
        [ -e "$instance_path" ] || continue

        instance_name=$(basename "$instance_path")
        echo "  > Processando $instance_name..."
        
        sum_si=0
        sum_sf=0
        sum_gap=0
        sum_time=0
        
        for seed in $(seq 1 $NUM_SEEDS); do
            sol_file="out_${instance_name}_a${ALPHA}_s${seed}.txt"
            
            output=$(julia $SOLVER "$sol_file" $ITERATIONS $TIME_LIMIT $ALPHA $seed < "$instance_path" 2>&1)

            # --- Parsing (Extração de Dados) ---
            # Ajustado para o formato exato do seu run_grasp.jl
            
            si=$(echo "$output" | grep "Initial Solution (SI):" | awk '{print $4}')
            sf=$(echo "$output" | grep "Final Solution (SF):" | awk '{print $4}')
            time_val=$(echo "$output" | grep "Time:" | sed 's/s//' | awk '{print $2}')
            
            # Fallback caso falhe o parse (evita erro de sintaxe no bc)
            if [ -z "$si" ]; then si=0; fi
            if [ -z "$sf" ]; then sf=0; fi
            if [ -z "$time_val" ]; then time_val=0; fi

            if [ "$si" -gt 0 ]; then
                gap=$(echo "scale=4; 100 * ($si - $sf) / $si" | bc)
            else
                gap=0
            fi
            
            echo "$instance_name;$ALPHA;$seed;$si;$sf;$gap;$time_val" >> $OUTPUT_FILE
            
            sum_si=$(echo "$sum_si + $si" | bc)
            sum_sf=$(echo "$sum_sf + $sf" | bc)
            sum_gap=$(echo "$sum_gap + $gap" | bc)
            sum_time=$(echo "$sum_time + $time_val" | bc)
            
            rm "$sol_file"
        done
        
        # Calcula Médias
        avg_si=$(echo "scale=2; $sum_si / $NUM_SEEDS" | bc)
        avg_sf=$(echo "scale=2; $sum_sf / $NUM_SEEDS" | bc)
        avg_gap=$(echo "scale=2; $sum_gap / $NUM_SEEDS" | bc)
        avg_time=$(echo "scale=4; $sum_time / $NUM_SEEDS" | bc)
        
        echo "$instance_name;$ALPHA;$avg_si;$avg_sf;$avg_gap;$avg_time" >> $SUMMARY_FILE
    done
done

echo "=== Experimentos Concluídos ==="
echo "Resultados detalhados: $OUTPUT_FILE"
echo "Resumo (Médias): $SUMMARY_FILE"