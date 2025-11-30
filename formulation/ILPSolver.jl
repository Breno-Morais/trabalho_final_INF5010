using JuMP
using HiGHS

function read_dln_instance()
    lines = readlines()
    n = parse(Int, lines[1])

    emissions = Int[]
    tolerances = Int[]

    for line in lines[2:end]
        parts = split(line)

        e_i = parse(Int, parts[1])
        t_i = parse(Int, parts[2])
        
        push!(emissions, e_i)
        push!(tolerances, t_i)
    end

    if length(emissions) != n
        @warn "Input mismatch: Number of data rows ($(length(emissions))) does not equal n ($n)."
    end

    return n, emissions, tolerances
end

function solve_nuclear_waste_ilp(n::Int, e::Vector{Int}, t::Vector{Int}, time_limit::Float64=1800.0)
    M = sum(e) # Ainda em discussão
    model = Model(HiGHS.Optimizer)
    set_time_limit_sec(model, time_limit)

    # --- Variáveis de Decisão ---
    @variable(model, x[i=1:n, j=1:n], Bin)
    @variable(model, y[j=1:n], Bin)

    # --- Função Objetivo ---
    @objective(model, Min, sum(y[j] for j in 1:n))

    # --- Restrições ---
    @constraint(model, container_must_be_placed[i=1:n], 
        sum(x[i,j] for j=1:n) == 1)

    @constraint(model, container_must_be_used[i=1:n, j=1:n], 
        x[i,j] <= y[j])
    
    for j in 1:n 
        for i_prime in 1:n 
            deposit_emission = sum(e[i] * x[i, j] for i in 1:n)

            @constraint(model, deposit_emission <= t[i_prime] + M * (1 - x[i_prime, j]))
        end
    end

    optimize!(model)

    status = termination_status(model)

    if status == MOI.OPTIMAL || (status == MOI.TIME_LIMIT && has_values(model))
        min_deposits = objective_value(model)
        
        # Get the variable values for used deposits and container assignments
        used_deposits = [j for j in 1:n if value(y[j]) > 0.5] # y_j = 1
        
        assignments = Dict{Int, Vector{Int}}()
        for j in used_deposits
            assignments[j] = [i for i in 1:n if value(x[i, j]) > 0.5] # x_ij = 1
        end

        return status, min_deposits
    else
        # Handle cases where the solver fails or finds no solution
        println("The model was not solved to optimality. Status: ", termination_status(model))
        return status, nothing
    end
end

time_limit = length(ARGS) >= 1 ? parse(Float64, ARGS[1]) : 1800.0

n, e, t = read_dln_instance()

start_t = time()
status, obj_val = solve_nuclear_waste_ilp(n, e, t, time_limit)
total_time = time() - start_t

println("--- Results ---")
println("Solver Status: $status")
println("Total Execution Time: $(round(total_time, digits=4))s")

if obj_val !== nothing
    println("Objective Value (Deposits): $(Int(round(obj_val)))")
else
    println("Objective Value (Deposits): -")
end