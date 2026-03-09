# ~/~ begin <<README.md#src/CAExplorer.jl>>[init]
module CAExplorer
    using GLMakie
    using Observables
    using CarboKitten
    using CarboKitten.Components: CellularAutomaton as CA

    # ~/~ begin <<README.md#ca-explorer-methods>>[init]
    function burn_in_state(input, state)
        step! = CA.step!(input)
        for _ in 1:100
            step!(state)
        end
        state
    end
    # ~/~ end
    # ~/~ begin <<README.md#ca-explorer-methods>>[1]
    function tic(t, dt, running)
        @async begin
            while running[]
                sleep(dt)
                t[] += dt
            end
        end
    end
    # ~/~ end

    function main()
        # ~/~ begin <<README.md#ca-explorer-main>>[init]
        @info "Welcome to CarboKitten's CAExplorer.jl!"
        
        input = CA.Input(
            box = CarboKitten.Box{Periodic{2}}(
                grid_size=(50, 50), phys_scale=1.0u"m"),
            facies = fill(CA.Facies(), 3)
        )
        state = CA.initial_state(input)
        image = Observable(state.ca)
        
        fig = Figure(size=(800, 800))
        ax = Axis(fig[1, 1], aspect=DataAspect(),
            xticksvisible=false, xticklabelsvisible=false,
            yticksvisible=false, yticklabelsvisible=false)
        
        sg = SliderGrid(fig[2, 1],
                ( label = "min viability", range = 0:25, startvalue = 4 ),
                ( label = "max viability", range = 0:25, startvalue = 10 ),
                ( label = "min activation", range = 0:25, startvalue = 6 ),
                ( label = "max activation", range = 0:25, startvalue = 10 ))
        
        t = Observable(0.0)
        fig[3, 1] = button_grid = GridLayout(tellwidth = false)
        reset_button = button_grid[1, 1] = Button(fig, label="Reset")
        step_button = button_grid[1, 2] = Button(fig, label="Step")
        running = button_grid[1, 3] = Toggle(fig, active=false)
        button_grid[1, 4] = Label(fig, lift(x -> x ? "Playing" : "Paused", running.active))
        
        on(running.active) do activated
            if activated
                tic(t, 0.01, running.active)
            end
        end
        
        step! = lift([s.value for s in sg.sliders]..., reset_button.clicks) do i, j, k, l, _
            facies = [
                CA.Facies((i, j), (k, l)),
                CA.Facies((i, j), (k, l)),
                CA.Facies((i, j), (k, l)),
            ]
            input = CA.Input(
                box = CarboKitten.Box{Periodic{2}}(
                    grid_size=(50, 50), phys_scale=1.0u"m"),
                facies = facies
            )
            CA.step!(input)
        end
        
        onany(t, step_button.clicks) do _, _
            step![](state)
            image[] = state.ca
        end
        
        heatmap!(ax, image)
        fig
        # ~/~ end
    end

    function make_readme_figures()
        # ~/~ begin <<README.md#default-input>>[init]
        input = CA.Input(
            box = CarboKitten.Box{Periodic{2}}(
                grid_size=(50, 50), phys_scale=1.0u"m"
            ),
            facies = fill(CA.Facies(), 3)
        )
        # ~/~ end
        # ~/~ begin <<README.md#plot-figures>>[init]
        let
            fig = Figure()
            x_axis, y_axis = box_axes(input.box)
            local_state = CA.initial_state(input)
            ax = Axis(fig[1, 1], aspect=DataAspect(), xlabel="x [m]", ylabel="y [m]")
            heatmap!(ax, x_axis |> in_units_of(u"m"), y_axis |> in_units_of(u"m"), local_state.ca)
            save("fig/noise.png", fig)
        end
        # ~/~ end
        # ~/~ begin <<README.md#plot-figures>>[1]
        let
            fig = Figure()
            x_axis, y_axis = box_axes(input.box)
              local_state = burn_in_state(input, CA.initial_state(input))
            ax = Axis(fig[1, 1], aspect=DataAspect(), xlabel="x [m]", ylabel="y [m]")
            heatmap!(ax, x_axis |> in_units_of(u"m"), y_axis |> in_units_of(u"m"), local_state.ca)
            save("fig/after-burn-in.png", fig)
        end
        # ~/~ end
        # ~/~ begin <<README.md#plot-figures>>[2]
        let
            input = CA.Input(
                box = CarboKitten.Box{Periodic{2}}(
                    grid_size=(50, 50), phys_scale=1.0u"m"),
                facies = fill(CA.Facies(), 3)
            )
        
            state = CA.initial_state(input)
            step! = CA.step!(input)
        
            for _ in 1:1000
                step!(state)
            end
        
            fig = Figure(size=(1000, 500))
            axes_indices = Iterators.flatten(eachrow(CartesianIndices((2, 4))))
            xaxis, yaxis = box_axes(input.box)
            i = 1000
        
            for row in 1:2
                for col in 1:4
                    ax = Axis(fig[row, col], aspect=AxisAspect(1), title="step $(i)")
        
                    if row == 2
                        ax.xlabel = "x [m]"
                    end
                    if col == 1
                        ax.ylabel = "y [m]"
                    end
        
                    heatmap!(ax, xaxis/u"m", yaxis/u"m", state.ca)
                    step!(state)
                    i += 1
                end
                for _ in 1:996
                    step!(state)
                    i += 1
                end
            end
            save("fig/ca-long-term.png", fig)
        end
        # ~/~ end
    end
end
# ~/~ end
