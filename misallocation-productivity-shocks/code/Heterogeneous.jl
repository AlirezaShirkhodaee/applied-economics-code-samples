module Heter
    using LinearAlgebra, Statistics, Distributions
    using Interpolations, LaTeXStrings, Parameters, Roots
    using Optim, Random, DataFrames, CSV, Plots, Plots.PlotMeasures

    include("Model.jl") # .DpModel
    include("PolicyCalculation.jl") # .PolicyCalc
    include("Simulation.jl") # SimulationTS.
    
    # Monte Carlo Sampling Weight
    function z_bar_weight(;μ_z_bar=0.0, σ_z_bar=0.35, length=7)
        dist = Normal(μ_z_bar, σ_z_bar)
        z_bar_values = range(-2σ_z_bar, stop=2σ_z_bar, length=length)
        weights = pdf.(dist, z_bar_values)
        weights /= sum(weights)    
        scaled_weights = round.(Int, weights .* 1000)
        return z_bar_values, scaled_weights
    end

    function data_generator(; m_bar=0, γₖ=-0.15, γₐ=-0.2, ϕₙ=0.02, ϕₐ=0.02,
        σᵢ=0.05, σₘ=0.05, financial_access=10000, σ_z_bar=0.35, simulation_time=10000)

        # Initialize a model with the given parameters
        m = DpModel.Model(σₘ=σₘ)

        # Generate common shocks for the simulation period
        shocks_m = m.shocks_m_sim(simulation_time, 14030614)
        
        # Generate a list of productivity levels and their corresponding weights
        x_list, x_weight = z_bar_weight(σ_z_bar=σ_z_bar)
        firms_p = sum(x_weight)

        # Initialize matrices to store simulation results
        k_list = zeros(firms_p, simulation_time)  # Capital levels
        i_list = zeros(firms_p, simulation_time)  # Investment levels
        y_list = zeros(firms_p, simulation_time)  # Output levels
        t_list = zeros(firms_p, simulation_time)  # Tax levels
        mrpk_list = zeros(firms_p, simulation_time)  # Marginal revenue product of capital

        # Index to track each firm in the simulation
        i = 1

        # Loop through each productivity level and its corresponding weight
        for (index, x) in pairs(x_list)
            # Create a new model for each productivity level
            m = DpModel.Model(z_bar=x, m_bar=m_bar, γₖ=γₖ, γₐ=γₐ, ϕₙ=ϕₙ, ϕₐ=ϕₐ,
                σᵢ=σᵢ, σₘ=σₘ, financial_access=financial_access)
            
            # Calculate the policy function for the given model
            p, m = PolicyCalc.policy_calculation(m, verbose=false)

            # Simulate the firm-level data for each occurrence of the given productivity level
            for j ∈ 1:x_weight[index]
                # Generate firm-level shocks for the simulation period
                shocks_z_i = m.shocks_z_sim(simulation_time + m.skipped_step, i)
                
                # Perform the time series simulation for the given firm
                simulation_ts = SimulationTS.simulate_ts(m, p, shocks_z_i, shocks_m)
                
                # Store the simulation results in the corresponding lists
                k_list[i, :] = simulation_ts[1, :]
                i_list[i, :] = simulation_ts[2, :]
                y_list[i, :] = simulation_ts[3, :]
                t_list[i, :] = simulation_ts[4, :]
                mrpk_list[i, :] = simulation_ts[5, :]
                
                # Increment the firm index
                i += 1
            end
        end

        # Return the results of the simulation
        return k_list, i_list, y_list, t_list, mrpk_list
    end

    function aggregation(x_mat)
        # Sum each column of the input matrix
        column_sums = sum(x_mat, dims=1)
        # Calculate the mean of the column sums
        mean_value = mean(column_sums)
        # Calculate the standard deviation of the column sums
        std_value = std(column_sums)
        return mean_value, std_value
    end
    
    function variation(x_mat)
        # Calculate the variance for each column of the input matrix
        column_var = var(x_mat, dims=1)
        # Calculate the mean of the column variances
        mean_value = mean(column_var)
        # Calculate the standard deviation of the column variances
        std_value = std(column_var)
        return mean_value, std_value
    end

    function report(file_name, k, i, y, t, mrpk)
        # Calculate aggregate values for each variable
        K_total, K_prc = aggregation(k)
        I_total, I_prc = aggregation(i)
        Y_total, Y_prc = aggregation(y)
        Pₖ_var, Pₖ_prc = variation(t)
        MRPK_var, MRPK_prc = variation(mrpk)
    
        # Store the calculated values in a DataFrame
        value = [K_total, I_total, Y_total, Pₖ_var, MRPK_var] 
        std = [K_prc, I_prc, Y_prc, Pₖ_prc, MRPK_prc]
        df = DataFrame(hcat(value, std)', [:K_total, :I_total, :Y_total, :Pₖ_var, :MRPK_var])
        df.Title = ["value", "std"]
        select!(df, :Title, :K_total, :I_total, :Y_total, :Pₖ_var, :MRPK_var)
    
        # Save the DataFrame as a CSV file
        CSV.write(file_name * ".csv", df)
        println(file_name * " is saved as csv")
    
        return df
    end

    function arsh_model(;file_name="Baseline", m_bar=0, γₖ=-0.15, γₐ=-0.2, ϕₙ=0.02, ϕₐ=0.02,
        σᵢ=0.05, σₘ=0.05, financial_access=10000, σ_z_bar=0.35)
    
        # Generate firm-level data using the data generator function
        k, i, y, t, mrpk = data_generator(m_bar=m_bar, γₖ=γₖ, γₐ=γₐ, ϕₙ=ϕₙ,
            ϕₐ=ϕₐ, σᵢ=σᵢ, σₘ=σₘ, financial_access=financial_access, σ_z_bar=σ_z_bar)    
            
        # Create a report with the generated data
        df = report(file_name, k, i, y, t, mrpk)
        return df
    end

    function arsh_models_m_bar()
        m_bar_values = -0.5:0.25:0.5
        dfs = []
    
        for m_bar in m_bar_values
            file_name = "m_bar=$(m_bar)"
            df = arsh_model(file_name=file_name, m_bar=m_bar)
            push!(dfs, df)
        end
        df = vcat(dfs...)
        return df
    end

    function plot_mrpk(data)
        # Extract MRPK values and standard deviations
        mrpk_values = data[1:2:end, :MRPK_var]
        mrpk_std = data[2:2:end, :MRPK_var]

        # Calculate confidence intervals (using 1.96 for a 95% confidence interval)
        confidence_interval = 1.96 .* mrpk_std
        upper_bound = mrpk_values .+ confidence_interval
        lower_bound = mrpk_values .- confidence_interval

        # Plot MRPK and its confidence interval
        p = plot(1:length(mrpk_values), mrpk_values, 
            ribbon=(mrpk_values .- lower_bound), 
            lw=2, 
            label="VAR(mrpk)", 
            xlabel="Average Common Productivity", 
            ylabel="VAR(mrpk)", 
            title="Misallocation vs Average Common Productivity",
            titlefont=font(13),
            margin = 5mm)
        return p
    end
end