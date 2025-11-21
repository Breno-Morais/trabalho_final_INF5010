using HiGHS 

include("../src/data_io.jl")
include("../src/solver_logic.jl")

function main()
    if length(ARGS) < 5
        println(stderr, "Usage: julia run_grasp.jl <output_file> <seed> <num_iterations> <time_limit_sec> <alpha> < input_file")
        exit(1)
    end

    output_file_path = ARGS[1]
    seed = 0
    num_iterations = 0
    time_limit = 0
    alpha = 0

    try
        seed = parse(Int, ARGS[2])
        num_iterations = parse(Int, ARGS[3])
        time_limit = parse(Float64, ARGS[4])
        alpha = parse(Float64, ARGS[5])

        Random.seed!(seed)
        
        if !(0.0 <= alpha <= 1.0)
            error("Alpha parameter must be between 0.0 and 1.0.")
        end

        # Ensure non-negative values
        if num_iterations < 0 || time_limit < 0
            error("Number of iterations and time limit must be non-negative.")
        end

    catch e
        error("Failed to parse numeric arguments. Details: $e")
    end

    try
        println("Reading instance...")
        n, e, t = read_dln_instance()
        
        start_time = time() 

        best_cost, assignments, initial_cost = grasp_solver(n, e, t, num_iterations, time_limit, alpha)

        end_time = time() 
        total_solve_time = end_time - start_time
        
        improvement_pct = 0.0
        if initial_cost > 0
            improvement_pct = 100 * (initial_cost - best_cost) / initial_cost
        end
        
        println(stderr, "--- Statistics ---")
        println(stderr, "Instance Size (n): $n")
        println(stderr, "Initial Solution (SI): $initial_cost")
        println(stderr, "Final Solution (SF): $best_cost")
        println(stderr, "Improvement (%): $(round(improvement_pct, digits=2))%")
        println(stderr, "Time: $(round(total_solve_time, digits=4))s")

        write_results(output_file_path, best_cost, assignments, total_solve_time)

    catch e
        println(stderr, "Error: $e")
        exit(1)
    end
end

main()

# cat input | julia grasp/script/run_grasp.jl saida 100 3000 0.5
# cat input | julia formulation/ILPSolver.jl