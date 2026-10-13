module PolicyCalc
    using LinearAlgebra, Statistics, Distributions
    using Interpolations, LaTeXStrings, Parameters, Roots
    using Optim, Random, ColorSchemes, Plots
    using DataFrames, GLM, DelimitedFiles

    export policy_and_value
    export policy_calculation
    export plot_policy

    function T(w, Tw = similar(w); m=m)
        grid_k = m.grid_k                         
        grid_a = m.grid_a
        β = m.β                          
        Π = m.Π
        ap = m.ap                        
        financial_constraint = m.financial_constraint   
        epsilon = 1e-10                    

        # apply linear interpolation to w
        w_func = LinearInterpolation((grid_k, grid_a), w, extrapolation_bc=Line())

        # initiate σ
        σ = similar(w)

        # set Tw[i] = max_kp {Π(a,k,ap,kp) + β E[w(kp,ap)]}
        for (i, k) in enumerate(grid_k)
            for (j, a) in enumerate(grid_a)
                objective(kp) =  mean(Π.(a, k, ap(a), kp) .+ β .* (w_func.(kp, ap(a))))
                res = maximize(objective, epsilon, financial_constraint(a, k))

                σ[i, j] = Optim.maximizer(res)
                Tw[i, j] = Optim.maximum(res)
            end
        end

        return  σ, Tw
    end

    function policy_and_value(m; max_iter=1000, verbose=true, print_skip=20)
        # Initialization
        i, error = 0, Inf
        tol = m.grid_max / 1e5
        converged = true
    
        # Initial policy and value function
        w = [m.grid_k[i] ^ m.α * exp(m.grid_a[j]) for i in 1:m.grid_size_k, j in 1:m.grid_size_a]
        p = copy(w)
    
        # Iteration loop
        while i < max_iter && error > tol
            p_new, w_new = T(w, m=m)
            error = maximum(abs.(w .- w_new))
    
            i += 1
            w, p = w_new, p_new
    
            if verbose && i % print_skip == 0
                println("Error at iteration $i: $error.")
            end
    
            if error > m.grid_max * 10
                println("Divergent error at iteration $i: $error.")
                converged = false
                break
            end
        end
    
        # Convergence check
        if error > tol
            println("Failed to converge!")
            verbose && println("The last error is $error.")
            converged = false
        else
            verbose && println("Converged in $i iterations. The last error is $error.")
        end
    
        return p, w, converged
    end

    function policy_calculation(m; verbose=false, print_skip=50, max_iter=40)
        # Calculate policy and value function using the given model
        p, v, converged = policy_and_value(m, verbose=verbose, print_skip=print_skip)
        
        # Check if the algorithm converged
        if !converged
            # If not converged, print the maximum grid of K
            println("The Maximum grid of K was ", m.grid_max, ".\n")

            # Increase the maximum grid of K to expand the search space
            m.grid_max_internal = 2 * m.grid_max
            m.grid_max = 2 * m.grid_max
            m.grid_k = range(m.grid_min, m.grid_max, length=m.grid_size_k)

            # Check if the maximum grid value exceeds the allowed limit
            if m.grid_max_internal > 2^max_iter
                # Print failure message if the grid exceeds the limit
                println("Failed to converge even with increasing maximum grid of K!")
                return
            end

            # Recursively call the function to attempt convergence with the new grid
            p, m = policy_calculation(m; verbose=verbose, print_skip=print_skip)
        end

        # Return the final policy function and updated model
        return p, m
    end


    function plot_policy(policy_function, m; title="Policy Function")
        # Extract capital grid
        k = m.grid_k
        n = m.grid_size_a 

        # Initialize plot
        plot(size=(600,300), legend = :outerright, title=title)
        plot!(k, k * (1-m.δ), lw=1, xlabel=L"k", ylabel=L"k′", label="k(1-δ)", line=:dash, color= RGB(0,0,0))
        
        # Plot each policy function for selected productivity levels
        for i in 1:n   
            plot!(k,
                policy_function[:, i],
                xlabel=L"k", ylabel=L"k′",
                lw=1,
                label="a=$(round(m.grid_a[i], digits=2))",
                color = RGBA(i/n, 0.5 - 0.5* i / n, 0, 0.8),
                line=:dashdot,
            )
        end
        plot!()
    end
end