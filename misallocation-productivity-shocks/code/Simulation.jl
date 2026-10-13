module SimulationTS
    using LinearAlgebra, Statistics, Distributions
    using Interpolations, LaTeXStrings, Parameters, Roots
    using Optim, Random, ColorSchemes, Plots
    using DataFrames, GLM, DelimitedFiles

    export simulate_ts
    export plot_dist

    function simulate_ts(m, p, shocks_z, shocks_m)
        skipped_step = m.skipped_step
        M = length(shocks_m)
        p_func = LinearInterpolation((m.grid_k, m.grid_a), p, extrapolation_bc=Line())
        s = zeros(5, M)
        K = m.ks_max
        z_prod = m.z_bar
        m_prod = m.m_bar

        for i ∈ 1:M
            s[1,i] = K
            Kp = p_func(K, z_prod + m_prod)
            s[2,i] = m.I(K, Kp)
            s[3,i] = m.sales(z_prod + m_prod, K)
            s[4,i] = m.T(z_prod + m_prod, K)
            s[5,i] = m.mrpk(z_prod + m_prod, K)

            # updating
            K = Kp
            z_prod = m.z_next(z_prod, shocks_z[i])
            m_prod = m.m_next(m_prod, shocks_m[i])
        end
        return s[:, (skipped_step+1):end]
    end

    function plot_dist(data)
        function create_histogram(data, title)
            histogram(data,
                bins=32,
                ylabel="Frequency",
                normalize=true,
                title=title,
                titlefont=10,
                xlabelfontsize=8,
                ylabelfontsize=8,
                grid=true,
                legend=false
            )
        end
    
        titles = ["Distribution of Capital",
                "Distribution of Investment",
                "Distribution of Production",
                "Distribution of Capital Price",
                "Distribution of MRPK"]

        plots = map((d, t) -> create_histogram(d, t), eachrow(data), titles)
        plot(plots..., layout=(2, 3), size=(900, 300))
    end
end