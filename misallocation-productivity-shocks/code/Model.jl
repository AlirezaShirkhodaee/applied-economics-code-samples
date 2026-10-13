module DpModel
    using LinearAlgebra, Statistics, Distributions
    using Interpolations, LaTeXStrings, Parameters, Roots
    using Optim, Random

    export Model

    # Normal Truncated Sample
    function normal_shocks(;μ=0, σ=1, n=250, lower_bound=-Inf, upper_bound=Inf, seed=1403)
        Random.seed!(seed)
        d = TruncatedNormal(μ, σ, lower_bound, upper_bound)
        x = rand(d, n)
        return x
    end

    # Non-convex Adjustment Cost
    function non_convex_adj(I, price_gap)
        smallest_num = 0.05
        if(I > smallest_num)
            return price_gap * I 
        elseif (I < -smallest_num)
            return - I 
        else
            return 0        
        end
    end

    # weighted grid
    function quarterspace(grid_min, grid_max, grid_size_k)
        quarter = grid_min + (grid_max-grid_min)/4
        step = (grid_max-grid_min)/4 / div(grid_size_k, 2)
        first_half = range(grid_min, quarter - step, length=div(grid_size_k, 2))
        second_half = range(quarter, grid_max, length=div(grid_size_k, 2))
        grid = vcat(first_half, second_half)
        return grid
    end

    @with_kw mutable struct Model 
        # Deep Parameters
        α::Float64 = 0.67 # Productivity parameter
        β::Float64 = 0.95 # Discount factor
        δ::Float64 = 0.05 # Depreciation rate
        G::Float64 = 1 # Monopolistic competition coef
        price_gap::Float64 = 0.5 # Investment price gap
        γₖ::Float64 = -0.15 # Capital related coefficient of capital Price
        γₐ::Float64 = -0.2 # Productivity related coefficient of capital Price
        ε::Float64 = 0 # Random noise
        ϕₙ::Float64 = 0.02 # Non-convex adjustment cost
        ϕₐ::Float64 = 0.02 # Convext adjustment cost
        financial_access::Float64 = 10000 # Never binded by default

        # Idiosyncratic Shocks (zₜ₊₁ = ρᵢ zₜ + σᵢ)
        n::UInt16 = 32 # Number of simulated shocks
        z_bar::Float64 = 0 # mean of idiosyncratic shock
        ρᵢ::Float64 = 0.8 # AR1 coefficient of idiosyncratic shock
        σᵢ::Float64 = 0.05 # Std of idiosyncratic noise
        ϵᵢ = σᵢ / ((1-(ρᵢ^2))^0.5) # Std of idiosyncratic shock
        
        # Common Shock (mₜ₊₁ = ρₘ mₜ + σₘ)
        m_bar::Float64 = 0 # mean of common shock
        ρₘ::Float64 = 0.8 # AR1 coefficient of common shock
        σₘ::Float64 = 0.01 # Std of common noise
        ϵₘ = σₘ / ((1-(ρₘ^2))^0.5) # Std of common shock
        
        # Productivity (A)
        grid_size_a::UInt16 = 5 # Grid Size of Total Productivity
        grid_a = range(-(4*ϵᵢ+4*ϵₘ) + m_bar + z_bar, (4*ϵᵢ+4*ϵₘ) + m_bar + z_bar, length = grid_size_a) # Grid of Total Productivity (A)
        shocks_z = normal_shocks(μ=0, σ=σᵢ, n=n, lower_bound=-2*σᵢ, upper_bound=2*σᵢ, seed=1402)
        shocks_m = normal_shocks(μ=0, σ=σₘ, n=n, lower_bound=-2*σₘ, upper_bound=2*σₘ, seed=1403)
        ap::Function = (a) -> (((ρᵢ * (ϵᵢ^2) + ρₘ * (ϵₘ^2))/((ϵᵢ^2)+(ϵₘ^2))) * (a-m_bar-z_bar) + m_bar + z_bar) .+ shocks_m .+ shocks_z
        
        # Capital
        grid_size_k::UInt16 = 128 # Number of grid points
        grid_min::Float64 = 1 # Smallest grid point
        A_max::Float64 = exp(m_bar + z_bar +(2*ϵₘ)+(2*ϵᵢ))
        A_min::Float64 = exp(m_bar + z_bar -(2*ϵₘ)-(2*ϵᵢ))
        ks_max::Float64 =  ((β * α * (A_max^(1-γₐ))) / ((1 - β * (1-δ)) * (1+γₖ))) ^ (1/(1-α+γₖ))
        grid_max_internal::Float64 = 500 # Maximum Value of Capital
        grid_max::Float64 = max(4 * ks_max, grid_max_internal) # Largest grid point
        grid_k = quarterspace(grid_min, grid_max, grid_size_k) # Grid of Capital (k)
        
        # Functions
        sales::Function = (a, k) -> G * exp(a) * k^α # Sales 
        T::Function = (a, k) ->  (k ^ γₖ) * exp(γₐ * a + ε) # Capital Price
        I::Function = (k, kp, δ=δ) -> kp-(1-δ) * k # Capital Equation
        k_cost::Function = (ap, kp) -> T(ap, kp) * kp * (1 - β * (1-δ)) # Cost of Capital
        Φ::Function = (k, kp) -> 0.5 * k * (I(k, kp)/k)^2 # Convex Adjustment Cost
        non_Φ::Function = (k, kp) -> non_convex_adj(I(k, kp), price_gap) # Non-convex Adjustment Cost
        Π::Function = (a, k, ap, kp) -> sales(a, k) -  k_cost(ap, kp) - ϕₙ * non_Φ(k, kp)  - ϕₐ * Φ(k, kp) # Profit
        arpk::Function = (a, k) -> k>=1 ? log(sales(a, k) / k) : 1 # Average Return Product of Capital (ARPK)
        mrpk::Function = (a, k) -> k>0 ? log(α * G * exp(a) * k^(α-1)) : NaN # Marginal Return Product of Capital (MRPK)
        financial_constraint::Function = (a, k) -> k*(1-δ) + financial_access * sales(a, k) # Financial Constraint
        
        # Simulation
        ## AR(1) process of idiosyncratic shocks
        z_next::Function = (z, shock) -> ρᵢ * z + (1-ρᵢ) * z_bar + shock 
        ## AR(1) process of common shocks
        m_next::Function = (m, shock) -> ρₘ * m + (1-ρₘ) * m_bar + shock 
        ## skipped period in simulation
        skipped_step::UInt16 = 100 
        ## iid part of idiosyncratic shocks 
        shocks_z_sim = (n, seed) -> normal_shocks(μ=0, σ=σᵢ, n=n+skipped_step, lower_bound=-2*σᵢ, upper_bound=2*σᵢ, seed=seed) 
        ## iid part of common shocks 
        shocks_m_sim = (n, seed) -> normal_shocks(μ=0, σ=σₘ, n=n+skipped_step, lower_bound=-2*σₘ, upper_bound=2*σₘ, seed=seed) 
    end
end