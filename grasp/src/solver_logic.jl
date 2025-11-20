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
    
    # Initialize best solution
    best_sol = generate_trivial_solution(n, emissions, tolerances)
    
    # Variable to store the cost of the initial solution
    first_construction_cost = -1

    iter = 0
    while iter < num_iterations
        if (time() - start_time) > time_limit
            break
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

    return best_sol.cost, final_assignments
end

# --- Construction Phase ---

function construct_greedy_randomized(n::Int, emissions::Vector{Int}, tolerances::Vector{Int}, alpha::Float64)
    unassigned = collect(1:n)
    
    # Sort by Tolerance Ascending (bottlenecks first)
    sort!(unassigned, by = i -> tolerances[i])

    assignment = zeros(Int, n)
    deposits = Dict{Int, Deposit}()
    deposit_counter = 0

    while !isempty(unassigned)
        deposit_counter += 1
        current_deposit_id = deposit_counter
        
        # Start new deposit with a seed from RCL
        rcl_size = max(1, floor(Int, length(unassigned) * alpha))
        seed_idx = rand(1:rcl_size)
        seed_item = unassigned[seed_idx]
        
        # Create new Deposit object with seed item
        deposits[current_deposit_id] = Deposit(
            [seed_item], 
            emissions[seed_item], 
            tolerances[seed_item]
        )
        assignment[seed_item] = current_deposit_id
        deleteat!(unassigned, seed_idx)
        
        # Fill deposit
        can_add = true
        while can_add && !isempty(unassigned)
            # Identify valid candidates based on CACHED deposit stats
            current_dep = deposits[current_deposit_id]
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
                assignment[selected_item] = current_deposit_id
                
                deleteat!(unassigned, selected_real_idx)
            end
        end
    end

    return Solution(assignment, deposit_counter, deposits)
end

# --- Local Search Phase ---

function local_search!(sol::Solution, emissions::Vector{Int}, tolerances::Vector{Int})
    # Strategy: Try to empty small deposits into others
    improved = true
    while improved
        improved = false
        dep_ids = collect(keys(sol.deposits))
        
        # Sort: try to empty smallest deposits first
        sort!(dep_ids, by = id -> length(sol.deposits[id].containers))
        
        for source_id in dep_ids
            if !haskey(sol.deposits, source_id) continue end
            
            source_dep = sol.deposits[source_id]
            items_to_move = copy(source_dep.containers)
            
            moves = Tuple{Int, Int}[] # (item, target_deposit_id)
            possible_targets = collect(keys(sol.deposits))
            filter!(x -> x != source_id, possible_targets)
            shuffle!(possible_targets)

            # Snapshot state for feasibility checking
            # We map ID -> temporary Deposit clone to simulate moves without breaking the loop
            temp_targets = Dict(id => deepcopy(sol.deposits[id]) for id in possible_targets)
            
            can_distribute_all = true
            
            for item in items_to_move
                item_moved = false
                for target_id in possible_targets
                    target_dep = temp_targets[target_id]
                    
                    if can_insert(target_dep, item, emissions, tolerances)
                        # Apply move to TEMPORARY target
                        add_to_deposit!(target_dep, item, emissions, tolerances)
                        push!(moves, (item, target_id))
                        item_moved = true
                        break
                    end
                end
                
                if !item_moved
                    can_distribute_all = false
                    break
                end
            end
            
            if can_distribute_all
                # Apply moves PERMANENTLY
                for (item, target_id) in moves
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