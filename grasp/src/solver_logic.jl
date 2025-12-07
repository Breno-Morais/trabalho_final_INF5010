using Random

# --- Data Structures ---

mutable struct Deposit
    containers::Vector{Int}
    current_emission::Int      # Cached sum of emissions
    current_min_tolerance::Int # Cached minimum tolerance
end

mutable struct Solution
    # assignment[i] = j: container i is in deposit j
    assignment::Vector{Int}
    cost::Int
    # map deposit (j) to the Deposit object
    deposits::Dict{Int, Deposit}
end

# --- Main Solver Loop ---

function grasp_solver(n::Int, emissions::Vector{Int}, tolerances::Vector{Int}, num_iterations::Int, time_limit::Float64, alpha::Float64)
    start_time = time()
    if(num_iterations < 0)
        num_iterations = typemax(Int)
    end
    
    # Initialize best solution
    best_sol = generate_trivial_solution(n, emissions, tolerances)
    
    # Variable to store the cost of the initial solution
    first_construction_cost = -1

    iter = 0
    while iter < num_iterations
        if(time_limit > 0)
            if (time() - start_time) > time_limit
                break
            end
        end
        
        iter += 1
        
        # Guloso − Randomizado(α)
        candidate_sol = construct_greedy_randomized(n, emissions, tolerances, alpha)
        
        # Capture the Inital Solution from the first iteration's construction phase
        if iter == 1
            first_construction_cost = candidate_sol.cost
        end

        # Local Search
        local_search!(candidate_sol, emissions, tolerances)
        
        # Update Best
        if candidate_sol.cost < best_sol.cost
            best_sol = deepcopy(candidate_sol)
            println("New best found at iteration $iter: $(best_sol.cost) deposits")
        end
    end

    # If loop didn't run, fallback
    if first_construction_cost == -1
        first_construction_cost = best_sol.cost 
    end

    # Convert Deposit objects back to simple Vectors for data_io compatibility
    final_assignments = Dict{Int, Vector{Int}}()
    for (id, dep) in best_sol.deposits
        final_assignments[id] = dep.containers
    end

    return best_sol.cost, final_assignments, first_construction_cost
end

# --- Construction Phase ---

function construct_greedy_randomized(n::Int, emissions::Vector{Int}, tolerances::Vector{Int}, alpha::Float64)
    unassigned = collect(1:n)

    assignment = zeros(Int, n)
    deposits = Dict{Int, Deposit}()
    deposit_counter = 0

    while !isempty(unassigned)
        deposit_counter += 1
        
        # Prioriza criar depósitos com alta capacidade
        sort!(unassigned, by = i -> tolerances[i] - (0.1 * emissions[i]), rev = true)

        # Start new deposit with a seed from RCL
        rcl_size = max(1, floor(Int, length(unassigned) * alpha))
        seed_idx = rand(1:rcl_size)
        seed_item = unassigned[seed_idx]
        
        deposits[deposit_counter] = Deposit(
            [seed_item], 
            emissions[seed_item], 
            tolerances[seed_item]
        )

        assignment[seed_item] = deposit_counter
        deleteat!(unassigned, seed_idx)
        
        # Fill deposit
        can_add = true
        while can_add && !isempty(unassigned)
            # Identify valid candidates based on cached deposit stats
            current_dep = deposits[deposit_counter]
            candidates = Int[]
            
            for (idx, item) in enumerate(unassigned)
                if can_insert(current_dep, item, emissions, tolerances)
                    push!(candidates, idx)
                end
            end
            
            if isempty(candidates)
                can_add = false
            else
                # Greedy selection: Best Fit (Largest Emission)
                sort!(candidates, by = i -> emissions[unassigned[i]], rev=true)
                
                rcl_fill_size = max(1, floor(Int, length(candidates) * alpha))
                selected_idx_idx = rand(1:rcl_fill_size)
                selected_real_idx = candidates[selected_idx_idx]
                selected_item = unassigned[selected_real_idx]
                
                # Update Deposit Object
                add_to_deposit!(current_dep, selected_item, emissions, tolerances)
                assignment[selected_item] = deposit_counter
                
                deleteat!(unassigned, selected_real_idx)
            end
        end
    end

    return Solution(assignment, deposit_counter, deposits)
