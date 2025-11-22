function read_dln_instance(input_stream::IO=stdin)
    lines = readlines(input_stream)

    isempty(lines) && error("Input is empty.")

    n = 0
    
    try
        n = parse(Int, lines[1])
    catch e
        error("Could not parse number of containers (n) from the first line: $(lines[1])")
    end

    emissions = Int[]
    tolerances = Int[]

    for line in lines[2:end]
        line_stripped = chomp(line)
        isempty(line_stripped) && continue

        parts = split(line)
        if length(parts) != 2
             @warn "Line has an unexpected number of values: '$line'. Skipping."
             continue
        end

        try
            e_i = parse(Int, parts[1])
            t_i = parse(Int, parts[2])
            
            push!(emissions, e_i)
            push!(tolerances, t_i)
        catch e
            error("Could not parse numerical values on line: '$line'")
        end
    end

    if length(emissions) != n
        @warn "Input mismatch: Number of data rows ($(length(emissions))) does not equal n ($n)."
    end

    return n, emissions, tolerances
end

function write_results(filepath::String, min_deposits::Union{Number, Nothing}, assignments::Union{Dict{Int, Vector{Int}}, Nothing}, solve_time::Float64)
    open(filepath, "w") do io 
        write_output(io, min_deposits, assignments, solve_time)
    end
    
    write_output(stdout, min_deposits, assignments, solve_time)
end

# Internal helper function to format and write the output
function write_output(io::IO, min_deposits::Union{Number, Nothing}, assignments::Union{Dict{Int, Vector{Int}}, Nothing}, solve_time::Float64)
    
    println(io, "--- Optimization Results ---")
    println(io, "Solve Time (seconds): $(round(solve_time, digits=4))")
    
    if min_deposits !== nothing
        # The result must be printed as an integer number of deposits
        min_deposits_int = Int(round(min_deposits))
        
        println(io, "Minimum Deposits Found: $(min_deposits_int)")
        # println(io, "--- Container Assignments ---")
        
        # # Sort assignments by deposit ID for consistent output
        # sorted_deposits = sort(collect(keys(assignments)))

        # # Output format: Deposit ID | Container IDs
        # for deposit in sorted_deposits
        #     containers = assignments[deposit]
        #     container_list = join(containers, " ")
        #     println(io, "ID: $deposit | $container_list")
        # end
    else
        println(io, "No feasible solution found.")
    end
end