end

# --- Local Search Phase ---

function local_search!(sol::Solution, emissions::Vector{Int}, tolerances::Vector{Int})
    improved = true
    while improved
        improved = false
        dep_ids = collect(keys(sol.deposits))
        
        # Tenta esvaziar os depósitos menores primeiro pois é mais fácil
        sort!(dep_ids, by = id -> length(sol.deposits[id].containers))
        
        for source_id in dep_ids
            if !haskey(sol.deposits, source_id) continue end
            
            source_dep = sol.deposits[source_id]
            items_to_move = copy(source_dep.containers)
            
            # Estrutura para guardar movimentos parciais antes de commitar (item, target_id)
            potential_moves = Tuple{Int, Int}[]
            
            # Snapshot das capacidades dos alvos para simulação
            targets_snapshot = Dict{Int, Tuple{Int, Int}}()
            for tid in keys(sol.deposits)
                if tid != source_id
                    t_dep = sol.deposits[tid]
                    targets_snapshot[tid] = (t_dep.current_emission, t_dep.current_min_tolerance)
                end
            end

            can_distribute_all = true
            
            for item in items_to_move
                best_target = -1
                min_slack = typemax(Int)
                
                # Tenta achar o melhor lugar para este item onde o
                # melhor lugar é aquele onde sobra menos espaço, mas ainda cabe.
                for (tid, stats) in targets_snapshot
                    curr_e, curr_t = stats
                    
                    # Simula
                    new_emission = curr_e + emissions[item]
                    new_tol = min(curr_t, tolerances[item])
                    
                    if new_emission <= new_tol
                        slack = new_tol - new_emission
                        # Critério de desempate: menor sobra
                        if slack < min_slack
                            min_slack = slack
                            best_target = tid
                        end
                    end
                end
                
                if best_target != -1
                    push!(potential_moves, (item, best_target))
                    # Atualiza o snapshot para que o próximo item considere a nova capacidade
                    old_e, old_t = targets_snapshot[best_target]
                    targets_snapshot[best_target] = (
                        old_e + emissions[item], 
                        min(old_t, tolerances[item])
                    )
                else
                    can_distribute_all = false
                    break
                end
            end
            
            if can_distribute_all
                # Aplica os movimentos de verdade
                for (item, target_id) in potential_moves
                    target_dep = sol.deposits[target_id]
                    add_to_deposit!(target_dep, item, emissions, tolerances)
                    sol.assignment[item] = target_id
                end
                
                delete!(sol.deposits, source_id)
                sol.cost -= 1
                improved = true
                break
            end
        end
    end
end

# --- Helper Functions ---

# Check using cached Deposit stats
function can_insert(dep::Deposit, item::Int, emissions::Vector{Int}, tolerances::Vector{Int})
    new_emission = dep.current_emission + emissions[item]
    new_tol = min(dep.current_min_tolerance, tolerances[item])
    return new_emission <= new_tol
end

# Update Deposit stats
function add_to_deposit!(dep::Deposit, item::Int, emissions::Vector{Int}, tolerances::Vector{Int})
    push!(dep.containers, item)
    dep.current_emission += emissions[item]
    dep.current_min_tolerance = min(dep.current_min_tolerance, tolerances[item])
end

function generate_trivial_solution(n::Int, emissions::Vector{Int}, tolerances::Vector{Int})
    assignment = collect(1:n)
    deposits = Dict{Int, Deposit}()
    for i in 1:n
        deposits[i] = Deposit([i], emissions[i], tolerances[i])
    end
    return Solution(assignment, n, deposits)
end

# When removing 'item' from 'dep' (during a move in Local Search):
function remove_from_deposit!(dep::Deposit, item::Int, emissions::Vector{Int}, tolerances::Vector{Int})
    filter!(x -> x != item, dep.containers)

    dep.current_emission -= emissions[item]

    if isempty(dep.containers)
        dep.current_min_tolerance = typemax(Int)
    else
        new_min = typemax(Int)
        for c in dep.containers
            if tolerances[c] < new_min
                new_min = tolerances[c]
            end
        end
        dep.current_min_tolerance = new_min
    end
end